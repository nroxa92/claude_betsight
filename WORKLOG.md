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

## Identified Issues

- **Telegram Bot API limitation:** Bot prima poruke samo iz kanala gdje je dodan kao član. Public tipster kanali koji ne dozvoljavaju bot-ove nisu dostupni kroz Bot API. Za full public channel access trebala bi MTProto migracija u kasnijoj sesiji.

