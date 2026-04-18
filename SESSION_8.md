# BetSight SESSION 8 — Stabilization + P&L Breakdown + Filter/Search

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` (pravila, autonomni režim, redoslijed unutar faze)
- `WORKLOG.md` (S1–S7 povijest — posebno obrati pažnju na: S6 IntelligenceProvider auto-refresh API, S7 TierProvider + matchStartedAt issue, postojeća PlSummaryWidget struktura iz S3)
- `WORKLOG.md` → `## Identified Issues` sekcija — ovo je **primarni input** za S8. Taskovi 1-5 su direktno mapirani na te issues.

**Nakon čitanja napiši kratki summary (3–5 rečenica) što ćeš raditi, potom nastavi autonomno kroz svih 8 zadataka bez čekanja na developerovu potvrdu.**

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues
2. `flutter build windows` — mora proći (za Task 8 pokreni i `flutter build apk --debug`)
3. Dodaj unos u `WORKLOG.md` pod novu sekciju `## Session 8: YYYY-MM-DD — Stabilization + P&L Breakdown + Filter/Search`
4. Tek onda prelazi na sljedeći zadatak

**Git:** Claude Code **NE radi git commit ni git push.** Developer preuzima.

**Identified Issues:** Kako S8 rješava postojeće issues, OBAVEZNO ukloni **riješene issues** iz `## Identified Issues` sekcije. Samo oni koji ostaju (Telegram Bot API by-design) ili koji se otkriju tijekom S8 ostaju.

**Verzija:** u Tasku 1 ažuriraj `pubspec.yaml` na `version: 3.1.0+9` (**minor bump** — mix bugfix + new functionality).

---

## Projektni kontekst

S7 je donio Three-Tier Framework + Charts + Push + Detail screens, ali zbog opsega te sesije **nekoliko high-impact issues ostalo je nedovršeno**:

1. **IntelligenceProvider auto-refresh nije wired iz UI** — hibrid refresh radi samo on-demand button, Timer.periodic se nikad ne pokreće (gubi se polovica S6 namjere)
2. **LIVE tier filtering je soft** — Bets screen u LIVE tieru pokazuje sve bet-ove kao i u PRE-MATCH jer Bet model nema `matchStartedAt` polje (gubi se polovica S7 Three-Tier namjere)
3. **Football-Data API key change zahtijeva app restart** — IntelligenceAggregator se gradi jednom u MultiProvider lambda-i
4. **Notifications per-type enable nije implementiran** — 3 tipa notifikacija (kickoff / drift / value) su always-on
5. **FD fuzzy match je naivan substring** — "Manchester" može zbrojiti United i City

**Plus polish iz CoinSight S10 pattern-a** (to je zapravo najveći dio koda u sesiji, ne bugfixes):

6. **Per-sport P&L breakdown** — Bets screen pokazuje ukupni P&L ali ne po sportu. Korisniku treba vidjeti koji sport mu donosi novac, koji gubi.
7. **Filter/search u Bets screenu** — po datumu, sport, status, selection. Trenutno je lista koja raste unedogled.

**S8 uklanja 5 Identified Issues iz backlog-a** (ostaje samo Telegram Bot API by-design i potencijalno 1-2 cosmetic, npr. Accumulator import hide).

---

## TASK 1 — IntelligenceProvider Auto-Refresh Wire-up + Pubspec Bump

**Cilj:** Hibrid refresh iz S6 konačno pokrenut. Timer.periodic(1h) gated na hasApiKey + watched matches non-empty. Wire-up iz MainNavigation (MultiProvider context pristup).

**Rješava issue:** *IntelligenceProvider auto-refresh nije wired iz UI-ja*

### Ažuriraj fajlove

**`pubspec.yaml`** — version bump: `version: 3.1.0+9`

**`lib/models/intelligence_provider.dart`** — revidirati `startAutoRefresh` API da prima callback koji vraća watched matches list (API već postoji iz S6, ali nije bio pozvan):

```dart
void startAutoRefresh(List<Match> Function() watchedProvider) {
  stopAutoRefresh();
  _autoRefreshTimer = Timer.periodic(const Duration(hours: 1), (_) async {
    final watched = watchedProvider();
    if (watched.isEmpty) return;
    // Force = true jer je auto-refresh smisao — uvijek dohvati svježe
    await refreshAllWatched(watched, force: true);
  });
}
```

**`lib/main.dart`** — u MainNavigation StatefulWidget (ako nije već StatefulWidget, konvertirati):

```dart
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  bool _autoRefreshStarted = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pokreni auto-refresh jednom, kad je widget tree spreman
    if (!_autoRefreshStarted) {
      _autoRefreshStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final intel = context.read<IntelligenceProvider>();
        intel.startAutoRefresh(() {
          final matches = context.read<MatchesProvider>();
          return matches.allMatches.where((m) => matches.isWatched(m.id)).toList();
        });
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ... postojeći Consumer<NavigationController> + Scaffold sa TierModeSelector-om i IndexedStack-om
  }
}
```

**Važno:** `startAutoRefresh` ne treba `dispose` override za cancel jer se IntelligenceProvider sam dispose-a (timer se zatvara u provider.dispose override-u koji postoji iz S6).

### Verifikacija Taska 1

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- **Manual check (dokumentiraj u WORKLOG):** app se pokrene, otvori Intelligence Dashboard za watched match, zapamti `cachedAt`; čeka se sat vremena ili manually edituje Hive da simulira expiry; ponovno otvoriti app — Timer će se pokrenuti u pozadini.

---

## TASK 2 — LIVE Tier Filtering (matchStartedAt on Bet + Filter Logic)

**Cilj:** Bet model dobiva `matchStartedAt` polje (nullable DateTime). LIVE tier u Bets screen-u pokazuje samo bet-ove gdje `placedAt > matchStartedAt`. PRE-MATCH pokazuje ostale.

**Rješava issue:** *LIVE tier filtering nedostaje matchStartedAt na Bet model*

### Ažuriraj fajlove

**`lib/models/bet.dart`** — dodaj `matchStartedAt` nullable polje:

```dart
class Bet {
  // ... postojeća polja
  final DateTime? matchStartedAt;  // NOVO — kickoff time u trenutku klade
  
  const Bet({
    // ... postojeći required
    this.matchStartedAt,
  });
  
  /// True ako je bet stavljen NAKON početka meča (live bet)
  bool get isLiveBet {
    if (matchStartedAt == null) return false;
    return placedAt.isAfter(matchStartedAt!);
  }
  
  /// True ako je bet stavljen PRIJE početka meča (pre-match bet)
  /// Bet-ovi bez matchStartedAt podatka se tretiraju kao pre-match (backward compat)
  bool get isPreMatchBet => !isLiveBet;
  
  // toMap/fromMap proširiti s matchStartedAt
  Map<String, dynamic> toMap() => {
    // ... postojeći
    'matchStartedAt': matchStartedAt?.toIso8601String(),
  };
  
  factory Bet.fromMap(Map<dynamic, dynamic> map) => Bet(
    // ... postojeći
    matchStartedAt: map['matchStartedAt'] == null
        ? null
        : DateTime.parse(map['matchStartedAt'] as String),
  );
  
  // copyWith proširiti s matchStartedAt
}
```

**`lib/widgets/bet_entry_sheet.dart`** — kad je tier LIVE, popuni `matchStartedAt = DateTime.now()` (simulira da je meč već počeo). Kad je PRE-MATCH, uzmi kickoff iz `prefilledMatch`:

```dart
// U onSave handleru:
final tierProvider = context.read<TierProvider>();
final tier = tierProvider.currentTier;

DateTime? matchStartedAt;
if (tier == InvestmentTier.live) {
  // Live bet — meč je već počeo, placedAt > matchStartedAt by construction
  matchStartedAt = DateTime.now().subtract(const Duration(minutes: 1));  // 1 min buffer
} else if (prefilledMatch != null) {
  // Pre-match bet — matchStartedAt je match.commenceTime
  matchStartedAt = prefilledMatch.commenceTime;
}

final bet = Bet(
  // ... ostala polja iz sheet
  matchStartedAt: matchStartedAt,
);
```

**`lib/screens/bets_screen.dart`** — u `_buildRegularBetsView(tier)`, primjeni filter:

```dart
List<Bet> _filterBetsForTier(List<Bet> bets, InvestmentTier tier) {
  return switch (tier) {
    InvestmentTier.preMatch => bets.where((b) => b.isPreMatchBet).toList(),
    InvestmentTier.live => bets.where((b) => b.isLiveBet).toList(),
    InvestmentTier.accumulator => [],  // accumulator tier koristi različit view
  };
}

// U build:
final filteredBets = _filterBetsForTier(bets.allBets, tier);
```

**Migracijski detalj:** Stari bet-ovi (prije S8) nemaju `matchStartedAt` — tretiramo ih kao pre-match (`isPreMatchBet = true`). Ovo znači da **postojeći bet-ovi nakon S8 upgrade-a ostaju u PRE-MATCH tier-u**, što je razumno.

### Verifikacija Taska 2

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Test: unesi bet u PRE-MATCH tier, prebaci tier na LIVE — ne smije ga pokazati. Unesi bet u LIVE tier, prebaci na PRE-MATCH — ne smije ga pokazati.

---

## TASK 3 — Football-Data Dynamic Re-wire

**Cilj:** Kad korisnik u Settings spremi novi Football-Data API ključ, FootballDataService se unutar IntelligenceAggregator-a **odmah** update-a bez app restart-a.

**Rješava issue:** *Football-Data API key change requires app restart*

### Ažuriraj fajlove

**`lib/models/intelligence_provider.dart`** — dodaj metodu za re-wire FD servisa:

```dart
void updateFootballDataApiKey(String? newKey) {
  if (newKey == null || newKey.isEmpty) {
    _footballService = null;
  } else {
    _footballService = FootballDataService()..setApiKey(newKey);
  }
  // Rebuild aggregator s novim servisom
  _aggregator = IntelligenceAggregator(
    oddsService: _oddsService,
    footballService: _footballService,
    nbaService: _nbaService,
    redditMonitor: _redditMonitor,
    telegramProvider: _telegramProvider,
  );
  notifyListeners();
}
```

**`lib/screens/settings_screen.dart`** — u Football-Data `_ApiKeySection` onSave/onRemove handlerima, pozvati update:

```dart
_ApiKeySection(
  title: 'Football-Data.org API',
  // ...
  onSave: (key) async {
    await StorageService.saveFootballDataApiKey(key);
    if (!context.mounted) return;
    context.read<IntelligenceProvider>().updateFootballDataApiKey(key);
    // Izmjeni SnackBar poruku — više ne treba restart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Football-Data API key saved and active')),
    );
  },
  onRemove: () async {
    await StorageService.deleteFootballDataApiKey();
    if (!context.mounted) return;
    context.read<IntelligenceProvider>().updateFootballDataApiKey(null);
  },
),
```

Isto tretirati potencijalne "restart required" SnackBar poruke u postojećem kodu — svi se miču jer sada nije potreban restart.

### Verifikacija Taska 3

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 4 — Notifications Per-Type Enable + Settings UI

**Cilj:** Settings dobiva 3 SwitchListTile-a za uključi/isključi: kickoff / drift / value alerts. NotificationsService čita flagove iz Storage-a prije nego pošalje notifikaciju.

**Rješava issue:** *Notifications per-type enable nije implementiran*

### Ažuriraj fajlove

**`lib/services/storage_service.dart`** — dodaj 3 enable fielda (default true):

```dart
static const _notifKickoffEnabledField = 'notif_kickoff_enabled';
static const _notifDriftEnabledField = 'notif_drift_enabled';
static const _notifValueEnabledField = 'notif_value_enabled';

static bool getNotifKickoffEnabled() => (_box.get(_notifKickoffEnabledField) as bool?) ?? true;
static Future<void> saveNotifKickoffEnabled(bool v) => _box.put(_notifKickoffEnabledField, v);

static bool getNotifDriftEnabled() => (_box.get(_notifDriftEnabledField) as bool?) ?? true;
static Future<void> saveNotifDriftEnabled(bool v) => _box.put(_notifDriftEnabledField, v);

static bool getNotifValueEnabled() => (_box.get(_notifValueEnabledField) as bool?) ?? true;
static Future<void> saveNotifValueEnabled(bool v) => _box.put(_notifValueEnabledField, v);
```

**`lib/services/notifications_service.dart`** — gate-aj sve metode na odgovarajući flag:

```dart
static Future<void> scheduleKickoffReminders(Match match) async {
  if (!StorageService.getNotifKickoffEnabled()) return;  // NOVO
  // ... postojeći kod
}

static Future<void> showDriftAlert(Match match, OddsDrift drift) async {
  if (!StorageService.getNotifDriftEnabled()) return;  // NOVO
  // ... postojeći kod
}

static Future<void> showValueAlert(Match match) async {
  if (!StorageService.getNotifValueEnabled()) return;  // NOVO
  // ... postojeći kod
}
```

**`lib/screens/settings_screen.dart`** — u "Notifications" sekciji (koja je bila placeholder iz S7 Task 10), dodaj 3 SwitchListTile-a:

```dart
class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();
  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  late bool _kickoff;
  late bool _drift;
  late bool _value;
  
  @override
  void initState() {
    super.initState();
    _kickoff = StorageService.getNotifKickoffEnabled();
    _drift = StorageService.getNotifDriftEnabled();
    _value = StorageService.getNotifValueEnabled();
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.notifications_outlined, size: 18),
              SizedBox(width: 8),
              Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Kickoff reminders', style: TextStyle(fontSize: 13)),
              subtitle: const Text('24h / 1h / 15min before', style: TextStyle(fontSize: 11)),
              value: _kickoff,
              dense: true,
              onChanged: (v) {
                setState(() => _kickoff = v);
                StorageService.saveNotifKickoffEnabled(v);
              },
            ),
            SwitchListTile(
              title: const Text('Odds drift alerts', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Significant movement >5% on watched', style: TextStyle(fontSize: 11)),
              value: _drift,
              dense: true,
              onChanged: (v) {
                setState(() => _drift = v);
                StorageService.saveNotifDriftEnabled(v);
              },
            ),
            SwitchListTile(
              title: const Text('VALUE signal alerts', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Claude detects new value recommendation', style: TextStyle(fontSize: 11)),
              value: _value,
              dense: true,
              onChanged: (v) {
                setState(() => _value = v);
                StorageService.saveNotifValueEnabled(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

Ubaci `_NotificationsSection()` između "Telegram Monitor" i "About" sekcija u Settings screen build metodi.

### Verifikacija Taska 4

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 5 — Football-Data Fuzzy Match Improvement (Token-Based)

**Cilj:** Zamjena substring-based matching-a tokeni-based algoritmom koji ne kolapsira "Manchester United" i "Manchester City".

**Rješava issue:** *Football-Data team name fuzzy matching edge cases*

### Ažuriraj fajlove

**`lib/services/football_data_service.dart`** — revidirati `_normalize` i matching algoritam:

```dart
/// Normalizira naziv tima u set tokena (riječi).
/// "Liverpool FC" → {"liverpool"}
/// "Manchester United" → {"manchester", "united"}
static Set<String> _tokenize(String name) {
  final cleaned = name
      .toLowerCase()
      .replaceAll(RegExp(r'\s+(fc|cf|afc|sc|ac|cd|cb|sl|b\.?k\.?)\b'), '')
      .replaceAll(RegExp(r'[^a-z\s]'), '')
      .trim();
  return cleaned
      .split(RegExp(r'\s+'))
      .where((t) => t.length >= 3)  // ignore tokens kraće od 3 znaka (npr. "cd", "al")
      .toSet();
}

/// Ocjena podudaranja između dva seta tokena.
/// Vraća broj zajedničkih tokena. "Manchester United" vs "Manchester City" = 1 (samo "manchester"),
/// "Manchester United" vs "Manchester United FC" = 2 (manchester + united).
static int _matchScore(Set<String> a, Set<String> b) {
  return a.intersection(b).length;
}

// U `getSignalForMatch`, zamijeni substring matching s token-based:
final oddsHomeTokens = _tokenize(match.home);
final oddsAwayTokens = _tokenize(match.away);

Map<String, dynamic>? fdMatch;
int bestScore = 0;

for (final m in fdMatches) {
  final map = m as Map<String, dynamic>;
  final fdHomeTokens = _tokenize((map['homeTeam'] as Map)['name'] as String);
  final fdAwayTokens = _tokenize((map['awayTeam'] as Map)['name'] as String);
  
  final homeScore = _matchScore(oddsHomeTokens, fdHomeTokens);
  final awayScore = _matchScore(oddsAwayTokens, fdAwayTokens);
  
  // Obje strane moraju imati bar 1 token match, i ukupni score mora biti bolji od dosadašnjeg
  if (homeScore >= 1 && awayScore >= 1) {
    final total = homeScore + awayScore;
    if (total > bestScore) {
      bestScore = total;
      fdMatch = map;
    }
  }
}

if (fdMatch == null) {
  throw FootballDataException('Match not found in Football-Data (no team name match)');
}
```

**Edge case testiranje (dokumentiraj u WORKLOG):** Claude Code neka provjeri kroz runtime assertion ili mental testing:
- "Manchester United" vs "Manchester City" → score 1 each, ali ne smije pogodno zbrojiti ako je samo "manchester" token zajednički (minimum 2 tokens po strani se može zahtijevati ako je sigurno)
- "Real Madrid CF" vs "Real Madrid" → tokens {"real", "madrid"} vs {"real", "madrid"} → score 2 ✓
- "Paris Saint-Germain" → normalize: "paris saintgermain" → tokens {"paris", "saintgermain"} (saintgermain je dovoljno unique)

**Dodatni safety:** ako `bestScore < 2` (jer je "Manchester" jedini match), odbaciti. Trebaju minimalno 2 unique tokena podudaranja (ukupno preko obje strane) za valid match.

```dart
if (bestScore < 2) {
  throw FootballDataException('Match not found (ambiguous team names)');
}
```

### Verifikacija Taska 5

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 6 — Per-Sport P&L Breakdown

**Cilj:** PlSummaryWidget dobiva novu sekciju s P&L po sportu. Tabela: sport | bets | won | lost | ROI%.

### Ažuriraj fajlove

**`lib/models/bets_provider.dart`** — dodaj helper za breakdown:

```dart
/// Breakdown P&L po sportu. Vraća Map gdje su ključevi Sport enum values.
Map<Sport, SportPl> get perSportBreakdown {
  final result = <Sport, SportPl>{};
  for (final sport in Sport.values) {
    final sportBets = settledBets.where((b) => b.sport == sport).toList();
    if (sportBets.isEmpty) continue;
    
    final won = sportBets.where((b) => b.status == BetStatus.won).length;
    final lost = sportBets.where((b) => b.status == BetStatus.lost).length;
    final totalStake = sportBets.fold<double>(0, (sum, b) => sum + b.stake);
    final totalProfit = sportBets.fold<double>(0, (sum, b) => sum + (b.actualProfit ?? 0));
    final roi = totalStake > 0 ? (totalProfit / totalStake) * 100 : 0.0;
    
    result[sport] = SportPl(
      sport: sport,
      bets: sportBets.length,
      won: won,
      lost: lost,
      totalStake: totalStake,
      totalProfit: totalProfit,
      roiPercent: roi.toDouble(),
    );
  }
  return result;
}
```

**`lib/models/sport_pl.dart`** — novi mali model:

```dart
class SportPl {
  final Sport sport;
  final int bets;
  final int won;
  final int lost;
  final double totalStake;
  final double totalProfit;
  final double roiPercent;
  
  const SportPl({
    required this.sport,
    required this.bets,
    required this.won,
    required this.lost,
    required this.totalStake,
    required this.totalProfit,
    required this.roiPercent,
  });
  
  double get winRate => bets > 0 ? (won / bets) * 100 : 0;
}
```

**`lib/widgets/pnl_summary.dart`** — proširi widget s novim breakdown sekcijom ispod equity curve-a:

```dart
// Nakon EquityCurveChart Card, dodati:
if (bets.perSportBreakdown.isNotEmpty)
  Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Per-sport breakdown', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          // Header row
          Row(
            children: const [
              SizedBox(width: 80, child: Text('Sport', style: _headerStyle)),
              Expanded(child: Text('Bets', style: _headerStyle, textAlign: TextAlign.right)),
              Expanded(child: Text('Win %', style: _headerStyle, textAlign: TextAlign.right)),
              Expanded(child: Text('ROI', style: _headerStyle, textAlign: TextAlign.right)),
              SizedBox(width: 70, child: Text('P&L', style: _headerStyle, textAlign: TextAlign.right)),
            ],
          ),
          const Divider(height: 16),
          ...bets.perSportBreakdown.entries.map((entry) {
            final pl = entry.value;
            final roiColor = pl.roiPercent > 0 ? Colors.green : pl.roiPercent < 0 ? Colors.red : Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Row(children: [
                      Text(pl.sport.icon),
                      const SizedBox(width: 4),
                      Text(pl.sport.display, style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                  Expanded(child: Text('${pl.bets}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                  Expanded(child: Text('${pl.winRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                  Expanded(child: Text('${pl.roiPercent > 0 ? "+" : ""}${pl.roiPercent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: roiColor, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                  SizedBox(width: 70, child: Text('${pl.totalProfit > 0 ? "+" : ""}${pl.totalProfit.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: roiColor), textAlign: TextAlign.right)),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  ),

// Dodati helper style ako ne postoji:
static const _headerStyle = TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500);
```

### Verifikacija Taska 6

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 7 — Filter/Search in Bets Screen

**Cilj:** Bets screen dobiva filter bar — datum range, sport, status, selection. Plus text search po home/away/league.

### Ažuriraj fajlove

**`lib/models/bets_provider.dart`** — dodaj filter state + apply logic:

```dart
// Filter state
Set<Sport> _filterSports = {};  // empty = sve
Set<BetStatus> _filterStatuses = {};  // empty = sve
DateTime? _filterFromDate;
DateTime? _filterToDate;
String _searchText = '';

Set<Sport> get filterSports => _filterSports;
Set<BetStatus> get filterStatuses => _filterStatuses;
DateTime? get filterFromDate => _filterFromDate;
DateTime? get filterToDate => _filterToDate;
String get searchText => _searchText;
bool get hasActiveFilters => _filterSports.isNotEmpty || _filterStatuses.isNotEmpty ||
    _filterFromDate != null || _filterToDate != null || _searchText.isNotEmpty;

void toggleSportFilter(Sport s) {
  if (_filterSports.contains(s)) _filterSports.remove(s); else _filterSports.add(s);
  notifyListeners();
}
void toggleStatusFilter(BetStatus st) {
  if (_filterStatuses.contains(st)) _filterStatuses.remove(st); else _filterStatuses.add(st);
  notifyListeners();
}
void setFilterDateRange(DateTime? from, DateTime? to) {
  _filterFromDate = from;
  _filterToDate = to;
  notifyListeners();
}
void setSearchText(String text) {
  _searchText = text.toLowerCase().trim();
  notifyListeners();
}
void clearFilters() {
  _filterSports.clear();
  _filterStatuses.clear();
  _filterFromDate = null;
  _filterToDate = null;
  _searchText = '';
  notifyListeners();
}

/// Apply filtere na list — koristi se iz BetsScreen-a
List<Bet> applyFilters(List<Bet> source) {
  return source.where((b) {
    if (_filterSports.isNotEmpty && !_filterSports.contains(b.sport)) return false;
    if (_filterStatuses.isNotEmpty && !_filterStatuses.contains(b.status)) return false;
    if (_filterFromDate != null && b.placedAt.isBefore(_filterFromDate!)) return false;
    if (_filterToDate != null && b.placedAt.isAfter(_filterToDate!.add(const Duration(days: 1)))) return false;
    if (_searchText.isNotEmpty) {
      final haystack = '${b.home} ${b.away} ${b.league}'.toLowerCase();
      if (!haystack.contains(_searchText)) return false;
    }
    return true;
  }).toList();
}
```

### Kreiraj fajlove

**`lib/widgets/bets_filter_bar.dart`** — compact horizontal filter bar koji ide iznad Bets liste:

```dart
class BetsFilterBar extends StatefulWidget {
  const BetsFilterBar({super.key});
  @override
  State<BetsFilterBar> createState() => _BetsFilterBarState();
}

class _BetsFilterBarState extends State<BetsFilterBar> {
  final _searchCtrl = TextEditingController();
  
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<BetsProvider>(
      builder: (context, bets, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey[900]!, width: 0.5)),
          ),
          child: Column(
            children: [
              // Search TextField
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search team, league...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            bets.setSearchText('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (text) {
                  bets.setSearchText(text);
                  setState(() {});  // for clear icon visibility
                },
              ),
              const SizedBox(height: 8),
              // Filter chips row
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildSportFilterChip(context, bets),
                    const SizedBox(width: 6),
                    _buildStatusFilterChip(context, bets),
                    const SizedBox(width: 6),
                    _buildDateFilterChip(context, bets),
                    if (bets.hasActiveFilters) ...[
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('Clear', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _searchCtrl.clear();
                          bets.clearFilters();
                        },
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                        labelStyle: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSportFilterChip(BuildContext ctx, BetsProvider bets) {
    final count = bets.filterSports.length;
    return ActionChip(
      avatar: const Icon(Icons.sports, size: 14),
      label: Text(count == 0 ? 'Sport' : '$count sports', style: const TextStyle(fontSize: 11)),
      backgroundColor: count > 0 ? Theme.of(ctx).primaryColor.withValues(alpha: 0.15) : null,
      onPressed: () async {
        await showModalBottomSheet<void>(
          context: ctx,
          builder: (_) => StatefulBuilder(
            builder: (sheetCtx, setState) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: Sport.values.map((s) => CheckboxListTile(
                  title: Row(children: [Text(s.icon), const SizedBox(width: 6), Text(s.display)]),
                  value: bets.filterSports.contains(s),
                  onChanged: (_) {
                    bets.toggleSportFilter(s);
                    setState(() {});
                  },
                )).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatusFilterChip(BuildContext ctx, BetsProvider bets) {
    // Analogno _buildSportFilterChip, ali BetStatus.values
  }
  
  Widget _buildDateFilterChip(BuildContext ctx, BetsProvider bets) {
    final hasRange = bets.filterFromDate != null || bets.filterToDate != null;
    return ActionChip(
      avatar: const Icon(Icons.date_range, size: 14),
      label: Text(hasRange ? 'Date range' : 'Date', style: const TextStyle(fontSize: 11)),
      backgroundColor: hasRange ? Theme.of(ctx).primaryColor.withValues(alpha: 0.15) : null,
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: ctx,
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: (bets.filterFromDate != null && bets.filterToDate != null)
              ? DateTimeRange(start: bets.filterFromDate!, end: bets.filterToDate!)
              : null,
        );
        if (picked != null) {
          bets.setFilterDateRange(picked.start, picked.end);
        }
      },
    );
  }
}
```

**`lib/screens/bets_screen.dart`** — ubaci `BetsFilterBar()` iznad bet-ova i primijeni filter:

```dart
Widget _buildRegularBetsView(InvestmentTier tier) {
  return Column(
    children: [
      const BetsFilterBar(),
      Expanded(
        child: Consumer<BetsProvider>(
          builder: (context, bets, _) {
            final tierFiltered = _filterBetsForTier(bets.allBets, tier);
            final fullyFiltered = bets.applyFilters(tierFiltered);
            
            if (fullyFiltered.isEmpty) {
              return _buildEmptyState(bets.hasActiveFilters);
            }
            
            return ListView.builder(
              itemCount: fullyFiltered.length,
              itemBuilder: (_, i) => BetCard(bet: fullyFiltered[i]),
            );
          },
        ),
      ),
    ],
  );
}
```

### Verifikacija Taska 7

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 8 — Polish + Final Verification + Issue Cleanup

**Cilj:** Sitnice — Accumulator stake validation UX (red border), Charts label responsive fix, tour final verification.

### Ažuriraj fajlove (minor polish)

**`lib/screens/accumulator_builder_screen.dart`** — stake TextField dobiva validator:

```dart
// Convertirati TextField u TextFormField s InputDecoration errorText
TextFormField(
  controller: _stakeController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  decoration: InputDecoration(
    labelText: 'Stake',
    prefixText: currency,
    errorText: _stakeError,  // NOVO
    border: const OutlineInputBorder(),
  ),
  onChanged: (text) {
    final value = double.tryParse(text);
    setState(() {
      if (value == null || value <= 0) {
        _stakeError = 'Enter positive stake';
      } else {
        _stakeError = null;
      }
    });
    accas.setDraftStake(value ?? 0);
  },
),
```

**`lib/widgets/charts/odds_movement_chart.dart` i `equity_curve_chart.dart`** — smanjiti `reservedSize` za leftTitles na uređajima <360dp:

```dart
// U build, pre-check screen width:
final isSmall = MediaQuery.of(context).size.width < 360;
final leftReserved = isSmall ? 32.0 : 40.0;  // za OddsMovement
// ili 40.0 / 50.0 za EquityCurve

leftTitles: AxisTitles(sideTitles: SideTitles(
  showTitles: true,
  reservedSize: leftReserved,
  getTitlesWidget: (value, meta) {
    return Text(
      value.toStringAsFixed(isSmall ? 1 : 2),  // manje decimala na malim uređajima
      style: TextStyle(fontSize: isSmall ? 9 : 10),
    );
  },
)),
```

### Ukloni riješene Identified Issues iz WORKLOG

U `## Identified Issues` sekciji, **izbriši ove unosove** (riješeni u S8):

- ~~Football-Data API key change requires app restart~~ → Task 3
- ~~IntelligenceProvider auto-refresh nije wired~~ → Task 1
- ~~Football-Data team name fuzzy matching edge cases~~ → Task 5
- ~~LIVE tier filtering nedostaje matchStartedAt~~ → Task 2
- ~~Notifications per-type enable nije implementiran~~ → Task 4
- ~~Accumulator stake validacija prihvata invalid input~~ → Task 8 polish
- ~~Chart widget axis labele mogu se preklapati~~ → Task 8 polish

**Ostaju:**
- Telegram Bot API limitation (by-design)
- MatchDetailScreen Charts tab ne pokriva tennis (won't fix for MVP)
- Accumulator import hide (cosmetic)

### Finalna verifikacija Session 8

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK u root: `betsight-v3.1.0.apk`
- Verzija: **`3.1.0+9`** (minor bump)
- Identified Issues: smanjeno s 10 na **3** (samo by-design i cosmetic)
- Git: Claude Code **NE commita/pusha** — developer preuzima

---

## FINALNI WORKLOG UNOS

Na kraju `WORKLOG.md`-a, nakon postojeće Session 7 sekcije, dodaj:

```markdown
---
---

## Session 8: YYYY-MM-DD — Stabilization + P&L Breakdown + Filter/Search

**Kontekst:** S7 je ostavio 10 Identified Issues u backlog-u. S8 rješava 5 high-impact issues (auto-refresh wire, LIVE tier filtering, FD dynamic re-wire, notifications per-type, FD fuzzy match) i dodaje two CoinSight S10-inspired polish features (per-sport P&L breakdown, filter/search u Bets screenu). Minor bump na 3.1.0+9 — mix stabilization + new functionality.

---

### Task 1 — IntelligenceProvider Auto-Refresh Wire-up
[detalji]

### Task 2 — LIVE Tier Filtering (matchStartedAt)
[detalji]

### Task 3 — Football-Data Dynamic Re-wire
[detalji]

### Task 4 — Notifications Per-Type Enable + Settings UI
[detalji]

### Task 5 — FD Fuzzy Match Improvement (Token-Based)
[detalji]

### Task 6 — Per-Sport P&L Breakdown
[detalji]

### Task 7 — Filter/Search in Bets Screen
[detalji]

### Task 8 — Polish + Final Verification + Issue Cleanup
[detalji — uključujući popis uklonjenih issues iz backlog-a]

---

### Finalna verifikacija Session 8:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v3.1.0.apk
- Verzija: 3.1.0+9 (minor bump)
- Identified Issues: smanjeno s 10 na 3
- Git: Claude Code NE commit-a/push-a — developer preuzima
```

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši sažetak:

- Ukupno zadataka izvršeno: 8
- Novih Dart fajlova: **2-3** (bets_filter_bar, sport_pl, eventualno drugi mali modeli)
- Ažuriranih Dart fajlova: [broj, očekivano ~10-12]
- Ukupno Dart fajlova u lib/: [novi total, očekivano ~64]
- Flutter analyze: 0 issues
- Flutter test: N/N passed
- Builds: Windows ✓, Android APK ✓ (betsight-v3.1.0.apk)
- **Version: 3.1.0+9 (minor bump)**
- **Identified Issues smanjeno s 10 na 3** — backlog je u najboljem stanju od S4 početka
- Sljedeći predloženi korak: **Developer commit-a i push-a S8 na GitHub.** Ovo je **kvalitetna stabilization release** — prethodni 10 issues su većinom riješeni, LIVE tier sada stvarno radi, Intelligence auto-refresh je live, FD re-wire bez restart-a, per-sport P&L + filter/search dodani. **Zgodan moment za real-world test** — ako developer odlučuje konačno testirati, ovo je APK koji idealno reprezentira "BetSight kao CoinSight". Nakon testa planira se **SESSION 9** na osnovu feedback-a — moguće opcije: MTProto migracija za Telegram (ako Bot API ograničenje postane blocker), više sportova (dodaj NHL/MLB kroz Odds API), ili AI bot (auto-analyze watched matches u scheduled interval).

Kraj SESSION 8.
