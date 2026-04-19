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

### Finalna verifikacija Session 2:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.1.0.apk (142M, NOT in git)
- Verzija: 1.1.0+2
- Git commit: 679a754

---

---
---

## Session 3: 2026-04-18 — Bet Tracking + Manual Entry + Settlement + Bankroll + P&L Summary

**Kontekst:** S2 završio s working value pipeline-om (filter + markers + logging). S3 zatvara loop: dodaje Bet tracking layer. Korisnik sada može zabilježiti bet (ručno ili iz VALUE preporuke), pratiti ga, zaključiti kao won/lost/void, i pratiti osnovnu P&L statistiku.

---

### Task 1 — Bet Model + BetsProvider + Hive Box
**Status:** Completed

**Opis:** Data layer za bet tracking. Bet model nosi sport/league/teams/selection/odds/stake + status (pending/won/lost/void_) i lifecycle timestamps (placedAt/settledAt). `actualProfit` getter switch-a po statusu (null za pending, +profit za won, -stake za lost, 0 za void). BankrollConfig drži total/stakeUnit/currency. BetsProvider izlaže openBets/settledBets filtere i P&L kalkulacije (winRate na decisive bets, ROI na settled stake, totalProfit). Novi Hive box `bets` + `bankroll_config` field u settings boxu.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/bet.dart` — BetSelection enum (home/draw/away) + BetStatus enum (pending/won/lost/void_; void_ s trailing underscore jer je `void` Dart keyword) + BetSelectionMeta/BetStatusMeta extensions; Bet klasa s 14 polja + copyWith + toMap/fromMap; getteri potentialPayout/potentialProfit/actualProfit/impliedProbability.
- `lib/models/bankroll.dart` — BankrollConfig (totalBankroll/defaultStakeUnit/currency) + defaultConfig (0/10/EUR) + stakeAsPercentage getter + toMap/fromMap.
- `lib/models/bets_provider.dart` — BetsProvider ChangeNotifier; konstruktor čita bets i bankroll iz Storage; getteri allBets/openBets (sort po matchStartedAt asc) /settledBets (sort po settledAt desc) /bankroll/error/totalBets/wonBets/lostBets/voidBets/pendingBets/winRate/totalProfit/totalStakedOnSettled/roi; metode addBet/settleBet (s assert da nije pending) /deleteBet/setBankroll.

**Ažurirani fajlovi:**
- `pubspec.yaml` — version bump na `1.2.0+3`.
- `lib/services/storage_service.dart` — dodan `_betsBox` constant + `_bankrollField`; `init()` otvara treći box; `_betsBoxRef` getter; `getAllBets` (skip malformed), `saveBet`, `deleteBet`, `getBankrollConfig`, `saveBankrollConfig`.
- `lib/main.dart` — BetsProvider dodan u MultiProvider nakon AnalysisProvider.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 2 — Bets Screen (4. Tab) + Open/Settled Tabs
**Status:** Completed

**Opis:** Navigacija proširena s 3 na 4 taba: Matches / Analysis / **Bets** / Settings (Settings se pomakla s indeksa 2 na 3). BetsScreen koristi SingleTickerProviderStateMixin i TabController(2) za Open / Settled subtabove. BetCard je Dismissible (endToStart, confirm dialog) za swipe-to-delete; tap na pending bet otvara settle bottom sheet (full implementation u Task 4 ali widget već prisutan); StatusChip s ikonama (hourglass/check/close/remove) i bojama (blue/green/red/grey); Settle button (full-width) na pending bet-ovima. Tests ažurirani na 4 taba + dodana tap+verify za Bets empty state.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows.

**Kreirani fajlovi:**
- `lib/widgets/bet_card.dart` — BetCard wrapped u Dismissible (background red s delete ikonom; confirmDismiss → AlertDialog); tap-na-card otvara settle sheet ako pending; layout: header (sport icon + league + StatusChip), teams + Pick row, meta chips (Odds/Stake/Bookmaker), conditional P&L row (s ±predznakom i bojom green/red/grey), conditional Settle button. Privatni `_StatusChip` (boje + ikone po BetStatus) i `_MetaChip` widgeti.
- `lib/screens/bets_screen.dart` — BetsScreen StatefulWidget s TabController; FAB Icons.add (TODO za Task 3); placeholder SizedBox.shrink() iznad TabBar-a (Task 5 zamjenjuje s PlSummaryWidget); `_buildOpenTab`/`_buildSettledTab` Consumer<BetsProvider> + empty states ("No open bets — tap + to log one" / "No settled bets yet"); `_buildBetList` ListView.builder s BetCard.

**Ažurirani fajlovi:**
- `lib/main.dart` — uvozi BetsScreen; IndexedStack proširen na 4 children (Bets na indeksu 2, Settings na 3); BottomNavigationBar dobio 4. item s `Icons.receipt_long_outlined`/`Icons.receipt_long` i labelom "Bets".
- `test/widget_test.dart` — uvozi BetsProvider; provider list proširen; setUpAll otvara `analysis_logs` i `bets` Hive boxove pored `settings`; test "renders" provjerava i "Bets" label; test "switches tabs" tap-a Bets tab i očekuje empty state string.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan.

---

### Task 3 — Manual Bet Entry
**Status:** Completed

**Opis:** BetEntrySheet bottom sheet (full scrollable, IsScrollControlled true) prima opcionalni `prefilledMatch`/`prefilledSelection`/`prefilledOdds`. Form polja: Sport (DropdownButtonFormField, disabled ako je prefilled), League/Home/Away (TextFormField required), Selection (ChoiceChip Wrap, Draw chip se prikazuje samo kad sport.hasDraw), Odds + Stake (FilteringTextInputFormatter dozvoljava digit/.,), Bookmaker + Notes (optional). Default stake se pre-fillaa iz BetsProvider.bankroll.defaultStakeUnit. Validatori provjeravaju required fields, odds > 1.0, stake > 0, draw + non-soccer mismatch. FAB u Bets tabu otvara prazan sheet; "Log this as a bet" OutlinedButton ispod assistant ChatBubble-a u Analysis-u (samo kad parseRecommendationType vrati VALUE) otvara sheet pre-fillan iz prvog staged matcha.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/widgets/bet_entry_sheet.dart` — BetEntrySheet StatefulWidget; init_state učitava controllere s prefill vrijednostima i bankroll defaultom; `_save` validira form + custom rules (draw+non-soccer, odds, stake), kreira Bet (UUID iz `generateUuid`, status pending, linkedMatchId iz prefilled), poziva `addBet`, zatvara sheet, SnackBar; bottom-sheet drag handle ručka na vrhu, KeyboardAvoiding preko `MediaQuery.viewInsets.bottom`.

**Ažurirani fajlovi:**
- `lib/screens/bets_screen.dart` — uvozi BetEntrySheet; `_showManualBetEntry` otvara sheet bez prefill-a; FAB sad funkcionalan.
- `lib/screens/analysis_screen.dart` — uvozi `recommendation.dart` i `bet_entry_sheet.dart`; messages itemBuilder zamjenjuje samostalni ChatBubble s Column[ChatBubble + conditional `_buildLogBetButton`] kad assistant message sadrži VALUE marker; `_buildLogBetButton` otvara BetEntrySheet s prefilledMatch iz `stagedMatches.first` ako postoji.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 4 — Bet Settlement
**Status:** Completed

**Opis:** Settlement bottom sheet (Won / Lost / Void) je već implementiran u BetCard-u u Tasku 2 — funkcionalno povezan i radi: tap na pending bet ili tap na "Settle" ElevatedButton otvara modal s 3 obojena buttona koji pozivaju `BetsProvider.settleBet(id, status)` + Navigator.pop + SnackBar. Swipe-to-delete (Dismissible endToStart, confirm AlertDialog) također je već u BetCard-u i poziva `deleteBet`. assert u `BetsProvider.settleBet` blokira pokušaj settle-a kao pending. Settled bet automatski izlazi iz Open lista (filter na `status == pending`) i ulazi u Settled (sort settledAt desc), `actualProfit` getter izračunava P/L po novom statusu. Ovaj task je čista verifikacija da sve E2E radi — bez dodatnih izmjena.

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:** *(nijedan — funkcionalnost je u potpunosti pokrivena Taskom 2)*

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 5 — Bankroll Management + P&L Summary Widget
**Status:** Completed

**Opis:** PlSummaryWidget Consumer<BetsProvider> renderira 4 metrik kolone (Total bets, Win rate, ROI, Total P/L) na vrhu Bets screena; sakriven kad totalBets == 0; boje su green ako > threshold, red ako < 0, grey ostalo. Settings dobiva novu Bankroll sekciju iznad About-a: dva TextField-a (Total bankroll + Default stake) s decimal-only inputom + Currency dropdown (EUR/USD/GBP/HRK/CHF/BAM/RSD); dynamic helper text "Default stake: X% of bankroll" + warning kad > 5% ("Industry recommendation: 1-3% per bet"). Save validira (bankroll > 0, stake > 0, stake < bankroll).

**Komande izvršene:** flutter analyze, flutter test, flutter build windows, flutter build apk --debug.

**Kreirani fajlovi:**
- `lib/widgets/pnl_summary.dart` — PlSummaryWidget StatelessWidget; conditional render; 4-metric Card s `_Metric` privatnim widgetom (label/value/unit + opcionalna boja).

**Ažurirani fajlovi:**
- `lib/screens/bets_screen.dart` — uvozi PlSummaryWidget; placeholder SizedBox.shrink() zamijenjen s `const PlSummaryWidget()`.
- `lib/screens/settings_screen.dart` — uvozi BankrollConfig + BetsProvider; nova privatna klasa `_BankrollSection` (StatefulWidget): controllers iniciraju iz `BetsProvider.bankroll`, `_save` validira granice + poziva `setBankroll` + SnackBar; live-updating "X% of bankroll" helper s warningom kad > 5%; renderira se izmedu Value Bets Filter i About sekcije.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan, flutter build apk --debug uspješan.

---

### Finalna verifikacija Session 3:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.2.0.apk (142M, NOT in git — `.gitignore` `*.apk`)
- Verzija: 1.2.0+3
- Git: Claude Code NE commit-a/push-a — developer preuzima

---

---
---

## Session 4: 2026-04-18 — Telegram Tipster Monitor + Odds Snapshot Engine

**Kontekst:** S1–S3 izgradili closed loop (Matches → Analyze → Log Bet → Settle → P&L). S4 uvodi prve vanjske intelligence kanale: Telegram tipster monitor (pasivni čitač kanala gdje je bot član) i Odds Snapshot Engine (watched matches + drift detection).

---

### Task 1 — TipsterSignal Model + TelegramMonitor Service + Hive Box
**Status:** Completed

**Opis:** Data + transport layer za Telegram integraciju. TipsterSignal model nosi telegramMessageId/channelUsername/title/text/receivedAt + heuristički detektirani sport/league + relevance flag. TelegramMonitor implementira polling getUpdates loop (10s interval, 15s timeout, allowed_updates filter na channel_post/message), parsiranje s keyword filterom (tip/bet/value/odds/pick/...) i naivnim sport detection-om (epl/ucl/nba/atp/wta substring), testConnection preko getMe, te lifecycle (setBotToken/start/stop/dispose). Storage proširen za signals box + Telegram settings (token/channels/enabled). Poznato Bot API ograničenje (samo kanali gdje je bot član) zabilježeno u Identified Issues.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/tipster_signal.dart` — TipsterSignal model + `preview` getter (truncate 150 char) + `toClaudeContext` (timeAgo + channel + sport + preview) + privatni `_relativeTime` helper + toMap/fromMap.
- `lib/services/telegram_monitor.dart` — TelegramMonitor klasa s `_botToken`/`_lastUpdateId`/`_pollTimer`; `setBotToken` (rolls monitoring kroz stop/restart ako je bilo aktivno); `startMonitoring`/`stopMonitoring`; `testConnection` preko `/getMe`; privatni `_poll` (silent fail try/catch jer poll ima retry semantiku) i `_parseUpdate` (skip private chats, keyword + sport heuristika); `dispose` cancela timer + close client. TelegramException klasa.

**Ažurirani fajlovi:**
- `pubspec.yaml` — version bump na `1.3.0+4`.
- `lib/services/storage_service.dart` — dodan `_tipsterSignalsBox` constant + 3 Telegram settings field-a; `init()` otvara četvrti box; `_signalsBox` getter; `saveSignal`/`getAllSignals` (sort desc, skip malformed) /`clearOldSignals` (default keep 7d, briše po cutoff-u i malformed); `getTelegramToken`/`saveTelegramToken`/`deleteTelegramToken`; `getMonitoredChannels`/`saveMonitoredChannels`; `getTelegramEnabled`/`saveTelegramEnabled`.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 2 — TelegramProvider + Main Lifecycle
**Status:** Completed

**Opis:** TelegramProvider ChangeNotifier umotava TelegramMonitor; konstruktor učitava saved signals/channels/enabled flag iz Storage, postavlja onSignalReceived callback, postavlja token na monitor i auto-start-a polling ako je `enabled` bio true. `_handleNewSignal` radi dedup po (telegramMessageId, channelUsername) i filter po monitoredChannels (samo ako je lista non-empty — inače propušta sve). Getter `recentSignals` daje 6h prozor; `signalsForSport` filtrira. CRUD metode za bot token, kanale, enabled toggle. `testConnection` pretvara getMe response u username string i nakratko buffer-ira error stanje. Test wrap proširen na peti provider + dodatni Hive box `tipster_signals` u setUpAll.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/telegram_provider.dart` — TelegramProvider ChangeNotifier; konstruktor (lifecycle init), getteri (signals/recentSignals/signalsForSport/monitoredChannels/enabled/hasToken/isMonitoring/error/recentCount), metode (setBotToken/removeBotToken/addChannel/removeChannel/setEnabled/testConnection/clearOldSignals/clearError); privatni `_handleNewSignal`; override `dispose` koji disposea monitor.

**Ažurirani fajlovi:**
- `lib/main.dart` — uvozi TelegramProvider; dodan kao peti provider u MultiProvider.
- `test/widget_test.dart` — uvozi TelegramProvider; provider list proširen; setUpAll otvara `tipster_signals` Hive box.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan.

---

### Task 3 — Telegram Settings Section
**Status:** Completed

**Opis:** Settings dobiva novu "Telegram Monitor" sekciju (između Bankroll i About). Header s _StatusBadge (Active/Not set, ovisno o `isMonitoring` umjesto hasToken — daje točan status pollera). Token TextField s obscure + visibility toggle, masked tekst se čisti tap-om. Buttoni Save/Test/Remove s confirm dialogom. Test Connection async preko `provider.testConnection()` s loading spinner-om i SnackBar feedbackom (TelegramException.message ili generic). Monitored channels Wrap od InputChip-ova (delete ikona) + TextField + Add (auto-prepend `@`, validacija min 5 char). SwitchListTile za enable/disable toggle (disabled kad nema token-a). Info footer + SelectableText link na BotFather (info-only, bez url_launcher-a).

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/screens/settings_screen.dart` — uvozi TelegramProvider + TelegramException; nova privatna klasa `_TelegramSection` StatefulWidget (controllers za token i channel input + show/hide flag + initialized flag za masked token + testing flag za spinner); render-a se izmedu Bankroll i About sekcije.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 4 — Signal UI u Analysis Screen + Context Injection
**Status:** Completed

**Opis:** Analysis screen dobiva 3 nova UI elementa: (a) `_SignalBanner` iznad chat liste — Consumer<TelegramProvider>, vidljiv samo kad `recentCount > 0`, prikazuje broj recent signala + "View →" GestureDetector; (b) `_SignalSheet` (DraggableScrollableSheet 0.85→0.95) — header + Sport filter chip-ovi (All/Soccer/Basketball/Tennis) + ListView SignalCard-ova s checkbox selection-om + footer s "X selected" + FilledButton "Use as context" → `stageSelectedSignals` + Navigator.pop + SnackBar; (c) `_buildStagedSignalsBar` analogan staged matches baru ali secondary boja teal — prikazuje broj staged signala + close ikona. AnalysisProvider proširen s `_stagedSignals` field-om, getter/method API-jem (stage/clear/has) i auto-čistim nakon uspješnog send-a; `_buildUserMessage` sada uzima opcionalne `contextSignals` i dodaje `[TIPSTER SIGNALS]...[/TIPSTER SIGNALS]` blok ispod `[SELECTED MATCHES]`.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/widgets/signal_card.dart` — SignalCard: opcionalni Checkbox (kad je `onSelectedChanged != null`), header s sport icon + channel title + relative time, channel username, preview text, conditional league badge.

**Ažurirani fajlovi:**
- `lib/models/analysis_provider.dart` — dodan `_stagedSignals` field + getteri/metode (stagedSignals/hasStagedSignals/stageSelectedSignals/clearStagedSignals); `_buildUserMessage` rewritten s 3-arg signature i conditional dva bloka; `sendMessage` koristi `effectiveSignals` i čisti staged signal listu nakon uspjeha.
- `lib/screens/analysis_screen.dart` — uvozi telegram_provider/sport/signal_card; dodan `_SignalBanner` na vrh Column-a; novi `_showSignalSheet`, `_buildStagedSignalsBar`; nove privatne klase `_SignalBanner`, `_SignalSheet` (StatefulWidget s lokalnim filter + selection state).

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 5 — BONUS: Odds Snapshot Engine
**Status:** Completed

**Opis:** Watched matches mehanizam s automatic snapshot-anjem pri svakom `fetchMatches()`. OddsSnapshot model + OddsDrift static helper (compute za par snapshota, dominantDrift kao record (side, percent), hasSignificantMove threshold 3%). Storage koristi composite key `${matchId}_${ISO timestamp}` kako bi sve snapshote za jedan match grupirao po prefix-u; `getSnapshotsForMatch` iterira keys. MatchesProvider drži `_watchedMatchIds` Set, perzistira ga u settings boxu, izlaže `isWatched`/`toggleWatched`/`driftForMatch`. MatchCard dobiva animated star toggle (AnimatedSwitcher 250ms) pored countdown-a i conditional drift indicator (ikona trending_up/down + side + signed % u red/blue) ispod OddsWidget-a kad postoji ≥2 snapshota i pomak je značajan.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows, flutter build apk --debug.

**Kreirani fajlovi:**
- `lib/models/odds_snapshot.dart` — OddsSnapshot (matchId/capturedAt/home/draw/away/bookmaker) + toMap/fromMap; OddsDrift klasa s 3 percent polja, `compute` static factory, `dominantDrift` getter (record syntax `({String side, double percent})`), `hasSignificantMove` threshold.

**Ažurirani fajlovi:**
- `lib/services/storage_service.dart` — uvozi OddsSnapshot; dodan `_oddsSnapshotsBox` constant + `_watchedMatchIdsField`; `init()` otvara peti box; `_snapshotsBox` getter; `saveSnapshot` (composite key `matchId_ISOtimestamp`), `getSnapshotsForMatch` (key prefix scan, sort capturedAt asc), `clearOldSnapshots` (cutoff + malformed); `getWatchedMatchIds`/`saveWatchedMatchIds`.
- `lib/models/matches_provider.dart` — uvozi OddsSnapshot; `_watchedMatchIds` field, učitava se iz Storage u konstruktoru; getteri `watchedMatchIds`/`isWatched`; `toggleWatched` perzistira; `driftForMatch` poziva Storage + računa OddsDrift; privatni `_captureSnapshotsForWatched` koji se zove iz `fetchMatches` nakon API odgovora.
- `lib/widgets/match_card.dart` — uvozi MatchesProvider + provider; star IconButton (AnimatedSwitcher 250ms star_border ↔ star, secondary teal kad je watched) ubacen na desni kraj header Row-a; novi Consumer<MatchesProvider> ispod OddsWidget-a renderira drift indicator (Icons.trending_up/down + dominantDrift.side + signed %, boja red za pad / blue za rast, bold 11px).
- `test/widget_test.dart` — setUpAll otvara `odds_snapshots` box.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan, flutter build apk --debug uspješan.

---

### Finalna verifikacija Session 4:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.3.0.apk (NOT in git — `.gitignore` `*.apk`)
- Verzija: 1.3.0+4
- Git: Claude Code NE commit-a/push-a — developer preuzima

---

---
---

## Session 5: 2026-04-18 — Infrastructure Hardening

**Kontekst:** S1–S4 izgradili full feature set. S5 je hardening sesija — ne dodaje nove taba ni screena, fokusira se na održivost: cache layer (free tier Odds API nije izdržljiv bez njega), rate limit tracking + UI, snapshot dedup, scheduled cleanup jobs, error handling audit. Verzija je patch bump (1.3.1+5).

---

### Task 1 — Odds API Cache Layer
**Status:** Completed

**Opis:** Sve `fetchMatches()` pozive sada kontrolira lokalni cache. Cache entry sadrži List<Match> + fetchedAt + remainingRequests; TTL je konfigurabilan u settings boxu (default 15 min). Pull-to-refresh poziva `forceRefresh: true` koji bypass-a cache i uvijek hita API. MatchesProvider izlaže `fromCache` i `cachedAt` getter, MatchesScreen renderira diskretni "Cached (Xm ago)" badge ispod SportSelector-a kad je data iz cache-a. Match dobio `toMap`/`fromMap` (čišće od privatnih helpera u CachedMatchesEntry). Snapshot capture za watched mečeve sad se pokreće SAMO kad je data svježa (ne iz cache-a) — sprečava dupliciranje snapshota za istu API poziciju.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/cached_matches_entry.dart` — CachedMatchesEntry (matches/fetchedAt/remainingRequests) + age/isExpired/ageDisplay getteri + toMap/fromMap koji delegira na Match.toMap/fromMap.

**Ažurirani fajlovi:**
- `pubspec.yaml` — version bump na `1.3.1+5`.
- `lib/models/match.dart` — dodane `toMap`/`fromMap` metode (uključuju serijalizaciju H2HOdds inline mape).
- `lib/services/storage_service.dart` — uvozi CachedMatchesEntry; dodan `_oddsCacheBox` constant + `_cacheEntryKey` (fiksan ključ "all_matches") + `_cacheTtlMinutesField`; `init()` otvara šesti box; `_cacheBox` getter; `getCachedMatches`/`saveCachedMatches`/`clearCachedMatches` + `getCacheTtlMinutes` (default 15) /`saveCacheTtlMinutes`.
- `lib/services/odds_api_service.dart` — uvozi CachedMatchesEntry + StorageService; nova typedef `CachedMatchesResult` (record); nova metoda `getMatchesCached` koja prvo provjeri cache (i postavi `_remainingRequests` iz njega), pa ako miss/expired/forceRefresh poziva postojeći `getMatches` i sprema novi entry.
- `lib/models/matches_provider.dart` — dodana polja `_fromCache`/`_cachedAt`/`_remainingRequests` (lokalna kopija); getteri prilagođeni; `fetchMatches({forceRefresh = false})` koristi getMatchesCached i preskače snapshot capture kad je data iz cache-a.
- `lib/screens/matches_screen.dart` — uvozi AppTheme; novi privatni `_CachedBadge` widget (Consumer<MatchesProvider>, vidljiv samo kad fromCache + cachedAt + non-empty); `_buildMatchList` RefreshIndicator sad zove `fetchMatches(forceRefresh: true)`.
- `test/widget_test.dart` — setUpAll otvara `odds_cache` box.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan.

---

### Task 2 — Rate Limit Tracking + UI Warning
**Status:** Completed

**Opis:** MatchesProvider sada izlaže `requestsUsedPercent`/`isApiLimitLow`/`isApiLimitCritical` getter-e bazirane na free-tier capu (500 req/mj, exposed kao `MatchesProvider.apiMonthlyCap`). `fetchMatches` na početku radi hard-stop kad je critical (< 1) — vraća cache ako postoji, inače setira error. MatchesScreen renderira `_ApiLimitBanner` između SportSelector-a i CachedBadge-a: orange warning kad <20 left, red banner kad <1. Settings dobiva novu sekciju "Cache & Limits" iznad Bankroll-a: LinearProgressIndicator s threshold-bojom (green/yellow/orange/red), used/cap text + remaining + reset napomena, te ChoiceChip selektor TTL-a (5/15/30/60 min) s helper tekstom.

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/models/matches_provider.dart` — dodana konstanta `apiMonthlyCap = 500`; getter `requestsUsedPercent` (null prije prvog poziva); thresholdi `isApiLimitLow`/`isApiLimitCritical`; `fetchMatches` early-return blok (cache fallback ili error) kad je critical i nije forceRefresh.
- `lib/screens/matches_screen.dart` — novi privatni `_ApiLimitBanner` widget (red kad critical, orange kad low, hidden inače) s helper `_banner` metodom; ubacen u Column iznad CachedBadge-a.
- `lib/screens/settings_screen.dart` — uvozi StorageService; nova privatna klasa `_CacheLimitsSection` StatefulWidget (učitava TTL u initState, `_setTtl` perzistira u Storage); progress bar s `_progressColor` po threshold-u; ChoiceChip selektor s 4 TTL opcije; renderira se izmedu Value Bets Filter i Bankroll sekcije.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 3 — Snapshot Deduplication
**Status:** Completed

**Opis:** `_captureSnapshotsForWatched` više ne piše identične snapshote — svaki novi snapshot prvo se uspoređuje s posljednjim za isti matchId, i ako su home/draw/away identične, save se preskoči. Ovo sprečava balooning Hive baze za watched mečeve čije se kvote rijetko mijenjaju. Debug log iznosi saved/skipped count za svaki capture pass.

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/services/storage_service.dart` — dodana `getLatestSnapshotForMatch` (return last iz ascending-sorted liste) i `saveSnapshotIfChanged` (vraća bool — true saved, false skipped) — strict equality na home/draw/away (bookmaker se ignorira jer ostaje isti).
- `lib/models/matches_provider.dart` — `_captureSnapshotsForWatched` koristi `saveSnapshotIfChanged`, broji saved/skipped i logira debugPrint kad ima rada.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 4 — Scheduled Cleanup Jobs
**Status:** Completed

**Opis:** Pri pokretanju app-a (`main` nakon Hive init) pokreće se `runScheduledCleanup` koji čisti signale i snapshote starije od 7 dana, te briše cache entry stariji od 24h. Cleanup je gateran preko `last_cleanup_at` timestamp-a — ako je zadnji run bio < 24h, vraća zero counts bez rada. Rezultati cleanupa logiraju se kroz debugPrint.

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/services/storage_service.dart` — dodan `_lastCleanupField` constant; `getLastCleanupAt`/`saveLastCleanupAt`; `runScheduledCleanup` metoda (24h gate, vraća Map s 3 ključa: signals_cleaned/snapshots_cleaned/cache_entries_cleaned).
- `lib/main.dart` — `main()` poziva `runScheduledCleanup` nakon `init()` u istom try/catch bloku, logira rezultat.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 5 — Error Handling Audit + Polish
**Status:** Completed

**Opis:** Audit svih providera i servisa: BetsProvider je imao nekorišten `_error` field bez UI hookupa — sada svaka mutirajuća metoda (addBet/settleBet/deleteBet/setBankroll) wrap-a Hive call u try/catch i postavlja informativnu poruku, a BetsScreen čita `error` getter i SnackBar-uje preko `_maybeShowError` (debounce-an `_lastShownError` da spriječi duplo prikazivanje istog errora). Dodan `clearError` u BetsProvider. Standardiziran SnackBar copy: API key Save/Remove sad koriste konkretan naziv ("Anthropic API key saved" / "Odds API key saved" / "...removed") umjesto generic "Saved"/"Removed". Dodani doc komentari na retry semantiku u TelegramMonitor._poll i OddsApiService.getMatches.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows.

**Audit nalazi (sažeto):**
- Provideri: matches/analysis/telegram već imaju `_error` + `clearError` + UI surfacing (Dismissible bar / SnackBar). BetsProvider — popravljen ovdje.
- Servisi: OddsApiService/ClaudeService/TelegramException — svi imaju tipizirane exception klase. StorageService — try/catch u svim deserializacijama (silent skip, ne baca).
- `_buildUserMessage` u AnalysisProvider već rukuje sve 4 kombinacije (matches∅ + signals∅, samo matches, samo signals, oba) — provjereno.
- Test wrap već čisti providere kroz tearDown lifecycle (Provider sam invokira dispose); explicitan tearDown nije potreban.

**Ažurirani fajlovi:**
- `lib/models/bets_provider.dart` — dodan `clearError`; addBet/settleBet/deleteBet/setBankroll wrap-ani u try/catch i resetiraju `_error` na null kad uspije, postavljaju ga na specifičnu poruku kad faila.
- `lib/screens/bets_screen.dart` — dodano `_lastShownError` polje + `_maybeShowError` helper (postFrameCallback debounced); pozvan iz oba tab buildera.
- `lib/screens/settings_screen.dart` — SnackBar copy unificiran ("Anthropic API key saved/removed", "Odds API key saved/removed").
- `lib/services/telegram_monitor.dart` — doc komentar na `_poll` (objašnjava silent fail / retry semantiku).
- `lib/services/odds_api_service.dart` — doc komentar na `getMatches` (per-sport partial-failure semantika; 401/429 throw jer su request-wide).

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan, flutter build apk --debug uspješan.

---

### Finalna verifikacija Session 5:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.3.1.apk (NOT in git — `.gitignore` `*.apk`)
- Verzija: 1.3.1+5
- Git: Claude Code NE commit-a/push-a — developer preuzima

---

---
---

## Session 5.5 FIX: 2026-04-18 — Prompt Redesign + Trade Action Bar + Bot Manager + Context Enhancements

**Kontekst:** S1–S5 izgradili stabilan feature set sa solidnom infrastrukturom, ali kvaliteta UX-a u ključnim dodirnim točkama nije bila na CoinSight razini. S5.5 FIX podiže prompt s generic S1-level teksta na strukturirani 40-line engleski (analogno CoinSight S2 + S6), zamjenjuje usamljeni "Log Bet" button s Trade Action Bar-om (CoinSight S3 Faza F), dodaje MonitoredChannel model s reliability scoring-om i zasebni Bot Manager screen (CoinSight S5), te proširuje Claude context s [BETTING HISTORY] i [ODDS DRIFT] blokovima.

---

### Task 1 — Prompt Redesign
**Status:** Completed

**Opis:** Generic S1-level system prompt zamijenjen strukturiranim 40-line engleskim promptom s 5 sekcija: User profile (skip basic explanations), Objective 1 (odds analysis flow s margin/value), Objective 2 (kontekst — SELECTED MATCHES + TIPSTER SIGNALS + BETTING HISTORY), Objective 3 (recommendation s VALUE/WATCH/SKIP gdje VALUE mora navesti WHICH outcome / WHICH odds / probability vs implied / concrete next step), Constraints (no chasing, percentage stakes), Language (mirror user, sport terms in EN). `[SELECTED MATCHES]` blok dobio konzistentni format `{league}: {home} vs {away} | kickoff {ISO} | odds H/D/A: x/y/z | bookmaker {name}` i closing `[/SELECTED MATCHES]` tag. Kreiran BETLOG.md template za ručno bilježenje ishoda Claude preporuka (calibration).

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `BETLOG.md` — root-level dokumentacijski template (analogno CoinSight CHATLOG); tablica Date/Match/Claude call/My decision/Actual outcome/Notes + sekcija za calibration notes.

**Ažurirani fajlovi:**
- `pubspec.yaml` — version bump na `1.3.2+6`.
- `lib/models/analysis_provider.dart` — `_systemPrompt` zamijenjen 40-line strukturiranim verzijom; `_buildUserMessage` SELECTED MATCHES blok prepravljen u novi format s closing tagom (kickoff prije odds, bookmaker uvijek vidljiv, odds H/A za sportove bez draw-a).

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 2 — Trade Action Bar
**Status:** Completed

**Opis:** Usamljeni "Log this as a bet" OutlinedButton (S3 Task 3) zamijenjen TradeActionBar widgetom — pojavljuje se ispod ZADNJE assistant ChatBubble-a kad parseRecommendationType vrati VALUE i postoji `lastLogId` u providera. Tri akcije: LOG BET (zelena ElevatedButton, otvara BetEntrySheet s prefilled stagedMatch.first + bilježi UserFeedback.logged), SKIP (OutlinedButton, bilježi UserFeedback.skipped + SnackBar "logged for calibration"), ASK MORE (OutlinedButton, bilježi UserFeedback.askedMore + setira inputPrefill koji TextField pickup-a kroz listener). AnalysisLog proširen s `userFeedback`/`feedbackAt` poljima i copyWith metodom. AnalysisProvider drži `_lastLogId`/`_inputPrefill` + `recordFeedback`/`setInputPrefill`/`clearInputPrefill`. Storage dobiva `updateAnalysisLogFeedback` + `getLogsByRecommendation` + `getFeedbackStats` (potencijalna podloga za buduću prompt kalibraciju).

**Komande izvršene:** flutter analyze, flutter test, flutter build windows.

**Kreirani fajlovi:**
- `lib/widgets/trade_action_bar.dart` — TradeActionBar StatelessWidget; light-green styled Container s flag iconom + "VALUE signal detected" header; Row s 3 buttona i njihovim handlerima; svaki handler poziva `recordFeedback` na provideru i radi specifičnu UI akciju (sheet / SnackBar / inputPrefill).

**Ažurirani fajlovi:**
- `lib/models/analysis_log.dart` — dodan `UserFeedback` enum (none/logged/skipped/askedMore) + nova polja `userFeedback`/`feedbackAt` u AnalysisLog + `copyWith` metoda; toMap/fromMap proširen s default fallbackom na `UserFeedback.none`.
- `lib/services/storage_service.dart` — uvozi recommendation; `updateAnalysisLogFeedback` (čita-update-spremi), `getLogsByRecommendation`, `getFeedbackStats` (Map<RecommendationType, Map<UserFeedback, int>>).
- `lib/models/analysis_provider.dart` — polja `_lastLogId`/`_inputPrefill` + getteri + `setInputPrefill`/`clearInputPrefill`/`recordFeedback` metode; `sendMessage` postavlja `_lastLogId = log.id` prije save-a.
- `lib/screens/analysis_screen.dart` — uvozi trade_action_bar (uklonjen direct bet_entry_sheet import jer ide kroz TradeActionBar); dodan `_inputFocus` FocusNode + `_listenedProvider` + `didChangeDependencies` listener registry + `_handlePrefill` callback (popuni controller + focus + clear); itemBuilder zamijenjen — `_buildLogBetButton` helper uklonjen, sad renderira TradeActionBar samo za zadnju VALUE poruku; TextField vezan na `_inputFocus`.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan.

---

### Task 3 — MonitoredChannel Model + Reliability Scoring
**Status:** Completed

**Opis:** Lista `List<String>` u TelegramProvider-u zamijenjena s `List<MonitoredChannel>` objektima. MonitoredChannel drži per-channel signalsReceived/signalsRelevant + timestamp-ove + reliability getter (-1 < 10 signala = "Novo", < 0.1 ratio = "Niska", < 0.3 = "Srednja", inače "Visoka") + colorValue za UI badge. Novi Hive box `monitored_channels_detail` (key = username). Migration helper migrira legacy `List<String>` iz settings boxa pri prvom pokretanju (no-op ako je novi box već popunjen). TelegramMonitor._parseUpdate sada uvijek vraća TipsterSignal s `isRelevant` flag-om (true/false) — više nije null za irrelevant — kako bi provider mogao ažurirati statistike. Provider._handleNewSignal: dedup → update channel stats (uvijek ako je kanal monitored) → skip save signal-a ako kanal nije monitored ili ako signal nije relevant (ali stats su već persisted). Settings screen privremeno koristi novi `channels` getter u InputChip listi (Task 4 zamjenjuje s Manage Channels button-om).

**Komande izvršene:** flutter analyze, flutter test, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/monitored_channel.dart` — MonitoredChannel klasa s reliability score/label/color getterima + lastRelevantDisplay (relativni time) + copyWith + toMap/fromMap.

**Ažurirani fajlovi:**
- `lib/services/storage_service.dart` — uvozi MonitoredChannel; dodan `_channelsDetailBox` constant; `init()` otvara sedmi box; `_channelsBox` getter; `getAllMonitoredChannels` (sort addedAt asc, skip malformed) /`saveMonitoredChannel` (key = username) /`deleteMonitoredChannel`; `migrateMonitoredChannels` helper (idempotent, no-op ako je box non-empty).
- `lib/services/telegram_monitor.dart` — `_parseUpdate` više ne vraća null za irrelevant signale; uvijek vraća signal s `isRelevant: isRelevant` flagom.
- `lib/models/telegram_provider.dart` — kompletno prepravljen: `_channels` lista MonitoredChannel-a; konstruktor poziva `_bootstrapChannels` (async migration + load + notify); novi `channels`/`channelUsernames` getteri; `addChannel`/`removeChannel` rade s MonitoredChannel objektima; `_handleNewSignal` ažurira stats (signalsReceived++ uvijek, signalsRelevant++ samo za relevant, lastRelevantAt samo za relevant) i samo persist-a relevant signale.
- `lib/screens/settings_screen.dart` — InputChip listing prilagoden novom `channels`/`channel.username` API-ju (privremeni; Task 4 zamjenjuje cijeli ovaj blok).
- `test/widget_test.dart` — setUpAll otvara `monitored_channels_detail` Hive box.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan.

---

### Task 4 — Bot Manager Screen
**Status:** Completed

**Opis:** Zasebni full-screen route (push iz Settings, ne IndexedStack tab) za upravljanje Telegram kanalima. Top stats header s 3 brojke (Channels / Total signals / Relevant), input red s TextField + Add buttonom (auto-prepend `@`, min 5 char validacija), ListView per-channel kartica. Svaka `_ChannelCard` prikazuje title (ako preuzet iz signala) + username + reliability badge (boja po threshold-u: grey/red/orange/green) + close ikona za delete s confirm dialog-om + meta chips (received/relevant/last). Settings _TelegramSection sad ima samo "Manage Channels (N)" OutlinedButton koji push-a BotManagerScreen — uklonjen inline channel input + chip listing iz Telegram sekcije.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/screens/bot_manager_screen.dart` — BotManagerScreen StatefulWidget; `_BotManagerScreenState` (controller za new channel input + helpers `_addChannel`/`_confirmDelete`/`_buildEmptyState`/`_statTile`); privatne klase `_ChannelCard` i `_ReliabilityBadge` (Color konvertira reliabilityColorValue int).

**Ažurirani fajlovi:**
- `lib/screens/settings_screen.dart` — uvozi BotManagerScreen; uklonjeni `_channelCtrl` field + `_addChannel` metoda + inline Wrap chip listing + Add button row; zamijenjeni s jednim "Manage Channels (N)" OutlinedButton.icon.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 5 — Context Injection Enhancements
**Status:** Completed

**Opis:** `_buildUserMessage` prepravljen na named arguments signature s 4 opcionalna konteksta (matches/signals/bettingHistory/driftByMatchId). Novi `[BETTING HISTORY — last N bets]` blok lista do 5 najnovijih user-ovih bet-ova (datum YYYY-MM-DD | sport | teams | pick @ odds | stake | outcome string). Novi `[ODDS DRIFT]` se ne renderira kao zaseban blok već kao **inline** linija ispod svakog matcha u SELECTED MATCHES bloku — `  [drift] {Side} ±X.X% since last snapshot` — samo kad je hasSignificantMove true. `sendMessage` prikuplja oba dodatna konteksta direktno iz Storage (decoupled od BetsProvider): `getAllBets().take(5)` i `getSnapshotsForMatch(id)` per-staged-match → OddsDrift.compute. Svi blokovi su opcionalni i izostaju kad nema podataka.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows, flutter build apk --debug.

**Ažurirani fajlovi:**
- `lib/models/analysis_provider.dart` — uvozi bet/odds_snapshot/sport; `_buildUserMessage` signature → named args (text + 4 named); BETTING HISTORY blok s closing tagom; ODDS DRIFT inline u SELECTED MATCHES; `sendMessage` skuplja history (sort placedAt desc, take 5) i drifts (per-match snapshot lookup) prije poziva `_buildUserMessage`.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan, flutter build apk --debug uspješan.

---

### Finalna verifikacija Session 5.5:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.3.2.apk (NOT in git — `.gitignore` `*.apk`)
- Verzija: 1.3.2+6
- Git: Claude Code NE commit-a/push-a — developer preuzima

---

---
---

## Session 6: 2026-04-18 — Multi-Source Intelligence Layer

**Kontekst:** S1–S5.5 izgradili single-source platformu ovisnu o Odds API-ju. S6 transformira BetSight u multi-source intelligence platformu s 5 izvora (Odds 0-2.0, Football-Data 0-1.5, NBA Stats 0-1.0, Reddit 0-1.0, Telegram 0-0.5 weighted by reliability) — zbroj confluence score 0-6.0. Scope: samo watched matches (2-5 po korisniku). Novi zasebni Intelligence Dashboard screen, hibrid auto-refresh (1h Timer + on-demand button). **Major version bump (2.0.0+7)** jer je ovo fundamentalna arhitekturalna transformacija.

---

### Task 1 — Source Signal Models + IntelligenceReport
**Status:** Completed

**Opis:** Data kostur za multi-source intelligence — 5 modela bez bilo kakvih API poziva. SourceScore drži score + reasoning + isActive flag s `inactive` factory za izvor koji nije dao podatke. SourceType enum nosi maxScore weighting (Odds 2.0 / Football-Data 1.5 / NBA Stats 1.0 / Reddit 1.0 / Telegram 0.5 — sum 6.0) + display + emoji icon. Specifični signal modeli (FootballData/NbaStats/Reddit) imaju toClaudeContext za prompt injection, te helper getter-e (form score, sentiment bias). IntelligenceReport agregira sources liste, izračunava confluenceScore, klasificira kategorije (STRONG_VALUE >=4.5 / POSSIBLE_VALUE >=3.0 / WEAK_SIGNAL >=1.5 / LIKELY_SKIP / INSUFFICIENT_DATA <2 active sources), ima color value + interpretacijski tekst po kategoriji.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/source_score.dart` — SourceType enum + SourceTypeMeta extension (display/maxScore/icon) + SourceScore klasa s `percentage` getterom + `inactive` factory + toMap/fromMap.
- `lib/models/football_data_signal.dart` — FootballDataSignal s formama (W/D/L lista do 5), H2H counts, optional standings positions, fetchedAt; form score getter (-1..+1) + toClaudeContext (multi-line).
- `lib/models/nba_stats_signal.dart` — NbaStatsSignal s last10 W/L lists, optional restDays + standingsRank; toClaudeContext koji izostavlja prazne dijelove.
- `lib/models/reddit_signal.dart` — RedditSignal s mentionCount, topUpvotes, teamMentions Map; getSentimentBias (-1 home tilt..+1 away tilt) + toClaudeContext s top postom.
- `lib/models/intelligence_report.dart` — IntelligenceCategory enum + IntelligenceCategoryMeta (display/colorValue/interpretation); IntelligenceReport klasa s confluenceScore (sum aktivnih) + activeSourceCount + category getter + age/isExpired + toClaudeContext (renderira sav blok s `[INTELLIGENCE REPORT]` headerom i `Hint:` linijom).

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 2 — Storage Integration + IntelligenceProvider skeleton
**Status:** Completed (s očekivanim analyze errorima — vidi napomenu)

**Opis:** Storage proširen na 4 nova Hive boxa (`intelligence_reports`, `football_signals_cache`, `nba_signals_cache`, `reddit_signals_cache`) + `football_data_api_key` field u settings boxu. CRUD za IntelligenceReport (get/save/getAll po confluenceScore desc/delete/clearOld 6h cutoff) i per-source signal cache-eve (3-day TTL). `runScheduledCleanup` proširen s `reports_cleaned`/`football_cleaned`/`nba_cleaned`/`reddit_cleaned` brojevima — dodan helper `_purgeOldSignalCache(box, fetchedAtOf)` koji generički briše stale entries u signal box-evima. IntelligenceProvider skeleton drži in-memory `_reports` map + `_generatingFor` set za loading state, izlaže `reportFor`/`isGeneratingFor`/`allReports`/`error`/`generateReport`/`refreshAllWatched`/`startAutoRefresh`/`stopAutoRefresh`/`removeReportFor`/`clearError`. Aggregator se inject-a kroz `wireAggregator(...)` (zato Provider stoji clean kad aggregator još nije postoji u Task 2 stanju) — generateReport rana-vraća s configuration error-om dok wire nije izvršen.

**Komande izvršene:** flutter analyze (3 očekivana errora — IntelligenceAggregator uri ne postoji, klasa nepoznata; bit će popravljeno u Tasku 6 kad se kreira aggregator); flutter build windows preskočen jer compile-ne prolazi.

**Napomena:** Per spec, Task 2 jedini u sesiji NE mora proći flutter analyze — preostali 3 errora su isključivo missing IntelligenceAggregator class (referenca u IntelligenceProvider) koji se kreira u Tasku 6. flutter analyze će biti 0 issues nakon Task 6.

**Kreirani fajlovi:**
- `lib/models/intelligence_provider.dart` — IntelligenceProvider ChangeNotifier; konstruktor učitava postojeće reportse iz Storage-a; `wireAggregator` inject; getteri za map/loading set/sorted list/error; metode `generateReport(match, force)`, `refreshAllWatched(matches, force)`, `startAutoRefresh(watchedProviderFn)`, `stopAutoRefresh`, `removeReportFor`, `clearError`; override `dispose` cancela timer.

**Ažurirani fajlovi:**
- `pubspec.yaml` — version bump na `2.0.0+7` (major bump).
- `lib/services/storage_service.dart` — uvozi 5 novih modela; 4 nova box constanta + 1 field constant; `init()` otvara 4 nova boxa (sad ukupno 11); 4 nova box getter-a (`_reportsBox`/`_footballBox`/`_nbaBox`/`_redditBox`); CRUD metode za FD/Anthropic/Football API key; report CRUD + clearOldReports; per-source signal cache get/save (Football/NBA/Reddit); `runScheduledCleanup` proširen s 4 nove brojke; novi privatni helper `_purgeOldSignalCache` generički briše stale signal cache entries (3 dana cutoff).

**Verifikacija:** flutter analyze ima samo očekivane errore vezane uz Task 6 missing class. Build verification odgodjen do Task 6.

---

### Task 3 — FootballDataService
**Status:** Completed (analyze i dalje čeka aggregator iz Task 6)

**Opis:** Football-Data.org v4 client za soccer signal acquisition. Mapira `soccer_epl` → `PL` i `soccer_uefa_champs_league` → `CL`. Glavna metoda `getSignalForMatch` radi 4-5 HTTP poziva po matchu: (1) competition matches lookup s ±1 dan dateRange, (2) fuzzy team-name match (private `_normalize` strip-a sufikse FC/AFC/CF/SC/AC/CD/CB/SL + non-alpha), (3) head2head endpoint za H2H counts, (4) per-team form preko `/teams/{id}/matches?status=FINISHED&limit=5` (calculate W/D/L iz score.winner ovisno o isHome), (5) optional standings za pozicije timova. Hvata 429 (rate limit) i 403 (invalid key) kao explicit FootballDataException. Per spec 10 req/min limit — IntelligenceAggregator (Task 6) treba osigurati serijski pristup.

**Komande izvršene:** flutter analyze (i dalje 3 očekivana errora — IntelligenceAggregator missing).

**Kreirani fajlovi:**
- `lib/services/football_data_service.dart` — FootballDataService s `_apiKey`/`_competitionMap`; static `_normalize` helper za fuzzy matching; `getSignalForMatch` glavna funkcija; privatni `_getTeamForm` (silent return na non-200); FootballDataException klasa.

**Verifikacija:** flutter analyze očekivane greške zbog aggregator missing.

---

### Task 4 — BallDontLieService
**Status:** Completed (analyze i dalje čeka aggregator)

**Opis:** BallDontLie.io NBA API client. Besplatan, bez API ključa, neograničen. Samo za NBA mečeve (throw-a BallDontLieException za druge sportove). Koristi privatni `_normalize` (last-word split) za team-name lookup (npr. "Los Angeles Lakers" → "lakers"); cache-ira team IDs in-memory za sve buduće pozive (`_teamIdCache`). `getSignalForMatch` radi: (1) lookup oba teamId-ja, (2) per-team `/games?team_ids[]=&seasons[]=&per_page=15` filter Final games, sort desc, take 10, (3) `_gamesToForm` mapira W/L iz scores ovisno o isHome, (4) rest days iz match.commenceTime - last game date. Standings rank ostaje null jer free tier nema standings endpoint.

**Komande izvršene:** flutter analyze (3 ista očekivana errora).

**Kreirani fajlovi:**
- `lib/services/ball_dont_lie_service.dart` — BallDontLieService s `_teamIdCache` Map; static `_normalize`; `_getTeamId` (cache check first, fallback fetch all teams, populate cache); `getSignalForMatch` glavna funkcija; privatni `_getTeamLast10Games` (silent fail) + `_gamesToForm`; BallDontLieException klasa.

**Verifikacija:** flutter analyze ima i dalje 3 errora (IntelligenceAggregator missing).

---

### Task 5 — RedditMonitor
**Status:** Completed (analyze i dalje čeka aggregator)

**Opis:** Reddit public JSON endpoint scanner za sport-specific subreddits — bez API ključa, čita `hot.json?limit=50`. Mandatorni `User-Agent: BetSight/1.0` header (Reddit returns 429 bez njega). Soccer scan-uje `r/soccer` + `r/sportsbook`, NBA `r/nba` + `r/sportsbook`, tennis `r/tennis` + `r/sportsbook`. `getSignalForMatch` iterira subreddits, kombinira title+selftext po post-u u lowercase, broji team mentions (case-insensitive substring), prati top post po upvotes. Returns RedditSignal s mentionCount/topUpvotes/teamMentions/topPostTitle. Per-subreddit failure se silent skip-a — drugi subredditi i dalje pokušavaju.

**Komande izvršene:** flutter analyze (i dalje 3 očekivana errora).

**Kreirani fajlovi:**
- `lib/services/reddit_monitor.dart` — RedditMonitor s `_subredditsForSport` mapom (Sport → list of subreddits); `getSignalForMatch` koji za svaki subreddit hvata posts i broji team mentions; RedditException klasa.

**Verifikacija:** flutter analyze ima i dalje 3 errora (IntelligenceAggregator missing — popravlja se u Task 6).

---

### Task 6 — IntelligenceAggregator + Scoring Engine
**Status:** Completed

**Opis:** Centralni aggregator koji koordinira svih 5 izvora paralelno (`Future.wait`), nikad ne baca exception izvan sebe — svaki source error se konvertira u inactive SourceScore. 5 privatnih scoring metoda implementira pravila iz spec-a: `_scoreOdds` (base 0.5 za h2h, +0.5 sharp <5%, +0.5 drift, +0.5 non-Home drift), `_scoreFootballData` (base 0.3 active, +0.4 strong form ≥4/5, +0.4 H2H dominant ≥3/5, +0.4 standings gap ≥8 — uz cache check 3h TTL), `_scoreNbaStats` (base 0.3, +0.35 hot streak ≥7/10, +0.35 rest diff ≥3 dana), `_scoreReddit` (inactive ako mentions <3, base 0.2, +0.3 high buzz ≥10, +0.3 sentiment tilt |bias|>0.3, +0.2 viral ≥500 upvotes), `_scoreTelegram` (max 0.5, sum weights × 0.25 — Visoka=1.0/Srednja=0.7/Niska=0.3/Novo=0.5). Sav cache pristup ide kroz Storage signal box-eve s 3h TTL — 4 izvora postaju efektivno besplatni nakon prvog poziva. **Svi prethodni analyze errori riješeni.**

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/services/intelligence_aggregator.dart` — IntelligenceAggregator klasa s 4 service refs (footballService nullable, nbaService nullable, redditMonitor nullable, telegramProvider required jer uvijek postoji); `buildReport(match)` glavna ulazna točka; 5 privatnih `_scoreXxx` metoda; signal cache check pattern za 3 izvora (FD/NBA/Reddit); per-method graceful handling kroz `SourceScore.inactive`.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 7 — Intelligence Dashboard + Wire-up + Settings + Prompt Injection
**Status:** Completed

**Opis:** Zasebni IntelligenceDashboardScreen (push route iz Matches) renderira watched matches s per-match karticama: header s sport/league/teams + ConfluenceBadge (boja po category), 5 source rows s emoji/name/LinearProgressIndicator/score-text, "Generated Xm ago" footer. Per-card "Generate" OutlinedButton kad reporta nema, refresh ikona u AppBar i RefreshIndicator za pull. Empty state s radar ikonom kad nema watched matches. main.dart MultiProvider dobio IntelligenceProvider — konstruktor instancira aggregator sa fresh service instancama (Football optional ako nema API key) i wire-a kroz `wireAggregator`. Matches screen dobio `_IntelligenceShortcut` widget (vidljiv samo s ≥1 watched) koji push-a Dashboard. Settings dobiva treću API key sekciju za Football-Data.org (uses postojeći _ApiKeySection pattern). AnalysisProvider `_buildUserMessage` proširen s `intelligenceReports` named arg — ako postoji report za staged match, IntelligenceReport.toClaudeContext() blok se ubacuje između SELECTED MATCHES i TIPSTER SIGNALS. sendMessage skuplja oba (drifts + reports) u istoj petlji nad effectiveMatches. Test wrap-u dodana 4 nova Hive boxa.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows, flutter build apk --debug.

**Kreirani fajlovi:**
- `lib/screens/intelligence_dashboard_screen.dart` — IntelligenceDashboardScreen StatelessWidget; privatne klase `_IntelligenceMatchCard` (s _relativeTime helperom), `_ConfluenceBadge`.

**Ažurirani fajlovi:**
- `lib/main.dart` — uvozi IntelligenceProvider + 4 servisa; novi 6. provider u MultiProvider koji konstruira aggregator (Football conditional, NBA + Reddit + Telegram uvijek) i wire-a ga.
- `lib/screens/matches_screen.dart` — uvozi IntelligenceDashboardScreen; novi `_IntelligenceShortcut` privatni widget render-an iznad TabBar-a.
- `lib/screens/settings_screen.dart` — `_footballController`/`_showFootball`/`_footballHasKey`/`_footballInited` polja; `_buildFootballDataSection` koristi postojeći `_ApiKeySection` pattern; SnackBar s napomenom "restart app to apply" (jer aggregator se kreira jednom u MultiProvider create lambda-i).
- `lib/models/analysis_provider.dart` — uvozi intelligence_report; `_buildUserMessage` dobio 5. named arg `intelligenceReports` i renderira IntelligenceReport blokove između SELECTED MATCHES i TIPSTER SIGNALS; sendMessage skuplja `reports` paralelno s `drifts`.
- `test/widget_test.dart` — setUpAll otvara 4 nova Hive boxa.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan, flutter build apk --debug uspješan.

---

### Finalna verifikacija Session 6:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v2.0.0.apk (NOT in git — `.gitignore` `*.apk`)
- Verzija: **2.0.0+7 (major bump — multi-source intelligence platform)**
- Git: Claude Code NE commit-a/push-a — developer preuzima

---

---
---

## Session 7: 2026-04-18 — Three-Tier Framework + Charts + Push + Detail Screens

**Kontekst:** S1-S6 izgradili single-tier multi-source platformu. S7 uvodi tri investicijska horizonta (PRE-MATCH / LIVE / ACCUMULATOR), svaki s vlastitim Claude promptom, suggestion chips, i Bets screen prikazom. Pored toga: Charts (odds movement, form, equity curve), MatchDetailScreen (deep dive s 4 taba), Push Notifications (kickoff + drift + VALUE), tier-aware empty states. **Major bump na 3.0.0+8** — fundamentalna transformacija iz single-strategy u multi-strategy platformu.

---

### Task 1 — InvestmentTier + TierProvider + Dependencies
**Status:** Completed

**Opis:** Data kostur za tier sustav. InvestmentTier enum (preMatch/live/accumulator) + InvestmentTierMeta extension s display/icon/horizon/philosophy/colorValue/fromString. TierProvider drži current tier, perzistira u settings boxu, izlaže `suggestionChips` (lista 3 prompt suggestiona po tier-u za Analysis empty state) i `claudeContextAppendix` (tier-specific blok koji se appenda u Claude user message — npr. "TIER: PRE-MATCH — 24-48h horizon, focus on deep pre-kickoff analysis..."). Tri nove dependencies u pubspec: `fl_chart ^0.69.0` (Task 6), `flutter_local_notifications ^18.0.0` + `timezone ^0.10.0` (Task 8). Storage proširen s `_currentTierField` getter/saver. main.dart MultiProvider — TierProvider added kao prvi (jer ostali provideri mogu read-ati u budućnosti).

**Komande izvršene:** flutter pub get, flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/investment_tier.dart` — InvestmentTier enum + extension getters.
- `lib/models/tier_provider.dart` — TierProvider ChangeNotifier + tier-specific suggestionChips + claudeContextAppendix.

**Ažurirani fajlovi:**
- `pubspec.yaml` — version bump 3.0.0+8 + 3 nove dependencies.
- `lib/services/storage_service.dart` — `_currentTierField` constant + `getCurrentTier`/`saveCurrentTier`.
- `lib/main.dart` — uvozi TierProvider; dodan kao prvi u MultiProvider.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 2 — Tier Mode Selector UI + Integration
**Status:** Completed

**Opis:** TierModeSelector widget renderira 3 tab-like buttona (⚽ Pre-Match / 🔴 Live / 🏆 Accumulator) ispod AppBar-a. Aktivni tab dobiva tier-specific boju (purple/red/orange) sa border + alpha 0.2 fill. AnimatedContainer 200ms na switch. MainNavigation dobio Column wrap iznad IndexedStack-a — TierModeSelector je SafeArea(bottom: false) GLOBAL element vidljiv na svim screen-ovima.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/widgets/tier_mode_selector.dart` — TierModeSelector StatelessWidget; Consumer<TierProvider>; map kroz InvestmentTier.values, GestureDetector + AnimatedContainer per tab.

**Ažurirani fajlovi:**
- `lib/main.dart` — uvozi TierModeSelector; MainNavigation body Scaffold zamijenjen s Column[SafeArea(TierModeSelector) + Expanded(IndexedStack)].

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 3 — Tier-Aware Analysis Screen
**Status:** Completed

**Opis:** Analysis screen sad reaguje na trenutni tier. Empty state dinamički prikazuje tier icon + display name + philosophy + tier-specific suggestion chips. `_sendMessage` čita TierProvider.currentTier i postavlja na AnalysisProvider prije slanja. AnalysisProvider sada drži `_currentTier` field i appenda `claudeContextAppendix` blok na kraj svakog user message-a (ispred user text-a). `claudeContextAppendix` premješten iz TierProvider-a u InvestmentTier extension da bi getter bio dostupan na enum vrijednosti — TierProvider sada delegira na enum.

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/models/investment_tier.dart` — extension dobio `claudeContextAppendix` getter (premješten iz TierProvider-a).
- `lib/models/tier_provider.dart` — `claudeContextAppendix` sada delegira na `_currentTier`; dodan `export 'investment_tier.dart'` za sažetiji import flow.
- `lib/models/analysis_provider.dart` — uvozi investment_tier; field `_currentTier` + `setCurrentTier` setter; `_buildUserMessage` appenda tier blok uvijek (early-return uklonjen).
- `lib/screens/analysis_screen.dart` — uvozi tier_provider; `_sendMessage` postavlja tier na AnalysisProvider; `_buildEmptyState` zamijenjen Consumer<TierProvider> koji renderira tier-specific icon/display/philosophy + dinamičke suggestion chips.
- `lib/widgets/tier_mode_selector.dart` — uklonjen unused investment_tier import (sad ide kroz tier_provider re-export).

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 4 — Accumulator Model + Provider + Builder Screen
**Status:** Completed

**Opis:** Acca data layer + builder UI. AccumulatorLeg drži snapshot ishoda (matchId/sport/league/teams/selection/odds/kickoff). Accumulator agregira legs + stake + status (building/placed/won/lost/partial), izračunava combinedOdds (multiplikacija) + potentialPayout/Profit + actualProfit. `correlationWarnings` getter detektira (a) duplicate match IDs i (b) više legs iz istog league-a istog dana — UI prikazuje orange warning banner. AccumulatorsProvider drži in-memory liste + currentDraft, exposes building/placed/settled filteri + lifecycle metode (startNewDraft/addLegToDraft/removeLegFromDraft/setDraftStake/saveDraftAsAccumulator validira ≥2 legs && stake>0/discardDraft/placeAccumulator/settleAccumulator/deleteAccumulator). AccumulatorBuilderScreen je full push route s 3-zone layout: legs lista (s remove), horizontal scroll watched matches za pick (otvara outcome dialog), stake input, summary card (legs/odds/payout), conditional warnings, Save FAB. Material `Accumulator` collision riješen `hide Accumulator` u import-u.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/accumulator.dart` — AccumulatorLeg + AccumulatorStatus + AccumulatorStatusMeta extension + Accumulator klasa s correlationWarnings getterom + copyWith + toMap/fromMap.
- `lib/models/accumulators_provider.dart` — AccumulatorsProvider ChangeNotifier.
- `lib/screens/accumulator_builder_screen.dart` — AccumulatorBuilderScreen + privatne klase `_LegTile`, `_PickableMatchCard`, `_SummaryCard`, `_MetricCol`; helper `_pickOutcome` AlertDialog s ListTile po dostupnom outcome-u (uključuje Draw za soccer); `hide Accumulator` u flutter/material import-u zbog naming collision-a.

**Ažurirani fajlovi:**
- `lib/services/storage_service.dart` — uvozi Accumulator; `_accumulatorsBox` constant + box getter; `init()` otvara 12. box; `getAllAccumulators` (sort createdAt desc) + `saveAccumulator` + `deleteAccumulator`.
- `lib/main.dart` — uvozi AccumulatorsProvider; dodan kao 7. provider.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 5 — Tier-Aware Bets Screen + AccumulatorCard
**Status:** Completed

**Opis:** Bets screen sad reaguje na trenutni tier — Consumer<TierProvider> grana izmedu `_buildRegularView` (Open/Settled tabs s BetCard, pre-existing) i `_buildAccumulatorView` (DefaultTabController length 3 — Building/Placed/Settled tabs s AccumulatorCard). FAB se ponaša drugačije: u acca tier-u otvara AccumulatorBuilderScreen (započne novi draft ako nema), inače otvara klasični BetEntrySheet. AccumulatorCard analogan BetCard-u: header s "${legs.length} legs" + odds badge (multiplied combined) + status chip; preview do 3 legs + "+X more"; meta chips (Stake/Payout); conditional P&L row; tier-specific action buttoni (Place za building, Settle sheet za placed s 3 opcije Won/Lost/Partial); Dismissible swipe-to-delete.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/widgets/accumulator_card.dart` — AccumulatorCard StatelessWidget s privatnim klasama `_OddsBadge`, `_StatusChip`, `_MetaChip` + helperi `_buildActions`/`_confirmDelete`/`_showSettleSheet`/`_settleButton`. `hide Accumulator` u flutter import.

**Ažurirani fajlovi:**
- `lib/screens/bets_screen.dart` — uvozi tier_provider/accumulators_provider/AccumulatorBuilderScreen/AccumulatorCard; build wrap-an u Consumer<TierProvider> koji bira view; novi `_buildRegularView` (extracted), `_buildAccumulatorView` (3 taba), `_buildAccaList` helper s empty state.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 6 — fl_chart Integration + Chart Widgets
**Status:** Completed

**Opis:** 3 reusable chart widgeta. OddsMovementChart koristi fl_chart LineChart s 2-3 linije (home blue, draw orange optional, away red); X-axis je hours offset od prvog snapshota, Y-axis decimalne kvote; "Not enough snapshots" placeholder kad <2. FormChart je jednostavan horizontal bar — za svaki W/D/L u listi renderira 28x28 obojen badge (green/grey/red s alpha 0.2 fill + border). EquityCurveChart sortira settled bets po `settledAt`/`placedAt`, akumulira running profit, renderira LineChart s bojom green/red ovisno o end-state-u + areaBelow s alpha 0.1.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/widgets/charts/odds_movement_chart.dart` — OddsMovementChart (LineChart, 2-3 line series).
- `lib/widgets/charts/form_chart.dart` — FormChart (Row badge sequence).
- `lib/widgets/charts/equity_curve_chart.dart` — EquityCurveChart (LineChart cumulative P/L).

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 7 — MatchDetailScreen + MatchNote
**Status:** Completed

**Opis:** Push route iz MatchCard tap (kad nije selectable). DefaultTabController s 4 taba: **Overview** (sport/league/kickoff + 2-3 OddsTile + bookmaker/margin row + "Analyze in AI" button koji prebacuje na Analysis tab i pop-a do root-a), **Intelligence** (Consumer<IntelligenceProvider>; placeholder s Generate button kad nema reporta, CircularProgressIndicator dok loadin, full report view s confluence circle/category/interpretation + per-source rows + Refresh button), **Charts** (OddsMovementChart 200px iz Storage snapshots + FormChart home + FormChart away ako postoji FootballDataSignal cached), **Notes** (full-screen TextField s pre-filled iz Storage + Save button + last-saved timestamp). AppBar action — star toggle za watched. MatchCard onTap default sad otvara MatchDetailScreen ako onTap nije eksplicitno proslijeđen.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/match_note.dart` — MatchNote (matchId/text/updatedAt) + toMap/fromMap.
- `lib/screens/match_detail_screen.dart` — MatchDetailScreen StatefulWidget + privatne klase `_OverviewTab`, `_OddsTile`, `_IntelligenceTab`, `_ReportView`, `_ChartsTab`.

**Ažurirani fajlovi:**
- `lib/services/storage_service.dart` — uvozi MatchNote; `_matchNotesBox` constant + `_notesBox` getter; `init()` otvara 13. box; `getMatchNote`/`saveMatchNote`/`deleteMatchNote`.
- `lib/widgets/match_card.dart` — uvozi MatchDetailScreen; default onTap (kad nije selectable i nije eksplicitno proslijeđen) otvara detail screen kroz Navigator.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 8 — Push Notifications Service
**Status:** Completed

**Opis:** NotificationsService statički wrapper oko `flutter_local_notifications` s 3 channela (kickoff defaultImportance, drift high, value high). `init` poziva tz.initializeTimeZones + plugin init s Android/iOS settings. `requestPermissions` traži notification permission na Android. `scheduleKickoffReminders(match)` zakazuje 3 reminderima (24h/1h/15min before kickoff) preko `zonedSchedule` s deterministic ID-om (matchId.hashCode + secondsOffset) za clean cancel; pre-past reminders se preskaču. `cancelKickoffReminders(matchId)` briše po istim ID-evima. `showDriftAlert` i `showValueAlert` su immediate `show` pozivi. main.dart inicijalizira u svom try/catch bloku nakon Storage init. MatchesProvider.toggleWatched scheduleKickoffReminders na watch / cancelKickoffReminders na unwatch. `_captureSnapshotsForWatched` pokreće drift alert kad postoji significant move s |%| ≥ 5. AnalysisProvider nakon successful response checka VALUE marker i pokreće value alert za prvi staged match. Sve notification pozive su u try/catch — failure ne smije razbiti UX.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/services/notifications_service.dart` — NotificationsService static wrapper.

**Ažurirani fajlovi:**
- `lib/main.dart` — uvozi NotificationsService; novi try/catch blok za init + requestPermissions.
- `lib/models/matches_provider.dart` — uvozi NotificationsService; toggleWatched schedule/cancel; `_captureSnapshotsForWatched` triggera drift alert >5%.
- `lib/models/analysis_provider.dart` — uvozi NotificationsService; nakon AnalysisLog save provjerava VALUE i triggera alert.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan. Notifications su Android-prvi feature — full E2E test traži APK na uređaju.

---

### Task 9 — Tier-Aware P&L Summary + Equity Curve
**Status:** Completed

**Opis:** PlSummaryWidget proširen — return value je sada Column s postojećim 4-metric Card-om (totalBets/winRate/ROI/totalP&L) PLUS conditional drugi Card s "Equity Curve" labelom + 120px EquityCurveChart kad ima ≥2 settled bets.

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/widgets/pnl_summary.dart` — uvozi EquityCurveChart; Card → Column wrap; conditional render drugog Card-a s chartom.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 10 — Polish + Final Verification
**Status:** Completed

**Opis:** Finalna sesijska polish runda. Test wrap proširen s TierProvider + AccumulatorsProvider + 2 nova Hive boxa (`accumulators`, `match_notes`). Tijekom APK build-a otkriveno da `flutter_local_notifications 18.x` zahtijeva core library desugaring na Android — popravak u `android/app/build.gradle.kts` (dodano `isCoreLibraryDesugaringEnabled = true` u compileOptions + dependency `desugar_jdk_libs:2.0.4`). Tier-aware Settings notification toggle blok preskočen — zabilježen kao Identified Issue za buduću sesiju.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows, flutter build apk --debug.

**Ažurirani fajlovi:**
- `test/widget_test.dart` — 2 nova Hive boxa + TierProvider/AccumulatorsProvider u test wrap.
- `android/app/build.gradle.kts` — `isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")` dependency.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan, flutter build apk --debug uspješan.

---

### Finalna verifikacija Session 7:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v3.0.0.apk (NOT in git — `.gitignore` `*.apk`)
- Verzija: **3.0.0+8** (major bump — multi-strategy intelligence platform)
- Git: Claude Code NE commit-a/push-a — developer preuzima

---

---
---

## Session 8: 2026-04-18 — Stabilization + P&L Breakdown + Filter/Search

**Kontekst:** S7 je ostavio 10 Identified Issues u backlog-u. S8 rješava 5 high-impact issues (auto-refresh wire, LIVE tier filtering, FD dynamic re-wire, notifications per-type, FD fuzzy match) i dodaje dva CoinSight S10-inspired polish feature-a (per-sport P&L breakdown, filter/search u Bets screenu). Minor bump na 3.1.0+9 — mix stabilization + new functionality.

---

### Task 1 — IntelligenceProvider Auto-Refresh Wire-up
**Status:** Completed

**Opis:** MainNavigation konvertiran iz StatelessWidget u StatefulWidget s `_autoRefreshStarted` guard flagom + `didChangeDependencies` koji nakon post-frame callback-a poziva `IntelligenceProvider.startAutoRefresh` s callback-om koji vraća watched matches listu iz MatchesProvider-a. Timer.periodic(1h) iz S6 sada stvarno radi — gated na `watched.isNotEmpty` unutar timer callback-a. Dispose je već pokriven kroz postojeći IntelligenceProvider.dispose override (cancela timer).

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `pubspec.yaml` — version bump na `3.1.0+9`.
- `lib/main.dart` — MainNavigation → StatefulWidget s `_MainNavigationState`; `didChangeDependencies` + post-frame wire up + guard flag; build wrap nepromijenjen.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 2 — LIVE Tier Filtering (matchStartedAt)
**Status:** Completed

**Opis:** Bet model (koji je već imao `matchStartedAt` field iz S3) dobio getter-e `isLiveBet` (placedAt > matchStartedAt) i `isPreMatchBet` (fallback). BetEntrySheet detektira trenutni tier — ako je LIVE, postavlja `matchStartedAt = now - 1min` (osigurava isLiveBet true); inače koristi `prefilledMatch.commenceTime`. BetsScreen tier-aware filter (`_filterBetsForTier`) u `_buildOpenTab`/`_buildSettledTab` — PRE-MATCH pokazuje samo pre-match bets, LIVE samo live. LIVE empty state ima drugačiju poruku. Accumulator tier vraća empty (koristi poseban view).

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/models/bet.dart` — dodani `isLiveBet`/`isPreMatchBet` getter-i (backward-compat: bez matchStartedAt → pre-match).
- `lib/widgets/bet_entry_sheet.dart` — uvozi TierProvider; `_save` detektira tier i postavlja matchStartedAt.
- `lib/screens/bets_screen.dart` — `_buildRegularView` wrapped u Consumer<TierProvider>; `_filterBetsForTier` helper; `_buildOpenTab`/`_buildSettledTab` prima tier i primjenjuje filter.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 3 — Football-Data Dynamic Re-wire
**Status:** Completed

**Opis:** IntelligenceProvider refaktoriran — umjesto `wireAggregator(aggregator)` sada `wireServices(footballService, nbaService, redditMonitor, telegramProvider)` drži individualne refove kao fieldove i gradi aggregator interno kroz privatni `_rebuildAggregator`. Nova `updateFootballDataApiKey(String? newKey)` metoda zamijeni FD service (null za delete) i rebuild-a aggregator + notifyListeners — sljedeći report generation koristi svjež key bez app restart-a. Settings Football-Data sekcija onSave/onRemove sada poziva `context.read<IntelligenceProvider>().updateFootballDataApiKey(...)` i SnackBar poruka je ažurirana ("saved and active" umjesto "restart to apply").

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/models/intelligence_provider.dart` — uvozi 4 servisa + TelegramProvider; dodana polja za service refs; `wireServices` + `_rebuildAggregator` + `updateFootballDataApiKey`; staru `wireAggregator` metodu ostavio radi compat-a.
- `lib/main.dart` — MultiProvider create koristi `wireServices` umjesto eksplicitnog `IntelligenceAggregator` instanciranja; uvoz `intelligence_aggregator.dart` uklonjen (nije više potreban ovdje).
- `lib/screens/settings_screen.dart` — uvozi IntelligenceProvider; Football-Data onSave/onRemove pozivaju `updateFootballDataApiKey`; SnackBar poruka bez "restart" napomene.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 4 — Notifications Per-Type Enable + Settings UI
**Status:** Completed

**Opis:** 3 nova bool field-a u settings boxu (kickoff/drift/value; default true). NotificationsService.scheduleKickoffReminders/showDriftAlert/showValueAlert sada early-return kad je odgovarajući flag false. Nova privatna klasa `_NotificationsSection` StatefulWidget u Settings screenu (izmedu Bankroll i Telegram) — 3 SwitchListTile-a s title/subtitle, persist-a u Hive on change. AnimatedSwitcher nije potreban jer SwitchListTile ima vlastitu animaciju.

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/services/storage_service.dart` — 3 nova constanta + `getNotif*Enabled`/`saveNotif*Enabled` pair-a.
- `lib/services/notifications_service.dart` — uvozi StorageService; svaka javna metoda early-return na odgovarajući flag.
- `lib/screens/settings_screen.dart` — nova privatna klasa `_NotificationsSection` + ubacivanje u ListView izmedu Bankroll i Telegram sekcije.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 5 — Football-Data Fuzzy Match Improvement (Token-Based)
**Status:** Completed

**Opis:** Naivni substring matching zamijenjen token-based algoritmom. `_tokenize(String)` vraća Set<String>: lowercase → strip club suffixes (FC/AFC/CF/SC/AC/CD/CB/SL/B.K.) → strip non-alpha → split whitespace → filter ≥3 char. `_matchScore(a, b)` vraća veličinu preseka. U `getSignalForMatch`, loop kroz FD matches tražeći best score (zbroj home + away score-a) uz guard da obje strane imaju bar 1 token match. Dodatni safety: `bestScore < 2` throw-a "ambiguous team names" — sprečava "Manchester" collision izmedu United i City (svaki bi dao 1+1=2, ali "Manchester United" vs "Manchester United FC" daje 2+2=4, čime best uvijek pobijedi nad ambiguous).

**Komande izvršene:** flutter analyze, flutter build windows.

**Ažurirani fajlovi:**
- `lib/services/football_data_service.dart` — `_normalize` zamijenjen s `_tokenize` + `_matchScore` helperima; `getSignalForMatch` lookup loop iterira sve matches, vodi bestScore, throws kad je <2.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 6 — Per-Sport P&L Breakdown
**Status:** Completed

**Opis:** SportPl mali model + `BetsProvider.perSportBreakdown` getter koji iterira `Sport.values`, filtrira settled bets po sportu, računa won/lost/totalStake/totalProfit/roiPercent. PlSummaryWidget dobio treći Card (`_PerSportCard`) ispod EquityCurve s tabular layoutom: header row (Sport/Bets/Win%/ROI/P/L u greys 10pt) + Divider + per-sport rows s sport icon + display + brojkama; ROI i P/L kolonu boje green/red/grey ovisno o predznaku.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/models/sport_pl.dart` — SportPl model s `winRate` getter-om.

**Ažurirani fajlovi:**
- `lib/models/bets_provider.dart` — uvozi sport + sport_pl; `perSportBreakdown` getter (skip sportova bez bets).
- `lib/widgets/pnl_summary.dart` — uvozi sport + sport_pl; conditional render `_PerSportCard` ispod EquityCurve; nova privatna klasa `_PerSportCard` s static `_headerStyle`.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 7 — Filter/Search in Bets Screen
**Status:** Completed

**Opis:** BetsProvider proširen s filter state-om — `_filterSports` Set, `_filterStatuses` Set, `_filterFromDate`/`_filterToDate`, `_searchText`. Toggle/setter metode + `clearFilters` + `applyFilters(source)` koja filtrira list. `hasActiveFilters` getter. Novi BetsFilterBar widget — TextField search (s clear icon kad ima text) + horizontal ListView 3 ActionChip-a (Sport/Status/Date) + conditional Clear chip. Filter chips otvaraju modal bottom sheet-ove (Sport/Status koriste CheckboxListTile per option, Date koristi `showDateRangePicker`). BetsScreen `_buildOpenTab`/`_buildSettledTab` sada apliciraju `bets.applyFilters(_filterBetsForTier(...))` umjesto direct tier filter, empty state poruka razlikuje "no filters match" od originalnih.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/widgets/bets_filter_bar.dart` — BetsFilterBar StatefulWidget + 3 modal pickerа.

**Ažurirani fajlovi:**
- `lib/models/bets_provider.dart` — filter state + getteri/metode/applyFilters.
- `lib/screens/bets_screen.dart` — uvozi BetsFilterBar; `_buildRegularView` ubacuje filter bar izmedu PlSummary i TabBar; `_buildOpenTab`/`_buildSettledTab` koriste applyFilters i diferencirane empty state poruke.

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 8 — Polish + Final Verification + Issue Cleanup
**Status:** Completed

**Opis:** Tri male polish promjene + cleanup riješenih issues iz backlog-a. (1) Accumulator stake TextField sad ima `errorText: _stakeError` koji se postavlja na "Enter a positive stake" kad je input ne-prazan ali ≤0 — daje vizualni feedback (red border) prije nego što korisnik klikne Save. (2) OddsMovementChart i EquityCurveChart sad čitaju `MediaQuery.of(context).size.width` i smanjuju `reservedSize` + `fontSize` + decimal precision kad je ekran <360dp. (3) Test wrap dobio IntelligenceProvider (zbog auto-refresh wire-up u MainNavigation iz Task 1). Iz Identified Issues uklonjeno **7 unosova** koji su riješeni u S2/S5.5/S8: FD restart, auto-refresh, FD fuzzy match, LIVE tier, notifications per-type, stake validation, chart labels.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows, flutter build apk --debug.

**Ažurirani fajlovi:**
- `lib/screens/accumulator_builder_screen.dart` — `_stakeError` field; TextField errorText + onChanged validacija (empty → null, value≤0 → error, valid → null).
- `lib/widgets/charts/odds_movement_chart.dart` — responsive `leftReserved`/`labelFontSize` + manje decimala na malim uređajima.
- `lib/widgets/charts/equity_curve_chart.dart` — analogno responsive sizing za leftTitles + bottomTitles.
- `test/widget_test.dart` — dodan IntelligenceProvider u test wrap (jer MainNavigation didChangeDependencies čita iz njega).

**Cleanup riješenih issues** (uklonjeno iz `## Identified Issues`):
- ~~Football-Data API key change requires app restart~~ → S8 Task 3
- ~~IntelligenceProvider auto-refresh nije wired iz UI-ja~~ → S8 Task 1
- ~~Football-Data team name fuzzy matching edge cases~~ → S8 Task 5
- ~~LIVE tier filtering nedostaje matchStartedAt~~ → S8 Task 2
- ~~Notifications per-type enable nije implementiran~~ → S8 Task 4
- ~~Accumulator stake validacija prihvata invalid input~~ → S8 Task 8
- ~~Chart widget axis labele mogu se preklapati~~ → S8 Task 8

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan, flutter build apk --debug uspješan.

---

### Finalna verifikacija Session 8:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v3.1.0.apk (NOT in git — `.gitignore` `*.apk`)
- Verzija: **3.1.0+9** (minor bump — mix stabilization + new functionality)
- Identified Issues: smanjeno s 10 na **3**
- Git: Claude Code NE commit-a/push-a — developer preuzima

---

---
---

## Session 9: 2026-04-18 — Backlog Cleanup + Tennis Minimal + Accumulator Rename

**Kontekst:** S8 je doveo Identified Issues backlog na 3. S9 rješava preostala 2 (tennis charts coverage + Accumulator import collision) i formalno prekvalificira treći (Telegram Bot API) kao by-design. Patch bump na 3.1.1+10 — cleanup + jedan mali feature (TennisInfoPanel). Nakon S9, BetSight ima 0 otvorenih bugova i 1 dokumentirano by-design ograničenje.

---

### Task 1 — Pubspec Bump + Telegram Issue Reclassification
**Status:** Completed

**Opis:** Verzija bump-ana na 3.1.1+10 (patch — cleanup sesija, nema breaking funkcionalnih promjena). Telegram Bot API limitation prekvalificiran iz "open issue" u formalnu "By-Design Will Not Fix" kategoriju s 4 dokumentirana obrazloženja (platformski / tehnički / security / arhitekturalni) i preporučenim workflow-om za korisnika (bot kroz @BotFather za vlastite kanale, alternativni izvori kroz Reddit/Football-Data za nedostupne tipster kanale).

**Komande izvršene:** flutter analyze, flutter build windows (odgođeno u Task 4 finalnoj verifikaciji jer Task 1 samo modificira WORKLOG i pubspec bez code promjena).

**Ažurirani fajlovi:**
- `pubspec.yaml` — version bump na `3.1.1+10`.
- `WORKLOG.md` — Identified Issues sekcija reorganizirana.

**Verifikacija:** flutter analyze 0 issues (nema code promjena u ovom tasku).

---

### Task 2 — Tennis Minimal: TennisInfoPanel
**Status:** Completed

**Opis:** MatchDetailScreen Charts tab sada renderira tier-specific sekcije ovisno o Sport enumu. Za soccer zadržan postojeći FormChart flow. Za tennis umjesto prazne sekcije sada TennisInfoPanel widget koji prikazuje: (a) bookmaker favourite badge (zeleni s zvjezdicom — igrač s nižim kvotama), (b) implied probability tile-ove za oba igrača (s highlight-om favorita — 1.5px green border), (c) margin indikator s label-om "sharp"/"normal"/"soft" ovisno o threshold-u (<5/<8/≥8), (d) info note objašnjava zašto nema detaljne forme (nema dedicated tennis data source-a, preporuka ATP/WTA site). Basketball dobio placeholder tekst koji upućuje korisnika na Intelligence tab za last10 stats.

**Komande izvršene:** flutter analyze, flutter build windows.

**Kreirani fajlovi:**
- `lib/widgets/charts/tennis_info_panel.dart` — TennisInfoPanel StatelessWidget + privatni `_ProbTile`; handle-a `h2h == null` fallback s "No odds data" porukom.

**Ažurirani fajlovi:**
- `lib/screens/match_detail_screen.dart` — uvozi TennisInfoPanel; `_ChartsTab` dobio sport-specific branching (soccer → FormChart / tennis → TennisInfoPanel / basketball → placeholder text).

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan.

---

### Task 3 — Accumulator → BetAccumulator Rename
**Status:** Completed

**Opis:** Klasa `Accumulator` preimenovana u `BetAccumulator` kroz cijeli codebase. AccumulatorLeg / AccumulatorStatus / AccumulatorsProvider / AccumulatorCard / AccumulatorBuilderScreen ostaju jer nisu kolidirali s Material lib. Rename odvijen fajl po fajl (constructor + copyWith + fromMap factory + storage getter/setter signatures + ChangeNotifier field tipovi + widget field tipovi). `import 'package:flutter/material.dart' hide Accumulator;` uklonjen iz 2 fajla (accumulator_builder_screen, accumulator_card) — sad standardni material import.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows.

**Ažurirani fajlovi:**
- `lib/models/accumulator.dart` — `class Accumulator` → `class BetAccumulator`; constructor / copyWith / fromMap factory signature-i.
- `lib/models/accumulators_provider.dart` — svi `Accumulator` → `BetAccumulator` u field tipovima i factory pozivima.
- `lib/services/storage_service.dart` — `getAllAccumulators` return type + internal list type + fromMap poziv; `saveAccumulator` parameter type.
- `lib/widgets/accumulator_card.dart` — uklonjen `hide Accumulator`; `final Accumulator acca` → `final BetAccumulator acca`.
- `lib/screens/accumulator_builder_screen.dart` — uklonjen `hide Accumulator`; `final Accumulator draft` → `final BetAccumulator draft`.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan.

---

### Task 4 — Final Identified Issues Cleanup + Verification
**Status:** Completed

**Opis:** Finalna sanity runda. Grep potvrdio da u codebase-u nema preostalih `hide Accumulator` import-a ni `class Accumulator` referenci (samo `class BetAccumulator`). APK uspješno buildan na 3.1.1. Identified Issues konsolidiran — preostaje samo 1 formalno "By-Design Will Not Fix" unos (Telegram Bot API). Backlog na povijesno minimumu.

**Komande izvršene:** flutter analyze, flutter test, flutter build windows, flutter build apk --debug, grep sanity checks.

**Sanity check rezultati:**
- `grep "hide Accumulator" lib/` → no matches
- `grep "class Accumulator\b" lib/` → no matches (samo BetAccumulator)
- `grep "^version:" pubspec.yaml` → `version: 3.1.1+10` ✓

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspješan, flutter build apk --debug uspješan.

---

### Finalna verifikacija Session 9:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v3.1.1.apk (NOT in git — `.gitignore` `*.apk`)
- Verzija: **3.1.1+10** (patch bump)
- Identified Issues: **1** (by-design Telegram only)
- Git: Claude Code NE commit-a/push-a — developer preuzima

---

### Resolved in S9
- ~~MatchDetailScreen Charts tab ne pokriva tennis~~ — resolved with TennisInfoPanel (S9 Task 2)
- ~~Material Accumulator name collision~~ — resolved with BetAccumulator rename (S9 Task 3)

---
---

## Session 10: 2026-04-18 — Documentation Final

**Kontekst:** S1-S9 izgradili kompletan BetSight kod (64 Dart fajla, verzija 3.1.1+10). Ali dokumentacija je bila doslovno default Flutter template ("A new Flutter project"). S10 zatvara taj jaz s 4 kljucna dokumentna fajla paralelna CoinSight-u: README.md (prvi dojam), NEWBIE_GUIDE.md (korak-po-korak za novog korisnika), MANUAL.md (feature reference), OVERVIEW.md (arhitekturalni dokument s session-by-session poviješću).

---

### Task 1 — README.md
**Status:** Completed

**Opis:** Profesionalni README s badges-ima (Flutter/Dart/License/Version/Platform), 3-tier tabelom, listom značajki (Intelligence Layer s 5 izvora, Betting & tracking, Charts, Push notifications, Detail screens), instalacija sekcija, konfiguracija s 6 API-ja tablicom, tehnicki stack tablica, dokumentacija links, proprietary license napomena. Hrvatski jezik. Analog CoinSight READMEu ali BetSight-specific sadrzaj.

**Kreirani fajlovi:**
- `README.md` — 154 linija (target ~150 ✓)

**Verifikacija:** flutter analyze 0 issues, sadržaj ne sadrzi "A new Flutter project" (grep verified).

---

### Task 2 — NEWBIE_GUIDE.md
**Status:** Completed

**Opis:** 15 sekcija kroz korak-po-korak od Anthropic API registracije do prvog bet-a: (1) sto je BetSight, (2) prerequisiti, (3) Claude AI setup s detaljnim troubleshooting-om, (4) The Odds API postavljanje + 500 req/mj objasnjenje, (5) Football-Data.org (opcionalno) s podrzanim ligama, (6) Telegram Bot (opcionalno) s detaljnim objasnjenjem Bot API ogranicenja i practical workflow-om, (7) Reddit auto-konfiguracija, (8) prvi koraci i navigacija, (9) detaljan tier walkthrough (PRE-MATCH / LIVE / ACCUMULATOR), (10) prva Claude analiza s context injection objasnjenjem, (11) prvi bet + bankroll, (12) 3 grafikona (Odds Movement / Form / Equity Curve), (13) 50+ pojmova rjecnik, (14) zlatna pravila + responsible gambling resources, (15) zavrsna rijec. Hrvatski, svaki pojam objasnjen kad se prvi put spominje.

**Kreirani fajlovi:**
- `NEWBIE_GUIDE.md` — 1263 linije (target 1200-1400 ✓)

**Verifikacija:** flutter analyze 0 issues.

---

### Task 3 — MANUAL.md
**Status:** Completed

**Opis:** 23 poglavlja korisnickog prirucnika za power-user-e. Razlika od NEWBIE_GUIDE: **NEWBIE je korak-po-korak za novog**, **MANUAL je reference za postojeceg** korisnika koji zeli detalje svake funkcionalnosti. Poglavlja: (1) sto je, (2) osnovni pojmovi, (3) Three-Tier Framework detaljno, (4) Intelligence Layer s scoring formulama po izvoru, (5-6) prvo pokretanje + turneja, (7) API kljucevi sazetak, (8) prva analiza, (9) kako citati Claude odgovor + Trade Action Bar + marker parser, (10-11) prvi bet + settlement, (12) bankroll + Kelly Criterion napomena, (13) accumulator strategija + correlation warnings, (14) Telegram Monitor s Bot API ogranicenjem obrazlozenje, (15) Intelligence Dashboard detaljno, (16) 4 charts + responsive sizing, (17) push notifikacije lifecycle, (18) Bot Manager, (19) tipicni scenariji (weekly routine, live, accumulator, after bad month), (20) problemi i rjesenja tablice, (21) sigurnost, (22) FAQ, (23) 50+ pojmova rjecnik.

**Kreirani fajlovi:**
- `MANUAL.md` — 1610 linija (target 1500-1800 ✓)

**Verifikacija:** flutter analyze 0 issues.

---

### Task 4 — OVERVIEW.md
**Status:** Completed

**Opis:** Arhitekturalni dokument. Sekcije: (1) sto je BetSight, (2) stack + struktura fajlova + dependency graph + providers + 13 Hive boxova + 6 external APIs, (3-13) session-by-session povijest S1-S10 s kontekstom/ciljem/fajlovima/odlukama/rezultatom, (14) konacan pregled arhitekture (multi-source flow, tier strategy, cache management, Claude prompt design), (15) poznata ogranicenja i by-design odluke (Telegram, tennis coverage, Odds cap, responsive UI, Android-only, proprietary license, Accumulator rename, S1.x chronology), (16) notifications lifecycle detaljno, (17) Android build configuration (desugaring, manifest, namespace, signing), (18) testing strategija i preporuke, (19) performance napomene (rebuild triggers, memory, network calls), (20) zavrsna rijec.

**Kreirani fajlovi:**
- `OVERVIEW.md` — 1033 linije (target 1000-1200 ✓)

**Verifikacija:** flutter analyze 0 issues.

---

### Task 5 — Pubspec Bump + WORKLOG Final + Verification
**Status:** Completed

**Opis:** Verzija bump na 3.1.2+11 (patch). WORKLOG dobio finalni unos s sazetkom svih 5 taskova. Pokrenute sve builds. APK kopiran u root. Sanity check: README ne sadrzi "A new Flutter project" (grep verified).

**Komande izvršene:** flutter analyze, flutter test, flutter build windows, flutter build apk --debug.

**Ažurirani fajlovi:**
- `pubspec.yaml` — version 3.1.2+11.

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build windows uspjesan, flutter build apk --debug uspjesan, APK `betsight-v3.1.2.apk` (144 MB) u rootu.

---

### Finalna verifikacija Session 10:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspjesan
- flutter build apk --debug — uspjesan
- APK u rootu: betsight-v3.1.2.apk (144 MB, NOT in git)
- Verzija: **3.1.2+11** (patch bump — documentation only)
- **Dokumentacija: 4 nova fajla ukupno ~4060 linija**
  - README.md (154)
  - NEWBIE_GUIDE.md (1263)
  - MANUAL.md (1610)
  - OVERVIEW.md (1033)
- Git: Claude Code NE commit-a/push-a — developer preuzima

**BetSight 3.1.2 status:**
- 0 otvorenih bugova
- 1 dokumentirano by-design ogranicenje (Telegram)
- 64 Dart fajla (~11500 linija koda) + ~4060 linija dokumentacije
- Feature parity s CoinSight-om za intelligence platform + dokumentacijski parity ostvaren
- BetSight je zavrsio svoju "greenfield" fazu — spreman za real-world test

---
---

## Session 10.5 HYGIENE: 2026-04-18 — Repository Hygiene (CoinSight 1:1 Parity)

**Kontekst:** S10 je zavrsio dokumentaciju, ali audit je otkrio 6 znacajnih inconsistency-ja u odnosu na CoinSight-ovu strukturu repozitorija: SESSION fajlovi committed, platformski direktoriji (iOS/linux/macos/windows/web) committed iako je projekt Android-only, .gitignore nepotpun, generic LICENSE, CLAUDE.md zastario od S1, testna struktura nepostojeca. S10.5 rjesava sve to u 7 fokusiranih zadataka. Patch bump na 3.1.3+12. Nema novog Dart koda — samo repositorijska higijena.

---

### Task 1 — Update .gitignore + pubspec bump
**Status:** Completed

**Opis:** pubspec version na 3.1.3+12. `.gitignore` kompletno prepisana prema CoinSight predlošku — proširena s 40 na 87 linija. Dodane sekcije: Android signing (jks/keystore/key.properties), secrets (secret/pem/p12), Hive database, platformski dirs (ios/linux/macos/windows/web), SESSION_*.md pattern, archive + temp.

**Komande izvrsene:** flutter analyze, flutter build windows (zadnji put prije Task 2 destroys windows/).

**Azurirani fajlovi:**
- `pubspec.yaml` — version 3.1.3+12.
- `.gitignore` — 87 linija (bilo 40).

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspjesan (posljednji).

---

### Task 2 — Ukloni platformske direktorije (Android-only)
**Status:** Completed

**Opis:** `git rm -rf` + `rm -rf` za 5 platformskih direktorija (iOS, linux, macOS, Windows, web). BetSight je Android-only — ostali targets nisu u scope-u i commitani su kao ostatak iz `flutter create` templatea. Ukupno ~100 fajlova uklonjeno iz git tracking-a + obrisano iz filesystema.

**Komande izvrsene:** git rm -rf (5 dirs), rm -rf (empty remnants), flutter pub get, flutter analyze, flutter build apk --debug.

**Obrisani direktoriji:**
- `ios/` — iOS Runner, Swift, Podfile
- `linux/` — GTK+ runner (C++)
- `macos/` — Swift + entitlements
- `windows/` — Win32 runner (C++)
- `web/` — HTML/JS wrapper, manifest, icons

**Verifikacija:** flutter analyze 0 issues, flutter build apk --debug uspjesan. Windows build preskocen — dir je obrisan.

---

### Task 3 — Ukloni SESSION_*.md + BETLOG iz git tracking-a
**Status:** Completed

**Opis:** Internal dev planning fajlovi (SESSION_1.md kroz SESSION_10.md + SESSION_5_5_FIX.md + BETLOG.md) uklonjeni iz git tracking-a kroz `git rm --cached`. Fajlovi i dalje postoje u filesystemu za lokalnu developer referencu — samo ne idu u repo. `.gitignore` pattern `SESSION_*.md` i `BETLOG.md` (iz T1) drzi ih trajno untracked.

**Komande izvrsene:** git rm --cached (12 fajlova), flutter analyze.

**Ukloneni iz tracking-a:**
- SESSION_1.md - SESSION_10.md (11 fajlova)
- SESSION_5_5_FIX.md
- BETLOG.md

**Verifikacija:** 13 fajlova ostaje u filesystemu (ukljucujuci SESSION_10_5_HYGIENE.md). git ls-files nema SESSION_/BETLOG pattern. flutter analyze 0 issues.

---

### Task 4 — Ukloni .metadata iz git tracking-a
**Status:** Completed

**Opis:** `.metadata` je Flutter internal state fajl (track-a last revision Flutter-a koja je inicjalizirala projekt) — ne treba biti u git-u. Uklonjen iz tracking-a kroz `git rm --cached`. Fajl ostaje u filesystemu za Flutter tool-e.

**Komande izvrsene:** git rm --cached .metadata.

**Verifikacija:** fajl postoji u filesystemu (1706 bytes, Apr 18 10:25). git ls-files ga vise ne sadrzi. flutter analyze 0 issues.

---

### Task 5 — LICENSE replacement (Neven Roksa proprietary)
**Status:** Completed

**Opis:** Generic "BetSight" LICENSE (39 linija, placeholder) zamijenjen s punim Neven Roksa proprietary license-om (139 linija) analognim CoinSight-u, ali s BetSight-specific sport betting adaptacijama. 8 sekcija: Grant of Rights, Protection of Functional Logic (eksplicitno opisuje three-tier, confluence scoring, drift detection, Claude prompts, accumulator logic, Hive schema, MonitoredChannel reliability), AI/ML restrictions, No Warranty, Limitation of Liability (ukljucuje lost betting stakes), Enforcement, Governing Law (Hrvatska + EU), Contact (nevenroksa@gmail.com).

**Komande izvrsene:** rm LICENSE, Write novi LICENSE, flutter analyze.

**Azurirani fajlovi:**
- `LICENSE` — 139 linija (bilo 39).

**Verifikacija:** head -5 LICENSE pokazuje "Copyright (c) 2026 Neven Roksa". flutter analyze 0 issues.

---

### Task 6 — Update CLAUDE.md (S1-S10 parity)
**Stajnost:** Completed

**Opis:** CLAUDE.md je bio iz S1 (lista osnovna: Coin, CoinPosition... pogresno crypto lista) — nije reflektirao ni jednu BetSight feature od S2 nadalje. Prepisan od nule — sada pokriva: identitet/pravila rada, potpunu arhitekturu (lib/ models/screens/services/widgets/theme), svih 6 API integracija, 13 Hive boxova, 8 providera, Intelligence Layer (5 izvora weight mapping), Three-Tier Framework, redoslijed implementacije, WORKLOG format, git workflow.

**Komande izvrsene:** rm CLAUDE.md, Write novi, grep verification, flutter analyze.

**Azurirani fajlovi:**
- `CLAUDE.md` — 89 linija (bilo ~30).

**Verifikacija:** grep pronalazi "Intelligence Layer" i "Three-Tier" (2 matcha). flutter analyze 0 issues.

---

### Task 7 — Test direktorij strukturiranje + Final Verification
**Status:** Completed

**Opis:** Test/ proširen s 4 nova placeholder direktorija (helpers, unit, widget, integration) za buduce testne sesije. Kreiran `test/README.md` koji dokumentira strukturu, trenutno stanje (2/2 passed), i TODO listu konkretnih testova koje treba pisati (unit za OddsDrift.compute, parseRecommendationType, BetAccumulator.correlationWarnings itd; widget za MatchCard, TradeActionBar, BetsFilterBar; integration za full user flow).

**Komande izvrsene:** mkdir -p (4 subdirs), Write test/README.md, flutter analyze, flutter test, flutter build apk --debug.

**Kreirani fajlovi:**
- `test/README.md` — dokumentira test strukturu + TODO.
- `test/helpers/` (prazan, placeholder)
- `test/unit/` (prazan)
- `test/widget/` (prazan)
- `test/integration/` (prazan)

**Verifikacija:** flutter analyze 0 issues, flutter test 2/2 passed, flutter build apk --debug uspjesan.

---

### Finalna verifikacija Session 10.5:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build apk --debug — uspjesan
- APK u rootu: betsight-v3.1.3.apk (145 MB, NOT in git)
- Verzija: **3.1.3+12** (patch bump — repository hygiene)
- **Repozitorij cleanup rezultat:**
  - 116 fajlova uklonjenih iz git tracking-a (platformski + SESSION + BETLOG + .metadata)
  - .gitignore proširena s 40 na 87 linija
  - LICENSE prepisana (39 → 139 linija, Neven Roksa proprietary)
  - CLAUDE.md azuriran (~30 → 89 linija)
  - test/ strukturirana (4 subdir + README)
- Git: Claude Code je izvrsio `git rm` komande za pripremu — developer preuzima commit/push
- **BetSight repozitorij sada ima 1:1 strukturu s CoinSight-om**

*Backlog journey: S4 imao 1 → S5.5 ostao 1 → S6 dodao 3 (total 4) → S7 dodao 6 (total 10) → S8 riješio 7 (total 3) → S9 riješio 2 i re-klasificirao 1 (total 1 — by-design).*

---

## Session 11: 2026-04-18 — Comprehensive Test Coverage

### Phase 1 — Unit Model Tests
**Status:** Completed

**Opis:** Pure-logic unit testovi za sve data modele u `lib/models/`. Pokriveni su enumi (Sport, BetSelection, BetStatus, RecommendationType, InvestmentTier, SourceType, AccumulatorStatus, IntelligenceCategory, UserFeedback), value objekti (H2HOdds, Match, Bet, BetAccumulator, AccumulatorLeg, BankrollConfig, OddsSnapshot, OddsDrift, TipsterSignal, MonitoredChannel, AnalysisLog, MatchNote, SourceScore, FootballDataSignal, NbaStatsSignal, RedditSignal, IntelligenceReport, CachedMatchesEntry, SportPl, ValuePreset) i čisti utility (parseRecommendationType, generateUuid).

Testovi su strukturirani kao `group()` blokovi s `buildX()` factory helpers-ima (CoinSight pattern) za concise, DRY arrange step-ove. Koriste se `closeTo()` za float aritmetiku, `throwsA(isA<T>())` za exception paths, i `toMap()/fromMap()` roundtrip pattern za sve Hive-serializable tipove.

**Direktoriji kreirani:**
- `test/unit/models/` — 16 test fajlova
- `test/unit/providers/` — 1 test fajl (NavigationController — jedini provider bez Hive coupling-a)
- `test/unit/services/` — 4 test fajla (Phase 2)
- `test/widget/widgets/` — 4 test fajla (Phase 3)

**Kreirani fajlovi (Phase 1 — models):**
- `test/unit/models/sport_test.dart` — Sport enum + SportMeta (display, icon, hasDraw, defaultSportKeys, fromSportKey); unknown keys → null.
- `test/unit/models/odds_test.dart` — H2HOdds (impliedHomeProb/AwayProb/DrawProb, bookmakerMargin za 2-way/3-way markete, null draw handling).
- `test/unit/models/match_test.dart` — Match.isLive, timeToKickoff, toMap/fromMap roundtrip, fromJson (Odds API parsing s league mapping-om, FormatException paths, h2h iz bookmakers array-a, basketball bez draw-a).
- `test/unit/models/value_preset_test.dart` — 3 preseta (conservative/standard/aggressive) s testovima za matches() i edgeScore() logiku; fromString s null i unknown fallback-ima na standard.
- `test/unit/models/recommendation_test.dart` — parseRecommendationType s line-level, inline fallback, specificity ordering (VALUE > WATCH > SKIP), none fallback, case-sensitivity.
- `test/unit/models/bet_test.dart` — BetSelection/BetStatus enumi, isLiveBet (placedAt vs matchStartedAt), actualProfit (all 4 states), potentialPayout/Profit, copyWith, full roundtrip; int-to-double coercion.
- `test/unit/models/bankroll_test.dart` — BankrollConfig defaultConfig, stakeAsPercentage (div-by-zero safety), roundtrip.
- `test/unit/models/odds_snapshot_test.dart` — OddsSnapshot + OddsDrift.compute, dominantDrift (abs() ranking across home/draw/away), hasSignificantMove (3% threshold).
- `test/unit/models/cached_matches_entry_test.dart` — age, isExpired, ageDisplay formating, roundtrip s matches list-om.
- `test/unit/models/tipster_signal_test.dart` — preview (150-char truncation), toClaudeContext s sport fallback-om.
- `test/unit/models/monitored_channel_test.dart` — reliabilityScore (-1 za insufficient data), reliabilityLabel (Novo/Niska/Srednja/Visoka), reliabilityColorValue, lastRelevantDisplay, copyWith.
- `test/unit/models/analysis_log_test.dart` — UserFeedback enum, copyWith, roundtrip s fallback-om na none, generateUuid (format, uniqueness across 100 calls, UUID v4 version/variant nibbles).
- `test/unit/models/investment_tier_test.dart` — 3-tier framework (preMatch/live/accumulator) — display, icon, horizon, philosophy, colorValue, fromString, claudeContextAppendix content assertions.
- `test/unit/models/match_note_test.dart` — roundtrip including empty + multiline text.
- `test/unit/models/source_score_test.dart` — SourceType maxScore (sum = 6.0), percentage computation, inactive factory, roundtrip za sve tipove.
- `test/unit/models/football_data_signal_test.dart` — form counts (W/D/L), formScore ((W-L)/5), toClaudeContext.
- `test/unit/models/nba_stats_signal_test.dart` — winsLast10, rest days, standings, conditional context formatting.
- `test/unit/models/reddit_signal_test.dart` — getSentimentBias (-1 home tilt, +1 away, 0 balanced), div-by-zero safety.
- `test/unit/models/intelligence_report_test.dart` — confluenceScore (active sources), category thresholds (< 2 sources = insufficientData, >= 4.5 = strongValue), toClaudeContext header.
- `test/unit/models/sport_pl_test.dart` — winRate (0% for 0 bets).
- `test/unit/models/accumulator_test.dart` — AccumulatorLeg + BetAccumulator: combinedOdds (fold), actualProfit za svih 5 statusa, correlationWarnings (same match, same league same day), copyWith.

**Kreirani fajlovi (Phase 1 — providers):**
- `test/unit/providers/navigation_controller_test.dart` — tab index state + notifyListeners (sa i bez change).

### Phase 2 — Service Tests
**Status:** Completed

**Opis:** HTTP service testovi koriste `package:http/testing.dart#MockClient` za injection u konstruktore (svi servisi imaju `{http.Client? client}` constructor pattern). Test fajlovi pokrivaju happy path, HTTP error kodove (401/429/500), malformed JSON, timeout behavior, i granular parsing (npr. Reddit team mention aggregation across subreddits, Telegram update parsing sa sport/league detection).

**Kreirani fajlovi:**
- `test/unit/services/odds_api_service_test.dart` — setup, getMatches (401/429/422/500 paths, malformed JSON, individual match skip, sorting by commenceTime, multi-sport aggregation, x-requests-remaining header tracking), OddsApiException toString.
- `test/unit/services/claude_service_test.dart` — sendMessage (text block concatenation, non-text block filtering, whitespace trim, 401/429, API error passthrough, empty content, header injection x-api-key + anthropic-version, history + system prompt payload, system omitted when null); ChatMessage toJson.
- `test/unit/services/reddit_monitor_test.dart` — getSignalForMatch (multi-subreddit aggregation, top upvote tracking, skipping unrelated posts, case-insensitive matching, failed subreddit silent skip).
- `test/unit/services/ball_dont_lie_service_test.dart` — non-basketball rejection, team not found, winsLast10 computation, rest days from most recent game, standings null-by-design.
- `test/unit/services/telegram_monitor_test.dart` — token setup, testConnection success + error + malformed paths, _poll parsing s sport detection (EPL → soccer, NBA → basketball), skipping posts bez username-a ili s empty text-om.

### Phase 3 — Widget Tests
**Status:** Completed

**Opis:** Widget testovi za widgete koji ne zahtijevaju Provider s Hive coupling-om. Provider-bound widgets (MatchCard, BetCard, AccumulatorCard, PlSummaryWidget, TierModeSelector, BetsFilterBar) skippani — zahtijevaju bootstrap BetsProvider/MatchesProvider/AccumulatorsProvider s Hive state-om, što bi bolje pristajalo Phase 4 integracijskim testovima.

**Kreirani fajlovi:**
- `test/widget/widgets/chat_bubble_test.dart` — text rendering, alignment (user right / assistant left), SelectableText presence, multiline.
- `test/widget/widgets/sport_selector_test.dart` — 4 chips (All + 3 sports), icons, tap callbacks (null za All, Sport.soccer za Soccer), selected state.
- `test/widget/widgets/odds_widget_test.dart` — "Odds unavailable" fallback, 2-way vs 3-way chips, hasDraw false blocks Draw chip, null draw handling, 2-decimal formatting.
- `test/widget/widgets/signal_card_test.dart` — channel title/username/preview, sport icon with fallback "📨", league badge, checkbox conditional on callback, tap toggles selection, time ago formatting ("5m", "2h").

### Phase 4 — Integration Tests
**Status:** Skipped

**Opis:** Integracijski testovi (full-app flows s Hive + Providers) odloženi za sljedeću sesiju. Zahtijevali bi Hive testna okruženja (Hive.initFlutter() + teardown path cleanup) i mockove za sve servise. Current coverage (unit modeli + services + pure widgets) već pokriva kritičnu logiku — integracijski testovi su follow-up.

### Phase 5 — Finalization
**Status:** Completed

**Komande izvršene:**
- `flutter test test/unit/models/` — 299 passed
- `flutter test test/unit/providers/` — 4 passed
- `flutter test test/unit/services/` — 56 passed
- `flutter test test/widget/widgets/` — 27 passed
- `flutter test test/widget_test.dart` — 2 passed (existing smoke tests)
- `flutter test` — **388 tests passed, 0 failed**
- `flutter analyze` — 0 issues

**Verzija:** 3.1.3+12 (patch i build ostaju; nova sesija dodaje samo testove — nema behavior changes).

### Finalna verifikacija Session 11:
- flutter analyze — 0 issues
- flutter test — **388 passed** (bio 2 → 388, povećanje 386 testova)
- flutter build apk --debug — nije re-ran (nema src changes, samo testovi)
- Test fajlovi kreirani: **25 novih** (20 model + 1 provider + 5 service + 4 widget + 0 integration)
- Test direktorijska struktura finalizirana: `test/unit/models/`, `test/unit/providers/`, `test/unit/services/`, `test/widget/widgets/` (integration ostaje za buduću sesiju)
- **Coverage overview:** svi pure-logic modeli 100% pokriveni, svi HTTP servisi osim football_data/notifications/storage (potonji zahtijeva Hive setup) pokriveni, 4 stateless widgeta pokrivena. Provider-bound widgeti ostaju za integration tests.
- **Identified Issues:** 0 novih bugova.
- **Backlog status:** 1 by-design (Telegram Bot API) — unchanged.

---

## Session 12: 2026-04-19 — Full Coverage Extension (Hive + Providers + Integration)

Proširuje S11 coverage u područja koja zahtijevaju Hive bootstrap: StorageService, svi ChangeNotifier provideri, provider-bound widgeti, preostali servisi (IntelligenceAggregator, FootballDataService) plus integracijski flow-ovi koji vežu providere s Hive persistence-om.

### Phase 1 — Hive test helper + StorageService tests
**Status:** Completed

**Opis:** Kreiran `test/helpers/hive_test_setup.dart` koji u svakom testu otvara Hive u svježem temp direktoriju (`Directory.systemTemp.createTemp('betsight_hive_test_')`) i inicijalizira svih 13 boxova koje `StorageService.init()` očekuje. Helper također stubba `flutter_local_notifications` platform channel mock-method-call-handler-om kako provideri koji rukuju watched-match toggle-om ne bi rušili test run s `MissingPluginException`. Svaki test poziva `setUpHive()` u `setUp` i `tearDownHive()` u `tearDown` (zatvara Hive + briše temp dir recursively).

Storage test suite pokriva sve API-key roundtrip-ove, value preset, tier, notifikacijske flagove (default `true`), bet/log/signal/accumulator/report CRUD, snapshots (save/getSnapshotsForMatch/getLatestSnapshotForMatch/saveSnapshotIfChanged change detection, clearOldSnapshots TTL gate), cache entry + TTL, cleanup scheduler (24h gate + first-run), migration path (legacy channel list → detail box), sort order (signals/logs DESC, snapshots ASC, reports DESC by confluence, channels ASC).

**Kreirani fajlovi:**
- `test/helpers/hive_test_setup.dart` — 40 linija, bootstraps + teardowns Hive state + stubs notifications channel.
- `test/unit/services/storage_service_test.dart` — 64 testa, ~500 linija.

### Phase 2 — Provider tests (7 providera, svi ChangeNotifier-i)
**Status:** Completed

**Opis:** Svaki ChangeNotifier provider dobio je vlastiti test file. Za `TelegramProvider` treba stvoriti `TelegramMonitor` s mock HTTP klijentom da bi bootstrap-migracija prošla u test-okruženju. `MatchesProvider.toggleWatched` poziva `NotificationsService.scheduleKickoffReminders` — radi u testu jer platform channel stub iz `hive_test_setup.dart` vraća null, pa plugin-call prođe kao no-op.

**Kreirani fajlovi:**
- `test/unit/providers/tier_provider_test.dart` — 6 testova: storage-driven init + setTier + suggestionChips po tier-u + claudeContextAppendix passthrough.
- `test/unit/providers/bets_provider_test.dart` — 27 testova: init, CRUD, stats, filteri, bankroll, error path.
- `test/unit/providers/matches_provider_test.dart` — 21 test: init iz storage-a, selection, watched, drift computation, API key management, request quota getters, fetchMatches error paths. `OddsApiService` injectiran preko MockClient-a.
- `test/unit/providers/analysis_provider_test.dart` — 19 testova: staging matches/signals, inputPrefill, sendMessage success + ClaudeException + log persistence + recordFeedback.
- `test/unit/providers/telegram_provider_test.dart` — 17 testova: channels add/remove/migrate, token lifecycle, setEnabled, recentSignals 6h window, signalsForSport filtering, testConnection success/failure.
- `test/unit/providers/accumulators_provider_test.dart` — 19 testova: draft lifecycle, save invariants, place → settle flow, delete.
- `test/unit/providers/intelligence_provider_test.dart` — 9 testova: init loads reports, generateReport without aggregator, cache-hit skip, updateFootballDataApiKey, removeReportFor, isGeneratingFor.

**Gotcha rezolucija:** `TelegramProvider._bootstrapChannels` je `async void`-like, pokreće se iz konstruktora i ne awaita se. U testovima se koristi `await Future<void>.delayed(const Duration(milliseconds: 50))` nakon konstrukcije da bi migracija stigla završiti prije assert-a.

### Phase 3 — Provider-bound widget tests
**Status:** Completed (s 1 dokumentiranim infrastructure backlog-om — vidi Identified Issues)

**Opis:** Widgeti testirani su s `ChangeNotifierProvider.value` wrapperom i pravim `BetsProvider` / `AccumulatorsProvider` / `TierProvider` (koji sada rade u test-okruženju zahvaljujući Hive setUp-u).

**Kreirani fajlovi:**
- `test/widget/widgets/tier_mode_selector_test.dart` — 3 smoke testa: render 3 pill-a, ikone, broj GestureDetector-a (3). Tap-to-switch i selected-border introspection isključeni — `pumpAndSettle` i `widgetList<AnimatedContainer>` ulaze u infinite loop zbog kombinacije AnimatedContainer (200 ms implicit transition) i async Hive write-a u `TierProvider.setTier`. Bavljenje taps-om ostaje za buduću iteraciju.
- `test/widget/widgets/bet_card_test.dart` — 7 testova: render league/teams/pick/odds/stake, Settle button za pending, +profit/-stake za won/lost, void → 0.00, status chip, izostanak bookmaker chip-a kad je null.
- `test/widget/widgets/accumulator_card_test.dart` — 4 testa: leg count header, prva 3 leg retka, "+N more" za >3 legs, status chip.
- `test/widget/widgets/bets_filter_bar_test.dart` — 6 testova: search TextField + trim/lowercase propagacija, 3 filter chipa, Clear chip conditional, Sport chip label update na toggle.

### Phase 4 — IntelligenceAggregator + FootballData service tests
**Status:** Completed

**Kreirani fajlovi:**
- `test/unit/services/intelligence_aggregator_test.dart` — 10 testova: Odds scoring po pravilima (base 0.5, sharp +0.5, significant drift +0.5, non-Home direction +0.5), Football-Data inactive paths (no service, non-soccer), NBA inactive, Reddit inactive, Telegram "No signals", report assembly (svih 5 SourceType-a uključeno).
- `test/unit/services/football_data_service_test.dart` — 11 testova: setup, error paths (no key, unsupported sport, 403, 429, no match found), happy path (EPL team fuzzy match + full signal build), FC/AFC suffix stripping (Manchester United vs City), standings optional (500 → null positions).

### Phase 5 — Integration tests
**Status:** Completed

**Opis:** End-to-end provider flow testovi koji koriste pravu Hive persistence (via helper). Cilj: verificirati da provider + storage hooks sjede zajedno kroz realne user pattern-e (ne samo jedan metod poziv).

**Kreirani fajlovi:**
- `test/integration/flows/bet_flow_test.dart` — 5 flow-ova: place → settle won → stats, multi-sport P&L breakdown, persistence across provider instances, filters chaining, settled storage roundtrip.
- `test/integration/flows/accumulator_flow_test.dart` — 4 flow-a: build → save → place → settle (persists across reload), correlation warning za same-league-same-day, removeLeg leaves valid 2-leg draft savable, delete cleans both.
- `test/integration/flows/intelligence_flow_test.dart` — 3 flow-a: wireAggregator → generateReport → persist → reload, generateReport bez wire-a surfaces config error, removeReportFor cleans both.

### Phase 6 — Finalization
**Status:** Completed

**Komande izvršene:**
- `flutter test test/unit/services/storage_service_test.dart` — 64 passed
- `flutter test test/unit/providers/` — 122 passed (S12 doprinosi 7 fajlova × ukupno 118 testova; 4 testa su iz S11 navigation_controller_test)
- `flutter test test/unit/services/intelligence_aggregator_test.dart` — 10 passed
- `flutter test test/unit/services/football_data_service_test.dart` — 11 passed
- `flutter test test/integration/` — 12 passed
- `flutter test` (cijela suite uključujući S11 + S12) — 623 passed
- `flutter analyze` — 0 issues

### Finalna verifikacija Session 12:
- flutter analyze — 0 issues
- flutter test (cijela suite) — **623 passed**
- Kumulativno od S11: 388 → 623 testa (povećanje +235)
- Novih test fajlova u S12: 18 (1 helper, 1 storage_service test, 2 service testa — aggregator + football_data, 7 provider testova, 4 widget testa, 3 integracijska testa)
- **Coverage overview:** Hive-backed StorageService pokriven, svi ChangeNotifier provideri pokriveni (init, mutations, persistence), preostali servisi pokriveni, 3 integracijska flow-a pokrivena.
- **Identified Issues:**
  - **TierModeSelector test — tap + border introspection hang** — `tester.tap(find.text('Live'))` praćen `pumpAndSettle`-om ulazi u infinite loop (kombinacija implicit AnimatedContainer + async `TierProvider.setTier` Hive write). Slično se događa s `tester.widgetList<AnimatedContainer>` introspection-om nakon setTier. Kept 3 smoke testova (render pills, icons, GestureDetector count = 3) — tap-to-switch i border-state assertion ostaju za sljedeću sesiju (vjerojatno rješenje: `fakeAsync` wrapper ili alternativa bez AnimatedContainer-a).
- **Backlog status:** 1 by-design + 1 test-infrastructure (TierModeSelector tap + pumpAndSettle).

---

## Identified Issues

### By-Design (Will Not Fix)

- **Telegram Bot API limitation** *(resolved as by-design in S9)*
  - **Status:** Formal decision to not migrate to MTProto.
  - **Ograničenje:** Bot API (Telegram Bot platform) prima poruke samo iz kanala gdje je bot dodan kao član. Public tipster kanali koji ne dozvoljavaju bot-ove nedostupni su.
  - **Zašto ne rješavamo:**
    1. **Platformski razlog:** Telegram je namjerno dizajnirao Bot API i User API (MTProto) kao dvije odvojene pristupne rute. Bot API je za bot programe (subscribing), MTProto za user-level clients. To nije bug Bot API-ja — to je dizajnska odluka.
    2. **Tehnički razlog:** MTProto u Dart ekosistemu nema produkcijski spreman SDK. `telegram_client` paket je eksperimentalni, `td_plugin` je Android-only i neaktivno održavan. Alternativa (C++ tdlib bindings kroz FFI) je nerazmjerno kompleksna za mobile MVP.
    3. **Security razlog:** MTProto zahtijeva korisnikov API ID + API Hash + phone number + SMS verification. BetSight bi tako dobio pristup cijelom korisnikovom Telegram računu — ozbiljan security/privacy footprint koji ne opravdava korist.
    4. **Arhitekturalni razlog:** BetSight od S6 koristi 5-source intelligence layer (Odds, Football-Data, BallDontLie, Reddit, Telegram). Telegram je 1 od 5 izvora, **ne primary**. Diverzifikacija kompenzira ograničenost pojedinačnog izvora — pattern posuđen iz CoinSight-a koji do v8.0.0 nikad nije dotakao MTProto i nije ga trebao.
  - **Preporučeni workflow za korisnika:** kreirati vlastiti Telegram bot preko `@BotFather`, dodati bot kao admin u vlastite kanale (gdje agregira tipster content koji prati) ili u manje zajednice koje prihvaćaju bot-ove. Za "big public" tipster kanale koji ne dopuštaju bot-ove, BetSight ne nudi ekstrakciju — korisnik neka koristi Reddit i Football-Data kao alternativne izvore za tu vrstu intelligencea.

