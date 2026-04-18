# BetSight SESSION 6 — Multi-Source Intelligence Layer

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` (pravila, autonomni režim, redoslijed unutar faze)
- `WORKLOG.md` (S1–S5.5 povijest — posebno obrati pažnju na: S2 Value Preset filter, S4 Telegram monitor + Odds Snapshot Engine, S5 cache + rate limit, S5.5 MonitoredChannel reliability scoring + TradeActionBar + BETTING HISTORY context)

**Nakon čitanja napiši kratki summary (3–5 rečenica) što ćeš raditi, potom nastavi autonomno kroz svih 7 zadataka bez čekanja na developerovu potvrdu.**

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues
2. `flutter build windows` — mora proći (za Task 7 pokreni i `flutter build apk --debug`)
3. Dodaj unos u `WORKLOG.md` pod novu sekciju `## Session 6: YYYY-MM-DD — Multi-Source Intelligence Layer`
4. Tek onda prelazi na sljedeći zadatak

**Git:** Claude Code **NE radi git commit ni git push.** Developer preuzima.

**Identified Issues:** Ako naiđeš na nove probleme, zabilježi u postojeću `## Identified Issues` sekciju. Posebno obrati pažnju — ovo je najveća sesija dosad, realno je očekivati 2-3 nova issues-a vezana uz third-party API-jeve.

**Verzija:** u Tasku 1 ažuriraj `pubspec.yaml` na `version: 2.0.0+7` (**major bump** jer ovo je fundamentalna transformacija iz single-source app-a u multi-source intelligence platformu — analogno CoinSight v3.0.0 bump-u za Intelligence Layer).

---

## Projektni kontekst

S1–S5.5 su izgradili kvalitetan single-source app: Odds API kao primarni izvor, Claude kao analitičar, Telegram kao sekundarni signal feed. **Ali kad izgori Odds API free tier (500/mj) — što će se dogoditi u 2-3 tjedna aktivnog korištenja čak i s cache-om — app postaje mrtav.** Diverzifikacija izvora je preživjetevna nužnost.

**S6 transformira BetSight u multi-source intelligence platformu** analognu CoinSight S6 Intelligence Layer-u. 5 izvora po meču, confluence scoring 0-6.0, strukturirani Intelligence Report koji se injektira u Claude prompt, zasebni Intelligence Dashboard screen.

**Ključne arhitekturalne odluke (potvrđene od developera prije pisanja):**

1. **5 izvora odmah:** OddsApiService (weighted 0-2.0), FootballDataService (0-1.5), BallDontLieService (0-1.0), RedditMonitor (0-1.0), TelegramMonitor (0-0.5 **weighted by channel reliability** iz S5.5). Zbroj = max 6.0 — ista skala kao CoinSight.
2. **Scope:** samo **watched matches** (star toggle iz S4). 2-5 mečeva po korisniku, ne svi. Drastično smanjuje API pozive.
3. **UI:** zasebni **Intelligence Dashboard screen** (push route iz Matches, ne IndexedStack tab) — kao CoinSight Portfolio screen.
4. **Refresh:** **hibrid** — auto 1x/h Timer.periodic (gated na hasApiKey i watched count > 0), plus on-demand refresh button u dashboardu.

**Novi Hive boxovi u S6:** `intelligence_reports`
**Novi servisi u S6:** `FootballDataService`, `BallDontLieService`, `RedditMonitor`, `IntelligenceAggregator`
**Novi modeli:** `FootballDataSignal`, `NbaStatsSignal`, `RedditSignal`, `IntelligenceReport`, `SourceScore`
**Novi provider:** `IntelligenceProvider`
**Novi screen:** `IntelligenceDashboardScreen`

---

## TASK 1 — Source Signal Models + IntelligenceReport

**Cilj:** Data kostur prije bilo kakvih API poziva. 4 nova signal modela + IntelligenceReport agregator + SourceScore tip.

### Kreiraj fajlove

**`lib/models/source_score.dart`:**

```dart
enum SourceType { odds, footballData, nbaStats, reddit, telegram }

extension SourceTypeMeta on SourceType {
  String get display => switch (this) {
    SourceType.odds => 'Odds',
    SourceType.footballData => 'Football-Data',
    SourceType.nbaStats => 'NBA Stats',
    SourceType.reddit => 'Reddit',
    SourceType.telegram => 'Telegram',
  };
  
  /// Maksimalni score po izvoru (weighting — CoinSight style)
  double get maxScore => switch (this) {
    SourceType.odds => 2.0,            // primary — dominira
    SourceType.footballData => 1.5,    // strong secondary — forma + h2h je meaty
    SourceType.nbaStats => 1.0,        // secondary — primjenjivo samo za NBA
    SourceType.reddit => 1.0,          // tertiary — community sentiment
    SourceType.telegram => 0.5,        // tertiary — weighted by channel reliability
  };
  
  String get icon => switch (this) {
    SourceType.odds => '📊',
    SourceType.footballData => '⚽',
    SourceType.nbaStats => '🏀',
    SourceType.reddit => '💬',
    SourceType.telegram => '📡',
  };
}

class SourceScore {
  final SourceType source;
  final double score;         // 0.0 do source.maxScore
  final String reasoning;     // kratak human-readable opis što je nađeno
  final bool isActive;        // false ako izvor nije dao podatke (nema api key, rate limited, no data for this match)
  
  const SourceScore({
    required this.source,
    required this.score,
    required this.reasoning,
    required this.isActive,
  });
  
  /// Score kao postotak maksimalnog (0-100) za UI progress bars
  double get percentage => source.maxScore == 0 ? 0 : (score / source.maxScore) * 100;
  
  /// Inactive placeholder
  factory SourceScore.inactive(SourceType source, String reason) => SourceScore(
    source: source,
    score: 0,
    reasoning: reason,
    isActive: false,
  );
  
  Map<String, dynamic> toMap() => {
    'source': source.name,
    'score': score,
    'reasoning': reasoning,
    'isActive': isActive,
  };
  
  factory SourceScore.fromMap(Map<dynamic, dynamic> map) => SourceScore(
    source: SourceType.values.firstWhere((s) => s.name == map['source']),
    score: (map['score'] as num).toDouble(),
    reasoning: map['reasoning'] as String,
    isActive: map['isActive'] as bool,
  );
}
```

**`lib/models/football_data_signal.dart`:**

```dart
/// Agregat Football-Data.org podataka za jedan meč
class FootballDataSignal {
  final String matchId;             // Match.id iz Odds API-ja (string-match heuristika)
  final String homeTeam;
  final String awayTeam;
  final String competition;         // "Premier League", "UEFA Champions League"
  
  // Forma — zadnjih 5 utakmica
  final List<String> homeFormLast5;  // npr. ['W', 'D', 'L', 'W', 'W']
  final List<String> awayFormLast5;
  
  // Head-to-head (zadnjih 5 medusobnih)
  final int h2hHomeWins;
  final int h2hDraws;
  final int h2hAwayWins;
  
  // Standings
  final int? homePosition;
  final int? awayPosition;
  
  final DateTime fetchedAt;
  
  const FootballDataSignal({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.competition,
    required this.homeFormLast5,
    required this.awayFormLast5,
    required this.h2hHomeWins,
    required this.h2hDraws,
    required this.h2hAwayWins,
    this.homePosition,
    this.awayPosition,
    required this.fetchedAt,
  });
  
  // Form stats helpers
  int get homeWinsForm => homeFormLast5.where((r) => r == 'W').length;
  int get homeDrawsForm => homeFormLast5.where((r) => r == 'D').length;
  int get homeLossesForm => homeFormLast5.where((r) => r == 'L').length;
  int get awayWinsForm => awayFormLast5.where((r) => r == 'W').length;
  int get awayDrawsForm => awayFormLast5.where((r) => r == 'D').length;
  int get awayLossesForm => awayFormLast5.where((r) => r == 'L').length;
  
  /// Form score po strani: -1.0 do +1.0 (W=+0.2, D=0, L=-0.2, suma max ±1.0)
  double get homeFormScore => (homeWinsForm - homeLossesForm) / 5.0;
  double get awayFormScore => (awayWinsForm - awayLossesForm) / 5.0;
  
  /// Kontekst za Claude prompt (jedan ili dva reda)
  String toClaudeContext() {
    final homeForm = homeFormLast5.join('');
    final awayForm = awayFormLast5.join('');
    final h2h = 'H2H last 5: ${h2hHomeWins}W ${h2hDraws}D ${h2hAwayWins}L (from home perspective)';
    final positions = (homePosition != null && awayPosition != null)
        ? 'Standings: $homeTeam #$homePosition, $awayTeam #$awayPosition'
        : '';
    return '$homeTeam form $homeForm | $awayTeam form $awayForm\n$h2h${positions.isNotEmpty ? "\n$positions" : ""}';
  }
  
  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'homeTeam': homeTeam,
    'awayTeam': awayTeam,
    'competition': competition,
    'homeFormLast5': homeFormLast5,
    'awayFormLast5': awayFormLast5,
    'h2hHomeWins': h2hHomeWins,
    'h2hDraws': h2hDraws,
    'h2hAwayWins': h2hAwayWins,
    'homePosition': homePosition,
    'awayPosition': awayPosition,
    'fetchedAt': fetchedAt.toIso8601String(),
  };
  
  factory FootballDataSignal.fromMap(Map<dynamic, dynamic> map) => FootballDataSignal(
    matchId: map['matchId'] as String,
    homeTeam: map['homeTeam'] as String,
    awayTeam: map['awayTeam'] as String,
    competition: map['competition'] as String,
    homeFormLast5: (map['homeFormLast5'] as List<dynamic>).cast<String>(),
    awayFormLast5: (map['awayFormLast5'] as List<dynamic>).cast<String>(),
    h2hHomeWins: map['h2hHomeWins'] as int,
    h2hDraws: map['h2hDraws'] as int,
    h2hAwayWins: map['h2hAwayWins'] as int,
    homePosition: map['homePosition'] as int?,
    awayPosition: map['awayPosition'] as int?,
    fetchedAt: DateTime.parse(map['fetchedAt'] as String),
  );
}
```

**`lib/models/nba_stats_signal.dart`:**

```dart
/// BallDontLie.io NBA statistike za jedan meč
class NbaStatsSignal {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  
  // Zadnjih 10 utakmica — W/L lista
  final List<String> homeLast10;
  final List<String> awayLast10;
  
  // Rest days (dana od zadnje utakmice)
  final int? homeRestDays;
  final int? awayRestDays;
  
  // Regular season standings
  final int? homeStandingsRank;     // 1-15 po conferenceu
  final int? awayStandingsRank;
  
  final DateTime fetchedAt;
  
  const NbaStatsSignal({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLast10,
    required this.awayLast10,
    this.homeRestDays,
    this.awayRestDays,
    this.homeStandingsRank,
    this.awayStandingsRank,
    required this.fetchedAt,
  });
  
  int get homeWinsLast10 => homeLast10.where((r) => r == 'W').length;
  int get awayWinsLast10 => awayLast10.where((r) => r == 'W').length;
  
  String toClaudeContext() {
    final homeStr = '$homeTeam: ${homeWinsLast10}/10 last 10';
    final awayStr = '$awayTeam: ${awayWinsLast10}/10 last 10';
    final restStr = (homeRestDays != null && awayRestDays != null)
        ? 'Rest days: $homeTeam ${homeRestDays}d, $awayTeam ${awayRestDays}d'
        : '';
    final standingsStr = (homeStandingsRank != null && awayStandingsRank != null)
        ? 'Standings: $homeTeam #$homeStandingsRank, $awayTeam #$awayStandingsRank'
        : '';
    final parts = <String>[homeStr, awayStr];
    if (restStr.isNotEmpty) parts.add(restStr);
    if (standingsStr.isNotEmpty) parts.add(standingsStr);
    return parts.join('\n');
  }
  
  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'homeTeam': homeTeam,
    'awayTeam': awayTeam,
    'homeLast10': homeLast10,
    'awayLast10': awayLast10,
    'homeRestDays': homeRestDays,
    'awayRestDays': awayRestDays,
    'homeStandingsRank': homeStandingsRank,
    'awayStandingsRank': awayStandingsRank,
    'fetchedAt': fetchedAt.toIso8601String(),
  };
  
  factory NbaStatsSignal.fromMap(Map<dynamic, dynamic> map) => NbaStatsSignal(
    matchId: map['matchId'] as String,
    homeTeam: map['homeTeam'] as String,
    awayTeam: map['awayTeam'] as String,
    homeLast10: (map['homeLast10'] as List<dynamic>).cast<String>(),
    awayLast10: (map['awayLast10'] as List<dynamic>).cast<String>(),
    homeRestDays: map['homeRestDays'] as int?,
    awayRestDays: map['awayRestDays'] as int?,
    homeStandingsRank: map['homeStandingsRank'] as int?,
    awayStandingsRank: map['awayStandingsRank'] as int?,
    fetchedAt: DateTime.parse(map['fetchedAt'] as String),
  );
}
```

**`lib/models/reddit_signal.dart`:**

```dart
/// Reddit sentiment signal za match
class RedditSignal {
  final String matchId;
  final int mentionCount;              // broj postova/komentara koji spominju oba tima
  final int topUpvotes;                 // upvotes najpopularnijeg posta koji spominje
  final Map<String, int> teamMentions; // "Liverpool": 12, "Arsenal": 8
  final String? topPostTitle;
  final String? topPostSubreddit;
  final DateTime fetchedAt;
  
  const RedditSignal({
    required this.matchId,
    required this.mentionCount,
    required this.topUpvotes,
    required this.teamMentions,
    this.topPostTitle,
    this.topPostSubreddit,
    required this.fetchedAt,
  });
  
  /// Sentiment bias — koji tim je više spominjan (-1 = home tilt, +1 = away tilt, 0 = balanced)
  double getSentimentBias(String homeTeam, String awayTeam) {
    final h = teamMentions[homeTeam] ?? 0;
    final a = teamMentions[awayTeam] ?? 0;
    final total = h + a;
    if (total == 0) return 0;
    return (a - h) / total; // positive = away tilt, negative = home tilt
  }
  
  String toClaudeContext(String homeTeam, String awayTeam) {
    final bias = getSentimentBias(homeTeam, awayTeam);
    final biasStr = bias.abs() < 0.2
        ? 'balanced sentiment'
        : bias > 0
            ? 'Reddit skewed toward $awayTeam'
            : 'Reddit skewed toward $homeTeam';
    final topStr = topPostTitle != null
        ? 'Top post on r/$topPostSubreddit ($topUpvotes upvotes): "$topPostTitle"'
        : '';
    return 'Reddit: $mentionCount mentions, $biasStr${topStr.isNotEmpty ? "\n$topStr" : ""}';
  }
  
  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'mentionCount': mentionCount,
    'topUpvotes': topUpvotes,
    'teamMentions': teamMentions,
    'topPostTitle': topPostTitle,
    'topPostSubreddit': topPostSubreddit,
    'fetchedAt': fetchedAt.toIso8601String(),
  };
  
  factory RedditSignal.fromMap(Map<dynamic, dynamic> map) => RedditSignal(
    matchId: map['matchId'] as String,
    mentionCount: map['mentionCount'] as int,
    topUpvotes: map['topUpvotes'] as int,
    teamMentions: (map['teamMentions'] as Map<dynamic, dynamic>).cast<String, int>(),
    topPostTitle: map['topPostTitle'] as String?,
    topPostSubreddit: map['topPostSubreddit'] as String?,
    fetchedAt: DateTime.parse(map['fetchedAt'] as String),
  );
}
```

**`lib/models/intelligence_report.dart`:**

```dart
enum IntelligenceCategory {
  strongValue,        // >= 4.5
  possibleValue,      // >= 3.0
  weakSignal,         // >= 1.5
  likelySkip,         // < 1.5
  insufficientData,   // < 2 aktivna izvora
}

extension IntelligenceCategoryMeta on IntelligenceCategory {
  String get display => switch (this) {
    IntelligenceCategory.strongValue => 'STRONG_VALUE',
    IntelligenceCategory.possibleValue => 'POSSIBLE_VALUE',
    IntelligenceCategory.weakSignal => 'WEAK_SIGNAL',
    IntelligenceCategory.likelySkip => 'LIKELY_SKIP',
    IntelligenceCategory.insufficientData => 'INSUFFICIENT_DATA',
  };
  
  int get colorValue => switch (this) {
    IntelligenceCategory.strongValue => 0xFF4CAF50,      // green
    IntelligenceCategory.possibleValue => 0xFF66BB6A,    // light green
    IntelligenceCategory.weakSignal => 0xFFFFA726,       // orange
    IntelligenceCategory.likelySkip => 0xFFEF5350,       // red
    IntelligenceCategory.insufficientData => 0xFF9E9E9E, // grey
  };
  
  String get interpretation => switch (this) {
    IntelligenceCategory.strongValue => 'Multiple sources align on edge. Worth deep analysis.',
    IntelligenceCategory.possibleValue => 'Some signals present. Confirm with additional reasoning.',
    IntelligenceCategory.weakSignal => 'Weak indications. Not clearly actionable.',
    IntelligenceCategory.likelySkip => 'Sources suggest no edge. Consider skipping.',
    IntelligenceCategory.insufficientData => 'Not enough source coverage to decide.',
  };
}

class IntelligenceReport {
  final String matchId;
  final List<SourceScore> sources;
  final DateTime generatedAt;
  
  const IntelligenceReport({
    required this.matchId,
    required this.sources,
    required this.generatedAt,
  });
  
  /// Sum svih aktivnih source scores — 0.0 do 6.0
  double get confluenceScore => sources
      .where((s) => s.isActive)
      .fold(0.0, (sum, s) => sum + s.score);
  
  int get activeSourceCount => sources.where((s) => s.isActive).length;
  
  IntelligenceCategory get category {
    if (activeSourceCount < 2) return IntelligenceCategory.insufficientData;
    final score = confluenceScore;
    if (score >= 4.5) return IntelligenceCategory.strongValue;
    if (score >= 3.0) return IntelligenceCategory.possibleValue;
    if (score >= 1.5) return IntelligenceCategory.weakSignal;
    return IntelligenceCategory.likelySkip;
  }
  
  Duration get age => DateTime.now().difference(generatedAt);
  bool isExpired(Duration ttl) => age > ttl;
  
  /// Kontekst za Claude user message
  String toClaudeContext() {
    final buf = StringBuffer();
    buf.writeln('[INTELLIGENCE REPORT — confluence ${confluenceScore.toStringAsFixed(1)}/6.0 — ${category.display}]');
    for (final s in sources) {
      if (!s.isActive) {
        buf.writeln('${s.source.display} (inactive): ${s.reasoning}');
      } else {
        buf.writeln('${s.source.display} (${s.score.toStringAsFixed(1)}/${s.source.maxScore}): ${s.reasoning}');
      }
    }
    buf.writeln('Hint: ${category.interpretation}');
    buf.writeln('[/INTELLIGENCE REPORT]');
    return buf.toString();
  }
  
  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'sources': sources.map((s) => s.toMap()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
  };
  
  factory IntelligenceReport.fromMap(Map<dynamic, dynamic> map) => IntelligenceReport(
    matchId: map['matchId'] as String,
    sources: (map['sources'] as List<dynamic>)
        .map((s) => SourceScore.fromMap(s as Map<dynamic, dynamic>))
        .toList(),
    generatedAt: DateTime.parse(map['generatedAt'] as String),
  );
}
```

### Verifikacija Taska 1

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 2 — Storage Integration + IntelligenceProvider skeleton

**Cilj:** Hive persistencija za IntelligenceReport + IntelligenceProvider kao ChangeNotifier skeleton. Bez servisa za sad — samo shell.

### Ažuriraj fajlove

**`pubspec.yaml`** — version bump na `2.0.0+7`.

**`lib/services/storage_service.dart`** — dodaj `intelligence_reports` box + Football/NBA/Reddit signal cache boxes (svaki zasebno, TTL se razlikuje):

```dart
static const _intelligenceReportsBox = 'intelligence_reports';
static const _footballSignalsBox = 'football_signals_cache';
static const _nbaSignalsBox = 'nba_signals_cache';
static const _redditSignalsBox = 'reddit_signals_cache';

// API ključevi za nove izvore
static const _footballDataApiKeyField = 'football_data_api_key';
// Reddit i BallDontLie su bez API ključa u free tier-u

// u init():
await Hive.openBox(_intelligenceReportsBox);
await Hive.openBox(_footballSignalsBox);
await Hive.openBox(_nbaSignalsBox);
await Hive.openBox(_redditSignalsBox);

static Box get _reportsBox => Hive.box(_intelligenceReportsBox);
static Box get _footballBox => Hive.box(_footballSignalsBox);
static Box get _nbaBox => Hive.box(_nbaSignalsBox);
static Box get _redditBox => Hive.box(_redditSignalsBox);

// Report CRUD
static IntelligenceReport? getReport(String matchId) {
  final map = _reportsBox.get(matchId);
  if (map == null) return null;
  try {
    return IntelligenceReport.fromMap(map as Map<dynamic, dynamic>);
  } catch (_) {
    return null;
  }
}

static Future<void> saveReport(IntelligenceReport report) =>
    _reportsBox.put(report.matchId, report.toMap());

static List<IntelligenceReport> getAllReports() {
  final list = <IntelligenceReport>[];
  for (final map in _reportsBox.values) {
    try {
      list.add(IntelligenceReport.fromMap(map as Map<dynamic, dynamic>));
    } catch (_) {}
  }
  list.sort((a, b) => b.confluenceScore.compareTo(a.confluenceScore));
  return list;
}

static Future<void> deleteReport(String matchId) => _reportsBox.delete(matchId);

static Future<int> clearOldReports({Duration keepFor = const Duration(hours: 6)}) async {
  final cutoff = DateTime.now().subtract(keepFor);
  final keys = <dynamic>[];
  for (final key in _reportsBox.keys) {
    try {
      final report = IntelligenceReport.fromMap(_reportsBox.get(key) as Map<dynamic, dynamic>);
      if (report.generatedAt.isBefore(cutoff)) keys.add(key);
    } catch (_) {
      keys.add(key);
    }
  }
  for (final k in keys) await _reportsBox.delete(k);
  return keys.length;
}

// Individual source signal cache (3h TTL default)
static FootballDataSignal? getFootballSignal(String matchId) {
  final map = _footballBox.get(matchId);
  if (map == null) return null;
  try {
    return FootballDataSignal.fromMap(map as Map<dynamic, dynamic>);
  } catch (_) { return null; }
}
static Future<void> saveFootballSignal(FootballDataSignal signal) =>
    _footballBox.put(signal.matchId, signal.toMap());

static NbaStatsSignal? getNbaSignal(String matchId) {
  final map = _nbaBox.get(matchId);
  if (map == null) return null;
  try {
    return NbaStatsSignal.fromMap(map as Map<dynamic, dynamic>);
  } catch (_) { return null; }
}
static Future<void> saveNbaSignal(NbaStatsSignal signal) =>
    _nbaBox.put(signal.matchId, signal.toMap());

static RedditSignal? getRedditSignal(String matchId) {
  final map = _redditBox.get(matchId);
  if (map == null) return null;
  try {
    return RedditSignal.fromMap(map as Map<dynamic, dynamic>);
  } catch (_) { return null; }
}
static Future<void> saveRedditSignal(RedditSignal signal) =>
    _redditBox.put(signal.matchId, signal.toMap());

// Football-Data API key
static String? getFootballDataApiKey() => _box.get(_footballDataApiKeyField) as String?;
static Future<void> saveFootballDataApiKey(String key) =>
    _box.put(_footballDataApiKeyField, key);
static Future<void> deleteFootballDataApiKey() => _box.delete(_footballDataApiKeyField);
```

Proširi `runScheduledCleanup` da briše stare Football/NBA/Reddit signal cache-eve i stare reportse (>6h):

```dart
// u runScheduledCleanup, nakon postojećih cleanups:
final reportsCleaned = await clearOldReports(keepFor: const Duration(hours: 6));
// Stari signal cache entries — >3 dana
int footballCleaned = 0, nbaCleaned = 0, redditCleaned = 0;
final cutoff3d = DateTime.now().subtract(const Duration(days: 3));

for (final key in _footballBox.keys) {
  try {
    final s = FootballDataSignal.fromMap(_footballBox.get(key) as Map<dynamic, dynamic>);
    if (s.fetchedAt.isBefore(cutoff3d)) {
      await _footballBox.delete(key);
      footballCleaned++;
    }
  } catch (_) {
    await _footballBox.delete(key);
    footballCleaned++;
  }
}
// Isto za nbaBox i redditBox...

return {
  'signals_cleaned': signalsCleaned,
  'snapshots_cleaned': snapshotsCleaned,
  'cache_entries_cleaned': cacheEntriesCleaned,
  'reports_cleaned': reportsCleaned,
  'football_cleaned': footballCleaned,
  'nba_cleaned': nbaCleaned,
  'reddit_cleaned': redditCleaned,
};
```

### Kreiraj fajlove

**`lib/models/intelligence_provider.dart`:**

```dart
class IntelligenceProvider extends ChangeNotifier {
  final Map<String, IntelligenceReport> _reports = {};
  final Set<String> _generatingFor = {};        // matchId-evi za koje trenutno gradimo report (loading state)
  String? _error;
  Timer? _autoRefreshTimer;
  
  // Lazy service refs — inicijalizirani kroz setServices
  late OddsApiService _oddsService;
  FootballDataService? _footballService;
  BallDontLieService? _nbaService;
  RedditMonitor? _redditMonitor;
  late TelegramProvider _telegramProvider;
  late IntelligenceAggregator _aggregator;
  
  IntelligenceProvider() {
    // Load existing reports from Storage
    for (final report in StorageService.getAllReports()) {
      _reports[report.matchId] = report;
    }
  }
  
  /// Inject dependencies after construction (called once from main.dart MultiProvider).
  void wireServices({
    required OddsApiService oddsService,
    required FootballDataService? footballService,
    required BallDontLieService? nbaService,
    required RedditMonitor? redditMonitor,
    required TelegramProvider telegramProvider,
  }) {
    _oddsService = oddsService;
    _footballService = footballService;
    _nbaService = nbaService;
    _redditMonitor = redditMonitor;
    _telegramProvider = telegramProvider;
    _aggregator = IntelligenceAggregator(
      oddsService: oddsService,
      footballService: footballService,
      nbaService: nbaService,
      redditMonitor: redditMonitor,
      telegramProvider: telegramProvider,
    );
  }
  
  // Getters
  IntelligenceReport? reportFor(String matchId) => _reports[matchId];
  bool isGeneratingFor(String matchId) => _generatingFor.contains(matchId);
  List<IntelligenceReport> get allReports {
    final list = _reports.values.toList();
    list.sort((a, b) => b.confluenceScore.compareTo(a.confluenceScore));
    return list;
  }
  String? get error => _error;
  void clearError() { _error = null; notifyListeners(); }
  
  /// Generate (or refresh) report za specifičan match.
  /// `force` = true bypassa TTL check.
  Future<void> generateReport(Match match, {bool force = false}) async {
    if (_generatingFor.contains(match.id)) return; // već u tijeku
    
    if (!force) {
      final existing = _reports[match.id];
      if (existing != null && !existing.isExpired(const Duration(hours: 1))) {
        return; // još uvijek svjež
      }
    }
    
    _generatingFor.add(match.id);
    notifyListeners();
    
    try {
      final report = await _aggregator.buildReport(match);
      _reports[match.id] = report;
      await StorageService.saveReport(report);
      _error = null;
    } catch (e) {
      _error = 'Intelligence report failed: ${e.toString()}';
    } finally {
      _generatingFor.remove(match.id);
      notifyListeners();
    }
  }
  
  /// Generate reports za sve watched mečeve paralelno.
  Future<void> refreshAllWatched(List<Match> watchedMatches, {bool force = false}) async {
    final futures = watchedMatches.map((m) => generateReport(m, force: force));
    await Future.wait(futures);
  }
  
  /// Start auto-refresh: svaki sat refresh-aj sve watched matches.
  void startAutoRefresh(List<Match> Function() watchedProvider) {
    stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      final watched = watchedProvider();
      if (watched.isNotEmpty) {
        await refreshAllWatched(watched, force: true);
      }
    });
  }
  
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
  
  /// Delete report za match kada korisnik unwatch-a
  Future<void> removeReportFor(String matchId) async {
    _reports.remove(matchId);
    await StorageService.deleteReport(matchId);
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
```

### Verifikacija Taska 2

- `flutter analyze` → mora pokazati missing imports/classes za `FootballDataService`, `BallDontLieService`, `RedditMonitor`, `IntelligenceAggregator` — to je očekivano, ti će fajlovi doći u Taskima 3-6. **Za ovaj task nije OK 0 issues**, ali samo očekivani errors, ne syntax greške. Dokumentiraj u WORKLOG: *"IntelligenceProvider skeleton kreiran, čeka servise iz Task 3-6; flutter analyze će proći nakon Taska 6."*
- `flutter build windows` → neće raditi još, preskoči ovaj verifikacijski korak za Task 2.
- **Task 2 je jedini task u sesiji koji NE mora proći `flutter analyze`** — razlog je da multi-file interdependence s aggregatorom koji ovisi o 4 servisa koji još ne postoje. Claude Code neka produži na Task 3 odmah.

---

## TASK 3 — FootballDataService

**Cilj:** Integracija Football-Data.org v4 API-ja. Free tier = 10 req/min, neograničen mjesečno. Potreban API key (registracija preko emaila na football-data.org).

### Poznavanje API-ja:

- Base URL: `https://api.football-data.org/v4`
- Header: `X-Auth-Token: {API_KEY}`
- Competitions relevantne za naš EPL/CL setup: `PL` (Premier League), `CL` (Champions League)
- Endpoint: `GET /competitions/{code}/matches?status=SCHEDULED&dateFrom={iso}&dateTo={iso}`
- Endpoint za standings: `GET /competitions/{code}/standings`
- Endpoint za H2H: `GET /matches/{id}/head2head?limit=10`

**Važno ograničenje:** Football-Data ima **vlastiti match ID** (npr. 442384), različit od Odds API match ID-a. Moramo **spajati po team nameovima + datumu** (fuzzy match). Timska imena se dijelom poklapaju (FD: "Liverpool FC", Odds API: "Liverpool"), ali ne uvijek — trebamo **name normalizaciju**.

### Kreiraj fajlove

**`lib/services/football_data_service.dart`:**

```dart
class FootballDataService {
  final http.Client _client;
  String _apiKey = '';
  
  static const _baseUrl = 'https://api.football-data.org/v4';
  static const _timeout = Duration(seconds: 15);
  
  // Sport key → FD competition code mapping
  static const _competitionMap = {
    'soccer_epl': 'PL',
    'soccer_uefa_champs_league': 'CL',
  };
  
  FootballDataService({http.Client? client}) : _client = client ?? http.Client();
  
  bool get hasApiKey => _apiKey.isNotEmpty;
  void setApiKey(String key) => _apiKey = key;
  
  /// Normalizira naziv tima za fuzzy matching.
  /// "Liverpool FC" → "liverpool", "Real Madrid CF" → "real madrid"
  static String _normalize(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'\s+(fc|cf|afc|sc|ac|cd|cb|sl)\b'), '')
      .replaceAll(RegExp(r'[^a-z\s]'), '')
      .trim();
  
  /// Glavna API metoda — vraća FootballDataSignal za match, ili throw-a.
  Future<FootballDataSignal> getSignalForMatch(Match match) async {
    if (!hasApiKey) {
      throw FootballDataException('No API key');
    }
    final competition = _competitionMap[match.sportKey];
    if (competition == null) {
      throw FootballDataException('Sport not supported');
    }
    
    // 1. Find the FD match ID by searching upcoming matches
    final dateFrom = match.commenceTime.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final dateTo = match.commenceTime.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    
    final matchesUri = Uri.parse('$_baseUrl/competitions/$competition/matches').replace(
      queryParameters: {
        'status': 'SCHEDULED,TIMED',
        'dateFrom': dateFrom,
        'dateTo': dateTo,
      },
    );
    
    final matchesResp = await _client.get(
      matchesUri,
      headers: {'X-Auth-Token': _apiKey},
    ).timeout(_timeout);
    
    if (matchesResp.statusCode == 429) throw FootballDataException('Rate limited');
    if (matchesResp.statusCode == 403) throw FootballDataException('Invalid API key');
    if (matchesResp.statusCode != 200) throw FootballDataException('HTTP ${matchesResp.statusCode}');
    
    final matchesData = json.decode(matchesResp.body) as Map<String, dynamic>;
    final fdMatches = (matchesData['matches'] as List<dynamic>?) ?? [];
    
    // Fuzzy match by team names
    final nHome = _normalize(match.home);
    final nAway = _normalize(match.away);
    Map<String, dynamic>? fdMatch;
    for (final m in fdMatches) {
      final map = m as Map<String, dynamic>;
      final fdHome = _normalize((map['homeTeam'] as Map)['name'] as String);
      final fdAway = _normalize((map['awayTeam'] as Map)['name'] as String);
      if (fdHome.contains(nHome) || nHome.contains(fdHome)) {
        if (fdAway.contains(nAway) || nAway.contains(fdAway)) {
          fdMatch = map;
          break;
        }
      }
    }
    
    if (fdMatch == null) {
      throw FootballDataException('Match not found in Football-Data');
    }
    
    final fdMatchId = fdMatch['id'];
    final homeTeamObj = fdMatch['homeTeam'] as Map<String, dynamic>;
    final awayTeamObj = fdMatch['awayTeam'] as Map<String, dynamic>;
    final homeTeamId = homeTeamObj['id'];
    final awayTeamId = awayTeamObj['id'];
    
    // 2. H2H
    final h2hUri = Uri.parse('$_baseUrl/matches/$fdMatchId/head2head?limit=5');
    final h2hResp = await _client.get(
      h2hUri,
      headers: {'X-Auth-Token': _apiKey},
    ).timeout(_timeout);
    
    int h2hHomeWins = 0, h2hDraws = 0, h2hAwayWins = 0;
    if (h2hResp.statusCode == 200) {
      final h2hData = json.decode(h2hResp.body) as Map<String, dynamic>;
      final resultSet = h2hData['resultSet'] as Map<String, dynamic>?;
      if (resultSet != null) {
        h2hHomeWins = (resultSet['wins'] as int?) ?? 0;
        h2hDraws = (resultSet['draws'] as int?) ?? 0;
        h2hAwayWins = (resultSet['losses'] as int?) ?? 0;
        // Ako je perspective pogrešna (resultSet može računati sa stajališta away tima), swap.
        // Pretpostavimo da je resultSet.wins = wins za prvi team (homeTeam)
      }
    }
    
    // 3. Form (zadnjih 5 matcheva tima) — koristi /teams/{id}/matches endpoint
    final homeForm = await _getTeamForm(homeTeamId as int);
    final awayForm = await _getTeamForm(awayTeamId as int);
    
    // 4. Standings
    int? homePos, awayPos;
    try {
      final standingsUri = Uri.parse('$_baseUrl/competitions/$competition/standings');
      final standingsResp = await _client.get(
        standingsUri,
        headers: {'X-Auth-Token': _apiKey},
      ).timeout(_timeout);
      if (standingsResp.statusCode == 200) {
        final data = json.decode(standingsResp.body) as Map<String, dynamic>;
        final standings = (data['standings'] as List<dynamic>?) ?? [];
        for (final s in standings) {
          if ((s as Map)['type'] == 'TOTAL') {
            final table = s['table'] as List<dynamic>;
            for (final row in table) {
              final team = (row as Map)['team'] as Map<String, dynamic>;
              if (team['id'] == homeTeamId) homePos = row['position'] as int?;
              if (team['id'] == awayTeamId) awayPos = row['position'] as int?;
            }
            break;
          }
        }
      }
    } catch (_) {/* standings optional */}
    
    return FootballDataSignal(
      matchId: match.id,
      homeTeam: homeTeamObj['name'] as String,
      awayTeam: awayTeamObj['name'] as String,
      competition: fdMatch['competition']?['name'] as String? ?? 'Unknown',
      homeFormLast5: homeForm,
      awayFormLast5: awayForm,
      h2hHomeWins: h2hHomeWins,
      h2hDraws: h2hDraws,
      h2hAwayWins: h2hAwayWins,
      homePosition: homePos,
      awayPosition: awayPos,
      fetchedAt: DateTime.now(),
    );
  }
  
  Future<List<String>> _getTeamForm(int teamId) async {
    try {
      final uri = Uri.parse('$_baseUrl/teams/$teamId/matches?status=FINISHED&limit=5');
      final resp = await _client.get(uri, headers: {'X-Auth-Token': _apiKey}).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final matches = (data['matches'] as List<dynamic>?) ?? [];
      final form = <String>[];
      for (final m in matches.take(5)) {
        final map = m as Map<String, dynamic>;
        final score = map['score'] as Map<String, dynamic>?;
        final winner = score?['winner']; // HOME_TEAM / AWAY_TEAM / DRAW
        final isHome = (map['homeTeam'] as Map)['id'] == teamId;
        if (winner == 'DRAW') {
          form.add('D');
        } else if ((winner == 'HOME_TEAM' && isHome) || (winner == 'AWAY_TEAM' && !isHome)) {
          form.add('W');
        } else {
          form.add('L');
        }
      }
      return form;
    } catch (_) {
      return [];
    }
  }
  
  void dispose() => _client.close();
}

class FootballDataException implements Exception {
  final String message;
  FootballDataException(this.message);
  @override
  String toString() => 'FootballDataException: $message';
}
```

**Napomena o optimizaciji:** Metoda `getSignalForMatch` radi 4-5 HTTP poziva po matchu (matches list + H2H + 2x team form + standings). Za 5 watched matches = ~25 req svaka refresh. Free tier je 10 req/min. **Moramo serijski, ne paralelno** — inače će rate limit puknuti. Claude Code neka osigura serijski pristup (await unutar petlje u IntelligenceAggregator).

### Verifikacija Taska 3

- `flutter analyze` → **i dalje error iz Taska 2** (IntelligenceAggregator ne postoji). To je OK, čekamo Task 6.
- `flutter build windows` → preskoči.

---

## TASK 4 — BallDontLieService

**Cilj:** Integracija BallDontLie.io NBA API-ja. **Besplatan, bez API ključa, neograničen.** Ograničenje: samo NBA.

### Poznavanje API-ja:

- Base URL: `https://www.balldontlie.io/api/v1`
- Endpoint: `GET /teams` (sve timove)
- Endpoint: `GET /games?seasons[]=2025&team_ids[]={id}&per_page=15` (zadnjih 15 igara tima)
- Bez rate limita u free verziji (iako se preporučuje razuman throttle)

### Kreiraj fajlove

**`lib/services/ball_dont_lie_service.dart`:**

```dart
class BallDontLieService {
  final http.Client _client;
  
  static const _baseUrl = 'https://www.balldontlie.io/api/v1';
  static const _timeout = Duration(seconds: 15);
  
  // Cache team ID lookups (teams se rijetko mijenjaju)
  final Map<String, int> _teamIdCache = {};
  
  BallDontLieService({http.Client? client}) : _client = client ?? http.Client();
  
  /// Normalizira NBA team ime za matching ("Los Angeles Lakers" → "lakers")
  static String _normalize(String name) => name.toLowerCase().split(' ').last.trim();
  
  Future<int?> _getTeamId(String name) async {
    final norm = _normalize(name);
    if (_teamIdCache.containsKey(norm)) return _teamIdCache[norm];
    
    try {
      final uri = Uri.parse('$_baseUrl/teams');
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final teams = (data['data'] as List<dynamic>);
      for (final t in teams) {
        final map = t as Map<String, dynamic>;
        final fullName = map['full_name'] as String;
        final nickname = map['name'] as String;
        _teamIdCache[_normalize(fullName)] = map['id'] as int;
        _teamIdCache[_normalize(nickname)] = map['id'] as int;
      }
      return _teamIdCache[norm];
    } catch (_) {
      return null;
    }
  }
  
  /// Vraća NbaStatsSignal za match — ili throw-a.
  Future<NbaStatsSignal> getSignalForMatch(Match match) async {
    if (match.sport != Sport.basketball) {
      throw BallDontLieException('Not an NBA match');
    }
    
    final homeId = await _getTeamId(match.home);
    final awayId = await _getTeamId(match.away);
    if (homeId == null || awayId == null) {
      throw BallDontLieException('Team not found in BallDontLie');
    }
    
    final season = DateTime.now().year;
    final homeGames = await _getTeamLast10Games(homeId, season);
    final awayGames = await _getTeamLast10Games(awayId, season);
    
    final homeLast10 = _gamesToForm(homeGames, homeId);
    final awayLast10 = _gamesToForm(awayGames, awayId);
    
    // Rest days — days between match.commenceTime i zadnje igre tima
    int? homeRest;
    int? awayRest;
    if (homeGames.isNotEmpty) {
      final lastGameDate = DateTime.parse(homeGames.first['date'] as String);
      homeRest = match.commenceTime.difference(lastGameDate).inDays;
    }
    if (awayGames.isNotEmpty) {
      final lastGameDate = DateTime.parse(awayGames.first['date'] as String);
      awayRest = match.commenceTime.difference(lastGameDate).inDays;
    }
    
    return NbaStatsSignal(
      matchId: match.id,
      homeTeam: match.home,
      awayTeam: match.away,
      homeLast10: homeLast10,
      awayLast10: awayLast10,
      homeRestDays: homeRest,
      awayRestDays: awayRest,
      homeStandingsRank: null,  // BallDontLie free tier nema standings endpoint
      awayStandingsRank: null,
      fetchedAt: DateTime.now(),
    );
  }
  
  Future<List<Map<String, dynamic>>> _getTeamLast10Games(int teamId, int season) async {
    try {
      final uri = Uri.parse('$_baseUrl/games').replace(queryParameters: {
        'team_ids[]': teamId.toString(),
        'seasons[]': season.toString(),
        'per_page': '15',
      });
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final games = (data['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((g) => g['status'] == 'Final')
          .toList();
      games.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return games.take(10).toList();
    } catch (_) {
      return [];
    }
  }
  
  List<String> _gamesToForm(List<Map<String, dynamic>> games, int teamId) {
    final form = <String>[];
    for (final g in games) {
      final homeTeam = g['home_team'] as Map<String, dynamic>;
      final isHome = homeTeam['id'] == teamId;
      final homeScore = g['home_team_score'] as int;
      final visitorScore = g['visitor_team_score'] as int;
      final won = isHome ? homeScore > visitorScore : visitorScore > homeScore;
      form.add(won ? 'W' : 'L');
    }
    return form;
  }
  
  void dispose() => _client.close();
}

class BallDontLieException implements Exception {
  final String message;
  BallDontLieException(this.message);
  @override
  String toString() => 'BallDontLieException: $message';
}
```

### Verifikacija Taska 4

- `flutter analyze` → i dalje error (IntelligenceAggregator).
- Prijelaz na Task 5.

---

## TASK 5 — RedditMonitor

**Cilj:** Čitaj top posts iz sport-specific subreddit-a, traži spominjanja timova iz watched matches. Bez API ključa (read-only JSON endpoint).

### Poznavanje:

- Reddit ima **public JSON endpoints** — `https://www.reddit.com/r/{subreddit}/hot.json?limit=50`
- **Bitno:** Reddit zahtijeva `User-Agent` header koji nije generičan ("BetSight/1.0 by /u/user"), inače vraća 429
- Rate limit: 60 req/h za unauthenticated users (dovoljno)
- Sport subreddits: `r/sportsbook`, `r/soccer`, `r/NBA`, `r/tennis`

### Kreiraj fajlove

**`lib/services/reddit_monitor.dart`:**

```dart
class RedditMonitor {
  final http.Client _client;
  
  static const _baseUrl = 'https://www.reddit.com';
  static const _userAgent = 'BetSight/1.0';  // mandatory for Reddit
  static const _timeout = Duration(seconds: 15);
  
  // Sport → list of subreddits to scan
  static const _subredditsForSport = {
    Sport.soccer: ['soccer', 'sportsbook'],
    Sport.basketball: ['nba', 'sportsbook'],
    Sport.tennis: ['tennis', 'sportsbook'],
  };
  
  RedditMonitor({http.Client? client}) : _client = client ?? http.Client();
  
  /// Vraća RedditSignal za match — broji spominjanja timova u top postovima.
  Future<RedditSignal> getSignalForMatch(Match match) async {
    final subreddits = _subredditsForSport[match.sport] ?? const <String>[];
    if (subreddits.isEmpty) {
      throw RedditException('Sport not supported');
    }
    
    var mentionCount = 0;
    var topUpvotes = 0;
    String? topTitle;
    String? topSub;
    final teamMentions = <String, int>{};
    teamMentions[match.home] = 0;
    teamMentions[match.away] = 0;
    
    for (final sub in subreddits) {
      try {
        final uri = Uri.parse('$_baseUrl/r/$sub/hot.json?limit=50');
        final resp = await _client.get(
          uri,
          headers: {'User-Agent': _userAgent},
        ).timeout(_timeout);
        if (resp.statusCode != 200) continue;
        
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final posts = ((data['data'] as Map<String, dynamic>)['children'] as List<dynamic>);
        
        for (final p in posts) {
          final post = ((p as Map<String, dynamic>)['data'] as Map<String, dynamic>);
          final title = (post['title'] as String?) ?? '';
          final text = (post['selftext'] as String?) ?? '';
          final fullText = '$title\n$text'.toLowerCase();
          final upvotes = (post['ups'] as int?) ?? 0;
          
          final homeL = match.home.toLowerCase();
          final awayL = match.away.toLowerCase();
          
          var mentioned = false;
          if (fullText.contains(homeL)) {
            teamMentions[match.home] = (teamMentions[match.home] ?? 0) + 1;
            mentioned = true;
          }
          if (fullText.contains(awayL)) {
            teamMentions[match.away] = (teamMentions[match.away] ?? 0) + 1;
            mentioned = true;
          }
          
          if (mentioned) {
            mentionCount++;
            if (upvotes > topUpvotes) {
              topUpvotes = upvotes;
              topTitle = title;
              topSub = sub;
            }
          }
        }
      } catch (_) {
        continue;  // skip failed subreddit, keep trying others
      }
    }
    
    return RedditSignal(
      matchId: match.id,
      mentionCount: mentionCount,
      topUpvotes: topUpvotes,
      teamMentions: teamMentions,
      topPostTitle: topTitle,
      topPostSubreddit: topSub,
      fetchedAt: DateTime.now(),
    );
  }
  
  void dispose() => _client.close();
}

class RedditException implements Exception {
  final String message;
  RedditException(this.message);
  @override
  String toString() => 'RedditException: $message';
}
```

### Verifikacija Taska 5

- `flutter analyze` → i dalje error (aggregator).
- Task 6 slijedi.

---

## TASK 6 — IntelligenceAggregator + Scoring Engine

**Cilj:** Središnji aggregator koji koordinira sve 5 izvora, cache-ira signale, računa scores + generira IntelligenceReport.

### Kreiraj fajlove

**`lib/services/intelligence_aggregator.dart`:**

```dart
class IntelligenceAggregator {
  final OddsApiService oddsService;
  final FootballDataService? footballService;
  final BallDontLieService? nbaService;
  final RedditMonitor? redditMonitor;
  final TelegramProvider telegramProvider;
  
  static const _signalCacheTtl = Duration(hours: 3);
  
  IntelligenceAggregator({
    required this.oddsService,
    required this.footballService,
    required this.nbaService,
    required this.redditMonitor,
    required this.telegramProvider,
  });
  
  /// Glavna metoda — paralelno pokreće sve 5 scoring evaluacija, sastavlja report.
  Future<IntelligenceReport> buildReport(Match match) async {
    // Paralelizirati sve — svaka evaluacija je independentna
    final futures = await Future.wait([
      _scoreOdds(match),
      _scoreFootballData(match),
      _scoreNbaStats(match),
      _scoreReddit(match),
      _scoreTelegram(match),
    ]);
    
    return IntelligenceReport(
      matchId: match.id,
      sources: futures,
      generatedAt: DateTime.now(),
    );
  }
  
  /// SOURCE 1: Odds (max 2.0)
  /// - Base 0.5 za matching cacheirani match
  /// - +0.5 ako margin <5% (sharp book)
  /// - +0.5 ako drift >3% na nekom outcome-u
  /// - +0.5 ako drift je toward favourite ili non-obvious outcome
  Future<SourceScore> _scoreOdds(Match match) async {
    try {
      final h2h = match.h2h;
      if (h2h == null) {
        return SourceScore.inactive(SourceType.odds, 'No odds data');
      }
      
      double score = 0.5;  // base for having odds at all
      final reasoning = <String>[];
      reasoning.add('margin ${(h2h.bookmakerMargin * 100).toStringAsFixed(1)}%');
      
      if (h2h.bookmakerMargin < 0.05) {
        score += 0.5;
        reasoning.add('sharp book');
      }
      
      // Drift signal (reuse S4 snapshot engine)
      final snapshots = StorageService.getSnapshotsForMatch(match.id);
      if (snapshots.length >= 2) {
        final drift = OddsDrift.compute(snapshots.first, snapshots.last);
        if (drift.hasSignificantMove) {
          score += 0.5;
          final dom = drift.dominantDrift;
          reasoning.add('drift ${dom.side} ${dom.percent > 0 ? "+" : ""}${dom.percent.toStringAsFixed(1)}%');
          
          // Extra 0.5 ako drift side je away ili draw (non-obvious)
          if (dom.side != 'Home') {
            score += 0.5;
            reasoning.add('non-favourite direction');
          }
        }
      }
      
      // Clamp na maxScore
      score = score.clamp(0.0, SourceType.odds.maxScore);
      
      return SourceScore(
        source: SourceType.odds,
        score: score,
        reasoning: reasoning.join(', '),
        isActive: true,
      );
    } catch (e) {
      return SourceScore.inactive(SourceType.odds, 'Error: $e');
    }
  }
  
  /// SOURCE 2: Football-Data (max 1.5)
  /// - 0.3 za postojanje signal-a (active)
  /// - 0.4 ako jedna strana ima strong form (≥4/5)
  /// - 0.4 ako H2H jasno favorizira jednu stranu (≥3/5)
  /// - 0.4 ako je standings razlika ≥8 pozicija (undervalued underdog potential)
  Future<SourceScore> _scoreFootballData(Match match) async {
    if (footballService == null || !footballService!.hasApiKey) {
      return SourceScore.inactive(SourceType.footballData, 'No API key');
    }
    if (match.sport != Sport.soccer) {
      return SourceScore.inactive(SourceType.footballData, 'Not a soccer match');
    }
    
    // Cache check
    FootballDataSignal? signal = StorageService.getFootballSignal(match.id);
    if (signal == null || DateTime.now().difference(signal.fetchedAt) > _signalCacheTtl) {
      try {
        signal = await footballService!.getSignalForMatch(match);
        await StorageService.saveFootballSignal(signal);
      } catch (e) {
        return SourceScore.inactive(SourceType.footballData, 'Fetch failed: $e');
      }
    }
    
    double score = 0.3;  // active bonus
    final reasoning = <String>[];
    
    final homeWins = signal.homeWinsForm;
    final awayWins = signal.awayWinsForm;
    if (homeWins >= 4 || awayWins >= 4) {
      score += 0.4;
      reasoning.add(homeWins >= 4 ? 'home strong form' : 'away strong form');
    }
    
    final h2hTotal = signal.h2hHomeWins + signal.h2hDraws + signal.h2hAwayWins;
    if (h2hTotal >= 5) {
      if (signal.h2hHomeWins >= 3 || signal.h2hAwayWins >= 3) {
        score += 0.4;
        reasoning.add(signal.h2hHomeWins >= 3 ? 'home H2H dominant' : 'away H2H dominant');
      }
    }
    
    if (signal.homePosition != null && signal.awayPosition != null) {
      final gap = (signal.homePosition! - signal.awayPosition!).abs();
      if (gap >= 8) {
        score += 0.4;
        reasoning.add('standings gap $gap');
      }
    }
    
    reasoning.add('form H${signal.homeFormLast5.join()} A${signal.awayFormLast5.join()}');
    
    score = score.clamp(0.0, SourceType.footballData.maxScore);
    return SourceScore(
      source: SourceType.footballData,
      score: score,
      reasoning: reasoning.join(', '),
      isActive: true,
    );
  }
  
  /// SOURCE 3: NBA Stats (max 1.0)
  /// - 0.3 active
  /// - 0.35 ako jedna strana ima ≥7/10 recent wins
  /// - 0.35 ako rest days differencija ≥3
  Future<SourceScore> _scoreNbaStats(Match match) async {
    if (nbaService == null) {
      return SourceScore.inactive(SourceType.nbaStats, 'Service unavailable');
    }
    if (match.sport != Sport.basketball) {
      return SourceScore.inactive(SourceType.nbaStats, 'Not an NBA match');
    }
    
    NbaStatsSignal? signal = StorageService.getNbaSignal(match.id);
    if (signal == null || DateTime.now().difference(signal.fetchedAt) > _signalCacheTtl) {
      try {
        signal = await nbaService!.getSignalForMatch(match);
        await StorageService.saveNbaSignal(signal);
      } catch (e) {
        return SourceScore.inactive(SourceType.nbaStats, 'Fetch failed: $e');
      }
    }
    
    double score = 0.3;
    final reasoning = <String>[];
    
    if (signal.homeWinsLast10 >= 7 || signal.awayWinsLast10 >= 7) {
      score += 0.35;
      reasoning.add(signal.homeWinsLast10 >= 7 ? 'home hot streak' : 'away hot streak');
    }
    
    if (signal.homeRestDays != null && signal.awayRestDays != null) {
      final diff = (signal.homeRestDays! - signal.awayRestDays!).abs();
      if (diff >= 3) {
        score += 0.35;
        reasoning.add('rest diff $diff days');
      }
    }
    
    reasoning.add('last10 H${signal.homeWinsLast10} A${signal.awayWinsLast10}');
    
    score = score.clamp(0.0, SourceType.nbaStats.maxScore);
    return SourceScore(
      source: SourceType.nbaStats,
      score: score,
      reasoning: reasoning.join(', '),
      isActive: true,
    );
  }
  
  /// SOURCE 4: Reddit (max 1.0)
  /// - 0.2 active (nema koristi ako <5 mentions)
  /// - 0.3 ako mention count ≥10
  /// - 0.3 ako sentiment bias (>0.3 u bilo kojem smjeru)
  /// - 0.2 ako top post upvotes ≥500
  Future<SourceScore> _scoreReddit(Match match) async {
    if (redditMonitor == null) {
      return SourceScore.inactive(SourceType.reddit, 'Service unavailable');
    }
    
    RedditSignal? signal = StorageService.getRedditSignal(match.id);
    if (signal == null || DateTime.now().difference(signal.fetchedAt) > _signalCacheTtl) {
      try {
        signal = await redditMonitor!.getSignalForMatch(match);
        await StorageService.saveRedditSignal(signal);
      } catch (e) {
        return SourceScore.inactive(SourceType.reddit, 'Fetch failed: $e');
      }
    }
    
    if (signal.mentionCount < 3) {
      return SourceScore.inactive(SourceType.reddit, 'Low mention count (${signal.mentionCount})');
    }
    
    double score = 0.2;
    final reasoning = <String>['${signal.mentionCount} mentions'];
    
    if (signal.mentionCount >= 10) {
      score += 0.3;
      reasoning.add('high buzz');
    }
    
    final bias = signal.getSentimentBias(match.home, match.away);
    if (bias.abs() > 0.3) {
      score += 0.3;
      reasoning.add(bias > 0 ? 'away tilt' : 'home tilt');
    }
    
    if (signal.topUpvotes >= 500) {
      score += 0.2;
      reasoning.add('viral post');
    }
    
    score = score.clamp(0.0, SourceType.reddit.maxScore);
    return SourceScore(
      source: SourceType.reddit,
      score: score,
      reasoning: reasoning.join(', '),
      isActive: true,
    );
  }
  
  /// SOURCE 5: Telegram (max 0.5, WEIGHTED BY CHANNEL RELIABILITY)
  /// - Signali se čitaju iz telegramProvider.recentSignals filtriranih po detectedSport i match.league
  /// - Svaki signal se ponderira: reliability label (Visoka=1.0, Srednja=0.7, Niska=0.3, Novo=0.5)
  /// - Score = min(0.5, sum(weighted mentions) * 0.25)
  Future<SourceScore> _scoreTelegram(Match match) async {
    final recent = telegramProvider.recentSignals;
    if (recent.isEmpty) {
      return SourceScore.inactive(SourceType.telegram, 'No signals');
    }
    
    // Filter signals that might be about this match
    final homeL = match.home.toLowerCase();
    final awayL = match.away.toLowerCase();
    final relevant = recent.where((s) {
      final text = s.text.toLowerCase();
      return text.contains(homeL) || text.contains(awayL);
    }).toList();
    
    if (relevant.isEmpty) {
      return SourceScore.inactive(SourceType.telegram, 'No matching signals');
    }
    
    // Weight each signal by source channel reliability
    final channels = telegramProvider.channels;
    double weightedSum = 0;
    final reasoning = <String>[];
    for (final signal in relevant) {
      final channel = channels.firstWhere(
        (c) => c.username == signal.channelUsername,
        orElse: () => MonitoredChannel(username: signal.channelUsername, addedAt: DateTime.now()),
      );
      final weight = switch (channel.reliabilityLabel) {
        'Visoka' => 1.0,
        'Srednja' => 0.7,
        'Niska' => 0.3,
        _ => 0.5,  // Novo
      };
      weightedSum += weight;
      reasoning.add('${signal.channelUsername} (${channel.reliabilityLabel})');
    }
    
    double score = (weightedSum * 0.25).clamp(0.0, SourceType.telegram.maxScore);
    
    return SourceScore(
      source: SourceType.telegram,
      score: score,
      reasoning: reasoning.take(3).join(', ') + (reasoning.length > 3 ? '...' : ''),
      isActive: true,
    );
  }
}
```

### Verifikacija Taska 6

- `flutter analyze` → **SADA 0 issues.** Ako ima errors, popraviti.
- `flutter build windows` → uspješan.

---

## TASK 7 — Intelligence Dashboard Screen + Wire-up + Settings Integration

**Cilj:** Zasebni screen za Intelligence prikaz, wire-up u main.dart, settings za Football-Data API key.

### Kreiraj fajlove

**`lib/screens/intelligence_dashboard_screen.dart`:**

```dart
class IntelligenceDashboardScreen extends StatelessWidget {
  const IntelligenceDashboardScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligence Dashboard'),
        actions: [
          Consumer2<MatchesProvider, IntelligenceProvider>(
            builder: (context, matches, intel, _) {
              final watchedMatches = matches.allMatches
                  .where((m) => matches.isWatched(m.id))
                  .toList();
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh all',
                onPressed: watchedMatches.isEmpty
                    ? null
                    : () => intel.refreshAllWatched(watchedMatches, force: true),
              );
            },
          ),
        ],
      ),
      body: Consumer2<MatchesProvider, IntelligenceProvider>(
        builder: (context, matches, intel, _) {
          final watchedMatches = matches.allMatches
              .where((m) => matches.isWatched(m.id))
              .toList();
          
          if (watchedMatches.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () => intel.refreshAllWatched(watchedMatches, force: true),
            child: ListView.builder(
              itemCount: watchedMatches.length,
              itemBuilder: (_, i) => _IntelligenceMatchCard(
                match: watchedMatches[i],
                report: intel.reportFor(watchedMatches[i].id),
                isGenerating: intel.isGeneratingFor(watchedMatches[i].id),
                onGenerate: () => intel.generateReport(watchedMatches[i], force: true),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 56, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text('No watched matches', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 4),
          Text('Star matches in Matches screen to see intelligence',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _IntelligenceMatchCard extends StatelessWidget {
  final Match match;
  final IntelligenceReport? report;
  final bool isGenerating;
  final VoidCallback onGenerate;
  
  const _IntelligenceMatchCard({
    required this.match,
    required this.report,
    required this.isGenerating,
    required this.onGenerate,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(match.sport.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.league, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${match.home} vs ${match.away}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (isGenerating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (report == null)
                  OutlinedButton(onPressed: onGenerate, child: const Text('Generate'))
                else
                  _ConfluenceBadge(report: report!),
              ],
            ),
            if (report != null) ...[
              const SizedBox(height: 12),
              ..._buildSourceRows(report!),
              const SizedBox(height: 8),
              Text(
                'Generated ${_relativeTime(report!.generatedAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildSourceRows(IntelligenceReport report) {
    return report.sources.map((s) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(s.source.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Text(
                s.source.display,
                style: TextStyle(
                  fontSize: 12,
                  color: s.isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: s.isActive
                  ? LinearProgressIndicator(
                      value: s.score / s.source.maxScore,
                      minHeight: 6,
                      backgroundColor: Colors.grey[800],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              child: Text(
                s.isActive
                    ? '${s.score.toStringAsFixed(1)}/${s.source.maxScore}'
                    : 'inactive',
                style: TextStyle(
                  fontSize: 11,
                  color: s.isActive ? Colors.white : Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _ConfluenceBadge extends StatelessWidget {
  final IntelligenceReport report;
  const _ConfluenceBadge({required this.report});
  
  @override
  Widget build(BuildContext context) {
    final color = Color(report.category.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${report.confluenceScore.toStringAsFixed(1)} — ${report.category.display.replaceAll('_', ' ')}',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

### Ažuriraj fajlove

**`lib/main.dart`** — dodaj sve nove providere + wire-up IntelligenceProvider + start auto-refresh:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await StorageService.init();
    final cleanupResult = await StorageService.runScheduledCleanup();
    debugPrint('Scheduled cleanup: $cleanupResult');
  } catch (e) {
    debugPrint('StorageService init/cleanup failed: $e');
  }
  runApp(const BetSightApp());
}

// U MultiProvider blocu:
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => NavigationController()),
    ChangeNotifierProvider(create: (_) => MatchesProvider()),
    ChangeNotifierProvider(create: (_) => AnalysisProvider()),
    ChangeNotifierProvider(create: (_) => BetsProvider()),
    ChangeNotifierProvider(create: (_) => TelegramProvider()),
    ChangeNotifierProvider(
      create: (context) {
        final provider = IntelligenceProvider();
        // Wire services odmah
        final footballKey = StorageService.getFootballDataApiKey();
        final footballService = (footballKey != null && footballKey.isNotEmpty)
            ? (FootballDataService()..setApiKey(footballKey))
            : null;
        final nbaService = BallDontLieService();
        final redditMonitor = RedditMonitor();
        provider.wireServices(
          oddsService: OddsApiService(),  // shared instance ideal, ali ok za MVP
          footballService: footballService,
          nbaService: nbaService,
          redditMonitor: redditMonitor,
          telegramProvider: context.read<TelegramProvider>(),
        );
        return provider;
      },
    ),
  ],
  child: const BetSightApp(),
)
```

**Start auto-refresh** — u BetSightApp ili u MainNavigation StatelessWidget-u, dodaj listener na MatchesProvider.watchedMatchIds koji restart-a IntelligenceProvider auto-refresh:

```dart
// U IntelligenceProvider, expose metoda koja prima callback za watched matches:
void startAutoRefresh(List<Match> Function() watchedProvider) { ... }

// U main.dart ili MainNavigation initState:
// Nakon prvog MatchesProvider fetchMatches, pozvati:
context.read<IntelligenceProvider>().startAutoRefresh(() {
  final matches = context.read<MatchesProvider>();
  return matches.allMatches.where((m) => matches.isWatched(m.id)).toList();
});
```

Ovo je malo tricky zbog Provider context pristupa — Claude Code neka riješi na način koji je clean (možda u ChangeNotifierProxyProvider pattern-u, ili kroz Consumer u MainNavigation widget tree-u). Ako je kompleksno, **preskočiti auto-refresh u S6** i ostaviti samo on-demand + dokumentirati kao Identified Issue za S6.5.

**`lib/screens/matches_screen.dart`** — dodaj navigation link prema Intelligence Dashboard-u:

Na vrhu (uz cached badge, npr. u istoj Column), dodaj **button "View Intelligence →"** koji se pojavljuje samo kad ima watched matches:

```dart
Consumer<MatchesProvider>(
  builder: (context, matches, _) {
    final watchedCount = matches.watchedMatchIds.length;
    if (watchedCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IntelligenceDashboardScreen()),
          );
        },
        icon: const Icon(Icons.radar, size: 18),
        label: Text('Intelligence for $watchedCount watched'),
      ),
    );
  },
),
```

**`lib/screens/settings_screen.dart`** — dodaj novu sekciju **"Football-Data.org"** za treći API key (analogno postojećim Anthropic i Odds API sekcijama):

Iznad Telegram Monitor sekcije, dodaj:
- Header: icon sports_soccer + title "Football-Data.org API" + status badge
- TextField (obscure s toggle), Save/Remove buttoni
- Helper text: "Free API for soccer stats. Register at football-data.org"

Koristi isti `_ApiKeySection` pattern koji već postoji — samo dodaj treći instance s relevantnim getter/setter-ima:
```dart
_ApiKeySection(
  title: 'Football-Data.org API',
  icon: Icons.sports_soccer,
  hint: 'Your football-data.org API token',
  currentKeyGetter: () => StorageService.getFootballDataApiKey(),
  onSave: (key) async {
    await StorageService.saveFootballDataApiKey(key);
    // TODO: notify IntelligenceProvider to re-wire footballService
  },
  onRemove: () async {
    await StorageService.deleteFootballDataApiKey();
  },
),
```

**Na notify IntelligenceProvider:** jednostavan pristup — `context.read<IntelligenceProvider>()` metoda `onFootballKeyChanged(String? newKey)` koja re-wire-a service. Ako nema vremena, preskoči i dokumentiraj kao Identified Issue: *"Football-Data API key change requires app restart to take effect."*

### Proširi AnalysisProvider context injection

U `_buildUserMessage`, dodaj `[INTELLIGENCE REPORT]` blok kad je staged match watched i ima report:

```dart
// U sendMessage, nakon postojećeg gatheringa matches/signals/history/drifts, dodaj:
final intelReports = <String, IntelligenceReport>{};
if (effectiveMatches != null) {
  for (final m in effectiveMatches) {
    final report = StorageService.getReport(m.id);
    if (report != null) intelReports[m.id] = report;
  }
}

final userContent = _buildUserMessage(
  text,
  contextMatches: effectiveMatches,
  contextSignals: effectiveSignals,
  bettingHistory: history,
  driftByMatchId: drifts,
  intelligenceReports: intelReports,  // NOVO
);
```

U `_buildUserMessage`, nakon SELECTED MATCHES blok-a, prije TIPSTER SIGNALS:

```dart
if (intelligenceReports != null && intelligenceReports.isNotEmpty) {
  for (final report in intelligenceReports.values) {
    buf.writeln(report.toClaudeContext());
    buf.writeln();
  }
}
```

### Verifikacija Taska 7

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed (setUpAll proširiti s novim Hive boxovima: `intelligence_reports`, `football_signals_cache`, `nba_signals_cache`, `reddit_signals_cache`)
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan

---

## FINALNA VERIFIKACIJA SESIJE 6

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK u root: `betsight-v2.0.0.apk`
- Verzija: **`2.0.0+7`** (major bump)
- Git: Claude Code **NE commita/pusha** — developer preuzima

---

## FINALNI WORKLOG UNOS

Na kraju `WORKLOG.md`-a, nakon postojeće Session 5.5 FIX sekcije, dodaj:

```markdown
---
---

## Session 6: YYYY-MM-DD — Multi-Source Intelligence Layer

**Kontekst:** S1–S5.5 izgradili single-source platformu ovisnu o Odds API-ju. S6 transformira BetSight u multi-source intelligence platformu s 5 izvora (Odds 0-2.0, Football-Data 0-1.5, NBA Stats 0-1.0, Reddit 0-1.0, Telegram 0-0.5 weighted by reliability) — zbroj confluence score 0-6.0. Scope: samo watched matches (2-5 po korisniku). Novi zasebni Intelligence Dashboard screen, hibrid auto-refresh (1h Timer + on-demand button). **Major version bump (2.0.0+7)** jer je ovo fundamentalna arhitekturalna transformacija.

---

### Task 1 — Source Signal Models + IntelligenceReport
[detalji]

### Task 2 — Storage Integration + IntelligenceProvider skeleton
[detalji]

### Task 3 — FootballDataService
[detalji]

### Task 4 — BallDontLieService
[detalji]

### Task 5 — RedditMonitor
[detalji]

### Task 6 — IntelligenceAggregator + Scoring Engine
[detalji]

### Task 7 — Intelligence Dashboard + Wire-up + Settings
[detalji]

---

### Finalna verifikacija Session 6:
- flutter analyze — 0 issues
- flutter test — N/N passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v2.0.0.apk
- Verzija: 2.0.0+7 (major bump)
- Git: Claude Code NE commita/pusha — developer preuzima
```

**Identified Issues** — vjerojatno će se dodati 2-3 nova (npr. Football-Data team name fuzzy match edge cases, Reddit rate limit hit, auto-refresh wire-up kompleksnost). Dokumentirati sve što nije rješeno.

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši sažetak:

- Ukupno zadataka izvršeno: 7
- Novih Dart fajlova: **11** (source_score, football_data_signal, nba_stats_signal, reddit_signal, intelligence_report, intelligence_provider, football_data_service, ball_dont_lie_service, reddit_monitor, intelligence_aggregator, intelligence_dashboard_screen)
- Ažuriranih Dart fajlova: [broj, očekivano ~5-6]
- Ukupno Dart fajlova u lib/: [novi total, očekivano ~48]
- Flutter analyze: 0 issues
- Flutter test: N/N passed
- Builds: Windows ✓, Android APK ✓ (betsight-v2.0.0.apk)
- **Version: 2.0.0+7 (major bump)** — BetSight je sada multi-source intelligence platforma
- Sljedeći predloženi korak: **Developer commit-a i push-a S6 na GitHub.** Ovo je **ključna verzija za testiranje** — Intelligence Dashboard dramatično mijenja kvalitetu odluka. Real-world test preporučen: star 2-3 meča, generate reports, analiziraj koji izvori daju najvrijednije signale, prati u BETLOG.md. Nakon 1-2 tjedna testa planira se **SESSION 7 — Three-Tier Framework** (analogno CoinSight S8): PRE-MATCH / LIVE / ACCUMULATOR tier sustav s tier-specific Claude promptima, adaptivnim UI-jem, per-tier bet tracking-om.

Kraj SESSION 6.
