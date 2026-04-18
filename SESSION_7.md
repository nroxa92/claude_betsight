# BetSight SESSION 7 — Three-Tier Framework + Charts + Push Notifications + Detail Screens

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` (pravila, autonomni režim, redoslijed unutar faze)
- `WORKLOG.md` (S1–S6 povijest — posebno obrati pažnju na: S2 VALUE/WATCH/SKIP markers, S4 Odds Snapshot Engine s drift computaction, S5 cache, S5.5 TradeActionBar, S6 IntelligenceProvider + Intelligence Dashboard + all 5 source services)

**Nakon čitanja napiši kratki summary (5–7 rečenica — ova sesija je kompleksnija od prethodnih) što ćeš raditi, potom nastavi autonomno kroz svih 10 zadataka bez čekanja na developerovu potvrdu.**

**Ovo je najveća sesija dosad.** Spaja CoinSight S8 (Three-Tier Framework) i CoinSight S9 (Charts + Push + Detail). Očekuj ~17 novih Dart fajlova i modifikacije u ~10 postojećih. Ako zapneš negdje, **ne ignoriraj problem** — dokumentiraj u Identified Issues i produži. Djelomičan rad je bolji nego sabotirana sesija.

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues (iznimka: Task 1 tolerira errors koji se riješe u Tasku 2, kao S6 Task 2 pattern)
2. `flutter build windows` — mora proći
3. Dodaj unos u `WORKLOG.md` pod novu sekciju `## Session 7: YYYY-MM-DD — Three-Tier Framework + Charts + Push + Detail Screens`
4. Tek onda prelazi na sljedeći zadatak

**Git:** Claude Code **NE radi git commit ni git push.** Developer preuzima.

**Identified Issues:** Očekivano 3-5 novih issues u sesiji ove veličine. Dokumentirati sve što ne bude riješeno.

**Verzija:** u Tasku 1 ažuriraj `pubspec.yaml` na `version: 3.0.0+8` (**major bump** — Three-Tier je fundamentalna transformacija, analogno CoinSight v4.0.0 bump-u za Three-Tier).

---

## Projektni kontekst

S6 je dovršio Multi-Source Intelligence Layer. Do sada BetSight tretira sve mečeve isto — jedan prompt, jedan value preset, jedan Action Bar. **Ali betting u stvarnosti ima tri potpuno različita pristupa:**

- **PRE-MATCH** (dan ranije) — duboko analiziraš, tražiš value na duže kvote, imaš vremena za DYOR
- **LIVE** (tijekom meča) — momentum shifts, score-based odds movement, in-play bet prilike koje se mijenjaju po minuti
- **ACCUMULATOR** (multi-bet) — kombiniraš 3-5 pick-ova u jedan veliki koeficijent; ključna je **korelacija** (ako oba tima zajedničkog kluba igraju istog dana, to nije nezavisni bet)

Svaki tier zahtijeva **drugačiju analizu, drugačiji prompt, drugačiji UI**.

**S7 istovremeno donosi:**

1. **Three-Tier Framework** — TierProvider, adaptivni UI, tier-specific prompti, per-tier bet tracking
2. **Charts** — fl_chart integracija, Odds Movement Chart (S4 snapshot engine konačno vizualiziran), Form Chart, P&L Equity Curve
3. **Match Detail Screen** — deep dive s per-source intelligence, chart tabs, Match Notes
4. **Push Notifications** — flutter_local_notifications, kickoff countdown, drift alerts, new VALUE alerts

**Novi provideri:** `TierProvider`, `NotificationsService`
**Novi Hive boxovi:** `accumulators`, `match_notes`
**Novi modeli:** `InvestmentTier` enum, `Accumulator`, `MatchNote`
**Novi screen:** `MatchDetailScreen`, `ChartScreen`, `AccumulatorBuilderScreen`

---

## TASK 1 — InvestmentTier + TierProvider + Dependencies

**Cilj:** Data kostur za tier sustav. Novi enum, provider, pubspec dependencies. **Bez UI promjena još — samo temelji.**

### Ažuriraj fajlove

**`pubspec.yaml`** — version bump + nove dependencies:

```yaml
version: 3.0.0+8

dependencies:
  # ... postojeći
  fl_chart: ^0.69.0
  flutter_local_notifications: ^18.0.0
  timezone: ^0.10.0  # required by flutter_local_notifications za scheduling
```

### Kreiraj fajlove

**`lib/models/investment_tier.dart`:**

```dart
enum InvestmentTier { preMatch, live, accumulator }

extension InvestmentTierMeta on InvestmentTier {
  String get display => switch (this) {
    InvestmentTier.preMatch => 'Pre-Match',
    InvestmentTier.live => 'Live',
    InvestmentTier.accumulator => 'Accumulator',
  };
  
  String get icon => switch (this) {
    InvestmentTier.preMatch => '⚽',
    InvestmentTier.live => '🔴',
    InvestmentTier.accumulator => '🏆',
  };
  
  /// Horizon — koliko unaprijed/trajanje
  String get horizon => switch (this) {
    InvestmentTier.preMatch => '24-48h before kickoff',
    InvestmentTier.live => 'In-play',
    InvestmentTier.accumulator => 'Multi-match build',
  };
  
  String get philosophy => switch (this) {
    InvestmentTier.preMatch => 'Deep analysis, find pre-kickoff value',
    InvestmentTier.live => 'React to momentum and in-play odds shifts',
    InvestmentTier.accumulator => 'Build correlated-aware multi-bets',
  };
  
  /// Primary color za UI theming — blue/red/orange
  int get colorValue => switch (this) {
    InvestmentTier.preMatch => 0xFF6C63FF,    // primary purple (app default)
    InvestmentTier.live => 0xFFEF5350,        // red (urgency)
    InvestmentTier.accumulator => 0xFFFFA726, // orange (warmth)
  };
  
  static InvestmentTier fromString(String? name) {
    return InvestmentTier.values.firstWhere(
      (t) => t.name == name,
      orElse: () => InvestmentTier.preMatch,
    );
  }
}
```

**`lib/models/tier_provider.dart`:**

```dart
class TierProvider extends ChangeNotifier {
  InvestmentTier _currentTier = InvestmentTier.preMatch;
  
  TierProvider() {
    final saved = StorageService.getCurrentTier();
    _currentTier = InvestmentTier.fromString(saved);
  }
  
  InvestmentTier get currentTier => _currentTier;
  
  Future<void> setTier(InvestmentTier tier) async {
    if (_currentTier == tier) return;
    _currentTier = tier;
    await StorageService.saveCurrentTier(tier.name);
    notifyListeners();
  }
  
  /// Tier-specific suggestion chips za Analysis screen
  List<String> get suggestionChips => switch (_currentTier) {
    InvestmentTier.preMatch => [
      "Analyze tomorrow's EPL",
      "Best value bets this weekend",
      "Underdog picks under 4.0 odds",
    ],
    InvestmentTier.live => [
      "Live odds movement on watched",
      "In-play value — which matches look mispriced now?",
      "Momentum shift detection",
    ],
    InvestmentTier.accumulator => [
      "Build a 3-leg accumulator from my watched matches",
      "Check correlation in my current selections",
      "Conservative acca — all favorites under 2.0",
    ],
  };
  
  /// Tier-specific context appendix za Claude prompt
  String get claudeContextAppendix => switch (_currentTier) {
    InvestmentTier.preMatch => '''
[TIER: PRE-MATCH — 24-48h horizon]
Focus on deep pre-kickoff analysis. User has time to DYOR. Consider form, H2H, injuries, weather (for outdoor sports), team news. Flag value where bookmaker implied probability < your estimate by at least 3 percentage points.
''',
    InvestmentTier.live => '''
[TIER: LIVE — in-play betting]
Focus on momentum reads and in-play odds drift. If odds data shows recent shift, weigh that heavily. Short decision windows. Favor clear, concise recommendations. Skip if data is ambiguous — no time for user to deliberate.
''',
    InvestmentTier.accumulator => '''
[TIER: ACCUMULATOR — multi-match build]
User is building a multi-bet combo. For each leg, consider correlation: avoid legs that are outcomes of the same match or share dependencies (e.g., both teams from the same league on same day). Total odds multiply — flag if combined odds exceed 20.0 (unrealistic value territory). Encourage 2-4 legs, not 10.
''',
  };
}
```

### Ažuriraj fajlove

**`lib/services/storage_service.dart`** — dodaj tier field:

```dart
static const _currentTierField = 'current_tier';

static String? getCurrentTier() => _box.get(_currentTierField) as String?;
static Future<void> saveCurrentTier(String tierName) => _box.put(_currentTierField, tierName);
```

**`lib/main.dart`** — dodaj TierProvider kao prvi u MultiProvider (jer ostali provideri mogu potencijalno čitati njegov state u budućim verzijama):

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TierProvider()),
    ChangeNotifierProvider(create: (_) => NavigationController()),
    ChangeNotifierProvider(create: (_) => MatchesProvider()),
    ChangeNotifierProvider(create: (_) => AnalysisProvider()),
    ChangeNotifierProvider(create: (_) => BetsProvider()),
    ChangeNotifierProvider(create: (_) => TelegramProvider()),
    ChangeNotifierProvider(/* IntelligenceProvider kao u S6 */),
  ],
  child: const BetSightApp(),
)
```

### Verifikacija Taska 1

- `flutter pub get` — mora proći (nove dependencies install)
- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan (flutter_local_notifications može zahtijevati windows plugin config — ako pukne build, provjeriti windows/runner/CMakeLists.txt — tipski `flutter pub get` sam to rješava)

---

## TASK 2 — Tier Mode Selector UI + Integration

**Cilj:** Global Tier Mode Selector ispod AppBar-a. Cijela app se vizualno adaptira na tier promjenu.

### Kreiraj fajlove

**`lib/widgets/tier_mode_selector.dart`:**

```dart
class TierModeSelector extends StatelessWidget {
  const TierModeSelector({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<TierProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Colors.grey[900]!, width: 0.5),
            ),
          ),
          child: Row(
            children: InvestmentTier.values.map((tier) {
              final isActive = provider.currentTier == tier;
              final tierColor = Color(tier.colorValue);
              return Expanded(
                child: GestureDetector(
                  onTap: () => provider.setTier(tier),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? tierColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? tierColor : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tier.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          tier.display,
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? tierColor : Colors.grey[400],
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
```

### Ažuriraj fajlove

**`lib/main.dart`** — MainNavigation dobije TierModeSelector iznad IndexedStack:

```dart
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, nav, _) {
        return Scaffold(
          body: Column(
            children: [
              // TierModeSelector je GLOBAL — iznad IndexedStack-a (ispod SafeArea top)
              SafeArea(
                bottom: false,
                child: const TierModeSelector(),
              ),
              Expanded(
                child: IndexedStack(
                  index: nav.currentIndex,
                  children: const [
                    MatchesScreen(),
                    AnalysisScreen(),
                    BetsScreen(),
                    SettingsScreen(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: nav.currentIndex,
            onTap: (i) => nav.setTab(i),
            items: const [/* isto */],
          ),
        );
      },
    );
  }
}
```

**Napomena:** zbog dodatnog SafeArea + TierModeSelector-a iznad IndexedStack-a, **svi screeni gube vlastiti SafeArea top** (inače će biti duplo padding). Provjeriti postojeće screen-ove — ako bilo koji ima `SafeArea(top: true)`, promijeniti u `SafeArea(top: false)` ili ukloniti jer je top već pokriven u MainNavigation-u.

### Verifikacija Taska 2

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Ručno (kad korisnik pokrene): tier selector vidljiv iznad svih screen-ova, prebacivanje radi, selected chip dobiva boju tier-a

---

## TASK 3 — Tier-Aware Analysis Screen

**Cilj:** Analysis screen adaptivno mijenja suggestion chipove i Claude context na osnovu trenutnog tier-a.

### Ažuriraj fajlove

**`lib/models/analysis_provider.dart`** — dodaj tier u context injection:

1. Constructor nema direct pristup TierProvider-u, pa ga dohvaćamo kroz `_tier` field koji se setira kroz `setTier`:

```dart
InvestmentTier _currentTier = InvestmentTier.preMatch;

void setCurrentTier(InvestmentTier tier) {
  _currentTier = tier;
  // No notifyListeners — tier promjena ne triggera UI rebuild ovdje
}
```

2. U `_buildUserMessage`, appenda tier kontekst na kraju (ispred user text-a):

```dart
String _buildUserMessage(
  String text, {
  List<Match>? contextMatches,
  List<TipsterSignal>? contextSignals,
  List<Bet>? bettingHistory,
  Map<String, OddsDrift>? driftByMatchId,
  Map<String, IntelligenceReport>? intelligenceReports,
}) {
  final buf = StringBuffer();
  
  // ... postojeći blokovi (SELECTED MATCHES, TIPSTER SIGNALS, BETTING HISTORY, INTELLIGENCE REPORT)
  
  // Tier context — uvijek prisutan, na kraju
  buf.writeln(_currentTier.claudeContextAppendix);
  buf.writeln();
  
  buf.write(text);
  return buf.toString();
}
```

**`lib/screens/analysis_screen.dart`** — suggestion chips su sada iz TierProvider:

```dart
// U _buildEmptyState(), Consumer<TierProvider>:
Consumer<TierProvider>(
  builder: (context, tierProvider, _) {
    return Wrap(
      spacing: 8,
      children: tierProvider.suggestionChips.map((chip) {
        return ActionChip(
          label: Text(chip),
          onPressed: () {
            _textController.text = chip;
            _sendMessage();
          },
        );
      }).toList(),
    );
  },
),
```

**Wire tier promjenu u AnalysisProvider** — u MainNavigation (ili u provider create lambda):

Umjesto da AnalysisProvider listenira TierProvider, najjednostavnije je na svaki `sendMessage` Consumer dohvati trenutni tier i postavi ga:

```dart
// U _sendMessage() u analysis_screen.dart:
void _sendMessage() {
  final text = _textController.text.trim();
  if (text.isEmpty) return;
  _textController.clear();
  
  final tier = context.read<TierProvider>().currentTier;
  final analysis = context.read<AnalysisProvider>();
  analysis.setCurrentTier(tier);
  analysis.sendMessage(text).then((_) => _scrollToBottom());
}
```

### Verifikacija Taska 3

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 4 — Accumulator Model + AccumulatorProvider + Builder Screen

**Cilj:** Kad je Accumulator tier aktivan, korisnik može graditi multi-bet kombinaciju iz watched matches. Svaki odabrani leg ima specifični outcome (Home/Draw/Away). Total odds = multiplikacija svih legs.

### Kreiraj fajlove

**`lib/models/accumulator.dart`:**

```dart
class AccumulatorLeg {
  final String matchId;
  final Sport sport;
  final String league;
  final String home;
  final String away;
  final BetSelection selection;  // reuse iz Bet modela
  final double odds;
  final DateTime kickoff;
  
  const AccumulatorLeg({
    required this.matchId,
    required this.sport,
    required this.league,
    required this.home,
    required this.away,
    required this.selection,
    required this.odds,
    required this.kickoff,
  });
  
  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'sport': sport.name,
    'league': league,
    'home': home,
    'away': away,
    'selection': selection.name,
    'odds': odds,
    'kickoff': kickoff.toIso8601String(),
  };
  
  factory AccumulatorLeg.fromMap(Map<dynamic, dynamic> map) => AccumulatorLeg(
    matchId: map['matchId'] as String,
    sport: Sport.values.firstWhere((s) => s.name == map['sport']),
    league: map['league'] as String,
    home: map['home'] as String,
    away: map['away'] as String,
    selection: BetSelection.values.firstWhere((s) => s.name == map['selection']),
    odds: (map['odds'] as num).toDouble(),
    kickoff: DateTime.parse(map['kickoff'] as String),
  );
}

enum AccumulatorStatus { building, placed, won, lost, partial }

extension AccumulatorStatusMeta on AccumulatorStatus {
  String get display => switch (this) {
    AccumulatorStatus.building => 'Building',
    AccumulatorStatus.placed => 'Placed',
    AccumulatorStatus.won => 'Won',
    AccumulatorStatus.lost => 'Lost',
    AccumulatorStatus.partial => 'Partial',
  };
}

class Accumulator {
  final String id;
  final List<AccumulatorLeg> legs;
  final double stake;
  final AccumulatorStatus status;
  final DateTime createdAt;
  final DateTime? placedAt;
  final DateTime? settledAt;
  final String? notes;
  
  const Accumulator({
    required this.id,
    required this.legs,
    required this.stake,
    required this.status,
    required this.createdAt,
    this.placedAt,
    this.settledAt,
    this.notes,
  });
  
  double get combinedOdds =>
      legs.fold(1.0, (acc, leg) => acc * leg.odds);
  
  double get potentialPayout => stake * combinedOdds;
  double get potentialProfit => stake * (combinedOdds - 1);
  
  double? get actualProfit {
    return switch (status) {
      AccumulatorStatus.building || AccumulatorStatus.placed => null,
      AccumulatorStatus.won => potentialProfit,
      AccumulatorStatus.lost => -stake,
      AccumulatorStatus.partial => 0.0,  // simplification — cash out u budućim sesijama
    };
  }
  
  /// Check for potential correlation issues:
  /// - Two legs from same match (impossible) — return "Same match"
  /// - Two legs from same day same league (weak correlation) — return "Same day/league"
  List<String> get correlationWarnings {
    final warnings = <String>[];
    
    // Same match check
    final matchIds = legs.map((l) => l.matchId).toSet();
    if (matchIds.length < legs.length) {
      warnings.add('Contains multiple legs from the same match');
    }
    
    // Same day same league check
    for (int i = 0; i < legs.length; i++) {
      for (int j = i + 1; j < legs.length; j++) {
        final a = legs[i];
        final b = legs[j];
        if (a.league == b.league &&
            a.kickoff.year == b.kickoff.year &&
            a.kickoff.month == b.kickoff.month &&
            a.kickoff.day == b.kickoff.day) {
          warnings.add('Multiple legs from ${a.league} on same day');
          break;
        }
      }
    }
    
    return warnings;
  }
  
  Accumulator copyWith({
    List<AccumulatorLeg>? legs,
    double? stake,
    AccumulatorStatus? status,
    DateTime? placedAt,
    DateTime? settledAt,
    String? notes,
  }) {
    return Accumulator(
      id: id,
      legs: legs ?? this.legs,
      stake: stake ?? this.stake,
      status: status ?? this.status,
      createdAt: createdAt,
      placedAt: placedAt ?? this.placedAt,
      settledAt: settledAt ?? this.settledAt,
      notes: notes ?? this.notes,
    );
  }
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'legs': legs.map((l) => l.toMap()).toList(),
    'stake': stake,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'placedAt': placedAt?.toIso8601String(),
    'settledAt': settledAt?.toIso8601String(),
    'notes': notes,
  };
  
  factory Accumulator.fromMap(Map<dynamic, dynamic> map) => Accumulator(
    id: map['id'] as String,
    legs: (map['legs'] as List<dynamic>)
        .map((l) => AccumulatorLeg.fromMap(l as Map<dynamic, dynamic>))
        .toList(),
    stake: (map['stake'] as num).toDouble(),
    status: AccumulatorStatus.values.firstWhere((s) => s.name == map['status']),
    createdAt: DateTime.parse(map['createdAt'] as String),
    placedAt: map['placedAt'] == null ? null : DateTime.parse(map['placedAt'] as String),
    settledAt: map['settledAt'] == null ? null : DateTime.parse(map['settledAt'] as String),
    notes: map['notes'] as String?,
  );
}
```

**`lib/models/accumulators_provider.dart`:**

```dart
class AccumulatorsProvider extends ChangeNotifier {
  List<Accumulator> _accumulators = [];
  Accumulator? _currentDraft;   // in-progress acca in Builder screen
  
  AccumulatorsProvider() {
    _accumulators = StorageService.getAllAccumulators();
  }
  
  List<Accumulator> get all => List.unmodifiable(_accumulators);
  Accumulator? get currentDraft => _currentDraft;
  
  List<Accumulator> get building =>
      _accumulators.where((a) => a.status == AccumulatorStatus.building).toList();
  List<Accumulator> get placed =>
      _accumulators.where((a) => a.status == AccumulatorStatus.placed).toList();
  List<Accumulator> get settled =>
      _accumulators.where((a) => [AccumulatorStatus.won, AccumulatorStatus.lost, AccumulatorStatus.partial].contains(a.status)).toList();
  
  void startNewDraft() {
    _currentDraft = Accumulator(
      id: generateUuid(),
      legs: [],
      stake: 0,
      status: AccumulatorStatus.building,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }
  
  void addLegToDraft(AccumulatorLeg leg) {
    if (_currentDraft == null) startNewDraft();
    _currentDraft = _currentDraft!.copyWith(
      legs: [..._currentDraft!.legs, leg],
    );
    notifyListeners();
  }
  
  void removeLegFromDraft(String matchId) {
    if (_currentDraft == null) return;
    _currentDraft = _currentDraft!.copyWith(
      legs: _currentDraft!.legs.where((l) => l.matchId != matchId).toList(),
    );
    notifyListeners();
  }
  
  void setDraftStake(double stake) {
    if (_currentDraft == null) return;
    _currentDraft = _currentDraft!.copyWith(stake: stake);
    notifyListeners();
  }
  
  Future<void> saveDraftAsAccumulator() async {
    if (_currentDraft == null || _currentDraft!.legs.length < 2 || _currentDraft!.stake <= 0) return;
    _accumulators.add(_currentDraft!);
    await StorageService.saveAccumulator(_currentDraft!);
    _currentDraft = null;
    notifyListeners();
  }
  
  Future<void> discardDraft() async {
    _currentDraft = null;
    notifyListeners();
  }
  
  Future<void> placeAccumulator(String id) async {
    final idx = _accumulators.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final updated = _accumulators[idx].copyWith(
      status: AccumulatorStatus.placed,
      placedAt: DateTime.now(),
    );
    _accumulators[idx] = updated;
    await StorageService.saveAccumulator(updated);
    notifyListeners();
  }
  
  Future<void> settleAccumulator(String id, AccumulatorStatus status) async {
    assert([AccumulatorStatus.won, AccumulatorStatus.lost, AccumulatorStatus.partial].contains(status));
    final idx = _accumulators.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final updated = _accumulators[idx].copyWith(
      status: status,
      settledAt: DateTime.now(),
    );
    _accumulators[idx] = updated;
    await StorageService.saveAccumulator(updated);
    notifyListeners();
  }
  
  Future<void> deleteAccumulator(String id) async {
    _accumulators.removeWhere((a) => a.id == id);
    await StorageService.deleteAccumulator(id);
    notifyListeners();
  }
}
```

**`lib/screens/accumulator_builder_screen.dart`:**

Full screen (push route) za gradnju acca. Struktura:

- AppBar s title "Build Accumulator" + IconButton (delete/discard) + IconButton (save)
- Consumer2<AccumulatorsProvider, MatchesProvider>:
  - Ako `currentDraft` null → "Start new accumulator" button → `startNewDraft()`
  - Ako ima draft:
    - **Legs list:** Column s trenutnih legs (dismissible za remove, chip s outcome)
    - **Dodaj leg iz watched matches:** horizontal ListView MatchCard-ova iz `matches.allMatches.where(isWatched)` — tap otvara outcome picker dialog (Home/Draw/Away)
    - **Stake input:** TextField s currency label
    - **Summary card:** legs count, combined odds (bold), potential payout
    - **Correlation warnings:** orange banner ako `correlationWarnings.isNotEmpty`
    - **Footer:** Save button (disabled ako <2 legs ili stake ≤0)

Helper dialog za outcome picker:
```dart
Future<BetSelection?> _pickOutcome(BuildContext context, Match match) {
  return showDialog<BetSelection>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('${match.home} vs ${match.away}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.h2h != null) ...[
            _outcomeTile(context, 'Home', match.h2h!.home, BetSelection.home),
            if (match.sport.hasDraw && match.h2h!.draw != null)
              _outcomeTile(context, 'Draw', match.h2h!.draw!, BetSelection.draw),
            _outcomeTile(context, 'Away', match.h2h!.away, BetSelection.away),
          ],
        ],
      ),
    ),
  );
}

Widget _outcomeTile(BuildContext ctx, String label, double odds, BetSelection sel) => 
    ListTile(
      title: Text('$label @ ${odds.toStringAsFixed(2)}'),
      onTap: () => Navigator.pop(ctx, sel),
    );
```

### Ažuriraj fajlove

**`lib/services/storage_service.dart`** — dodaj Accumulator CRUD:

```dart
static const _accumulatorsBox = 'accumulators';

// u init():
await Hive.openBox(_accumulatorsBox);

static Box get _accaBox => Hive.box(_accumulatorsBox);

static List<Accumulator> getAllAccumulators() {
  final list = <Accumulator>[];
  for (final map in _accaBox.values) {
    try { list.add(Accumulator.fromMap(map as Map<dynamic, dynamic>)); }
    catch (_) {}
  }
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}
static Future<void> saveAccumulator(Accumulator acca) => _accaBox.put(acca.id, acca.toMap());
static Future<void> deleteAccumulator(String id) => _accaBox.delete(id);
```

**`lib/main.dart`** — dodaj AccumulatorsProvider:

```dart
ChangeNotifierProvider(create: (_) => AccumulatorsProvider()),
```

### Verifikacija Taska 4

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 5 — Tier-Aware Bets Screen + Accumulator Integration

**Cilj:** Bets screen se adaptira per-tier: PRE-MATCH/LIVE pokazuju klasične bet-ove (postojeće), ACCUMULATOR pokazuje acca.

### Ažuriraj fajlove

**`lib/screens/bets_screen.dart`** — Consumer2<TierProvider, BetsProvider>:

```dart
Consumer<TierProvider>(
  builder: (context, tier, _) {
    if (tier.currentTier == InvestmentTier.accumulator) {
      return _buildAccumulatorView();
    }
    return _buildRegularBetsView(tier.currentTier);
  },
)
```

**`_buildAccumulatorView()`** — Consumer<AccumulatorsProvider>:
- TabBar: Building / Placed / Settled
- Each tab list AccumulatorCard-ova (novi widget, v. dolje)
- FAB: "+" ikonica otvara AccumulatorBuilderScreen kao push route

**`_buildRegularBetsView(tier)`** — postojeći view iz S3, ali filtrira bet-ove:
- PRE-MATCH: pokazuje sve klasične bet-ove (default behavior iz S3)
- LIVE: pokazuje bet-ove koji su placed tijekom live match-a (tj. placedAt > matchStartedAt). Za sada, bez matchStartedAt tracking-a na Bet modelu, ovaj filter je soft — može se dokumentirati kao Identified Issue: *"LIVE tier filtering requires matchStartedAt field on Bet model for strict separation. Currently shows all non-accumulator bets in PRE-MATCH tab."*

### Kreiraj fajlove

**`lib/widgets/accumulator_card.dart`:**

Analogno BetCard-u iz S3, ali prikazuje:
- Header: "${legs.length} legs" + StatusChip + combined odds badge
- Legs preview (max 3 vidljiva + "+X more"): "${home} vs ${away} — ${selection}"
- Stake + Payout row
- Action buttons:
  - Building: [Edit] [Place] [Delete]
  - Placed: [Settle] (otvara sheet Won/Lost/Partial)
  - Settled: [Delete]
- Dismissible za swipe delete s confirm dialog

### Verifikacija Taska 5

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 6 — fl_chart Integration + OddsMovementChart + FormChart + EquityCurveChart

**Cilj:** 3 chart widget-a koji se koriste u budućim screen-ovima (MatchDetailScreen u Task 7, P&L u Task 9).

### Kreiraj fajlove

**`lib/widgets/charts/odds_movement_chart.dart`:**

Koristi fl_chart `LineChart`. Input: List<OddsSnapshot>. X-axis: vrijeme. Y-axis: decimalne kvote. Tri linije: home (plava), draw (narančasta, samo soccer), away (crvena).

```dart
class OddsMovementChart extends StatelessWidget {
  final List<OddsSnapshot> snapshots;
  final bool showDraw;
  
  const OddsMovementChart({super.key, required this.snapshots, required this.showDraw});
  
  @override
  Widget build(BuildContext context) {
    if (snapshots.length < 2) {
      return Center(
        child: Text('Not enough snapshots yet (${snapshots.length}/2)',
            style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    final baseTime = snapshots.first.capturedAt.millisecondsSinceEpoch;
    
    List<FlSpot> homeSpots = [];
    List<FlSpot> drawSpots = [];
    List<FlSpot> awaySpots = [];
    
    for (final s in snapshots) {
      final x = (s.capturedAt.millisecondsSinceEpoch - baseTime) / (1000 * 60 * 60); // hours offset
      homeSpots.add(FlSpot(x, s.home));
      if (showDraw && s.draw != null) drawSpots.add(FlSpot(x, s.draw!));
      awaySpots.add(FlSpot(x, s.away));
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(spots: homeSpots, color: Colors.blue, barWidth: 2, isCurved: true, dotData: const FlDotData(show: false)),
          if (showDraw && drawSpots.isNotEmpty)
            LineChartBarData(spots: drawSpots, color: Colors.orange, barWidth: 2, isCurved: true, dotData: const FlDotData(show: false)),
          LineChartBarData(spots: awaySpots, color: Colors.red, barWidth: 2, isCurved: true, dotData: const FlDotData(show: false)),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) {
            return Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 10));
          })),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (value, meta) {
            return Text('${value.toStringAsFixed(0)}h', style: const TextStyle(fontSize: 10));
          })),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 0.2),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
```

**`lib/widgets/charts/form_chart.dart`:**

Horizontal bar chart pokazujući W/D/L iz forme za oba tima. Input: form stringova `['W','W','D','L','W']`.

```dart
class FormChart extends StatelessWidget {
  final String teamName;
  final List<String> form;  // ['W','D','L','W','W']
  const FormChart({super.key, required this.teamName, required this.form});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: form.asMap().entries.map((entry) {
            final result = entry.value;
            final color = switch (result) {
              'W' => Colors.green,
              'D' => Colors.grey,
              'L' => Colors.red,
              _ => Colors.transparent,
            };
            return Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(result, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

**`lib/widgets/charts/equity_curve_chart.dart`:**

Kumulativni P&L kroz vrijeme — koristi u P&L dashboardu. Input: List<Bet> (settled only).

```dart
class EquityCurveChart extends StatelessWidget {
  final List<Bet> settledBets;  // sorted by settledAt ascending
  final String currency;
  
  const EquityCurveChart({super.key, required this.settledBets, required this.currency});
  
  @override
  Widget build(BuildContext context) {
    if (settledBets.length < 2) {
      return Center(child: Text('Not enough settled bets', style: TextStyle(color: Colors.grey[500])));
    }
    
    final sorted = [...settledBets]
      ..sort((a, b) => (a.settledAt ?? a.placedAt).compareTo(b.settledAt ?? b.placedAt));
    
    double running = 0;
    final spots = <FlSpot>[const FlSpot(0, 0)];
    for (int i = 0; i < sorted.length; i++) {
      running += sorted[i].actualProfit ?? 0;
      spots.add(FlSpot((i + 1).toDouble(), running));
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: running >= 0 ? Colors.green : Colors.red,
            barWidth: 2,
            isCurved: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (running >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) {
            return Text('${value.toStringAsFixed(0)}$currency', style: const TextStyle(fontSize: 9));
          })),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, getTitlesWidget: (value, meta) {
            return Text('#${value.toInt()}', style: const TextStyle(fontSize: 9));
          })),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
```

### Verifikacija Taska 6

- `flutter analyze` → 0 issues (fl_chart treba raditi nakon `flutter pub get` u Tasku 1)
- `flutter build windows` → uspješan

---

## TASK 7 — MatchDetailScreen + MatchNote

**Cilj:** Zasebni push route iz MatchCard tap. Deep dive: tabovi za Overview/Intelligence/Charts/Notes.

### Kreiraj fajlove

**`lib/models/match_note.dart`:**

```dart
class MatchNote {
  final String matchId;
  final String text;
  final DateTime updatedAt;
  
  const MatchNote({required this.matchId, required this.text, required this.updatedAt});
  
  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'text': text,
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  factory MatchNote.fromMap(Map<dynamic, dynamic> map) => MatchNote(
    matchId: map['matchId'] as String,
    text: map['text'] as String,
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );
}
```

**`lib/screens/match_detail_screen.dart`:**

DefaultTabController s 4 taba (Overview / Intelligence / Charts / Notes):

- AppBar: title "${home} vs ${away}", actions: star toggle (watched), share (placeholder)
- TabBar: Overview | Intelligence | Charts | Notes
- TabBarView:

**Tab 1 — Overview:**
- League + kickoff countdown
- Odds prikaz (full H2H markets)
- Quick stats row (bookmaker, margin)
- "Analyze in AI" button → stage match + navigate to Analysis tab

**Tab 2 — Intelligence:**
- Consumer<IntelligenceProvider>.reportFor(match.id)
- Prikaz sličan IntelligenceMatchCard-u iz S6 Dashboard-a (reused _IntelligenceMatchCard kao public widget)
- Generate/Refresh button

**Tab 3 — Charts:**
- OddsMovementChart (koristi `getSnapshotsForMatch(match.id)`)
- FormChart home + FormChart away (ako postoji `getFootballSignal(match.id)`)
- NBA: last10 results (koristi NbaStatsSignal iz Storage-a)

**Tab 4 — Notes:**
- TextField s multiline (min 5 lines)
- Save button → `StorageService.saveMatchNote(...)`
- Last updated timestamp
- Simple text field — korisnik bilježi svoje misli prije klade (trigger za disciplinu)

### Ažuriraj fajlove

**`lib/services/storage_service.dart`** — dodaj match_notes box + CRUD:

```dart
static const _matchNotesBox = 'match_notes';

// u init():
await Hive.openBox(_matchNotesBox);

static Box get _notesBox => Hive.box(_matchNotesBox);

static MatchNote? getMatchNote(String matchId) {
  final map = _notesBox.get(matchId);
  if (map == null) return null;
  try { return MatchNote.fromMap(map as Map<dynamic, dynamic>); }
  catch (_) { return null; }
}
static Future<void> saveMatchNote(MatchNote note) => _notesBox.put(note.matchId, note.toMap());
static Future<void> deleteMatchNote(String matchId) => _notesBox.delete(matchId);
```

**`lib/widgets/match_card.dart`** — tap na MatchCard otvara MatchDetailScreen:

```dart
onTap: () {
  if (selectable) {
    onSelectionToggle?.call();
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
    );
  }
},
```

### Verifikacija Taska 7

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 8 — Push Notifications Service

**Cilj:** Tri tipa local notifications: kickoff countdown (24h / 1h / 15min before), drift alert (kad OddsDrift > 5%), new VALUE alert (kad Claude vrati VALUE u Analysis bez user presence).

### Kreiraj fajlove

**`lib/services/notifications_service.dart`:**

```dart
class NotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  
  static Future<void> init() async {
    if (_initialized) return;
    
    tz.initializeTimeZones();
    
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }
  
  static Future<void> requestPermissions() async {
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
  
  static const _kickoffChannel = AndroidNotificationDetails(
    'kickoff_channel', 'Kickoff Alerts',
    channelDescription: 'Notifications for upcoming match kickoff',
    importance: Importance.defaultImportance,
  );
  
  static const _driftChannel = AndroidNotificationDetails(
    'drift_channel', 'Odds Drift Alerts',
    channelDescription: 'Significant odds movement on watched matches',
    importance: Importance.high,
  );
  
  static const _valueChannel = AndroidNotificationDetails(
    'value_channel', 'Value Signal Alerts',
    channelDescription: 'Claude detected new VALUE recommendation',
    importance: Importance.high,
  );
  
  /// Schedule kickoff reminders (24h, 1h, 15min before)
  static Future<void> scheduleKickoffReminders(Match match) async {
    if (!_initialized) await init();
    final id = match.id.hashCode;
    
    final reminders = [
      (Duration(hours: 24), 'Match starts in 24 hours'),
      (Duration(hours: 1), 'Match starts in 1 hour'),
      (Duration(minutes: 15), 'Match starts in 15 minutes'),
    ];
    
    for (final (before, msg) in reminders) {
      final scheduledAt = match.commenceTime.subtract(before);
      if (scheduledAt.isBefore(DateTime.now())) continue;
      
      await _plugin.zonedSchedule(
        id + before.inSeconds,
        '${match.home} vs ${match.away}',
        msg,
        tz.TZDateTime.from(scheduledAt, tz.local),
        const NotificationDetails(android: _kickoffChannel),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
  
  static Future<void> cancelKickoffReminders(String matchId) async {
    final id = matchId.hashCode;
    for (final hours in [24 * 3600, 3600, 900]) {
      await _plugin.cancel(id + hours);
    }
  }
  
  /// Immediate drift alert
  static Future<void> showDriftAlert(Match match, OddsDrift drift) async {
    if (!_initialized) await init();
    final dom = drift.dominantDrift;
    await _plugin.show(
      match.id.hashCode,
      '⚡ Drift on ${match.home} vs ${match.away}',
      '${dom.side} ${dom.percent > 0 ? "+" : ""}${dom.percent.toStringAsFixed(1)}%',
      const NotificationDetails(android: _driftChannel),
    );
  }
  
  /// Immediate VALUE alert
  static Future<void> showValueAlert(Match match) async {
    if (!_initialized) await init();
    await _plugin.show(
      match.id.hashCode + 1,
      '🎯 VALUE detected',
      '${match.home} vs ${match.away} — tap to see Claude analysis',
      const NotificationDetails(android: _valueChannel),
    );
  }
  
  static Future<void> cancelAll() => _plugin.cancelAll();
}
```

### Ažuriraj fajlove

**`lib/main.dart`** — init notifications + request permissions u main:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await StorageService.init();
    await NotificationsService.init();
    await NotificationsService.requestPermissions();
    await StorageService.runScheduledCleanup();
  } catch (e) {
    debugPrint('Init error: $e');
  }
  runApp(const BetSightApp());
}
```

**`lib/models/matches_provider.dart`** — hook za watched toggle + drift alert:

```dart
// U toggleWatched metodi:
Future<void> toggleWatched(String matchId) async {
  final match = _allMatches.firstWhere((m) => m.id == matchId, orElse: () => throw StateError('No match'));
  if (_watchedMatchIds.contains(matchId)) {
    _watchedMatchIds.remove(matchId);
    await NotificationsService.cancelKickoffReminders(matchId);  // NOVO
  } else {
    _watchedMatchIds.add(matchId);
    await NotificationsService.scheduleKickoffReminders(match);  // NOVO
  }
  await StorageService.saveWatchedMatchIds(_watchedMatchIds);
  notifyListeners();
}

// U _captureSnapshotsForWatched, nakon saveSnapshotIfChanged, check drift:
if (didSave) {
  final drift = driftForMatch(match.id);
  if (drift != null && drift.hasSignificantMove) {
    // Show drift alert only if significant move (>5%) — threshold je strikter nego UI indicator
    final dominantAbs = drift.dominantDrift.percent.abs();
    if (dominantAbs >= 5) {
      await NotificationsService.showDriftAlert(match, drift);
    }
  }
}
```

**`lib/models/analysis_provider.dart`** — VALUE alert u sendMessage:

```dart
// Nakon successful response i AnalysisLog save, ako recommendation je VALUE i postoji stagedMatch:
if (parseRecommendationType(assistantResponse) == RecommendationType.value &&
    _stagedMatches.isNotEmpty) {
  try {
    await NotificationsService.showValueAlert(_stagedMatches.first);
  } catch (_) {/* notification failure ne smije blokirati UX */}
}
```

### Verifikacija Taska 8

- `flutter analyze` → 0 issues
- `flutter build apk --debug` → uspješan (notifications najbolje testirati na Android-u)
- **Ručni test** (kad developer instalira APK): watched toggle → provjeri da li scheduled kickoff reminder pusti ikonu u notifikacijskoj traci.

---

## TASK 9 — Tier-Aware P&L Summary

**Cilj:** PlSummaryWidget u Bets screen-u se proširi s breakdown-om po tier-u. Plus EquityCurveChart u novom P&L sekciji.

### Ažuriraj fajlove

**`lib/widgets/pnl_summary.dart`** — proširi s tier breakdown + chart:

```dart
class PlSummaryWidget extends StatelessWidget {
  const PlSummaryWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<BetsProvider, AccumulatorsProvider>(
      builder: (context, bets, accas, _) {
        if (bets.totalBets == 0 && accas.all.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          children: [
            // Existing 4-metric card (totalBets / winRate / ROI / totalProfit) — samo za bets
            _buildMetricsCard(context, bets),
            
            // Equity curve chart — samo ako postoji settled bets
            if (bets.settledBets.length >= 2)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Equity Curve', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: EquityCurveChart(
                          settledBets: bets.settledBets,
                          currency: bets.bankroll.currency,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildMetricsCard(BuildContext context, BetsProvider bets) {
    // ... postojeći kod iz S3 Task 5
  }
}
```

### Verifikacija Taska 9

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 10 — Polish + Settings Integration + Final Verification

**Cilj:** Zadnje sitnice. Settings sekcija za notifikacije (toggle po tipu), tier awareness u Analysis screen empty state-ovi, final testing.

### Ažuriraj fajlove

**`lib/screens/settings_screen.dart`** — nova sekcija "Notifications" iznad "About":

```
┌────────────────────────────────────────┐
│ 🔔 Notifications                        │
│                                         │
│ ☑  Kickoff reminders (24h/1h/15m)     │
│ ☑  Odds drift alerts (>5%)            │
│ ☑  VALUE signal alerts                 │
│                                         │
│ ⓘ Permission status: [Granted]         │
└────────────────────────────────────────┘
```

Samo vizualne toggles — underlying logika može ostati always-on za sada, ili dodati per-type enable field u StorageService (preferirano ako ima vremena).

Koristi postojeći `SwitchListTile` pattern iz Telegram sekcije.

**Analysis screen empty state** — personaliziraj za tier:

```dart
// U _buildEmptyState(), tier-aware title:
Consumer<TierProvider>(
  builder: (_, tier, __) => Column(
    children: [
      Text(tier.currentTier.icon, style: const TextStyle(fontSize: 36)),
      const SizedBox(height: 8),
      Text('${tier.currentTier.display} analysis',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      Text(tier.currentTier.philosophy,
          style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      const SizedBox(height: 16),
      // Suggestion chips iz Task 3
    ],
  ),
),
```

### Test widget update

**`test/widget_test.dart`** — proširi setUpAll s novim boxovima i provideri:

```dart
setUpAll(() async {
  final tempDir = Directory.systemTemp.createTempSync();
  Hive.init(tempDir.path);
  await Hive.openBox('settings');
  await Hive.openBox('analysis_logs');
  await Hive.openBox('bets');
  await Hive.openBox('tipster_signals');
  await Hive.openBox('odds_snapshots');
  await Hive.openBox('odds_cache');
  await Hive.openBox('monitored_channels_detail');
  await Hive.openBox('intelligence_reports');
  await Hive.openBox('football_signals_cache');
  await Hive.openBox('nba_signals_cache');
  await Hive.openBox('reddit_signals_cache');
  await Hive.openBox('accumulators');
  await Hive.openBox('match_notes');
});

// U main test wrapper, svi novi provideri:
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TierProvider()),
    // ... postojeći
    ChangeNotifierProvider(create: (_) => AccumulatorsProvider()),
    // ... ostali
  ],
  // ...
)
```

### Finalna verifikacija Session 7

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed (ili više ako dodani novi testovi)
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK u root: `betsight-v3.0.0.apk` (očekivano ~150 MB)
- Verzija: **`3.0.0+8`** (major bump)
- Git: Claude Code **NE commita/pusha** — developer preuzima

---

## FINALNI WORKLOG UNOS

Na kraju `WORKLOG.md`-a, nakon postojeće Session 6 sekcije, dodaj:

```markdown
---
---

## Session 7: YYYY-MM-DD — Three-Tier Framework + Charts + Push + Detail Screens

**Kontekst:** S1-S6 izgradili single-tier multi-source platformu. S7 uvodi tri investicijska horizonta (PRE-MATCH / LIVE / ACCUMULATOR), svaki s vlastitim Claude promptom, suggestion chips, i Bets screen prikazom. Pored toga: Charts (odds movement, form, equity curve), MatchDetailScreen (deep dive s 4 taba), Push Notifications (kickoff + drift + VALUE), tier-aware empty states. **Major bump na 3.0.0+8** — ovo je fundamentalna transformacija iz single-strategy u multi-strategy platformu.

---

### Task 1 — InvestmentTier + TierProvider + Dependencies
[detalji]

### Task 2 — Tier Mode Selector UI + Integration
[detalji]

### Task 3 — Tier-Aware Analysis Screen
[detalji]

### Task 4 — Accumulator Model + AccumulatorsProvider + Builder Screen
[detalji]

### Task 5 — Tier-Aware Bets Screen + Accumulator Integration
[detalji]

### Task 6 — fl_chart Integration + Chart Widgets
[detalji]

### Task 7 — MatchDetailScreen + MatchNote
[detalji]

### Task 8 — Push Notifications Service
[detalji]

### Task 9 — Tier-Aware P&L Summary + Equity Curve
[detalji]

### Task 10 — Polish + Settings Integration + Final Verification
[detalji]

---

### Finalna verifikacija Session 7:
- flutter analyze — 0 issues
- flutter test — N/N passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v3.0.0.apk
- Verzija: 3.0.0+8 (major bump)
- Git: Claude Code NE commita/pusha — developer preuzima
```

**Identified Issues** — očekivano 3-5 novih. Kandidati:
- "LIVE tier filtering nedostaje matchStartedAt tracking" (Task 5)
- "Notifications per-type enable nije implementiran ako preskočen u Tasku 10"
- "Accumulator stake validation treba bolju UX (prihvata negative u TextField-u)"
- "Chart dimensions na malim uređajima (<360 dp) mogu preklapati axis labele"
- "MatchDetailScreen Charts tab za Basketball/Tennis prikazuje samo NBA stats, ne i tennis stats (jer ne postoji tennis service)"

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši sažetak:

- Ukupno zadataka izvršeno: 10
- Novih Dart fajlova: **~17** (investment_tier, tier_provider, tier_mode_selector, accumulator, accumulators_provider, accumulator_builder_screen, accumulator_card, charts/odds_movement_chart, charts/form_chart, charts/equity_curve_chart, match_note, match_detail_screen, notifications_service, i dodatne helpere)
- Ažuriranih Dart fajlova: [broj, očekivano ~10]
- Ukupno Dart fajlova u lib/: [novi total, očekivano ~65]
- Nove dependencies: fl_chart, flutter_local_notifications, timezone
- Flutter analyze: 0 issues
- Flutter test: N/N passed
- Builds: Windows ✓, Android APK ✓ (betsight-v3.0.0.apk)
- **Version: 3.0.0+8 (major bump)** — BetSight je sada multi-strategy intelligence platforma
- Sljedeći predloženi korak: **Developer commit-a i push-a S7 na GitHub.** Ovo je **najveća kvalitativna skok u projektu** — od sada korisnik ima tri kompletna pristupa (pre-match DYOR, live reactive, accumulator multi-bet) s vlastitim prompima i UX-om. **Stvarni real-world test prijeko potreban prije bilo kakve dalje sesije** — testirati sva tri tiera, provjeriti notifications na Android-u, bilježiti u BETLOG.md ishode. Nakon 3-5 dana testa planira se **SESSION 8 — User Experience Polish + Stabilization** (analogno CoinSight S10 P&L Dashboard proširenje): per-sport P&L, per-tier detaljna analitika, filter/search u Bets screenu, cleaner empty states, potencijalne bug fixes iz real-world testa.

Kraj SESSION 7.
