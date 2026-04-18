# BetSight Worklog

## Session 1: 2026-04-18 — Initial Build (Faze 1-5)

### Phase 1 — Scaffold
**Status:** Completed

**Opis:** Inicijalni setup Flutter projekta — scaffold, dark tema, 3-tab bottom navigation, stub screens. Tema koristi BetSight palette (primary #6C63FF, surface #1E1E1E). MainNavigation koristi IndexedStack za state-preserving tab switching.

**Komande izvršene:**
- `flutter --version` (Flutter 3.41.6, Dart 3.11.4)
- `flutter create --org com.betsight --project-name betsight .`
- `flutter pub get`
- `flutter analyze`
- `flutter build windows`
- `flutter test`

**Direktoriji kreirani:** `lib/screens/`, `lib/widgets/`, `lib/services/`, `lib/models/`, `lib/theme/`

**Kreirani fajlovi:**
- `lib/theme/app_theme.dart` — AppTheme klasa s static `darkTheme` getterom; konstante za primary/secondary/surface/card/error/green/red boje; konfiguracija AppBar/BottomNav/Card/Input/ElevatedButton tema.
- `lib/screens/matches_screen.dart` — Stub Scaffold za Matches tab.
- `lib/screens/analysis_screen.dart` — Stub Scaffold za Analysis tab.
- `lib/screens/settings_screen.dart` — Stub Scaffold za Settings tab.

**Ažurirani fajlovi:**
- `pubspec.yaml` — dodane dependencies: http ^1.4.0, provider ^6.1.0, hive ^2.2.3, hive_flutter ^1.1.0, intl ^0.20.0, hive_generator ^2.0.1, build_runner ^2.4.0; opis aplikacije.
- `lib/main.dart` — `BetSightApp` MaterialApp + `MainNavigation` StatefulWidget s IndexedStack i BottomNavigationBar (3 taba: Matches/Analysis/Settings).
- `test/widget_test.dart` — Test koji renderira BetSightApp i provjerava prisustvo Matches/Analysis/Settings labela.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan (betsight.exe built), flutter test 1/1 passed.

---

### Phase 2 — The Odds API + Matches Screen
**Status:** Completed

**Opis:** Multi-sport odds integracija (soccer/basketball/tennis) preko The Odds API v4. Apstraktni Match model pokriva sva tri sporta uz sport-specific draw handling. MatchesProvider agregira sve sport keyove u jednom fetchu, podržava sport filter i graceful no-API-key state. UI gracefully handle-a sve states (no key, loading, error, empty, lista).

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/sport.dart` — Sport enum (soccer/basketball/tennis) + SportMeta extension (display, icon, hasDraw, defaultSportKeys, fromSportKey factory).
- `lib/models/odds.dart` — H2HOdds model s home/away/draw kvotama, lastUpdate, bookmaker; getteri za implied probability i bookmaker margin.
- `lib/models/match.dart` — Match model s id/sport/league/sportKey/teams/commenceTime/h2h; Match.fromJson factory parsira Odds API JSON; isLive/timeToKickoff getteri; private _leagueDisplayNames mapa.
- `lib/services/odds_api_service.dart` — OddsApiService HTTP klijent; setApiKey, getMatches (per-sport iteracija s graceful failure), 15s timeout, hvata 401/429/422 statuse, prati x-requests-remaining header. OddsApiException klasa.
- `lib/models/matches_provider.dart` — MatchesProvider ChangeNotifier; allMatches/filteredMatches/selectedSport/isLoading/error/hasApiKey/remainingRequests; setSelectedSport, setApiKey, fetchMatches (agregira sva 3 sporta), clearError.
- `lib/widgets/odds_widget.dart` — OddsWidget prikazuje 2 ili 3 chipa (Home/Draw/Away) s decimalnim kvotama; "Odds unavailable" fallback.
- `lib/widgets/match_card.dart` — MatchCard prikazuje league header + countdown/LIVE badge + teams + OddsWidget; intl DateFormat za >24h.
- `lib/widgets/sport_selector.dart` — Horizontal ChoiceChip lista (All / Soccer / Basketball / Tennis).

**Ažurirani fajlovi:**
- `lib/screens/matches_screen.dart` — StatefulWidget; Consumer<MatchesProvider>; renderira no-API-key / skeleton / error / empty / RefreshIndicator+ListView state.
- `lib/main.dart` — MultiProvider s MatchesProvider.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Phase 3 — Anthropic/Claude Integration
**Status:** Completed

**Opis:** Chat sučelje s Claude AI za analizu mečeva i kvota. ClaudeService šalje messages na claude-sonnet-4-20250514 endpoint, AnalysisProvider drži povijest poruka i podržava match context injection (header `[SELECTED MATCHES]`). Chat UI ima empty state s 3 suggestion chipa, typing indicator, error bar, clear-chat confirm dialog i no-API-key state.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/services/claude_service.dart` — ClaudeService HTTP klijent za /v1/messages endpoint, claude-sonnet-4-20250514 model, 30s timeout, 1024 max tokens, hvata 401/429 + parse error; ChatMessage model (role/content/timestamp); ClaudeException klasa.
- `lib/models/analysis_provider.dart` — AnalysisProvider ChangeNotifier; messages/isLoading/error/hasApiKey; system prompt s VALUE/WATCH/SKIP smjernicama; `_buildUserMessage` injecta `[SELECTED MATCHES]` blok kad ima context; rollback user message-a na grešku.
- `lib/widgets/chat_bubble.dart` — ChatBubble s asymmetric border radius, user (primary alpha 0.2, desno) vs assistant (card boja, lijevo); SelectableText.

**Ažurirani fajlovi:**
- `lib/screens/analysis_screen.dart` — StatefulWidget; Consumer<AnalysisProvider>; renderira no-key/empty/lista state, error bar, input bar (delete + TextField + send) i typing indicator.
- `lib/main.dart` — dodano AnalysisProvider u MultiProvider.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Phase 4 — Hive Storage + Settings
**Status:** Completed

**Opis:** Lokalna persistencija API ključeva preko Hive boxa `settings`. Oba providera (Matches/Analysis) u konstruktoru čitaju saved key i prosljeđuju ga svom servisu, te imaju `setApiKey`/`removeApiKey` metode koje async pišu u Hive. Settings screen ima dvije sekcije (Anthropic, Odds API) s status badge-om, masked input, show/hide toggle, Save i conditional Remove (s confirm dialog-om), plus About sekciju.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/services/storage_service.dart` — Static StorageService; `init` (Hive.initFlutter + open settings box), gettere/settere/delete za anthropic_api_key i odds_api_key fields.

**Ažurirani fajlovi:**
- `lib/models/matches_provider.dart` — konstruktor učitava odds key iz Storage; setApiKey async sprema; removeApiKey briše key + clear matches.
- `lib/models/analysis_provider.dart` — analogno za Anthropic key (setApiKey/removeApiKey).
- `lib/screens/settings_screen.dart` — kompletno prepisan StatefulWidget; dvije API key sekcije (custom `_ApiKeySection` widget) s `_StatusBadge` (Active/Not set), masked obscure input s show/hide toggle, Save/Remove tijek s SnackBar i confirm dialog; About sekcija s version, source info, disclaimer i SelectableText link.
- `lib/main.dart` — `main` postao async; `WidgetsFlutterBinding.ensureInitialized()` + `StorageService.init()` u try/catch prije runApp.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Phase 5 — Polish
**Status:** Completed

**Opis:** UX poboljšanja: shimmer skeletoni za Matches loading, periodic timer (30s) za live countdown refresh, AnimatedSwitcher na LIVE badge i status badges, Dismissible error bar u Analysis chat-u, dvostruki guard na _scrollToBottom (`_disposed` + hasClients), confirm dialog za clear chat, hint copy promjena dok je provider loading.

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/widgets/match_card.dart` — MatchCard postao StatefulWidget s 30s Timer.periodic za rebuild countdown-a; AnimatedSwitcher 250ms na LIVE↔countdown switch; dodan novi `MatchCardSkeleton` widget (AnimationController 1200ms repeat reverse, Tween 0.3→0.6, easeInOut, shimmer barovi za header/teams/odds redove).
- `lib/screens/matches_screen.dart` — _buildSkeletonList koristi 6 MatchCardSkeleton widgeta umjesto praznih Card placeholdera.
- `lib/screens/analysis_screen.dart` — `_disposed` flag, double-guard u _scrollToBottom, _sendMessage chain-a `.then((_) => _scrollToBottom())`, hint "Waiting for response..." kad isLoading, error bar wrapped u Dismissible + extracted `_confirmClearChat`.
- `lib/screens/settings_screen.dart` — `_StatusBadge` wrapped u AnimatedSwitcher 250ms (Active/Not set tranzicija).

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Post-Phase — Audit, Documentation & Git Setup
**Status:** Completed

**Audit rezultati:** 17 Dart fajlova u `lib/` (1 entry + 1 theme + 5 models + 3 services + 4 widgets + 3 screens), 1878 linija. Verificirano: nema hardkodiranih API ključeva (jedini `sk-ant-` placeholder je hint string u Settings TextField-u), svi providers su u MultiProvider-u, svi controlleri imaju dispose(), svi Hive ključevi prolaze kroz StorageService, HTTPS upstream pozivi.

**Cleanup:** Sve dependencies iz pubspec.yaml su korištene (http, provider, hive, hive_flutter, intl, cupertino_icons, flutter_lints, hive_generator, build_runner). Nije bilo potrebe za pruning-om.

**Kreirani fajlovi:**
- `LICENSE` — Proprietary Software License (5 restrikcija, confidentiality, AS-IS, auto-termination, copyright BetSight 2026).
- `README.md` — Kompletna dokumentacija s badge-ovima, tech stack tablica, architecture tree, setup, configuration, API usage tablica, error handling tablica, security sekcija.

**Ažurirani fajlovi:**
- `.gitignore` — Dodane sekcije za Secrets, Hive, dev logs, APK/AAB.
- `windows/runner/Runner.rc` — CompanyName/FileDescription/LegalCopyright/ProductName branding na BetSight.
- `test/widget_test.dart` — Hive temp directory init u setUpAll, dodan drugi test "Bottom navigation switches tabs" koji provjerava all 3 taba i njihove no-API-key stringove.

**Git:** initial commit `0e239d4`: "Initial commit: BetSight v1.0.0" — 150 fajlova, 8363 insertions.

**Finalna verifikacija Session 1:**
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — betsight.exe built

---

---
---

## Session 2: 2026-04-18 — Value Bets + Markers + Logging + Android + Match Selection

**Kontekst:** S1 završio s working MVP-om. S2 dodaje value bet pipeline (deterministički filter s 3 preseta), strukturirane recommendation markere (VALUE/WATCH/SKIP), analysis logging u Hive, prvi Android APK build, i match selection UI flow u Analysis tab.

---

### Task 1 — Value Bets Tab + 3 Presets
**Status:** Completed

**Opis:** Matches screen dobiva TabBar s 2 taba (Value Bets default + All Matches). Sport selector ostaje iznad TabBar-a i radi na oba taba. ValuePreset enum s 3 preseta (Conservative/Standard/Aggressive) sadrži kriterije (marginMax, oddsMin/Max, spreadMax) + `matches()` filter i `edgeScore()` sort. Settings dobiva treću sekciju s RadioGroup<ValuePreset>.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/value_preset.dart` — ValuePreset enum s constructor parametrima i `matches(Match)` (h2h ne-null + margin + odds range + spread) + `edgeScore(Match)` (1/(margin+0.001)) + `fromString` factory s standard fallback.

**Ažurirani fajlovi:**
- `pubspec.yaml` — version bump na `1.1.0+2`.
- `lib/services/storage_service.dart` — dodano `_valuePresetField` polje, `getValuePreset` i `saveValuePreset` metode.
- `lib/models/matches_provider.dart` — `_valuePreset` field; konstruktor čita preset iz Storage; getteri `valuePreset` i `valueBets` (filter + edge sort); `setValuePreset` async sprema u Hive.
- `lib/screens/matches_screen.dart` — kompletno refaktoriran s SingleTickerProviderStateMixin i TabController; 2 tab buildera (Value Bets + All Matches) + zajedničke pomoćne metode (no-API-key, skeleton, error, empty); novi `_buildEmptyValueState` koji spominje aktivni preset.
- `lib/screens/settings_screen.dart` — dodana "Value Bets Filter" sekcija s RadioGroup<ValuePreset> (3 RadioListTile, subtitle = description) iznad About-a.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 2 — VALUE / WATCH / SKIP Recommendation Markers
**Status:** Completed

**Opis:** Claude system prompt prepravljen s eksplicitnom output format sekcijom — svaka response mora završiti točno jednim od `**VALUE**` / `**WATCH**` / `**SKIP**` markera na zasebnoj liniji. Dodan parser koji najprije traži marker kao standalone trimanu liniju (po redoslijedu specificity: VALUE > WATCH > SKIP), pa fallback na inline. Parser je u zasebnom fajlu jer će se koristiti iz više mjesta (Task 3 logging i buduće sesije).

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/recommendation.dart` — RecommendationType enum (value/watch/skip/none) + RecommendationTypeMeta extension (display) + top-level `parseRecommendationType` funkcija (line-by-line trimirana provjera + fallback inline contains).

**Ažurirani fajlovi:**
- `lib/models/analysis_provider.dart` — `_systemPrompt` zamijenjen s detaljnijim verzijama: Analysis method (implied prob iz decimal kvota, comparison, value threshold 3pp), Output format (VALUE/WATCH/SKIP marker na zadnjoj liniji), Constraints (DYOR, no chasing).

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 3 — Analysis Logging
**Status:** Completed

**Opis:** Svaka uspješna Claude analiza sprema se u novi Hive box `analysis_logs` kao `AnalysisLog` zapis. Log sadrži UUID v4, timestamp, originalni user message (bez `[SELECTED MATCHES]` injekcije), assistant response, popis match.id-ova iz konteksta i parsani `RecommendationType`. Log save je u try/catch — failure se logira preko debugPrint i ne razbija chat UX.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/analysis_log.dart` — AnalysisLog model s `toMap`/`fromMap` i top-level `generateUuid()` (RFC 4122 v4 preko `dart:math` `Random.secure`, postavlja version i variant biteove ručno).

**Ažurirani fajlovi:**
- `lib/services/storage_service.dart` — dodan `_analysisLogsBox` constant; `init()` otvara i drugi box; `_logsBox` getter; `saveAnalysisLog`, `getAllAnalysisLogs` (sort timestamp desc, malformed maps se preskoče), `deleteAnalysisLog`, `clearAllAnalysisLogs`.
- `lib/models/analysis_provider.dart` — uvozi `analysis_log.dart` i `recommendation.dart`; nakon uspjeha `sendMessage` kreira AnalysisLog (originalni `trimmed` text, ne userContent) i zove `StorageService.saveAnalysisLog` u try/catch.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 4 — Android Build
**Status:** Completed

**Opis:** Prvi Android APK artefakt. AndroidManifest.xml dobio `INTERNET` uses-permission i `android:label="BetSight"` (umjesto lowercase `betsight` defaulta iz `flutter create`). `flutter clean` + `flutter pub get` + `flutter build apk --debug` proizveli 142M APK koji je kopiran u root projekta kao `betsight-v1.1.0.apk`. APK NIJE u git status (već pokriven `*.apk` patternom iz S1 .gitignore).

**Komande izvršene:** flutter clean, flutter pub get, flutter build apk --debug, flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `android/app/src/main/AndroidManifest.xml` — dodano `<uses-permission android:name="android.permission.INTERNET" />`; promijenjen `android:label` s `"betsight"` na `"BetSight"`.

**Artefakti:**
- `betsight-v1.1.0.apk` (142M) — debug APK u rootu projekta, NIJE commit-an.

**Verifikacija:** flutter build apk --debug uspješan, flutter analyze 0 issues, flutter build windows uspješan, APK file postoji u root-u, `git status` ne sadrži APK.

---

### Task 5 — Match Selection → Analysis Context Injection
**Status:** Completed

**Opis:** Korisnik može označiti mečeve u Value Bets / All Matches tabovima (checkbox na lijevoj strani header-a, tap na cijelu karticu toggla selection), pritisnuti FAB "Analyze N matches" → automatski se prebacuje u Analysis tab sa staged matches. AnalysisProvider drži `_stagedMatches` i auto-koristi ih kao context u sljedećem `sendMessage` ako poziv ne dostavi explicit `contextMatches`. Staged matches se očiste nakon uspješnog send-a. NavigationController omogućuje tab switching iz vana MainNavigation-a. Test wrap (widget_test.dart) ažuriran s NavigationController providerom kako bi prošao novu MainNavigation strukturu.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/navigation_controller.dart` — NavigationController ChangeNotifier; `_currentIndex`, `setTab(int)` (no-op ako isti index, inače notifyListeners).

**Ažurirani fajlovi:**
- `lib/main.dart` — MainNavigation refaktoriran iz StatefulWidget u StatelessWidget koji čita Consumer<NavigationController> i delegira `currentIndex` + `onTap`; NavigationController dodan kao prvi provider u MultiProvider.
- `lib/models/matches_provider.dart` — `_selectedMatchIds` Set field; getteri `selectedMatchIds`/`selectedCount`/`selectedMatches`/`isMatchSelected`; metode `toggleMatchSelection`/`clearSelection`.
- `lib/widgets/match_card.dart` — dodani opcioni propovi `selectable`, `isSelected`, `onSelectionToggle`; tap-target switcha između selection toggle i onTap based on `selectable`; checkbox renderira na lijevoj strani header Row-a samo kad `selectable == true`.
- `lib/screens/matches_screen.dart` — uvozi NavigationController i AnalysisProvider; FAB `Consumer<MatchesProvider>` pojavljuje se kad `selectedCount > 0`; `_goToAnalysisWithSelection` helper stage-a matches u AnalysisProvider i prebacuje na tab 1; `_buildMatchList` propušta selection state u MatchCard.
- `lib/models/analysis_provider.dart` — `_stagedMatches` field; getteri `stagedMatches`/`hasStagedMatches`; metode `stageSelectedMatches`/`clearStagedMatches`; `sendMessage` koristi effective context (explicit ili staged), čisti staged nakon uspjeha; AnalysisLog koristi `effectiveContext` umjesto explicit contextMatches.
- `lib/screens/analysis_screen.dart` — novi `_buildStagedBar` (primary chip s brojem staged matches + close ikona) prikazan iznad error bar-a kad `hasStagedMatches`.
- `test/widget_test.dart` — dodan NavigationController provider u test wrap.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan.

---

## Identified Issues

*No unresolved issues at this time.*

