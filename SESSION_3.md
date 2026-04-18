# BetSight SESSION 3 — Bet Tracking + Manual Entry + Settlement + Bankroll + P&L Summary

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` u root direktoriju (pravila sesije, autonomni režim, redoslijed unutar faze model→service→provider→widget→screen)
- `WORKLOG.md` u root direktoriju (S1 i S2 povijest — posebno obrati pažnju na S2 Task 5 (Match Selection) i NavigationController pattern koji ćeš koristiti)
- `SESSION_2.md` ako trebaš kontekst (ne obavezno)

**Nakon čitanja napiši kratki summary (3–5 rečenica) što ćeš raditi, potom nastavi autonomno kroz svih 5 zadataka bez čekanja na developerovu potvrdu.**

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues
2. `flutter build windows` — mora proći (za Task 4 Android promjene pokreni i `flutter build apk --debug`)
3. Dodaj unos u `WORKLOG.md` pod novu sekciju `## Session 3: YYYY-MM-DD — Bet Tracking + Manual Entry + Settlement + Bankroll + P&L Summary` — isti format kao S2 (Task naziv, Status, Opis, Komande, Kreirani fajlovi, Ažurirani fajlovi, Verifikacija)
4. Tek onda prelazi na sljedeći zadatak

**Git:** Claude Code **NE radi git commit ni git push.** Jedino što je dozvoljeno je `git status` za provjeru što je uncommitano. Developer (Neven) preuzima `git add -A; git commit; git push` nakon što pregleda rad.

**Identified Issues:** Ako naiđeš na problem izvan scope-a trenutnog zadatka, zabilježi u sekciju `## Identified Issues` na dnu `WORKLOG.md`.

**Verzija:** u Tasku 1 ažuriraj `pubspec.yaml` na `version: 1.2.0+3` (minor bump jer dodajemo feature set).

---

## Projektni kontekst

S2 je dovršio value bet pipeline (filter + markers + logging). Korisnik sada može pronaći value mečeve i dobiti Claude analizu s jasnim **VALUE/WATCH/SKIP** preporukom. **Ono što nedostaje:** nakon što Claude kaže VALUE, korisnik treba mjesto da *zabilježi bet*, *prati ga*, *zaključi ga* (won/lost/void), i vidi **je li mu strategija radi preko vremena**. To je S3.

**S3 donosi:**

1. **Bet model + perzistencija** — prvi "financial" entity u appu, treba pažljiv dizajn jer će svi kasniji P&L Dashboards (S10) graditi na ovom modelu
2. **Četvrti tab "Bets"** — proširuje navigaciju s 3 na 4 taba, posljedica: `NavigationController.setTab(3)` radi, `IndexedStack` ima 4 children-a
3. **Manual Bet Entry** iz dva mjesta: (a) FAB u Bets tabu, (b) "Log Bet" button u Analysis nakon VALUE preporuke — zatvara E2E flow: Matches → Select → Analyze → VALUE → Log Bet
4. **Bet Settlement flow** — long-press ili tap-action na otvorenom betu → bottom sheet Won/Lost/Void
5. **Bankroll management** u Settings — korisnik postavlja total bankroll, default stake unit, valutu
6. **P&L Summary widget** na vrhu Bets screen-a — osnovne brojke (Total bets, Win rate, ROI, Total P/L) — kompleksnija analitika (equity curve, per-sport breakdown) ostavljamo za S10

**Novi Hive box u S3:** `bets`
**Novi provider u S3:** `BetsProvider`
**Tab count mijenja se:** 3 → 4

---

## TASK 1 — Bet Model + BetsProvider + Hive Box

**Cilj:** Osnovni data layer za bet tracking. Svi kasniji taskovi ovise o ovome.

### Kreiraj fajlove

**`lib/models/bet.dart`:**

```dart
enum BetSelection { home, draw, away }

extension BetSelectionMeta on BetSelection {
  String get display => switch (this) {
    BetSelection.home => 'Home',
    BetSelection.draw => 'Draw',
    BetSelection.away => 'Away',
  };
}

enum BetStatus { pending, won, lost, void_ }

extension BetStatusMeta on BetStatus {
  String get display => switch (this) {
    BetStatus.pending => 'Pending',
    BetStatus.won => 'Won',
    BetStatus.lost => 'Lost',
    BetStatus.void_ => 'Void',
  };
  
  bool get isSettled => this != BetStatus.pending;
}

class Bet {
  final String id;                    // UUID v4 — koristi generateUuid() iz analysis_log.dart
  final Sport sport;
  final String league;
  final String home;
  final String away;
  final BetSelection selection;
  final double odds;                  // decimalne, kako ih korisnik unese
  final double stake;                 // u valuti koju korisnik koristi
  final String? bookmaker;            // optional
  final String? notes;                // optional
  final DateTime placedAt;
  final DateTime? matchStartedAt;     // optional — kickoff time ako je preuzeto iz Match-a
  final BetStatus status;
  final DateTime? settledAt;
  final String? linkedMatchId;        // optional — ako je bet napravljen iz staged Match-a, referenca
  
  const Bet({
    required this.id,
    required this.sport,
    required this.league,
    required this.home,
    required this.away,
    required this.selection,
    required this.odds,
    required this.stake,
    required this.placedAt,
    required this.status,
    this.bookmaker,
    this.notes,
    this.matchStartedAt,
    this.settledAt,
    this.linkedMatchId,
  });
  
  /// Potential payout (if won)
  double get potentialPayout => stake * odds;
  
  /// Potential profit (if won) — payout minus stake
  double get potentialProfit => stake * (odds - 1);
  
  /// Actual profit — null za pending, 0 za void, -stake za lost, +profit za won
  double? get actualProfit {
    return switch (status) {
      BetStatus.pending => null,
      BetStatus.won => stake * (odds - 1),
      BetStatus.lost => -stake,
      BetStatus.void_ => 0.0,
    };
  }
  
  /// Implied probability from odds
  double get impliedProbability => 1 / odds;
  
  Bet copyWith({
    BetStatus? status,
    DateTime? settledAt,
    String? notes,
  }) {
    return Bet(
      id: id,
      sport: sport,
      league: league,
      home: home,
      away: away,
      selection: selection,
      odds: odds,
      stake: stake,
      bookmaker: bookmaker,
      notes: notes ?? this.notes,
      placedAt: placedAt,
      matchStartedAt: matchStartedAt,
      status: status ?? this.status,
      settledAt: settledAt ?? this.settledAt,
      linkedMatchId: linkedMatchId,
    );
  }
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'sport': sport.name,
    'league': league,
    'home': home,
    'away': away,
    'selection': selection.name,
    'odds': odds,
    'stake': stake,
    'bookmaker': bookmaker,
    'notes': notes,
    'placedAt': placedAt.toIso8601String(),
    'matchStartedAt': matchStartedAt?.toIso8601String(),
    'status': status.name,
    'settledAt': settledAt?.toIso8601String(),
    'linkedMatchId': linkedMatchId,
  };
  
  factory Bet.fromMap(Map<dynamic, dynamic> map) => Bet(
    id: map['id'] as String,
    sport: Sport.values.firstWhere((s) => s.name == map['sport']),
    league: map['league'] as String,
    home: map['home'] as String,
    away: map['away'] as String,
    selection: BetSelection.values.firstWhere((s) => s.name == map['selection']),
    odds: (map['odds'] as num).toDouble(),
    stake: (map['stake'] as num).toDouble(),
    bookmaker: map['bookmaker'] as String?,
    notes: map['notes'] as String?,
    placedAt: DateTime.parse(map['placedAt'] as String),
    matchStartedAt: map['matchStartedAt'] == null ? null : DateTime.parse(map['matchStartedAt'] as String),
    status: BetStatus.values.firstWhere((s) => s.name == map['status']),
    settledAt: map['settledAt'] == null ? null : DateTime.parse(map['settledAt'] as String),
    linkedMatchId: map['linkedMatchId'] as String?,
  );
}
```

**Važno:** Enum `void` je Dart keyword pa mora biti `void_` s trailing underscore. Za display string je to "Void" (Python-style).

**`lib/models/bankroll.dart`:**

```dart
class BankrollConfig {
  final double totalBankroll;         // korisnikov bankroll
  final double defaultStakeUnit;      // default stake (1 unit)
  final String currency;              // 'EUR', 'USD', 'GBP', 'HRK', etc.
  
  const BankrollConfig({
    required this.totalBankroll,
    required this.defaultStakeUnit,
    required this.currency,
  });
  
  static const defaultConfig = BankrollConfig(
    totalBankroll: 0,
    defaultStakeUnit: 10,
    currency: 'EUR',
  );
  
  double get stakeAsPercentage => totalBankroll == 0 ? 0 : (defaultStakeUnit / totalBankroll) * 100;
  
  Map<String, dynamic> toMap() => {
    'totalBankroll': totalBankroll,
    'defaultStakeUnit': defaultStakeUnit,
    'currency': currency,
  };
  
  factory BankrollConfig.fromMap(Map<dynamic, dynamic> map) => BankrollConfig(
    totalBankroll: (map['totalBankroll'] as num).toDouble(),
    defaultStakeUnit: (map['defaultStakeUnit'] as num).toDouble(),
    currency: map['currency'] as String,
  );
}
```

**`lib/models/bets_provider.dart`:**

```dart
class BetsProvider extends ChangeNotifier {
  List<Bet> _bets = [];
  BankrollConfig _bankroll = BankrollConfig.defaultConfig;
  String? _error;
  
  BetsProvider() {
    _bets = StorageService.getAllBets();
    final bankrollMap = StorageService.getBankrollConfig();
    if (bankrollMap != null) {
      try {
        _bankroll = BankrollConfig.fromMap(bankrollMap);
      } catch (_) {
        _bankroll = BankrollConfig.defaultConfig;
      }
    }
  }
  
  // Filter getteri
  List<Bet> get allBets => List.unmodifiable(_bets);
  List<Bet> get openBets => _bets.where((b) => b.status == BetStatus.pending).toList()
    ..sort((a, b) => (a.matchStartedAt ?? a.placedAt).compareTo(b.matchStartedAt ?? b.placedAt));
  List<Bet> get settledBets => _bets.where((b) => b.status.isSettled).toList()
    ..sort((a, b) => (b.settledAt ?? b.placedAt).compareTo(a.settledAt ?? a.placedAt));
  
  BankrollConfig get bankroll => _bankroll;
  String? get error => _error;
  
  // P&L kalkulacije na settled bet-ovima
  int get totalBets => _bets.length;
  int get wonBets => _bets.where((b) => b.status == BetStatus.won).length;
  int get lostBets => _bets.where((b) => b.status == BetStatus.lost).length;
  int get voidBets => _bets.where((b) => b.status == BetStatus.void_).length;
  int get pendingBets => _bets.where((b) => b.status == BetStatus.pending).length;
  
  /// Win rate na settled (ne-void) bet-ovima; 0.0 ako nema settled-bets
  double get winRate {
    final decisive = wonBets + lostBets;
    return decisive == 0 ? 0.0 : wonBets / decisive;
  }
  
  /// Total P/L iz svih settled bets
  double get totalProfit => _bets
      .map((b) => b.actualProfit)
      .whereType<double>()
      .fold(0.0, (a, b) => a + b);
  
  /// Total stake plasiran na settled (ne-void) bet-ove
  double get totalStakedOnSettled => _bets
      .where((b) => b.status == BetStatus.won || b.status == BetStatus.lost)
      .map((b) => b.stake)
      .fold(0.0, (a, b) => a + b);
  
  /// ROI (Return on Investment) — total profit kao % staked. 0 ako nema settled.
  double get roi => totalStakedOnSettled == 0 ? 0 : (totalProfit / totalStakedOnSettled) * 100;
  
  // Metode
  Future<void> addBet(Bet bet) async {
    _bets.add(bet);
    await StorageService.saveBet(bet);
    notifyListeners();
  }
  
  Future<void> settleBet(String id, BetStatus status) async {
    assert(status != BetStatus.pending, 'Cannot settle as pending');
    final idx = _bets.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final updated = _bets[idx].copyWith(status: status, settledAt: DateTime.now());
    _bets[idx] = updated;
    await StorageService.saveBet(updated);
    notifyListeners();
  }
  
  Future<void> deleteBet(String id) async {
    _bets.removeWhere((b) => b.id == id);
    await StorageService.deleteBet(id);
    notifyListeners();
  }
  
  Future<void> setBankroll(BankrollConfig config) async {
    _bankroll = config;
    await StorageService.saveBankrollConfig(config.toMap());
    notifyListeners();
  }
}
```

### Ažuriraj fajlove

**`pubspec.yaml`** — version bump:

```yaml
version: 1.2.0+3
```

**`lib/services/storage_service.dart`** — dodaj `bets` box i bankroll metode:

```dart
static const _betsBox = 'bets';
static const _bankrollField = 'bankroll_config';

// U init():
await Hive.openBox(_betsBox);

static Box get _betsBoxRef => Hive.box(_betsBox);

static List<Bet> getAllBets() {
  final maps = _betsBoxRef.values.toList();
  final bets = <Bet>[];
  for (final map in maps) {
    try {
      bets.add(Bet.fromMap(map as Map<dynamic, dynamic>));
    } catch (_) {
      // skip malformed
    }
  }
  return bets;
}

static Future<void> saveBet(Bet bet) => _betsBoxRef.put(bet.id, bet.toMap());
static Future<void> deleteBet(String id) => _betsBoxRef.delete(id);

// Bankroll se sprema u settings box, ne u poseban box
static Map<dynamic, dynamic>? getBankrollConfig() =>
    _box.get(_bankrollField) as Map<dynamic, dynamic>?;
static Future<void> saveBankrollConfig(Map<String, dynamic> config) =>
    _box.put(_bankrollField, config);
```

**`lib/main.dart`** — dodaj BetsProvider u MultiProvider (nakon MatchesProvider, prije AnalysisProvider ili bilo gdje — redoslijed nije kritičan):

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => NavigationController()),
    ChangeNotifierProvider(create: (_) => MatchesProvider()),
    ChangeNotifierProvider(create: (_) => AnalysisProvider()),
    ChangeNotifierProvider(create: (_) => BetsProvider()),
  ],
  child: const BetSightApp(),
)
```

### Verifikacija Taska 1

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Nema runtime testa u ovom tasku — provjera u sljedećim taskovima

---

## TASK 2 — Bets Screen (4. Tab) + Open/Settled Tabs

**Cilj:** Proširiti navigaciju s 3 na 4 taba. Novi Bets tab ima TabBar (Open / Settled) + listu bet kartica.

### Kreiraj fajlove

**`lib/screens/bets_screen.dart`** — StatefulWidget s SingleTickerProviderStateMixin, TabController(length: 2):

- Scaffold.body → Column:
  - PlSummaryWidget na vrhu (kreiran u Tasku 5, za sad placeholder SizedBox.shrink())
  - TabBar (controller: _tabController, tabs: [Tab("Open"), Tab("Settled")])
  - Expanded → TabBarView:
    - Tab 0: Consumer<BetsProvider> → `_buildBetList(provider.openBets)` ili empty state (sentiment_neutral icon + "No open bets — tap + to log one")
    - Tab 1: isto s `settledBets` + empty state ("No settled bets yet")
- Scaffold.floatingActionButton: FloatingActionButton(onPressed: → _showManualBetEntry, child: Icon(Icons.add))

`_buildBetList(List<Bet> bets)` → ListView.builder s BetCard widgetom (Task 3 kreira)

`_showManualBetEntry(BuildContext context)` otvara bottom sheet (detalji u Task 3).

**`lib/widgets/bet_card.dart`:**

BetCard (StatelessWidget) — props: `bet` (Bet), `onSettle` (VoidCallback? — samo ako je pending), `onDelete` (VoidCallback?):

- Card → InkWell (onTap: → showDetailsDialog ili bottom sheet s detaljima):
  - Padding(16) → Column:
    - **Header Row:** sport.icon + SizedBox(8) + Text(league bold) + Spacer + StatusChip (coloured badge po statusu)
    - SizedBox(12)
    - **Selection Row:** Text("${bet.home} vs ${bet.away}", small grey) + SizedBox(4) + Text("Pick: ${selection.display}", bold)
    - SizedBox(8)
    - **Odds/Stake Row:** Chip("Odds ${odds.toStringAsFixed(2)}") + SizedBox(8) + Chip("Stake ${stake.toStringAsFixed(2)} ${currency}")
    - SizedBox(8)
    - **P&L Row** (samo ako settled): bold tekst boji success/error "${profit > 0 ? '+' : ''}${profit.toStringAsFixed(2)} ${currency}"
    - SizedBox(8)
    - **Action Row** (samo ako pending): ElevatedButton.icon(label: "Settle", icon: check_circle_outline, onPressed: onSettle)

StatusChip helper:
- pending → plavi ("Pending")
- won → zeleni ("Won", Icons.check)
- lost → crveni ("Lost", Icons.close)
- void → sivi ("Void")

### Ažuriraj fajlove

**`lib/main.dart`** — proširi MainNavigation na 4 taba:

```dart
BottomNavigationBar(
  currentIndex: nav.currentIndex,
  onTap: (i) => nav.setTab(i),
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.scoreboard_outlined),
      activeIcon: Icon(Icons.scoreboard),
      label: 'Matches',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.auto_awesome_outlined),
      activeIcon: Icon(Icons.auto_awesome),
      label: 'Analysis',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      activeIcon: Icon(Icons.receipt_long),
      label: 'Bets',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ],
),
// IndexedStack:
IndexedStack(
  index: nav.currentIndex,
  children: const [
    MatchesScreen(),
    AnalysisScreen(),
    BetsScreen(),        // NOVO
    SettingsScreen(),
  ],
),
```

**VAŽNO:** AnalysisScreen je sada na indeksu 1 (nepromijenjeno), Settings se pomaknula s 2 na 3. Sve postojeće `NavigationController.setTab(2)` pozive (ako postoje u kodu) treba provjeriti i prebaciti na `setTab(3)` za Settings (ali pretpostavljam da u kodu iz S2 nije bilo direktnih kontroliranih skokova na Settings — samo na Analysis koji ostaje indeks 1).

**`test/widget_test.dart`** — ažuriraj da reflektira 4 taba:

```dart
expect(find.text('Matches'), findsWidgets);
expect(find.text('Analysis'), findsWidgets);
expect(find.text('Bets'), findsWidgets);        // NOVO
expect(find.text('Settings'), findsWidgets);
```

U drugom testu "Bottom navigation switches tabs" dodaj tap na Bets tab i provjeri empty state string ("No open bets" ili sličan).

### Verifikacija Taska 2

- `flutter analyze` → 0 issues
- `flutter test` → 2/2 passed (ili 3/3 ako dodaš test za Bets tab)
- `flutter build windows` → uspješan

---

## TASK 3 — Manual Bet Entry

**Cilj:** Korisnik može ručno unijeti bet na dva načina:
1. **FAB u Bets tabu** → otvara bottom sheet s praznom formom
2. **"Log Bet" button u Analysis screenu** nakon što Claude response sadrži `**VALUE**` marker → otvara isti bottom sheet ali s pre-fill podacima iz staged matches

### Kreiraj fajlove

**`lib/widgets/bet_entry_sheet.dart`:**

StatefulWidget `BetEntrySheet` koji se pokazuje preko `showModalBottomSheet` (fullscreen, `isScrollControlled: true`).

Props:
- `prefilledMatch` (Match?) — ako je dat, sport/league/home/away/matchStartedAt se pre-fillaju iz match-a
- `prefilledSelection` (BetSelection?) — ako je dat (npr. iz Claude "bet on Home" preporuke), radio button pre-selected
- `prefilledOdds` (double?) — ako je dat, odds polje pre-fillano

Fields (svi u scrollable Column):
- **Sport** — dropdown `DropdownButtonFormField<Sport>` (disabled ako prefilled)
- **League** — `TextFormField` (decoration label "League")
- **Home team** — `TextFormField`
- **Away team** — `TextFormField`
- **Selection** — `Row` s 2 ili 3 `ChoiceChip` (Home/Draw/Away; Draw vidljiv samo za soccer)
- **Odds** — `TextFormField` s `keyboardType: TextInputType.numberWithOptions(decimal: true)` + input formatter koji dozvoljava samo brojeve i 1 decimal separator
- **Stake** — isto, pre-fill s `bankroll.defaultStakeUnit`
- **Bookmaker** — optional `TextFormField` (label "Bookmaker (optional)")
- **Notes** — optional `TextFormField` (maxLines: 3, label "Notes (optional)")

Primary action:
- ElevatedButton "Save Bet" (full width) — validira sve required polja (sport, league, home, away, selection, odds > 1.0, stake > 0), kreira novi Bet s generateUuid(), poziva `context.read<BetsProvider>().addBet(bet)`, zatvara sheet, prikazuje SnackBar "Bet logged"

Validator logika:
- Ako je **Selection.draw** odabran ali Sport **nije soccer** → error "Draw only available for soccer"
- Ako je odds ≤ 1.0 → error "Odds must be greater than 1.0"
- Ako je stake ≤ 0 → error "Stake must be positive"
- Empty string fields → error "Required"

### Ažuriraj fajlove

**`lib/screens/bets_screen.dart`** — `_showManualBetEntry` otvara BetEntrySheet bez prefill:

```dart
void _showManualBetEntry(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const BetEntrySheet(),
  );
}
```

**`lib/screens/analysis_screen.dart`** — dodaj "Log Bet" button koji se pojavljuje ispod ChatBubble-a **samo ako ta specifična assistant poruka sadrži `**VALUE**` marker**:

```dart
// U ListView.builder za messages:
itemBuilder: (context, i) {
  final msg = provider.messages[i];
  final isUser = msg.role == 'user';
  final isValueResponse = !isUser && parseRecommendationType(msg.content) == RecommendationType.value;
  
  return Column(
    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      ChatBubble(text: msg.content, isUser: isUser),
      if (isValueResponse) _buildLogBetButton(context),
    ],
  );
},
```

`_buildLogBetButton(context)` → Padding + OutlinedButton.icon(label: "Log this as a bet", icon: Icons.receipt_long):

- onPressed: otvara `BetEntrySheet` s prefilledMatch iz `_stagedMatches.firstOrNull` ili null, prefilledSelection null (Claude može sugerirati, ali ne parsiramo automatski — korisnik ručno označi)

**Napomena za buduće sesije:** parsiranje koji outcome (home/draw/away) Claude preporučuje je **kompleksan NLP problem** — ostavljamo za kasnije (npr. S6 Intelligence Layer može to eksplicitno zatražiti kao strukturirani output).

### Verifikacija Taska 3

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Manuelna provjera flow-a (bez API ključa): FAB u Bets tabu → sheet se otvara → save dummy bet → pojavi se u Open listi

---

## TASK 4 — Bet Settlement

**Cilj:** Korisnik može zaključiti otvoreni bet kao Won/Lost/Void. Settled bet se miče iz Open tab-a u Settled tab, profit se kalkulira automatski.

### Ažuriraj fajlove

**`lib/widgets/bet_card.dart`** — osiguraj da **Settle button** (kreiran u Task 2) poziva helper koji pokazuje bottom sheet (ili AlertDialog) s izborom Won/Lost/Void:

```dart
void _showSettleDialog(BuildContext context, Bet bet) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settle bet', style: Theme.of(sheetContext).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('${bet.home} vs ${bet.away}', style: TextStyle(color: Colors.grey[400])),
          Text('Pick: ${bet.selection.display} @ ${bet.odds.toStringAsFixed(2)}'),
          const SizedBox(height: 24),
          _buildSettleButton(sheetContext, bet, BetStatus.won, '✓ Won', Color(0xFF4CAF50)),
          const SizedBox(height: 8),
          _buildSettleButton(sheetContext, bet, BetStatus.lost, '✗ Lost', Color(0xFFEF5350)),
          const SizedBox(height: 8),
          _buildSettleButton(sheetContext, bet, BetStatus.void_, '— Void', Colors.grey),
        ],
      ),
    ),
  );
}

Widget _buildSettleButton(BuildContext ctx, Bet bet, BetStatus status, String label, Color color) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    onPressed: () async {
      await ctx.read<BetsProvider>().settleBet(bet.id, status);
      if (ctx.mounted) {
        Navigator.of(ctx).pop();
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Bet settled as ${status.display}')),
        );
      }
    },
    child: Text(label, style: const TextStyle(fontSize: 16)),
  );
}
```

**Dodatno:** Swipe-to-delete na BetCard (Dismissible wrapper) za mogućnost brisanja pogrešno unesenog bet-a. Confirm dialog prije brisanja. Na confirm → `provider.deleteBet(id)` + SnackBar.

### Verifikacija Taska 4

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Ručna provjera: dummy pending bet iz Taska 3 → tap Settle → izaberi Won → bet se prebaci u Settled tab s ✓ Won statusom i ispravno kalkuliranim profitom

---

## TASK 5 — Bankroll Management + P&L Summary Widget

**Cilj:** Korisnik postavlja total bankroll, default stake unit i valutu u Settings. Bets screen ima compact P&L summary widget na vrhu (Total bets, Win rate, ROI, Total P/L).

### Kreiraj fajlove

**`lib/widgets/pnl_summary.dart`:**

PlSummaryWidget (StatelessWidget), Consumer<BetsProvider>:

- Ako `provider.totalBets == 0`: return SizedBox.shrink() (ne prikazuj widget uopće)
- Inače: Card (margin horizontal 16, vertical 8) → Padding(16) → Column:
  - **Row 1:** 4 metric column-a ravnomjerno raspoređenih:
    - Column("Total", "${totalBets}", "bets", grey label + bold value + grey unit)
    - Column("Win rate", "${(winRate * 100).toStringAsFixed(1)}%", "${wonBets}W ${lostBets}L", boja: zelena ako >50%, siva ostalo)
    - Column("ROI", "${roi.toStringAsFixed(1)}%", "on ${bankroll.currency}", boja: zelena ako >0, crvena ako <0, siva ako 0)
    - Column("Total P/L", "${totalProfit >= 0 ? '+' : ''}${totalProfit.toStringAsFixed(2)}", bankroll.currency, boja analogno ROI)

Koristi Theme.of(context) za boje (AppTheme.green i AppTheme.red koje su već definirane).

### Ažuriraj fajlove

**`lib/screens/bets_screen.dart`** — zamijeni placeholder s PlSummaryWidget:

```dart
Scaffold(
  body: Column(
    children: [
      const PlSummaryWidget(),   // umjesto SizedBox.shrink()
      TabBar(...),
      Expanded(child: TabBarView(...)),
    ],
  ),
  floatingActionButton: ...,
)
```

**`lib/screens/settings_screen.dart`** — dodaj novu sekciju **"Bankroll"** između postojeće "Value Bets Filter" i "About":

```
┌─────────────────────────────────────────┐
│ 💰 Bankroll                             │
│                                         │
│ Total bankroll        [____100.00____]  │
│ Default stake unit    [_____10.00____]  │
│ Currency              [ EUR ▼ ]         │
│                                         │
│ Default stake: 10.0% of bankroll        │
│                                         │
│ [Save]                                  │
└─────────────────────────────────────────┘
```

Implementacija: Consumer<BetsProvider>, StatefulWidget s kontrolerima za bankroll, stakeUnit, i valutu (DropdownButtonFormField s popisom: EUR, USD, GBP, HRK, CHF, BAM, RSD — prilagodi po potrebi, EUR default).

Dynamic helper tekst ispod polja: `"Default stake: ${(stakeUnit / totalBankroll * 100).toStringAsFixed(1)}% of bankroll"` — upozorenje ako je > 5% (grey text "Industry recommendation: 1-3% per bet").

Save button → validira (totalBankroll > 0, stakeUnit > 0, stakeUnit < totalBankroll), kreira BankrollConfig, poziva `provider.setBankroll(config)`, SnackBar "Bankroll saved".

### Verifikacija Taska 5

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Ručna provjera: Postavi bankroll u Settings → dummy bet → settle kao Won → P&L summary pokazuje ispravne brojke (ROI, Win rate, Total P/L u pravoj valuti)

---

## FINALNA VERIFIKACIJA SESIJE 3

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed (ili 3/3 ako si dodao test za Bets tab)
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK u root: `betsight-v1.2.0.apk` (očekivano ~145 MB, slično S2)
- Verzija: `1.2.0+3`
- Git status: Claude Code **NE commita i NE pusha** — developer preuzima

---

## FINALNI WORKLOG UNOS

Na kraju `WORKLOG.md`-a, nakon postojeće Session 2 sekcije, dodaj:

```markdown
---
---

## Session 3: YYYY-MM-DD — Bet Tracking + Manual Entry + Settlement + Bankroll + P&L Summary

**Kontekst:** S2 završio s working value pipeline-om (filter + markers + logging). S3 zatvara loop: dodaje Bet tracking layer. Korisnik sada može zabilježiti bet (ručno ili iz VALUE preporuke), pratiti ga, zaključiti kao won/lost/void, i pratiti osnovnu P&L statistiku.

---

### Task 1 — Bet Model + BetsProvider + Hive Box
[detalji]

### Task 2 — Bets Screen (4. Tab) + Open/Settled Tabs
[detalji]

### Task 3 — Manual Bet Entry
[detalji]

### Task 4 — Bet Settlement
[detalji]

### Task 5 — Bankroll + P&L Summary
[detalji]

---

### Finalna verifikacija Session 3:
- flutter analyze — 0 issues
- flutter test — N/N passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.2.0.apk
- Verzija: 1.2.0+3
- Git: Claude Code NE commita/pusha — developer preuzima
```

**Ako ima novih Identified Issues** — pod `## Identified Issues` sekciju, zamijeni `*No unresolved issues at this time.*` s listom issues-a.

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši sažetak:

- Ukupno zadataka izvršeno: 5
- Novih Dart fajlova: 5 (bet.dart, bankroll.dart, bets_provider.dart, bets_screen.dart, bet_card.dart, bet_entry_sheet.dart, pnl_summary.dart — može biti više jer je Task 2 možda zahtijevao split)
- Ažuriranih Dart fajlova: [broj]
- Ukupno Dart fajlova u lib/: [novi total, očekivano ~28-30]
- Flutter analyze: 0 issues
- Flutter test: [N]/[N] passed
- Builds: Windows ✓, Android APK ✓ (betsight-v1.2.0.apk)
- Identified Issues (ako ih ima): [lista]
- Sljedeći predloženi korak: **Developer commit-a i push-a S3 na GitHub.** Poslije developer testira full E2E flow na Android-u: Matches → Value Bets → select → Analyze → Claude VALUE → Log Bet → nakon meča Settle → P&L summary. Nakon potvrde da sve radi, planira se **SESSION 4**: analogno CoinSight S4 — **Telegram Refactoring / Intelligence Source** (pasivni čitač javnih tipster kanala, signal filter, ili slična "intelligence source" integracija).

Kraj SESSION 3.
