# BetSight SESSION 2 — Value Bets + Recommendation Markers + Logging + Android Build + Match Selection

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` u root direktoriju (pravila sesije, autonomni režim)
- `WORKLOG.md` u root direktoriju (što je završeno u S1, trenutno stanje kodnih fajlova)
- `SESSION_1.md` ako trebaš kontekst o dizajnerskim odlukama iz S1

**Nakon čitanja napiši kratki summary (3–5 rečenica) što ćeš raditi, potom nastavi autonomno kroz svih 5 zadataka bez čekanja na developerovu potvrdu.**

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues
2. `flutter build windows` — mora proći (za Task 4 pokreni i `flutter build apk --debug`)
3. Dodaj unos u `WORKLOG.md` pod novi `## Session 2: YYYY-MM-DD — Value Bets + Markers + Logging + Android + Match Selection` s: Task naziv, Status, Opis, Komande izvršene, Kreirani fajlovi, Ažurirani fajlovi, Verifikacija
4. Tek onda prelazi na sljedeći zadatak

**Ako naiđeš na problem izvan scope-a trenutnog zadatka:** ne popravljaj ga, zabilježi u sekciju `## Identified Issues` na dnu `WORKLOG.md`.

**Verzija:** ažuriraj `pubspec.yaml` na `version: 1.1.0+2` u Tasku 1 (prvo mjesto gdje mijenjaš pubspec).

---

## Projektni kontekst

S1 je završio s working MVP-om: 3-tab app (Matches / Analysis / Settings), Odds API integracija za multi-sport (soccer/basketball/tennis), Claude chat s match context injection, Hive perzistencija dva API ključa. Bez ijednog otvorenog Identified Issue-a.

**S2 cilj:** pretvoriti pasivnu listu mečeva u **aktivni value bet pipeline**. Dodajemo:

1. Default filter tab **Value Bets** (deterministički, bez Claude poziva, s 3 preset-a koje korisnik bira u Settings)
2. **Strukturirani recommendation markeri** `**VALUE**` / `**WATCH**` / `**SKIP**` kao machine-parsable output iz Claude-a
3. **Analysis Logging** — svaka Claude analiza se bilježi u Hive za kasnije filtriranje i buduće P&L tracking
4. **Android APK build** (prvi Android artefakt)
5. **Match selection → Analysis context injection** — tap na match → selection state → "Analyze in AI" button → automatsko prebacivanje u Analysis tab s pre-filled matches

**Novi Hive boxovi u S2:** `analysis_logs`
**Novi provider u S2:** `NavigationController` (za tab switching iz izvan MainNavigation-a)

---

## TASK 1 — Value Bets Tab + 3 Preseta

**Cilj:** Matches screen dobiva `TabBar` s dva taba: **Value Bets** (default) i **All Matches**. Sport selector ostaje iznad TabBar-a i radi na oba taba. Korisnik u Settings-u bira jedan od tri value preseta.

### Kreiraj fajlove

**`lib/models/value_preset.dart`:**

```dart
enum ValuePreset {
  conservative(
    display: 'Conservative',
    description: 'Sharp books only, tight odds range',
    marginMax: 0.05,
    oddsMin: 1.50,
    oddsMax: 3.00,
    spreadMax: 2.5,
  ),
  standard(
    display: 'Standard',
    description: 'Balanced edge and match volume',
    marginMax: 0.08,
    oddsMin: 1.40,
    oddsMax: 5.00,
    spreadMax: 4.0,
  ),
  aggressive(
    display: 'Aggressive',
    description: 'Wider range, more candidates',
    marginMax: 0.12,
    oddsMin: 1.20,
    oddsMax: 10.00,
    spreadMax: 10.0,
  );
  
  final String display;
  final String description;
  final double marginMax;      // max bookmaker margin (fraction, not percent)
  final double oddsMin;        // min odd na home ili away
  final double oddsMax;        // max odd na home ili away
  final double spreadMax;      // max ratio max(home,away) / min(home,away)
  
  const ValuePreset({
    required this.display,
    required this.description,
    required this.marginMax,
    required this.oddsMin,
    required this.oddsMax,
    required this.spreadMax,
  });
  
  /// Vraća true ako Match prolazi sva tri kriterija preseta.
  /// Meč bez h2h kvota automatski ne prolazi.
  bool matches(Match match) {
    final h2h = match.h2h;
    if (h2h == null) return false;
    if (h2h.bookmakerMargin > marginMax) return false;
    
    final minOdd = [h2h.home, h2h.away].reduce((a, b) => a < b ? a : b);
    final maxOdd = [h2h.home, h2h.away].reduce((a, b) => a > b ? a : b);
    
    if (minOdd < oddsMin) return false;
    if (maxOdd > oddsMax) return false;
    if ((maxOdd / minOdd) > spreadMax) return false;
    
    return true;
  }
  
  /// Edge score — lower margin = higher edge. Used for sort.
  /// Returns double for stable sort.
  double edgeScore(Match match) {
    final h2h = match.h2h;
    if (h2h == null) return 0.0;
    return 1.0 / (h2h.bookmakerMargin + 0.001); // +0.001 to avoid div by zero
  }
  
  static ValuePreset fromString(String? value) {
    return ValuePreset.values.firstWhere(
      (p) => p.name == value,
      orElse: () => ValuePreset.standard,
    );
  }
}
```

### Ažuriraj fajlove

**`pubspec.yaml`** — bump version:

```yaml
version: 1.1.0+2
```

**`lib/services/storage_service.dart`** — dodaj metode za value preset:

```dart
static const _valuePresetField = 'value_preset';

static String? getValuePreset() => _box.get(_valuePresetField) as String?;
static Future<void> saveValuePreset(String preset) => _box.put(_valuePresetField, preset);
```

**`lib/models/matches_provider.dart`** — dodaj value preset support:

```dart
// Novo polje
ValuePreset _valuePreset = ValuePreset.standard;

// Konstruktor (dodaj nakon postojećeg API key loadinga)
final presetStr = StorageService.getValuePreset();
_valuePreset = ValuePreset.fromString(presetStr);

// Novi getter
ValuePreset get valuePreset => _valuePreset;

/// Vraća samo mečeve koji prolaze trenutni value preset,
/// sortirane po edge score descending.
List<Match> get valueBets {
  final matches = filteredMatches.where((m) => _valuePreset.matches(m)).toList();
  matches.sort((a, b) => _valuePreset.edgeScore(b).compareTo(_valuePreset.edgeScore(a)));
  return matches;
}

// Nova metoda
Future<void> setValuePreset(ValuePreset preset) async {
  _valuePreset = preset;
  await StorageService.saveValuePreset(preset.name);
  notifyListeners();
}
```

**`lib/screens/matches_screen.dart`** — kompletno refaktoriraj u `DefaultTabController` s 2 taba:

- StatefulWidget s `SingleTickerProviderStateMixin`, `late TabController _tabController` (length: 2, initialIndex: 0)
- Scaffold.body → Column:
  - Padding(16) → SportSelector (postojeći, netaknuti)
  - TabBar (controller: _tabController, tabs: [Tab("Value Bets"), Tab("All Matches")])
  - Expanded → TabBarView:
    - Tab 0: `_buildValueBetsTab()` — isti pattern kao postojeći matches list ALI koristi `provider.valueBets` umjesto `provider.filteredMatches`. Empty state drugačiji: "No value bets match current preset (Conservative/Standard/Aggressive). Try a different preset in Settings."
    - Tab 1: `_buildAllMatchesTab()` — **identično trenutnom ponašanju** iz S1 koristeći `provider.filteredMatches`
- Zadrži `_buildNoApiKeyState()` i `_buildSkeletonList()` pomoćne metode (dijeljene između tabova)
- Preset badge u TabBar-u ispod "Value Bets" taba (mali chip s tekućim preset-om, desno) — ako je teško implementirati, ostavi za Polish

**`lib/screens/settings_screen.dart`** — dodaj treću sekciju **"Value Bets Filter"** iznad About sekcije:

```
┌─────────────────────────────────────┐
│ 🎯 Value Bets Filter                │
│                                     │
│ ○ Conservative                      │
│   Sharp books only, tight odds      │
│                                     │
│ ● Standard            ← selected    │
│   Balanced edge and match volume    │
│                                     │
│ ○ Aggressive                        │
│   Wider range, more candidates      │
└─────────────────────────────────────┘
```

Implementacija: Consumer<MatchesProvider>, Column sa 3 RadioListTile<ValuePreset>, onChanged → `provider.setValuePreset(value)`. Subtitle = `preset.description`.

### Verifikacija Taska 1

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Ručna provjera: Value Bets tab pokazuje "No value bets..." ako nema API ključa (jer nema mečeva)

---

## TASK 2 — VALUE / WATCH / SKIP Recommendation Markers

**Cilj:** Claude mora završiti svaku analizu s točno jednim od tri markera: `**VALUE**`, `**WATCH**`, `**SKIP**`. Ovo je podloga za Task 3 (Analysis Logging) i buduće sesije (filtriranje, P&L tracking).

### Ažuriraj fajlove

**`lib/models/analysis_provider.dart`** — zamijeni trenutni `_systemPrompt` s:

```dart
static const _systemPrompt = '''
You are BetSight AI, a sports betting intelligence assistant.
Your job is to analyze matches, odds, and betting value across soccer, basketball, and tennis.

## Analysis method

When match context is provided, calculate implied probability from decimal odds (probability = 1/odds) for each outcome.
Compare implied probability to your own estimate based on team form, head-to-head history, injuries, and recent news you may know about.
A match has value when your estimate exceeds implied probability by a meaningful margin (at least 3 percentage points).

Always mention bookmaker margin if it exceeds 8 percent (sign of a soft book).
Always mention which specific outcome (home/draw/away) looks like value, not just "the match".

## Output format

Every response MUST end with exactly one of these three markers on its own line:

**VALUE** — clear edge detected on a specific outcome, recommend a bet
**WATCH** — interesting spot but edge is marginal or data is incomplete, monitor only
**SKIP** — no edge, fair odds, or too uncertain

Never combine markers. Never skip the marker. The marker must be on its own line as the last line of your response.

## Constraints

This is informational analysis, not financial advice. Users must do their own research and gamble responsibly.
Never suggest loan-based betting, chasing losses, or increasing stakes after a loss.
''';
```

**Kreiraj novu metodu `parseRecommendationType()` u istom fajlu (na dnu klase ili kao top-level funkcija):**

```dart
enum RecommendationType { value, watch, skip, none }

extension RecommendationTypeMeta on RecommendationType {
  String get display => switch (this) {
    RecommendationType.value => 'VALUE',
    RecommendationType.watch => 'WATCH',
    RecommendationType.skip => 'SKIP',
    RecommendationType.none => 'NONE',
  };
}

/// Parses Claude's response for a VALUE/WATCH/SKIP marker.
/// IMPORTANT: order matters — VALUE checked first, then WATCH, then SKIP.
/// Looks for `**MARKER**` as a standalone line (after trim).
RecommendationType parseRecommendationType(String response) {
  // Normalize: split by lines, trim each
  final lines = response.split('\n').map((l) => l.trim()).toList();
  
  // Check order: VALUE > WATCH > SKIP (specificity)
  for (final line in lines) {
    if (line == '**VALUE**') return RecommendationType.value;
  }
  for (final line in lines) {
    if (line == '**WATCH**') return RecommendationType.watch;
  }
  for (final line in lines) {
    if (line == '**SKIP**') return RecommendationType.skip;
  }
  
  // Fallback: inline check (if marker appears mid-line)
  if (response.contains('**VALUE**')) return RecommendationType.value;
  if (response.contains('**WATCH**')) return RecommendationType.watch;
  if (response.contains('**SKIP**')) return RecommendationType.skip;
  
  return RecommendationType.none;
}
```

**Mjesto funkcije:** ili na dno `analysis_provider.dart` (kao top-level funkcija), ili u novi fajl `lib/models/recommendation.dart`. **Preporučam novi fajl** jer će se parseRecommendationType pozivati iz više mjesta (Task 3 Analysis Logging, buduće Task/Session Match Selection screen).

**`lib/models/recommendation.dart`** — enum + parser, kao gore.

### Verifikacija Taska 2

- `flutter analyze` → 0 issues
- Manuelna provjera: pozovi Claude u Analysis screenu s nekim mečem → response mora završiti s `**VALUE**`, `**WATCH**` ili `**SKIP**` na posebnoj liniji. **Ovo ne možemo testirati u autonomnom režimu bez API ključa — provjera radi developer nakon sesije.**

---

## TASK 3 — Analysis Logging

**Cilj:** Svaka uspješna Claude analiza se sprema u Hive box `analysis_logs` kao `AnalysisLog` zapis.

### Kreiraj fajlove

**`lib/models/analysis_log.dart`:**

```dart
class AnalysisLog {
  final String id;              // UUID v4 generiraj ručno
  final DateTime timestamp;
  final String userMessage;
  final String assistantResponse;
  final List<String> contextMatchIds;   // match.id values koji su bili u contextu
  final RecommendationType recommendationType;
  
  const AnalysisLog({
    required this.id,
    required this.timestamp,
    required this.userMessage,
    required this.assistantResponse,
    required this.contextMatchIds,
    required this.recommendationType,
  });
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'userMessage': userMessage,
    'assistantResponse': assistantResponse,
    'contextMatchIds': contextMatchIds,
    'recommendationType': recommendationType.name,
  };
  
  factory AnalysisLog.fromMap(Map<dynamic, dynamic> map) => AnalysisLog(
    id: map['id'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
    userMessage: map['userMessage'] as String,
    assistantResponse: map['assistantResponse'] as String,
    contextMatchIds: (map['contextMatchIds'] as List).cast<String>(),
    recommendationType: RecommendationType.values.firstWhere(
      (t) => t.name == map['recommendationType'],
      orElse: () => RecommendationType.none,
    ),
  );
}

/// Helper: generate UUID v4 (RFC 4122). No external dependency.
String generateUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  // Set version (4) and variant (10xx)
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  
  String hex(int i, int len) => bytes.sublist(i, i + len)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  
  return '${hex(0, 4)}-${hex(4, 2)}-${hex(6, 2)}-${hex(8, 2)}-${hex(10, 6)}';
}
```

Import `dart:math` za Random.secure().

### Ažuriraj fajlove

**`lib/services/storage_service.dart`** — dodaj drugi box i metode:

```dart
static const _analysisLogsBox = 'analysis_logs';

// U init() metodi dodaj:
await Hive.openBox(_analysisLogsBox);

static Box get _logsBox => Hive.box(_analysisLogsBox);

// Spremanje
static Future<void> saveAnalysisLog(AnalysisLog log) async {
  await _logsBox.put(log.id, log.toMap());
}

// Čitanje svih logova sortiranih po timestamp desc (najnoviji prvi)
static List<AnalysisLog> getAllAnalysisLogs() {
  final maps = _logsBox.values.toList();
  final logs = <AnalysisLog>[];
  for (final map in maps) {
    try {
      logs.add(AnalysisLog.fromMap(map as Map<dynamic, dynamic>));
    } catch (_) {
      // skip malformed log
    }
  }
  logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return logs;
}

// Brisanje (za buduće potrebe — ne koristi se u S2)
static Future<void> deleteAnalysisLog(String id) => _logsBox.delete(id);
static Future<int> clearAllAnalysisLogs() => _logsBox.clear();
```

**`lib/models/analysis_provider.dart`** — na kraju uspješnog `sendMessage`, prije notifyListeners i setLoading(false), dodaj log zapis:

```dart
// Nakon što je assistantResponse uspješno primljen i dodan u _messages:
try {
  final log = AnalysisLog(
    id: generateUuid(),
    timestamp: DateTime.now(),
    userMessage: text,   // originalni korisnički tekst, BEZ [SELECTED MATCHES] prefiksa
    assistantResponse: assistantResponse,
    contextMatchIds: contextMatches?.map((m) => m.id).toList() ?? [],
    recommendationType: parseRecommendationType(assistantResponse),
  );
  await StorageService.saveAnalysisLog(log);
} catch (e) {
  debugPrint('Failed to save analysis log: $e');
  // Ne forsiraj error — log failure ne smije razbiti chat UX
}
```

**Važno:** `userMessage` u logu mora biti **originalni tekst** koji je korisnik napisao (ne string s injected `[SELECTED MATCHES]` prefiksom). `_buildUserMessage` gradi string za Claude API, ali log mora biti semantički čist.

### Verifikacija Taska 3

- `flutter analyze` → 0 issues
- Logs se ne mogu testirati bez API ključa — provjera radi developer nakon sesije

---

## TASK 4 — Android Build

**Cilj:** Prvi Android APK artefakt (`betsight-v1.1.0.apk`).

### Provjeri fajlove

**`android/app/build.gradle.kts`** ili **`android/app/build.gradle`** — potvrdi:

- `namespace "com.betsight"` (postavljeno u S1 kroz `flutter create --org`)
- `minSdk` ≥ 21 (Flutter default je OK, nema reown/WC potrebe)
- `compileSdk` = Flutter default (33+)
- `applicationId "com.betsight"`

**`android/app/src/main/AndroidManifest.xml`** — dodaj ako nedostaje:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Aplikacija naziv:

```xml
<application
    android:label="BetSight"
    ...>
```

Ako je `android:label` još uvijek `betsight` iz `flutter create`, promijeni u `BetSight` (displayName za launcher).

### Build i verifikacija

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

Nakon uspješnog buildā, **kopiraj APK u root projekta** (analogno CoinSight konvenciji):

```bash
# Windows PowerShell
Copy-Item build\app\outputs\flutter-apk\app-debug.apk .\betsight-v1.1.0.apk

# ili bash/zsh
cp build/app/outputs/flutter-apk/app-debug.apk ./betsight-v1.1.0.apk
```

**Provjeri `.gitignore`** — uvjeri se da `*.apk` je unutra (bilo je dodano u S1 Post-Phase). APK se **NE commit-a u git**, samo postoji lokalno kao artefakt.

### Verifikacija Taska 4

- `flutter build apk --debug` → uspješan
- APK postoji u root-u projekta: `betsight-v1.1.0.apk`
- APK se **NE** commit-a (verifikacija: `git status` ne smije pokazati APK u staged changes — ako pokazuje, provjeri `.gitignore`)

---

## TASK 5 — Match Selection → Analysis Context Injection

**Cilj:** Korisnik može označiti mečeve u Value Bets/All Matches tabu, pritisnuti "Analyze in AI" FAB, i automatski biti prebačen u Analysis tab s tim mečevima već ubačenima u pre-fill context.

### Kreiraj fajlove

**`lib/models/navigation_controller.dart`:**

```dart
import 'package:flutter/foundation.dart';

class NavigationController extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  
  void setTab(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }
}
```

### Ažuriraj fajlove

**`lib/main.dart`** — dodaj NavigationController u MultiProvider **prije** postojećih provider-a (jer se koristi u MainNavigation-u):

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => NavigationController()),
    ChangeNotifierProvider(create: (_) => MatchesProvider()),
    ChangeNotifierProvider(create: (_) => AnalysisProvider()),
  ],
  child: const BetSightApp(),
)
```

**MainNavigation** refaktoriraj da koristi NavigationController umjesto lokalnog `_currentIndex`:

```dart
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, nav, _) {
        return Scaffold(
          body: IndexedStack(
            index: nav.currentIndex,
            children: const [
              MatchesScreen(),
              AnalysisScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
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
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
```

**`lib/models/matches_provider.dart`** — dodaj selection state:

```dart
// Novi field
final Set<String> _selectedMatchIds = {};

// Getteri
Set<String> get selectedMatchIds => Set.unmodifiable(_selectedMatchIds);
int get selectedCount => _selectedMatchIds.length;
bool isMatchSelected(String matchId) => _selectedMatchIds.contains(matchId);

List<Match> get selectedMatches =>
    _allMatches.where((m) => _selectedMatchIds.contains(m.id)).toList();

// Metode
void toggleMatchSelection(String matchId) {
  if (_selectedMatchIds.contains(matchId)) {
    _selectedMatchIds.remove(matchId);
  } else {
    _selectedMatchIds.add(matchId);
  }
  notifyListeners();
}

void clearSelection() {
  if (_selectedMatchIds.isEmpty) return;
  _selectedMatchIds.clear();
  notifyListeners();
}
```

**`lib/widgets/match_card.dart`** — dodaj optional selection checkbox:

- Novi prop `bool selectable` (default false) i `bool isSelected` (default false) i `VoidCallback? onSelectionToggle`
- Ako `selectable == true`: dodaj na lijevu stranu header Row-a `Checkbox(value: isSelected, onChanged: (_) => onSelectionToggle?.call())` s malim primary-boja tick-om
- Zadrži postojeći `onTap` prop — ako je `selectable` aktivan, tap na cijelu karticu toggla selection; inače pokreće postojeći onTap

**`lib/screens/matches_screen.dart`** — dodaj FAB i selection integracija:

- U obje tab builder metode (_buildValueBetsTab, _buildAllMatchesTab), proslijedi `selectable: true`, `isSelected: provider.isMatchSelected(match.id)`, `onSelectionToggle: () => provider.toggleMatchSelection(match.id)` u MatchCard konstruktor
- Scaffold dobiva `floatingActionButton`:

```dart
floatingActionButton: Consumer<MatchesProvider>(
  builder: (context, provider, _) {
    if (provider.selectedCount == 0) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: () => _goToAnalysisWithSelection(context, provider),
      label: Text('Analyze ${provider.selectedCount} match${provider.selectedCount == 1 ? "" : "es"}'),
      icon: const Icon(Icons.auto_awesome),
    );
  },
),
```

Plus helper metoda:

```dart
void _goToAnalysisWithSelection(BuildContext context, MatchesProvider matches) {
  final selected = matches.selectedMatches;
  if (selected.isEmpty) return;
  
  final analysis = context.read<AnalysisProvider>();
  analysis.stageSelectedMatches(selected);  // Nova metoda u AnalysisProvider — v. ispod
  
  context.read<NavigationController>().setTab(1);  // Analysis tab index
  // NE clearamo selection odmah — korisnik se može vratiti i prilagoditi
}
```

**`lib/models/analysis_provider.dart`** — dodaj `_stagedMatches` field i metodu:

```dart
List<Match> _stagedMatches = [];
List<Match> get stagedMatches => List.unmodifiable(_stagedMatches);
bool get hasStagedMatches => _stagedMatches.isNotEmpty;

void stageSelectedMatches(List<Match> matches) {
  _stagedMatches = List.from(matches);
  notifyListeners();
}

void clearStagedMatches() {
  if (_stagedMatches.isEmpty) return;
  _stagedMatches = [];
  notifyListeners();
}
```

**`sendMessage(text)`** — promijeni signaturu tako da ako `contextMatches` **nije** prosljeđen, automatski koristi `_stagedMatches`:

```dart
Future<void> sendMessage(String text, {List<Match>? contextMatches}) async {
  final effectiveContext = contextMatches ?? (_stagedMatches.isNotEmpty ? _stagedMatches : null);
  // ... ostatak metode koristi effectiveContext umjesto contextMatches
  
  // Nakon uspješnog slanja, očisti staged matches (iskorišteni su)
  if (_stagedMatches.isNotEmpty && contextMatches == null) {
    _stagedMatches = [];
    // ne zovi notifyListeners() ovdje — već je pozvano dalje dolje
  }
}
```

**`lib/screens/analysis_screen.dart`** — dodaj vizualni indikator staged matches-a iznad input bar-a:

```dart
Consumer<AnalysisProvider>(
  builder: (context, provider, _) {
    if (!provider.hasStagedMatches) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${provider.stagedMatches.length} match${provider.stagedMatches.length == 1 ? "" : "es"} staged for next question',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () => provider.clearStagedMatches(),
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  },
),
```

### Verifikacija Taska 5

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Verifikacija UX flow-a radi developer nakon sesije (bez API ključeva ne možemo full E2E test)

---

## FINALNA VERIFIKACIJA SESIJE 2

Nakon svih 5 zadataka:

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed (testovi iz S1 moraju i dalje proći; ako neki padne zbog promjena u MainNavigation strukturi, popravi test da reflektira novi NavigationController setup)
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK postoji u root-u: `betsight-v1.1.0.apk`

---

## GIT COMMIT

```bash
git add .
git status                      # proviri — APK NE smije biti staged
git commit -m "Session 2: Value Bets + Recommendation Markers + Logging + Android Build + Match Selection"
git push origin main
```

**Napomena o commit strategiji:** S2 je velika sesija s 5 zadataka. Ako zelis čistiji commit history, napravi 5 zasebnih commit-ova (po jedan po zadatku) umjesto jednog velikog. Ali za autonomni režim, jedan commit na kraju sesije je OK. Developer će odlučiti u praksi.

---

## FINALNI WORKLOG UNOS

Na kraju `WORKLOG.md`-a, nakon postojeće Session 1 sekcije, dodaj:

```markdown
---
---

## Session 2: YYYY-MM-DD — Value Bets + Markers + Logging + Android + Match Selection

**Kontekst:** S1 završio s working MVP-om. S2 dodaje value bet pipeline (deterministički filter s 3 preseta), strukturirane recommendation markere (VALUE/WATCH/SKIP), analysis logging u Hive, prvi Android APK build, i match selection UI flow u Analysis tab.

---

### Task 1 — Value Bets Tab + 3 Presets
[detalji iz gore navedene strukture]

### Task 2 — VALUE / WATCH / SKIP Markers
[detalji]

### Task 3 — Analysis Logging
[detalji]

### Task 4 — Android Build
[detalji]

### Task 5 — Match Selection → Context Injection
[detalji]

---

### Finalna verifikacija Session 2:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.1.0.apk
- Verzija: 1.1.0+2
- Git commit: <hash>
```

**Ako ima novih Identified Issues** — pod postojeću `## Identified Issues` sekciju, zamijeni `*No unresolved issues at this time.*` s listom issues-a.

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši kratki sažetak:

- Ukupno zadataka izvršeno: 5
- Novih Dart fajlova: [broj] (value_preset.dart, recommendation.dart, analysis_log.dart, navigation_controller.dart)
- Ažuriranih Dart fajlova: [broj]
- Ukupno Dart fajlova u lib/: [novi total]
- Ukupno linija koda: [novi total]
- Flutter analyze: 0 issues
- Flutter test: [N]/[N] passed
- Builds: Windows ✓, Android APK ✓ (`betsight-v1.1.0.apk`)
- Git commit hash: [hash]
- Identified Issues (ako ih ima): [lista]
- Sljedeći predloženi korak: **Developer testira APK na Android uređaju**, registrira API ključeve, testira E2E flow value-bet pipeline-a (Matches → Value Bets tab → select → Analyze in AI → Claude vraća VALUE/WATCH/SKIP → log u Hive). Nakon potvrde da sve radi, planira se SESSION 3: **Bet Tracking + Manualni Bet Entry + Bankroll Management** (analogno CoinSight S3 Portfolio + Trade logging, ali bez trading API-ja — manualni unos bet-ova, closing flow, bankroll Kelly Criterion calculator).

Kraj SESSION 2.
