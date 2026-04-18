# BetSight SESSION 5 — Infrastructure Hardening (Cache + Rate Limit + Dedup + Cleanup + Error Audit)

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` (pravila, autonomni režim, redoslijed unutar faze)
- `WORKLOG.md` (S1–S4 povijest — posebno obrati pažnju na S2 OddsApiService, S4 Odds Snapshot Engine, i S4 Identified Issues)

**Nakon čitanja napiši kratki summary (3–5 rečenica) što ćeš raditi, potom nastavi autonomno kroz svih 5 zadataka bez čekanja na developerovu potvrdu.**

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues
2. `flutter build windows` — mora proći (za Task 5 završni pokreni i `flutter build apk --debug`)
3. Dodaj unos u `WORKLOG.md` pod novu sekciju `## Session 5: YYYY-MM-DD — Infrastructure Hardening`
4. Tek onda prelazi na sljedeći zadatak

**Git:** Claude Code **NE radi git commit ni git push.** Samo `git status` dozvoljen. Developer preuzima.

**Identified Issues:** Ako naiđeš na nove probleme izvan scope-a, zabilježi u postojeću `## Identified Issues` sekciju (već ima Telegram Bot API limitation iz S4).

**Verzija:** u Tasku 1 ažuriraj `pubspec.yaml` na `version: 1.3.1+5` (patch bump — hardening, ne feature).

---

## Projektni kontekst

S1–S4 su izgradili full feature set: Matches s multi-sport odds, Claude analiza s VALUE/WATCH/SKIP markerima, Bet tracking, Bankroll, Telegram monitor, Odds snapshots. App radi **end-to-end**. Ali ispod haube postoji ozbiljan tehnički dug kojeg treba riješiti prije nego korisnik krene ozbiljno koristiti:

1. **Odds API cache ne postoji** — svaki `fetchMatches()` troši kvotu. Free tier 500 req/mj znači da ćemo izgorjeti za par dana aktivnog korištenja. **Cache sa TTL-om je obavezan.**
2. **Rate limit tracking je samo interno** — `x-requests-remaining` header je spremljen u MatchesProvider, ali korisnik ga ne vidi i nema upozorenje kad se približava kraju.
3. **Snapshot dedup nije implementiran** — svaki refresh Matches screen-a za watched match sprema novi snapshot, čak i ako su kvote identične prethodnom. Brzi rast Hive baze bez vrijednosti.
4. **Old data cleanup ne radi** — imamo `clearOldSignals` i `clearOldSnapshots` metode u StorageService-u, ali nitko ih ne zove. Baza raste beskonačno.
5. **Error handling je nedosljedan** — pojedini provideri imaju `error` string, drugi nemaju, neki rade retry semantiku, drugi tiho propadaju. Nije katastrofalno, ali treba audit prije nego rastemo dalje.

**S5 donosi:** ništa vidljivo korisniku osim (a) rate limit indicator u Settings, (b) "cached" badge u Matches screenu kad se podaci vraćaju iz cache-a, i (c) general responsiveness boost. **Fokus je na održivost sustava.**

**Novi Hive boxovi u S5:** `odds_cache`
**Novi servisi u S5:** `CacheService` (samostalan) ili ekstenzija OddsApiService-a
**Ažurirani modeli:** StorageService (cleanup jobs), OddsApiService (cache integration), MatchesProvider (cached flag, rate limit state)

---

## TASK 1 — Odds API Cache Layer

**Cilj:** Sve `fetchMatches()` pozive protuči kroz lokalni cache s TTL-om. Pri pozivu, prvo provjeri cache — ako postoji entry mlađi od TTL-a, vrati ga bez API poziva. Inače pozovi API i update cache. Korisnik vidi "Cached (5m ago)" badge kad gleda cached data.

**TTL strategija:**
- Default TTL: **15 minuta** (balans između freshness i kvote)
- Korisnik može override-ati u Settings (5 min / 15 min / 30 min / 1 h)
- Pull-to-refresh **force-bypass cache** i uvijek radi API poziv

### Kreiraj fajlove

**`lib/models/cached_matches_entry.dart`:**

```dart
class CachedMatchesEntry {
  final List<Match> matches;
  final DateTime fetchedAt;
  final int? remainingRequests;
  
  const CachedMatchesEntry({
    required this.matches,
    required this.fetchedAt,
    this.remainingRequests,
  });
  
  Duration get age => DateTime.now().difference(fetchedAt);
  
  bool isExpired(Duration ttl) => age > ttl;
  
  /// Human-friendly age: "2m ago", "1h ago"
  String get ageDisplay {
    if (age.inSeconds < 60) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }
  
  Map<String, dynamic> toMap() => {
    'matches': matches.map((m) => _matchToMap(m)).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
    'remainingRequests': remainingRequests,
  };
  
  factory CachedMatchesEntry.fromMap(Map<dynamic, dynamic> map) => CachedMatchesEntry(
    matches: (map['matches'] as List<dynamic>)
        .map((m) => _matchFromMap(m as Map<dynamic, dynamic>))
        .toList(),
    fetchedAt: DateTime.parse(map['fetchedAt'] as String),
    remainingRequests: map['remainingRequests'] as int?,
  );
  
  /// Helper za serijalizaciju Match objekta (nema još toMap na Match klasi)
  static Map<String, dynamic> _matchToMap(Match m) => {
    'id': m.id,
    'sport': m.sport.name,
    'league': m.league,
    'sportKey': m.sportKey,
    'home': m.home,
    'away': m.away,
    'commenceTime': m.commenceTime.toIso8601String(),
    'h2h': m.h2h == null ? null : {
      'home': m.h2h!.home,
      'draw': m.h2h!.draw,
      'away': m.h2h!.away,
      'lastUpdate': m.h2h!.lastUpdate.toIso8601String(),
      'bookmaker': m.h2h!.bookmaker,
    },
  };
  
  static Match _matchFromMap(Map<dynamic, dynamic> map) {
    final h2hMap = map['h2h'] as Map<dynamic, dynamic>?;
    return Match(
      id: map['id'] as String,
      sport: Sport.values.firstWhere((s) => s.name == map['sport']),
      league: map['league'] as String,
      sportKey: map['sportKey'] as String,
      home: map['home'] as String,
      away: map['away'] as String,
      commenceTime: DateTime.parse(map['commenceTime'] as String),
      h2h: h2hMap == null ? null : H2HOdds(
        home: (h2hMap['home'] as num).toDouble(),
        draw: h2hMap['draw'] == null ? null : (h2hMap['draw'] as num).toDouble(),
        away: (h2hMap['away'] as num).toDouble(),
        lastUpdate: DateTime.parse(h2hMap['lastUpdate'] as String),
        bookmaker: h2hMap['bookmaker'] as String,
      ),
    );
  }
}
```

**Napomena o serijalizaciji:** Match nema `toMap`/`fromMap` iz S1 — dodavanje tih metoda u `match.dart` je čišći pristup. Ako Claude Code radije doda metode direktno u Match klasu (umjesto privatnih helpers ovdje), neka to uradi — čitljivije je. Glavno je da se Match može serijalizirati u Hive.

### Ažuriraj fajlove

**`pubspec.yaml`** — version bump: `version: 1.3.1+5`

**`lib/services/storage_service.dart`** — dodaj `odds_cache` box i TTL field:

```dart
static const _oddsCacheBox = 'odds_cache';
static const _cacheTtlMinutesField = 'cache_ttl_minutes';
static const _cacheEntryKey = 'all_matches';  // single entry u boxu, ključ fiksan

// u init():
await Hive.openBox(_oddsCacheBox);

static Box get _cacheBox => Hive.box(_oddsCacheBox);

// Cache CRUD
static CachedMatchesEntry? getCachedMatches() {
  final map = _cacheBox.get(_cacheEntryKey);
  if (map == null) return null;
  try {
    return CachedMatchesEntry.fromMap(map as Map<dynamic, dynamic>);
  } catch (_) {
    return null;
  }
}

static Future<void> saveCachedMatches(CachedMatchesEntry entry) =>
    _cacheBox.put(_cacheEntryKey, entry.toMap());

static Future<void> clearCachedMatches() => _cacheBox.delete(_cacheEntryKey);

// TTL setting
static int getCacheTtlMinutes() => (_box.get(_cacheTtlMinutesField) as int?) ?? 15;
static Future<void> saveCacheTtlMinutes(int minutes) =>
    _box.put(_cacheTtlMinutesField, minutes);
```

**`lib/services/odds_api_service.dart`** — dodaj cache-aware helper (ne mijenjaj postojeći `getMatches`, dodaj novi layer):

```dart
/// Cached fetch — uses cache if not expired, else calls API and updates cache.
/// If `forceRefresh` is true, bypasses cache completely.
Future<({List<Match> matches, bool fromCache, int? remaining, DateTime? cachedAt})> getMatchesCached({
  required List<String> sportKeys,
  bool forceRefresh = false,
}) async {
  if (!forceRefresh) {
    final cached = StorageService.getCachedMatches();
    if (cached != null) {
      final ttlMinutes = StorageService.getCacheTtlMinutes();
      if (!cached.isExpired(Duration(minutes: ttlMinutes))) {
        return (
          matches: cached.matches,
          fromCache: true,
          remaining: cached.remainingRequests,
          cachedAt: cached.fetchedAt,
        );
      }
    }
  }
  
  // Cache miss ili force refresh → API poziv
  final matches = await getMatches(sportKeys: sportKeys);
  final entry = CachedMatchesEntry(
    matches: matches,
    fetchedAt: DateTime.now(),
    remainingRequests: _remainingRequests,
  );
  await StorageService.saveCachedMatches(entry);
  return (
    matches: matches,
    fromCache: false,
    remaining: _remainingRequests,
    cachedAt: null,
  );
}
```

**`lib/models/matches_provider.dart`** — update `fetchMatches` da koristi `getMatchesCached`:

```dart
bool _fromCache = false;
DateTime? _cachedAt;

// Gettere
bool get fromCache => _fromCache;
DateTime? get cachedAt => _cachedAt;

/// `forceRefresh` = true za pull-to-refresh, bypassa cache
Future<void> fetchMatches({bool forceRefresh = false}) async {
  if (!_service.hasApiKey) {
    _error = 'API key not configured';
    notifyListeners();
    return;
  }
  
  _isLoading = true;
  _error = null;
  notifyListeners();
  
  try {
    final allKeys = Sport.values
        .expand((s) => s.defaultSportKeys)
        .toList();
    final result = await _service.getMatchesCached(
      sportKeys: allKeys,
      forceRefresh: forceRefresh,
    );
    _allMatches = result.matches;
    _fromCache = result.fromCache;
    _cachedAt = result.cachedAt;
    _remainingRequests = result.remaining;
    
    if (!_fromCache) {
      await _captureSnapshotsForWatched();
    }
  } on OddsApiException catch (e) {
    _error = e.message;
  } catch (e) {
    _error = 'Failed to load matches';
  }
  
  _isLoading = false;
  notifyListeners();
}
```

**`lib/screens/matches_screen.dart`** — dodaj "Cached (Xm ago)" badge:

- U Column iznad TabBar-a (ili ispod SportSelector-a), Consumer<MatchesProvider>:
- Ako `provider.fromCache && provider.cachedAt != null && provider.allMatches.isNotEmpty`:
  - Mali Container s subtle styling (grey card bg, small padding): Icon(Icons.cached, 14px) + Text("Cached (${ageString}) — pull to refresh")
  - `ageString` računa se iz `DateTime.now().difference(provider.cachedAt!)` i formatira kao CachedMatchesEntry.ageDisplay
- Pull-to-refresh trigger: `RefreshIndicator` onRefresh: `provider.fetchMatches(forceRefresh: true)`

### Verifikacija Taska 1

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 2 — Rate Limit Tracking + UI Warning

**Cilj:** Korisnik u Settings-u jasno vidi stanje API kvote. Matches screen prikazuje warning banner kad je ispod praga. Hard stop (no fetch) kad je na 0.

**Threshold-ovi:**
- ≥ 100 requests left: no warning
- 20-99 left: yellow info banner u Settings ("API usage: 80/500")
- 1-19 left: orange warning banner u Settings + Matches screen
- 0 left: red error banner + block fetchMatches (show "Monthly API quota exhausted. Resets on 1st of month.")

### Ažuriraj fajlove

**`lib/models/matches_provider.dart`** — dodaj rate limit getters i protective logiku:

```dart
int? get remainingRequests => _remainingRequests;

/// null ako nije poznato (nije bilo API poziva još), inače %
double? get requestsUsedPercent {
  if (_remainingRequests == null) return null;
  // free tier = 500 requests
  return ((500 - _remainingRequests!) / 500) * 100;
}

/// Threshold za UI
bool get isApiLimitLow => _remainingRequests != null && _remainingRequests! < 20;
bool get isApiLimitCritical => _remainingRequests != null && _remainingRequests! < 1;
```

U `fetchMatches()`, na početku dodaj:
```dart
if (isApiLimitCritical && !forceRefresh) {
  // Vrati cache ako postoji, inače grešku
  final cached = StorageService.getCachedMatches();
  if (cached != null) {
    _allMatches = cached.matches;
    _fromCache = true;
    _cachedAt = cached.fetchedAt;
    _error = null;
    notifyListeners();
    return;
  }
  _error = 'Monthly API quota exhausted. Resets on 1st of month.';
  notifyListeners();
  return;
}
```

**`lib/screens/matches_screen.dart`** — dodaj warning banner:

- Iznad Cached-badge-a (u istoj Column), Consumer<MatchesProvider>:
- Ako `provider.isApiLimitCritical`: red Container "⚠️ API quota exhausted — showing cached data only" (ili ako nema cache-a, error bar)
- Ako `provider.isApiLimitLow && !isApiLimitCritical`: orange Container "⚠️ Only ${remaining} API requests left this month"

**`lib/screens/settings_screen.dart`** — dodaj novu podsekciju **"API Usage"** unutar postojeće Odds API sekcije:

Ispod TextField-a i buttona, Consumer<MatchesProvider>:

```
┌────────────────────────────────────────┐
│ API Usage this month                    │
│                                         │
│   ████████████████░░░░░  320 / 500     │
│                                         │
│   180 requests left                     │
│   Resets on 1st of month                │
└────────────────────────────────────────┘
```

Implementacija:
- Ako `provider.remainingRequests == null` → skip (još nije bilo poziva)
- Inače: Column s:
  - Text("API Usage this month", small)
  - LinearProgressIndicator(value: `usedPercent / 100`, color ovisi o threshold-u: green > 100 left, yellow 20-99, orange 1-19, red 0)
  - Row(MainAxisAlignment.spaceBetween) s "${used} / 500" i "${remaining} left"
  - Text("Resets on 1st of month", grey small)

**Cache TTL Settings** — dodaj još jedan control u istu sekciju ili posebnu **"Cache"** sekciju:

```
┌────────────────────────────────────────┐
│ Cache TTL                                │
│                                         │
│   [5 min] [15 min ●] [30 min] [1 h]   │
│                                         │
│   Lower TTL = fresher data but more    │
│   API calls                             │
└────────────────────────────────────────┘
```

ChoiceChip s 4 opcije (5, 15, 30, 60), selected je trenutni `getCacheTtlMinutes()`, onChanged → `StorageService.saveCacheTtlMinutes(value)`.

### Verifikacija Taska 2

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 3 — Snapshot Deduplication

**Cilj:** `_captureSnapshotsForWatched` ne sprema identične snapshote. Ako se kvote nisu promijenile od zadnjeg snapshota za taj match, preskoči save.

### Ažuriraj fajlove

**`lib/services/storage_service.dart`** — dodaj helper za zadnji snapshot:

```dart
/// Returns the most recent snapshot za match, ili null ako nema.
static OddsSnapshot? getLatestSnapshotForMatch(String matchId) {
  final snapshots = getSnapshotsForMatch(matchId);
  if (snapshots.isEmpty) return null;
  return snapshots.last; // getSnapshotsForMatch već sortira ascending po capturedAt
}

/// Saves snapshot only if odds are different from the last saved snapshot.
/// Returns true if saved, false if skipped (identical to last).
static Future<bool> saveSnapshotIfChanged(OddsSnapshot snapshot) async {
  final last = getLatestSnapshotForMatch(snapshot.matchId);
  if (last != null &&
      last.home == snapshot.home &&
      last.draw == snapshot.draw &&
      last.away == snapshot.away) {
    return false; // identical, skip
  }
  await saveSnapshot(snapshot);
  return true;
}
```

**`lib/models/matches_provider.dart`** — u `_captureSnapshotsForWatched`, zamijeni `saveSnapshot` s `saveSnapshotIfChanged`:

```dart
Future<void> _captureSnapshotsForWatched() async {
  int saved = 0;
  int skipped = 0;
  for (final match in _allMatches) {
    if (!_watchedMatchIds.contains(match.id)) continue;
    final h2h = match.h2h;
    if (h2h == null) continue;
    
    final snapshot = OddsSnapshot(
      matchId: match.id,
      capturedAt: DateTime.now(),
      home: h2h.home,
      draw: h2h.draw,
      away: h2h.away,
      bookmaker: h2h.bookmaker,
    );
    
    final didSave = await StorageService.saveSnapshotIfChanged(snapshot);
    if (didSave) saved++; else skipped++;
  }
  if (saved > 0 || skipped > 0) {
    debugPrint('Snapshots: saved $saved, skipped (unchanged) $skipped');
  }
}
```

### Verifikacija Taska 3

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 4 — Scheduled Cleanup Jobs

**Cilj:** Na pokretanju app-a, pokreni cleanup starih signala i snapshota. Čuvaj last cleanup timestamp tako da se cleanup ne izvršava češće od 1x dnevno.

### Ažuriraj fajlove

**`lib/services/storage_service.dart`** — dodaj last cleanup tracking:

```dart
static const _lastCleanupField = 'last_cleanup_at';

static DateTime? getLastCleanupAt() {
  final iso = _box.get(_lastCleanupField) as String?;
  if (iso == null) return null;
  try {
    return DateTime.parse(iso);
  } catch (_) {
    return null;
  }
}

static Future<void> saveLastCleanupAt(DateTime t) =>
    _box.put(_lastCleanupField, t.toIso8601String());

/// Runs cleanup if it hasn't run in the last 24h.
/// Returns a map with counts of what was cleaned.
static Future<Map<String, int>> runScheduledCleanup() async {
  final lastRun = getLastCleanupAt();
  if (lastRun != null && DateTime.now().difference(lastRun) < const Duration(hours: 24)) {
    return {'signals_cleaned': 0, 'snapshots_cleaned': 0, 'cache_entries_cleaned': 0};
  }
  
  final signalsCleaned = await clearOldSignals(keepFor: const Duration(days: 7));
  final snapshotsCleaned = await clearOldSnapshots(keepFor: const Duration(days: 7));
  
  // Cache entry — ako je stariji od 24h (sigurno expiran), briši
  final cached = getCachedMatches();
  int cacheEntriesCleaned = 0;
  if (cached != null && cached.age > const Duration(hours: 24)) {
    await clearCachedMatches();
    cacheEntriesCleaned = 1;
  }
  
  await saveLastCleanupAt(DateTime.now());
  return {
    'signals_cleaned': signalsCleaned,
    'snapshots_cleaned': snapshotsCleaned,
    'cache_entries_cleaned': cacheEntriesCleaned,
  };
}
```

**`lib/main.dart`** — pozovi cleanup nakon `StorageService.init()`:

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
```

### Verifikacija Taska 4

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Ručna provjera: pokreni app, zatvori, pokreni za 5 sekundi — cleanup se NE smije pokrenuti drugi put (zbog 24h gate-a). Promijeni `lastCleanupAt` na pre-24h u Hive editoru ili briši polje → cleanup se pokreće opet.

---

## TASK 5 — Error Handling Audit + Polish

**Cilj:** Pregled svih providera i servisa. Osiguraj da:
- Sve `throw` instance imaju tipizirane exception-e (ne generic `Exception`)
- Svi `_error` string-ovi prolaze kroz `clearError()` na success refresh
- UI error bar-ovi su consistentni (Dismissible + dodatni X button)
- Retry semantika je prisutna gdje smislena

### Checklist za audit (Claude Code neka iterira kroz ove fajlove):

**Provideri:**
- [x] `matches_provider.dart` — `_error` field, `clearError()`, retry button u Matches screen
- [x] `analysis_provider.dart` — `_error` field, `clearError()`, Dismissible error bar (iz S1 Phase 5)
- [x] `bets_provider.dart` — ima `_error`, treba `clearError()` + UI reference — **provjeri**
- [x] `telegram_provider.dart` — ima `_error`, `clearError()`, koristi se u Settings testConnection

**Servisi:**
- [x] `odds_api_service.dart` — baca OddsApiException (consistent)
- [x] `claude_service.dart` — baca ClaudeException (consistent)
- [x] `telegram_monitor.dart` — baca TelegramException (consistent)
- [x] `storage_service.dart` — try/catch u deserializaciji, ne baca (consistent)

### Ažuriraj fajlove (ovisno o nalazima audit-a)

Claude Code treba:

1. **Provjeriti** je li `BetsProvider.error` izložen u UI-ju (kroz SnackBar ili error bar). Ako nije, dodati minimalan error UI u Bets screen.

2. **Standardizirati retry pattern** u Matches screen: umjesto samo "Retry" buttona u error state, dodati i **inline retry** ikonu u error banner-u kad je ispod lista.

3. **Pregledati `_buildUserMessage` u AnalysisProvider-u** — ima 3-arg signature iz S4 (text, contextMatches, contextSignals). Osigurati da NULL handling pokriva sve kombinacije (nema matches + nema signals, samo matches, samo signals, oboje).

4. **Provjeriti dispose() chain** — `TelegramProvider.dispose()` disposea monitor. Provjeri da se `dispose()` poziva u testu (test wrapper mora čistiti providere). Ako nedostaje, dodati u test `tearDown`.

5. **Standardizirati SnackBar poruke** — formulacije kao "Saved", "Removed", "Settled" su u različitim engleskim stilovima. Konzistentno: Past tense bez emoji-ja (npr. "Bet settled as Won", "Token saved", "Channel added"). Pregled svih `showSnackBar` poziva i unifikacija.

6. **Provjeriti null safety u fromMap metodama** — osobito u S4 modelima (`TipsterSignal.fromMap`, `OddsSnapshot.fromMap`). Ako je key missing, trebalo bi baciti informativnu grešku umjesto tihog `null`-a.

7. **Dokumentirati retry semantiku** — dodaj doc comment u TelegramMonitor._poll ("silent fail because poll retries on next interval"), OddsApiService.getMatches ("per-sport continue on failure"), itd. Ovo nije UI change, samo developer docs.

### Verifikacija Taska 5

- `flutter analyze` → 0 issues
- `flutter test` → 2/2 passed (ako su testovi fragilni zbog dispose-a, popraviti)
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan

---

## FINALNA VERIFIKACIJA SESIJE 5

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK u root: `betsight-v1.3.1.apk`
- Verzija: `1.3.1+5`
- Git: Claude Code **NE commita/pusha** — developer preuzima

---

## FINALNI WORKLOG UNOS

Na kraju `WORKLOG.md`-a, nakon postojeće Session 4 sekcije, dodaj:

```markdown
---
---

## Session 5: YYYY-MM-DD — Infrastructure Hardening

**Kontekst:** S1–S4 izgradili full feature set. S5 je hardening sesija — ne dodaje nove taba ni screena, fokusira se na održivost: cache layer (free tier Odds API nije izdržljiv bez njega), rate limit tracking + UI, snapshot dedup, scheduled cleanup jobs, error handling audit. Verzija je patch bump (1.3.1+5).

---

### Task 1 — Odds API Cache Layer
[detalji]

### Task 2 — Rate Limit Tracking + UI Warning
[detalji]

### Task 3 — Snapshot Deduplication
[detalji]

### Task 4 — Scheduled Cleanup Jobs
[detalji]

### Task 5 — Error Handling Audit + Polish
[detalji]

---

### Finalna verifikacija Session 5:
- flutter analyze — 0 issues
- flutter test — N/N passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.3.1.apk
- Verzija: 1.3.1+5
- Git: Claude Code NE commita/pusha — developer preuzima
```

**Identified Issues** — ako pronađeš nove probleme tijekom audit-a (Task 5), dodaj ih. Telegram Bot API ograničenje iz S4 ostaje tamo.

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši sažetak:

- Ukupno zadataka izvršeno: 5
- Novih Dart fajlova: 1 (cached_matches_entry.dart)
- Ažuriranih Dart fajlova: [broj, očekivano ~8-10]
- Ukupno Dart fajlova u lib/: [novi total, očekivano 34]
- Flutter analyze: 0 issues
- Flutter test: [N]/[N] passed
- Builds: Windows ✓, Android APK ✓ (betsight-v1.3.1.apk)
- Identified Issues: [update lista ako ima novih iz audit-a]
- Sljedeći predloženi korak: **Developer commit-a i push-a S5 na GitHub.** Ovo je dobra točka za **prvi real-world test na Android-u** — instaliraj APK, unesi stvarne API ključeve (Anthropic + Odds API), provedi full E2E flow preko dan-dva aktivnog korištenja. Promatraj: (a) koliko brzo troši Odds API kvotu (cache mora držati trošenje pod ~30 req/dan), (b) je li drift indicator koristan signal, (c) koje signale javi Telegram monitor ako konfiguriraš test kanal. Nakon real-world feedback-a planira se **SESSION 6**: analogno CoinSight S6 — **Intelligence Layer Aggregator** (multi-source confluence scoring koji kombinira Telegram signals + odds movement + Claude analysis u jedinstveni 0-6.0 score po meču, kategorije STRONG_VALUE / POSSIBLE_VALUE / WEAK / SKIP / INSUFFICIENT_DATA).

Kraj SESSION 5.
