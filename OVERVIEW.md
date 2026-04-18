# BetSight Overview

**Verzija:** 3.1.2+11
**Datum:** 2026-04-18
**Opseg:** Arhitekturalni dokument — tehnicki overview cijelog projekta

---

## 0. Svrha ovog dokumenta

Ovaj dokument sluzi dvjema publikama:

1. **Razvojnom timu (samo ti, u buducnosti)** — kad za 6 mjeseci budes zaboravio detalje S6 Intelligence Aggregator scoring logike ili zasto je `BetAccumulator` renamed u S9, ovaj dokument ti je referentnu tocku.

2. **Novim developerima/contributorима** — koji zele razumjeti arhitekturu prije contribute-anja ili fork-anja.

Dokument je **chronoloski organiziran** po development sesijama (S1 kroz S10). Svaka sesija dokumentira svoj opseg, odluke i rezultat. Uz to, sekcije 2 (stack) i 14 (final overview) sumiraju trenutno stanje v3.1.2.

---

## 1. Sto je BetSight

### 1.1 Kratki opis

BetSight je **Flutter Android aplikacija** za sportsko kladenje analizu. Tri sporta (soccer, basketball, tennis) kroz tri tier-a (PRE-MATCH / LIVE / ACCUMULATOR). 5 izvora intelligence-a (Odds API, Football-Data, BallDontLie NBA, Reddit, Telegram). Claude AI kao analiticar s VALUE/WATCH/SKIP markerima. Lokalni bet tracking u Hive bazi.

### 1.2 Core value proposition

Razlika od:
- **Kladionica:** ne prihvaca uplate, nije match engine
- **Generalnih AI alata (ChatGPT):** specijaliziran sistem prompt + automatski context injection iz 5 izvora
- **Tipster kanala:** ne servera samo preporuke, nego daje framework za vlastitu disciplinu (BETLOG, per-sport tracking)
- **Excel sheet trackera:** integracija s live kvotama + AI analizom + automatskom drift detekcijom

### 1.3 Sto BetSight NIJE i nece biti

- **Nije kladionica** — ne prihvaca uplate, nema payment processing
- **Nije auto-trading** (kao CoinSight-ov Binance integration) — kladjenje ostaje manualno kod kladionice
- **Nece imati MTProto** (full Telegram user API) — security + technical razlozi, vidi [WORKLOG.md](WORKLOG.md) by-design section
- **Nece integrirati exchange markete** (Betfair Exchange) u doglednoj buducnosti — API cost + legal complexity

---

## 2. Stack, arhitektura, ovisnosti

### 2.1 Tech stack

| Sloj | Tehnologija | Verzija |
|------|-------------|---------|
| Framework | Flutter | 3.41+ |
| Language | Dart | 3.11+ |
| State management | Provider (ChangeNotifier pattern) | 6.1 |
| Local storage | Hive (NoSQL) | 2.2.3 |
| HTTP client | http | 1.4 |
| Charts | fl_chart | 0.69 |
| Notifications | flutter_local_notifications | 18.0 |
| Timezone | timezone | 0.10 |
| i18n | intl | 0.20 |
| Platform | Android (primarno) + Windows (dev build) | - |

### 2.2 Struktura fajlova (`lib/`)

```
lib/
├── main.dart                             # Entry + MultiProvider + MainNavigation
├── models/                               # Data modeli + ChangeNotifier provider-i
│   ├── accumulator.dart                  # BetAccumulator + AccumulatorLeg + AccumulatorStatus (S7, renamed S9)
│   ├── accumulators_provider.dart        # Provider za acca drafts i settled list (S7)
│   ├── analysis_log.dart                 # AnalysisLog + UserFeedback + generateUuid (S3, enhanced S5.5)
│   ├── analysis_provider.dart            # ChangeNotifier: Claude chat + system prompt + context injection (S1, +6 enhancements)
│   ├── bankroll.dart                     # BankrollConfig (S3)
│   ├── bet.dart                          # Bet + BetSelection + BetStatus + isLiveBet (S3, +matchStartedAt S8)
│   ├── bets_provider.dart                # Bets + filter state + per-sport breakdown (S3, +S8 enhancements)
│   ├── cached_matches_entry.dart         # CachedMatchesEntry (Odds API cache) (S5)
│   ├── football_data_signal.dart         # FD signal (form+H2H+standings) (S6)
│   ├── intelligence_provider.dart        # Intelligence reports + auto-refresh + FD re-wire (S6, +S8)
│   ├── intelligence_report.dart          # IntelligenceReport + category (S6)
│   ├── investment_tier.dart              # InvestmentTier enum + claudeContextAppendix (S7)
│   ├── match.dart                        # Match + H2HOdds + isLive + toMap/fromMap (S1, +S5)
│   ├── match_note.dart                   # MatchNote (user notes on match) (S7)
│   ├── matches_provider.dart             # Matches + watched + filter + cache + rate limit (S1, +6 evolutions)
│   ├── monitored_channel.dart            # Channel reliability scoring (S5.5)
│   ├── navigation_controller.dart        # Tab switching state (S2)
│   ├── nba_stats_signal.dart             # NBA signal (last10 + rest days) (S6)
│   ├── odds.dart                         # H2HOdds (S1)
│   ├── odds_snapshot.dart                # OddsSnapshot + OddsDrift (S4)
│   ├── recommendation.dart               # RecommendationType enum + parser (S2)
│   ├── reddit_signal.dart                # RedditSignal (mentions + sentiment) (S6)
│   ├── source_score.dart                 # SourceScore + SourceType enum (S6)
│   ├── sport.dart                        # Sport enum + SportMeta extension (S1)
│   ├── sport_pl.dart                     # Per-sport P&L breakdown (S8)
│   ├── telegram_provider.dart            # Telegram signals + channels + monitoring (S4, +S5.5)
│   ├── tier_provider.dart                # Current tier state (S7)
│   ├── tipster_signal.dart               # TipsterSignal (parsed Telegram message) (S4)
│   └── value_preset.dart                 # ValuePreset enum (Conservative/Standard/Aggressive) (S2)
├── screens/                              # UI screen widgets
│   ├── accumulator_builder_screen.dart   # Leg picker + correlation warnings (S7)
│   ├── analysis_screen.dart              # Claude chat UI (S1, +signal/trade/tier UI)
│   ├── bets_screen.dart                  # Bets list tier-aware + filter bar (S3, +S5+S7+S8)
│   ├── bot_manager_screen.dart           # Telegram channels management (S5.5)
│   ├── intelligence_dashboard_screen.dart # Per-match confluence + source breakdown (S6)
│   ├── match_detail_screen.dart          # 4 tabs: Overview/Intel/Charts/Notes (S7)
│   ├── matches_screen.dart               # Matches list tier-aware + filter (S1, +multi evol)
│   └── settings_screen.dart              # 9 sections (API keys + preferences + notif + telegram) (S1, heavy evol)
├── services/                             # External API + Storage
│   ├── ball_dont_lie_service.dart        # NBA API (besplatan) (S6)
│   ├── claude_service.dart               # Anthropic API client (S1)
│   ├── football_data_service.dart        # FD API client + token fuzzy match (S6, S8 improved)
│   ├── intelligence_aggregator.dart      # Scoring engine (5 sources → 6.0 confluence) (S6)
│   ├── notifications_service.dart        # Push notif wrapper + per-type gates (S7, +S8)
│   ├── odds_api_service.dart             # Odds API client + cached variant (S1, +S5)
│   ├── reddit_monitor.dart               # Reddit JSON scanner (S6)
│   ├── storage_service.dart              # Hive wrapper — 13 boxes + cleanup jobs (S1, heavy evol)
│   └── telegram_monitor.dart             # Bot API polling (S4, +S5.5)
├── theme/
│   └── app_theme.dart                    # Dark theme + constants (S1)
└── widgets/                              # Reusable UI components
    ├── accumulator_card.dart             # BetAccumulator kartica (S7, renamed S9)
    ├── bet_card.dart                     # Bet kartica + Dismissible (S3)
    ├── bet_entry_sheet.dart              # Manual bet entry modal (S3)
    ├── bets_filter_bar.dart              # Search + filter chips (S8)
    ├── charts/
    │   ├── equity_curve_chart.dart       # Cumulative P&L line chart (S7)
    │   ├── form_chart.dart               # W/D/L bar sequence (S7)
    │   ├── odds_movement_chart.dart      # Odds drift line chart (S7)
    │   └── tennis_info_panel.dart        # Tennis placeholder s odds info (S9)
    ├── chat_bubble.dart                  # Claude/user message bubble (S1)
    ├── match_card.dart                   # Match kartica + star toggle (S1, +drift S4)
    ├── odds_widget.dart                  # 2-3 odds chips (S1)
    ├── pnl_summary.dart                  # P&L metrics + equity + per-sport (S3, +S7 +S8)
    ├── signal_card.dart                  # TipsterSignal kartica (S4)
    ├── sport_selector.dart               # Sport filter chips (S1)
    ├── tier_mode_selector.dart           # Global tier switcher (S7)
    └── trade_action_bar.dart             # LOG BET/SKIP/ASK MORE za VALUE response (S5.5)
```

**Ukupno:** 64 Dart fajla, ~11500 linija.

### 2.3 Dependency graph (simplified)

```
MainNavigation (StatefulWidget)
  ├─ TierProvider ──────────────────── (used by all screens + AnalysisProvider for context)
  ├─ NavigationController ──────────── (IndexedStack index)
  ├─ MatchesProvider ─────────────────┐
  │    └─ OddsApiService               │
  │    └─ StorageService (cache, watched, snapshots)
  ├─ AnalysisProvider                  │
  │    └─ ClaudeService                │
  │    └─ StorageService (logs, reports for context)
  ├─ BetsProvider                      │
  │    └─ StorageService (bets, bankroll)
  ├─ AccumulatorsProvider              │
  │    └─ StorageService (accumulators)
  ├─ TelegramProvider                  │
  │    └─ TelegramMonitor              │
  │    └─ StorageService (channels, signals, token)
  └─ IntelligenceProvider              │
       └─ IntelligenceAggregator ──────┤
            ├─ OddsApiService          │
            ├─ FootballDataService     │
            ├─ BallDontLieService      │
            ├─ RedditMonitor           │
            └─ TelegramProvider ───────┘ (reads, doesn't own)

StorageService (singleton static class)
  └─ Hive (13 boxes)
       ├─ settings (API keys, prefs)
       ├─ analysis_logs
       ├─ bets
       ├─ accumulators
       ├─ tipster_signals
       ├─ monitored_channels_detail
       ├─ odds_snapshots
       ├─ odds_cache
       ├─ intelligence_reports
       ├─ football_signals_cache
       ├─ nba_signals_cache
       ├─ reddit_signals_cache
       └─ match_notes
```

### 2.4 Providers (state management)

| Provider | State drzi | Ključne metode |
|---|---|---|
| **TierProvider** | currentTier (InvestmentTier enum) | setTier, claudeContextAppendix, suggestionChips |
| **NavigationController** | currentIndex (int 0-3) | setTab |
| **MatchesProvider** | allMatches, watched, selectedSport, filter, cache state, rate limit | fetchMatches(forceRefresh), toggleWatched, driftForMatch, setValuePreset |
| **AnalysisProvider** | messages, stagedMatches, stagedSignals, lastLogId, inputPrefill | sendMessage, recordFeedback, setInputPrefill, stageSelectedMatches |
| **BetsProvider** | allBets, bankroll, filters (sports/statuses/date/search) | addBet, settleBet, deleteBet, setBankroll, perSportBreakdown, applyFilters |
| **AccumulatorsProvider** | accumulators, currentDraft | startNewDraft, addLegToDraft, saveDraftAsAccumulator, settleAccumulator |
| **TelegramProvider** | signals, channels (MonitoredChannel list), enabled, monitor instance | addChannel, removeChannel, setEnabled, testConnection |
| **IntelligenceProvider** | reports map, generatingFor set, autoRefreshTimer, service refs | generateReport, refreshAllWatched, startAutoRefresh, updateFootballDataApiKey |

### 2.5 Hive box-ovi

| Box | Sadrzaj | Key pattern |
|---|---|---|
| `settings` | API keys, preferences, current tier, cache TTL, bankroll, notif flags | field names (npr. `anthropic_api_key`, `current_tier`, `cache_ttl_minutes`) |
| `analysis_logs` | AnalysisLog zapisi (prompt calibration) | id (UUID) |
| `bets` | Bet zapisi | id (UUID) |
| `accumulators` | BetAccumulator zapisi | id (UUID) |
| `tipster_signals` | TipsterSignal zapisi | id (UUID) |
| `monitored_channels_detail` | MonitoredChannel s reliability stats | username (`@channel`) |
| `odds_snapshots` | OddsSnapshot zapisi | `matchId_ISOtimestamp` |
| `odds_cache` | CachedMatchesEntry | fixed key `all_matches` |
| `intelligence_reports` | IntelligenceReport zapisi | matchId |
| `football_signals_cache` | FootballDataSignal cache | matchId |
| `nba_signals_cache` | NbaStatsSignal cache | matchId |
| `reddit_signals_cache` | RedditSignal cache | matchId |
| `match_notes` | MatchNote zapisi | matchId |

### 2.6 External APIs

| API | Svrha | Free tier | Rate limit |
|-----|-------|-----------|------------|
| **Anthropic Claude** | AI analiza | Per-tokens pricing | 1000 req/min |
| **The Odds API** | Kvote za sve sportove | 500 req/mj | ~60 req/min |
| **Football-Data.org v4** | Form, H2H, standings (soccer) | Neograniceno mj | 10 req/min |
| **BallDontLie** | NBA statistike | Neograniceno | No enforced |
| **Reddit public JSON** | Community sentiment | 60 req/h (unauth) | Strict |
| **Telegram Bot API** | Tipster signali (channel member) | Neograniceno | ~30 msg/s |

---

## 3. Session 1 — Scaffold + Odds API + Matches + Claude + Hive + Polish

**Verzija:** 1.0.0+1
**Datum:** 2026-04-18 (ponedjeljak)
**Scope:** 5 faza + Post-Phase

### Kontekst
Projektni scaffold. Nothing existed.

### Ciljevi
- Flutter scaffold s 3 taba (Matches/Analysis/Settings)
- Dark tema (primary #6C63FF, surface #1E1E1E)
- Odds API v4 integracija za 3 sporta (soccer, basketball, tennis)
- Claude API chat UI s match context injection
- Hive lokalna persistencija API kljuceva
- Polish (skeletons, animations, error bars)
- LICENSE, README, .gitignore, Runner.rc branding, tests

### Kreirani fajlovi (17 Dart)
- Entry: `main.dart`
- Models: `sport`, `odds`, `match`, `matches_provider`, `analysis_provider`
- Services: `odds_api_service`, `claude_service`, `storage_service`
- Widgets: `match_card` (+skeleton), `odds_widget`, `sport_selector`, `chat_bubble`
- Screens: `matches_screen`, `analysis_screen`, `settings_screen`
- Theme: `app_theme`

### Ključne arhitekturalne odluke
- **State management:** Provider pattern (ne BLoC, ne Riverpod) — kompatibilnost s CoinSight-om
- **Local storage:** Hive (performantno, lakše od sqflite)
- **Sport enum** kao osnova: `soccer`, `basketball`, `tennis`
- **H2HOdds model** za standard decimal odds + bookmaker margin calculation
- **IndexedStack** u MainNavigation (state-preserving tab switching)

### Rezultat
- v1.0.0+1
- 2/2 tests passed
- APK buildan (ne pushnut u repo)

---

## 4. Session 2 — Value Bets + Markers + Logging + Android + Match Selection

**Verzija:** 1.1.0+2
**Scope:** 5 taskova

### Ciljevi
- Value Bets filter s 3 preseta (Conservative / Standard / Aggressive)
- VALUE/WATCH/SKIP markeri u Claude prompt + parser
- AnalysisLog Hive logging svake Claude preporuke
- Prvi Android APK
- Match selection → Analysis staging

### Kreirani fajlovi (4)
- `value_preset.dart` (enum s marginMax/oddsMin/Max/spreadMax)
- `recommendation.dart` (RecommendationType enum + `parseRecommendationType`)
- `analysis_log.dart` (UUID + toMap/fromMap)
- `navigation_controller.dart` (provider za tab switching)

### Ključne odluke
- Value preset **deterministicki filter**, ne ML — transparent kriteriji
- Marker parser ide line-by-line pa fallback inline — specificnost VALUE>WATCH>SKIP
- Svi Claude odgovori se **auto-log-iraju** (source of truth za kalibraciju)
- Match selection state na MatchesProvider (not NavigationController)

### Rezultat
- v1.1.0+2
- Prvi APK (142M)
- Backlog: 0

---

## 5. Session 3 — Bet Tracking + Manual Entry + Settlement + Bankroll

**Verzija:** 1.2.0+3
**Scope:** 5 taskova

### Ciljevi
- Prvi "financial" entity: Bet model
- BetsProvider s openBets / settledBets filter-ima + P&L kalkulacije
- BetEntrySheet (bottom sheet) + Bets screen s tabs
- Settlement flow (Won/Lost/Void)
- Bankroll management u Settings
- PlSummaryWidget (4 metrics)

### Kreirani fajlovi (7)
- `bet.dart` (BetSelection enum, BetStatus, copyWith)
- `bankroll.dart` (BankrollConfig)
- `bets_provider.dart`
- `bets_screen.dart`
- `bet_card.dart`
- `bet_entry_sheet.dart`
- `pnl_summary.dart`

### Ključne odluke
- Bet model **design-first** — svi P&L getter-i (actualProfit, impliedProbability) na modelu
- Settlement preko **bottom sheet-a** (ne dialoga) — modern UX
- BankrollConfig **u settings boxu** (ne poseban box) — logički pripada u preferences
- FAB za manual bet entry + "Log Bet" u Analysis (dva ulaza)

### Rezultat
- v1.2.0+3
- 4. tab **Bets** dodan
- Settings moved s indeksa 2 na 3

---

## 6. Session 4 — Telegram Tipster Monitor + Odds Snapshot Engine

**Verzija:** 1.3.0+4
**Scope:** 5 taskova (Telegram + bonus Snapshot)

### Ciljevi
- TipsterSignal model + TelegramMonitor service (polling getUpdates)
- Keyword filter (tip/bet/value/odds/pick/...)
- Heuristic sport/league detection iz poruke
- TelegramProvider s dedup + channel filter
- Settings sekcija za token + channel management
- Signal UI u Analysis (banner + sheet + staged bar)
- Bonus: Odds Snapshot Engine (watched matches → snapshot pri fetchu → drift indicator)

### Kreirani fajlovi (5)
- `tipster_signal.dart`
- `telegram_monitor.dart` (Bot API polling s silent-fail retry)
- `telegram_provider.dart`
- `odds_snapshot.dart` (+ OddsDrift klasa)
- `signal_card.dart`

### Poznato ogranicenje zabilježeno
**Telegram Bot API limitation:** Bot može primati poruke samo iz kanala gdje je dodan kao član. Nije bug, dizajnerska odluka Telegrama.

### Ključne odluke
- **Polling** (ne webhook) — jednostavno, rade uvijek, radi bez cloud-a
- **Keyword filter** namjerno široki (false positive bolji od false negative)
- **Snapshot kljuc pattern** `matchId_ISOtimestamp` — omogucuje key-prefix scan po match-u

### Rezultat
- v1.3.0+4
- Prvi APK s Telegram integration

---

## 7. Session 5 — Infrastructure Hardening

**Verzija:** 1.3.1+5 (patch)
**Scope:** 5 taskova

### Ciljevi
- Odds API cache layer (TTL, force-refresh, badge UI)
- Rate limit tracking + UI warning (progress bar, banneri, hard-stop)
- Snapshot deduplication (saveSnapshotIfChanged)
- Scheduled cleanup jobs (24h gate, brise signals >7d + snapshots >7d + cache >24h)
- Error handling audit + polish (SnackBar consistency, dispose chain, doc comments)

### Kreirani fajlovi (1)
- `cached_matches_entry.dart` (+ Match.toMap/fromMap dodano)

### Ključne odluke
- Cache key fiksan `all_matches` (ne per-sport) — jedan entry pokriva sve
- Scheduled cleanup **gated** na 24h da ne troši CPU redundantno
- Free tier Odds API (500 req/mj) **must-have cache** — bez njega aplikacija neodrziva u 2 tjedna

### Rezultat
- v1.3.1+5
- Settings dobiva "Cache & Limits" sekciju s TTL chips

---

## 8. Session 5.5 FIX — Prompt Redesign + Trade Action Bar + Bot Manager + Context Enhancements

**Verzija:** 1.3.2+6 (fix)
**Scope:** 5 taskova

### Kontekst
S1-S5 su izgradili stabilan feature set, ali UX u dodirnim tockama nije bio "CoinSight level":
- Prompt je bio generic 28-line
- "Log Bet" je bio usamljen button
- Telegram kanali bili samo stringovi u listi (bez reliability)

### Ciljevi
- Claude prompt rewrite (40 lines, 5 sekcija: User profile, Objective 1-3, Constraints, Language)
- Trade Action Bar (LOG BET / SKIP / ASK MORE) + UserFeedback enum za calibration
- MonitoredChannel model s reliability scoring (Novo/Niska/Srednja/Visoka)
- BotManagerScreen (push route s stats header + add input + per-channel cards)
- [BETTING HISTORY] i [ODDS DRIFT] context blokovi u Claude prompt

### Kreirani fajlovi (3)
- `monitored_channel.dart`
- `bot_manager_screen.dart`
- `trade_action_bar.dart`
- **+ BETLOG.md** (user-facing template, ne Dart fajl)

### Ključne odluke
- Prompt redizajn ima **"Objective 3 — Recommendation"** sekciju s VALUE spec (mora navesti WHICH/WHICH/WHICH/concrete step)
- Trade Action Bar **samo ispod zadnje VALUE response** (ne kroz cijeli history chat-a)
- MonitoredChannel reliability threshold-i: 10 signals min / 0.1 / 0.3
- TelegramMonitor._parseUpdate vraca signal s `isRelevant: false` umjesto null (za stats update)

### Rezultat
- v1.3.2+6
- Prva sesija s explicit "CoinSight parity" ciljem

---

## 9. Session 6 — Multi-Source Intelligence Layer

**Verzija:** 2.0.0+7 (**major bump**)
**Scope:** 7 taskova (najveci do tada)

### Kontekst
Free tier Odds API (500/mj) = app neodrziva u 2-3 tjedna aktivnog koristenja. Diversifikacija izvora = preživjetevna nuznost. Analog CoinSight S6 Intelligence Layer.

### Ciljevi
- 5 source models (SourceScore, FootballDataSignal, NbaStatsSignal, RedditSignal, IntelligenceReport)
- IntelligenceProvider skeleton
- FootballDataService (10 req/min, fuzzy team match, 4-5 HTTP calls po meču)
- BallDontLieService (NBA only, bez API key-a)
- RedditMonitor (public JSON, mandatorni User-Agent header)
- IntelligenceAggregator (paralelni scoring sve 5 izvora → confluence 0-6.0)
- IntelligenceDashboardScreen + main.dart wire-up + Settings FD key sekcija

### Kreirani fajlovi (11)
- 5 models + 1 provider
- 4 services + 1 aggregator
- 1 screen

### Scoring formule
- Odds (2.0): base 0.5 + sharp(<5%) 0.5 + drift 0.5 + non-Home drift 0.5
- Football-Data (1.5): active 0.3 + strong form(≥4/5) 0.4 + H2H dominant(≥3/5) 0.4 + standings gap(≥8) 0.4
- NBA (1.0): active 0.3 + hot streak(≥7/10) 0.35 + rest diff(≥3) 0.35
- Reddit (1.0): active 0.2 + high buzz(≥10) 0.3 + sentiment tilt(>0.3) 0.3 + viral(≥500ups) 0.2
- Telegram (0.5): weighted sum × 0.25 (Visoka=1.0/Srednja=0.7/Niska=0.3/Novo=0.5)

### Ključne odluke
- **Major version bump (2.0.0)** jer je ovo fundamentalna transformacija iz single-source u multi-source platform
- **Cache TTL 3h per signal** (vs 15 min za Odds cache) — source signal je stabilniji
- **Scope:** samo watched matches — drastično smanjuje API call-ove (iz 50+ mecva na 2-5)
- **Hibrid refresh:** 1h Timer + on-demand button
- **Aggregator paralelan:** sve 5 scoring metoda kroz `Future.wait` — 5x brže nego serialno

### Rezultat
- v2.0.0+7
- 48 Dart fajla
- Identified Issues +6 (FD team fuzzy matching, auto-refresh wire, FD key restart, NBA scope...)

---

## 10. Session 7 — Three-Tier Framework + Charts + Push + Detail Screens

**Verzija:** 3.0.0+8 (**major bump**)
**Scope:** 10 taskova (najveci)

### Kontekst
Nakon S6 BetSight tretira sve mecve isto — jedan prompt, jedan value preset. Ali betting u stvarnosti ima tri pristupa (PRE-MATCH deep DYOR, LIVE reactive, ACCUMULATOR multi-bet). Analog CoinSight S8 (Three-Tier) + S9 (Charts + Push + Detail).

### Ciljevi
- InvestmentTier enum + TierProvider + 3 dependencies (fl_chart, flutter_local_notifications, timezone)
- TierModeSelector (global iznad svih screen-ova)
- Tier-aware Analysis (suggestion chips + prompt appendix)
- Accumulator model + provider + Builder screen (s correlation warnings)
- Tier-aware Bets screen (acca view vs regular view)
- 3 chart widgets (OddsMovement, Form, EquityCurve)
- MatchDetailScreen (4 tabs: Overview/Intel/Charts/Notes) + MatchNote
- NotificationsService (kickoff/drift/value alerts + Android desugaring)
- Tier-aware P&L + EquityCurve in PlSummary
- Polish + Settings Notifications sekcija + tests

### Kreirani fajlovi (13)
- 5 models (investment_tier, tier_provider, accumulator, accumulators_provider, match_note)
- 4 screens (acca_builder, match_detail, notifications setup)
- 4 widgets (tier_selector, acca_card, trade_action_bar, 3 charts)
- 1 service (notifications)

### Ključne odluke
- **Major version bump (3.0.0)** — fundamentalna transformacija iz single-strategy u multi-strategy
- **TierModeSelector je global** — nije per-screen toggle, nego uvijek iznad svega
- **Bet.matchStartedAt field** uveden ali je u S7 bio **nullable i nije filtriran** (strict filter tek u S8 Task 2)
- **Material `Accumulator` collision** — rijeseno s `import 'flutter/material.dart' hide Accumulator;` (renamed tek u S9)
- **Core library desugaring** dodan u Android build.gradle za flutter_local_notifications 18.x kompatibilnost

### Rezultat
- v3.0.0+8
- 61 Dart fajl (~10500 linija)
- 10 Identified Issues (najvise tokom cijelog projekta)

---

## 11. Session 8 — Stabilization + P&L Breakdown + Filter/Search

**Verzija:** 3.1.0+9 (minor — mix stabilization + new functionality)
**Scope:** 8 taskova

### Kontekst
S7 ostavio 10 Identified Issues. S8 rjesava 5 high-impact + dodaje CoinSight S10-inspired polish.

### Ciljevi
- **Task 1:** IntelligenceProvider auto-refresh wire-up u MainNavigation didChangeDependencies
- **Task 2:** LIVE tier filtering (Bet.isLiveBet getter + tier-aware filter u BetsScreen)
- **Task 3:** Football-Data dynamic re-wire bez restart-a (IntelligenceProvider.updateFootballDataApiKey)
- **Task 4:** Notifications per-type toggle (3 flagovi + Settings SwitchListTile sekcija)
- **Task 5:** Football-Data token-based fuzzy match (zamjena substring-a, guard score >= 2)
- **Task 6:** Per-sport P&L breakdown (SportPl model + `perSportBreakdown` getter + tabular UI)
- **Task 7:** Bets filter/search (BetsProvider filter state + BetsFilterBar widget + apply)
- **Task 8:** Polish (Accumulator stake validator, chart responsive sizing)

### Kreirani fajlovi (2)
- `sport_pl.dart`
- `bets_filter_bar.dart`

### Ključne odluke
- **Token-based fuzzy match** guardant da "Manchester" solo match odbija (>=2 tokens required) — izbjegava United/City confusion
- **Per-sport breakdown** samo settled bets (ne pending — nema decisive win/loss)
- **Filter state on provider** (ne on screen) — perzistira izmedju tab switchanja

### Rezultat
- v3.1.0+9
- 63 Dart fajla
- **Identified Issues smanjen s 10 na 3**

---

## 12. Session 9 — Backlog Cleanup + Tennis Minimal + Accumulator Rename

**Verzija:** 3.1.1+10 (patch — cleanup)
**Scope:** 4 taskova

### Ciljevi
- **Task 1:** Pubspec bump + Telegram issue formally reclassified "By-Design Will Not Fix" u WORKLOG (4 obrazlozenja)
- **Task 2:** TennisInfoPanel widget (bookmaker favourite + implied probability tiles + margin + info note)
- **Task 3:** `Accumulator` → `BetAccumulator` rename (uklanja material collision + `hide Accumulator` imports)
- **Task 4:** Final cleanup (grep sanity checks + APK build)

### Kreirani fajlovi (1)
- `tennis_info_panel.dart`

### Ključne odluke
- Telegram MTProto migration **nece biti** — 4 razloga dokumentirano (platform, tehnicki, security, arhitektura)
- Tennis coverage ostavljen **minimal** — nema dedicated service, samo odds-based info panel
- BetAccumulator **preferirano ime** nad `hide Accumulator` hack-ovima

### Rezultat
- v3.1.1+10
- 64 Dart fajla
- **Identified Issues: 1** (samo by-design Telegram)

---

## 13. Session 10 — Documentation Final

**Verzija:** 3.1.2+11 (patch — documentation only)
**Scope:** 5 taskova (ovaj dokument)

### Kontekst
S1-S9 izgradili kompletan kod (64 Dart fajla, 0 bugova), ali dokumentacija je bila default Flutter template ("A new Flutter project").

### Ciljevi
- README.md (profesionalni GitHub prvi dojam, ~150 linija)
- NEWBIE_GUIDE.md (korak-po-korak za novog korisnika, ~1200-1400 linija)
- MANUAL.md (feature reference prirucnik, ~1500-1800 linija)
- OVERVIEW.md (ovaj dokument — arhitekturalna povijest, ~1000-1200 linija)
- Pubspec bump + WORKLOG final entry

### Kreirani fajlovi (4 MD)
- README.md
- NEWBIE_GUIDE.md
- MANUAL.md
- OVERVIEW.md

### Ključne odluke
- **Hrvatski jezik** — dokumentacija kao primarna publika lokalne zajednice
- **Bez dijakritickih znakova** uglavnom (radi kompatibilnosti s file systemima i usporedbe s CoinSight-om)
- **Format analogno CoinSight-u** ali **sadržaj potpuno BetSight-specific** — ne kopiraj-pasteajuci
- **Licenca ostaje Proprietary** (vs CoinSight MIT)

### Rezultat
- v3.1.2+11
- 4 nova MD fajla, ~4000+ linija dokumentacije
- Project **feature + documentation parity** s CoinSight-om ostvarena

---

## 14. Konacan pregled arhitekture (v3.1.2)

### 14.1 Multi-source intelligence flow

```
Korisnik zvjezdica meč (MatchesProvider.toggleWatched)
    ↓
Kickoff reminders scheduled (NotificationsService)
    ↓
MatchesProvider.fetchMatches() — odds cache check → API ako expired
    ↓
_captureSnapshotsForWatched() — dedup-an save OddsSnapshot
    ↓
Auto-refresh Timer (1h) triggera IntelligenceProvider.refreshAllWatched(force: true)
    ↓
Aggregator.buildReport(match) — 5 paralelnih scoring Future-ova
    ↓
   ├─ Odds scoring (bez fetch-a — koristi match.h2h iz MatchesProvider)
   ├─ Football-Data scoring (cache 3h, inače fetch, 4-5 HTTP po mecu)
   ├─ NBA scoring (cache 3h, inače fetch preko BallDontLie)
   ├─ Reddit scoring (cache 3h, inače fetch public JSON)
   └─ Telegram scoring (no fetch — koristi TelegramProvider recent signals)
    ↓
IntelligenceReport sa 5 SourceScore-ova + confluence score (0-6.0) + category
    ↓
Saved u Hive (intelligence_reports box)
    ↓
Dashboard UI prikazuje (ConfluenceBadge + per-source progress bars)
```

### 14.2 Three-tier investment strategy

```
Korisnik tapne Tier Mode Selector (PRE-MATCH / LIVE / ACCUMULATOR)
    ↓
TierProvider.setTier(tier) → notifyListeners
    ↓
   ├─ Analysis screen: suggestion chips adaptivno
   ├─ Analysis screen: Claude prompt appendix dynamic
   ├─ Bets screen: filter (preMatch / live / accumulator view)
   ├─ Bet Entry Sheet: matchStartedAt logic
   └─ Various empty states personalizirani
    ↓
Korisnik radi tier-specific workflow:
   • PRE-MATCH → deep DYOR → LOG BET → Settle
   • LIVE → reactive → LOG BET (live flag) → Settle
   • ACCUMULATOR → builder → Save → Place → Settle
```

### 14.3 Cache + rate limit management

```
Odds API free tier: 500 req/mj
    ↓
MatchesProvider.fetchMatches():
   1. Check isApiLimitCritical → return cache ako postoji
   2. Cache check (15-60 min TTL) → return cached entry
   3. Call API → save snapshot + update cache
    ↓
Intelligence source cache (3h TTL per-source):
   - Football-Data: 10 req/min, cached per matchId
   - NBA, Reddit: ratel-limit managed internally, cached per matchId
   - Telegram, Odds: no explicit cache (Telegram je push via polling; Odds koristi MatchesProvider cache)
    ↓
Scheduled cleanup (24h gate, via main.dart startup):
   - Signals > 7d — briše
   - Snapshots > 7d — briše
   - Cache > 24h — briše
   - Reports > 6h — briše
   - Source signal caches > 3 days — briše
```

### 14.4 Claude AI prompt design

```
User poruka → AnalysisProvider.sendMessage(text)
    ↓
Gather context:
   - effectiveMatches = stagedMatches ili explicit context
   - effectiveSignals = stagedSignals
   - bettingHistory = Storage.getAllBets() sorted desc, take 5
   - drifts = per-matchId OddsDrift.compute(firstSnapshot, lastSnapshot)
   - intelReports = per-matchId IntelligenceReport from Storage
    ↓
_buildUserMessage() — strukturira blokove:
   [SELECTED MATCHES]
   [INTELLIGENCE REPORT]  ← ako postoji
   [TIPSTER SIGNALS]      ← ako staged
   [BETTING HISTORY]      ← zadnjih 5
   [TIER: X — Y horizon]
   ...
   <user text>
    ↓
ClaudeService.sendMessage() — sistem prompt (40 linija) + history + user content
    ↓
Claude response → parse marker → save AnalysisLog → (optional) VALUE notification
    ↓
UI renders response → TradeActionBar ako VALUE
```

---

## 15. Poznata ogranicenja i by-design odluke

### 15.1 Telegram Bot API limitation (By-Design, Will Not Fix)

**Problem:** Bot ne moze citati poruke iz kanala gdje nije clan.

**Zasto ne rjesavamo:**
1. **Platforma:** Telegram je dizajnirao Bot API namerno s ovim ogranicenjem. MTProto je odvojeni API za user-level clients.
2. **Tehnicki:** MTProto SDK-evi u Dart-u nisu produkcijski spremni (`telegram_client` experimentalni, `td_plugin` Android-only neaktivan).
3. **Security:** MTProto trazi korisnikov API ID + phone + SMS. BetSight bi dobio pristup cijelom korisnikovom Telegram accountu — unacceptable privacy footprint.
4. **Arhitektura:** Telegram je 1 od 5 izvora, ne primary. Diverzifikacija kompenzira ogranicenje.

**Workaround za korisnike:** Kreiraj vlastiti kanal → dodaj bot kao admin → forward-aj/copy-paste zanimljive poruke iz drugih kanala u svoj.

### 15.2 Tennis coverage (Limited, No Dedicated Service)

BetSight v3.1.2 podrzava tennis samo kroz:
- Odds API (ATP Singles kvote)
- TennisInfoPanel u MatchDetailScreen (implied probability + margin)

Nema:
- Player form data
- H2H between players
- Surface (hard/clay/grass) breakdown
- Ranking integration (ATP official nema public API)

Razlog: tennis data API-ji su ili placeni (Sportmonks, Enetpulse) ili ogranicenog pokrivanja. Za deep tennis research, korisnik neka referira Tennis Abstract ili ATPTour sluzbeni sajt.

### 15.3 Odds API 500 req/mj cap

Free tier je 500 req/mj. BetSight mitigira kroz:
- Cache TTL (15 min default, 5/30/60 configurable)
- Rate limit warning banners u Matches
- Hard-stop kad je remaining = 0 (vraca cache, nece pozivati API)

Pri normalnom koristenju: 2-5 refresha dnevno × 3 sporta = 150-450 req/mj (pod capom).

### 15.4 Responsive UI nije testirano na svim Android uređajima

Chart widgets (OddsMovement, EquityCurve) imaju responsive sizing za <360dp ekrane, ali nisu testirani na:
- Fold screens (Galaxy Fold, Z Flip)
- Extreme small (watch OS)
- Extreme large tablets (Pixel Tablet, Galaxy Tab)

Za standardne Android 8+ phone-ove (360-480dp) BetSight radi.

### 15.5 Android-only official support

BetSight je primarno Android. Windows desktop build postoji samo za **development** (flutter build windows tijekom razvoja). iOS build nije testiran ni distribuiran — teoretski cross-platform kroz Flutter, ali nema CI/CD za iOS, nema App Store certificate.

### 15.6 Proprietary license

BetSight nije open source. `LICENSE` fajl definira restrictive proprietary terms (no copy, no modify, no distribute, no reverse engineer, no transfer). Za osobnu uporabu korisnika koji je primio APK/source directno.

Razlika od CoinSight-a (MIT) — razlog je iskljucivo redovna logika.

### 15.7 Accumulator naming history

BetAccumulator klasa renamed iz `Accumulator` u S9 Task 3 zbog collision-a s Flutter Material `Accumulator` widgetom (za TextSpan inline accumulator — rijetko korišteno). Prije S9, 2 fajla (`accumulator_card.dart`, `accumulator_builder_screen.dart`) imali `import 'package:flutter/material.dart' hide Accumulator;` hack. Nakon rename-a, regular material import radi.

Ostali identifikatori (`AccumulatorLeg`, `AccumulatorStatus`, `AccumulatorsProvider`, `AccumulatorCard`, `AccumulatorBuilderScreen`) nisu renamed — nisu kolidirali.

### 15.8 Session 1.x chronology

Redoslijed sesija:

```
S1 (v1.0.0) — Scaffold
S2 (v1.1.0) — Value Bets + Markers + Logging + Android
S3 (v1.2.0) — Bet Tracking + Manual Entry + Settlement + Bankroll
S4 (v1.3.0) — Telegram Tipster Monitor + Odds Snapshot Engine
S5 (v1.3.1) — Infrastructure Hardening (cache, rate limit, cleanup)
S5.5 FIX (v1.3.2) — Prompt Redesign + Trade Action Bar + Bot Manager
S6 (v2.0.0) — Multi-Source Intelligence Layer
S7 (v3.0.0) — Three-Tier Framework + Charts + Push + Detail
S8 (v3.1.0) — Stabilization + P&L Breakdown + Filter/Search
S9 (v3.1.1) — Backlog Cleanup + Tennis Minimal + Rename
S10 (v3.1.2) — Documentation Final
```

---

## 16. Notifications lifecycle

### 16.1 Initialization

Pri startup (main.dart):
```dart
await StorageService.init();           // otvara 13 Hive boxova
await StorageService.runScheduledCleanup();  // 24h gated cleanup
await NotificationsService.init();     // tz.initializeTimeZones + plugin init
await NotificationsService.requestPermissions();  // Android permission dialog
runApp(...);
```

### 16.2 Kickoff reminders (scheduled)

Kad `MatchesProvider.toggleWatched(matchId)` dodaje matchId u watched set:
```dart
final match = _allMatches.firstWhere((m) => m.id == matchId);
await NotificationsService.scheduleKickoffReminders(match);
```

`scheduleKickoffReminders` zakazuje tri reminders (24h / 1h / 15min) kroz `_plugin.zonedSchedule` s deterministic ID-ovima (`matchId.hashCode + offsetSeconds`). Prosle reminders se preskaču (scheduledAt < DateTime.now()).

Per-type gate: Ako `StorageService.getNotifKickoffEnabled() == false`, early-return bez scheduleinga.

Kad korisnik unstar-a:
```dart
await NotificationsService.cancelKickoffReminders(matchId);
// Cancels ID + 86400, ID + 3600, ID + 900
```

### 16.3 Drift alerts (immediate)

Tijekom `MatchesProvider._captureSnapshotsForWatched()`:
```dart
final didSave = await StorageService.saveSnapshotIfChanged(snapshot);
if (didSave) {
  final drift = driftForMatch(match.id);
  if (drift != null && drift.hasSignificantMove) {
    final dominantAbs = drift.dominantDrift.percent.abs();
    if (dominantAbs >= 5) {
      await NotificationsService.showDriftAlert(match, drift);
    }
  }
}
```

Threshold 5% (stricti nego UI drift indicator 3%) da izbjegne notification spam.

### 16.4 VALUE alerts (immediate)

U AnalysisProvider.sendMessage nakon successful response:
```dart
final recType = parseRecommendationType(reply);
if (recType == RecommendationType.value &&
    effectiveContext != null &&
    effectiveContext.isNotEmpty) {
  await NotificationsService.showValueAlert(effectiveContext.first);
}
```

Koristi prvi staged match za notification subject.

### 16.5 Per-type toggle (S8)

Svaka notification metoda early-returns ako je odgovarajuci flag OFF:
```dart
static Future<void> scheduleKickoffReminders(Match match) async {
  if (!StorageService.getNotifKickoffEnabled()) return;
  // ...
}
```

Default sva tri su ON. Settings Notifications sekcija ima SwitchListTile za svaku.

---

## 17. Android build configuration

### 17.1 Gradle Kotlin DSL (build.gradle.kts)

S7 uveo novi dependency (flutter_local_notifications 18.x) koji zahtijeva **core library desugaring**:

```kotlin
android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true  // S7
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")  // S7
}
```

Bez ovoga, `flutter build apk --debug` faila sa "requires core library desugaring to be enabled".

### 17.2 AndroidManifest.xml

S2 dodao INTERNET permission + ispravio app label:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<application
    android:label="BetSight"
    ...
```

Za notifications (S7+) Android automatski trazi permission pri prvom `scheduleZonedNotification()` pozivu kroz flutter_local_notifications plugin — ne treba eksplicitan manifest entry za POST_NOTIFICATIONS.

### 17.3 Namespace + applicationId

```kotlin
android {
    namespace = "com.betsight.betsight"
    defaultConfig {
        applicationId = "com.betsight.betsight"
    }
}
```

### 17.4 Signing

Release build koristi **debug keys** (nije production-signed):
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

Za production APK release, developer treba generirati vlastite keys (keytool -genkey) i update-ati gradle config.

---

## 18. Testing strategija

### 18.1 Trenutno stanje (v3.1.2)

```
test/
└── widget_test.dart  (79 linija, 2 testa)
```

2 smoke testa:
1. `BetSightApp renders with bottom navigation` — provjerava 4 tab-a
2. `Bottom navigation switches tabs` — simulira tap na svaki tab + empty state verify

Test wrapper koristi 8 providera (TierProvider / NavigationController / MatchesProvider / AnalysisProvider / BetsProvider / AccumulatorsProvider / TelegramProvider / IntelligenceProvider) + 13 Hive boxova u setUpAll.

Nema:
- Unit testova za business logic (Bet.actualProfit, OddsDrift.compute, parseRecommendationType, ValuePreset.matches)
- Integration testova za cache layer, Hive persistence, API service retry/error paths
- Widget testova za specificne screen-ove (Accumulator Builder, Intelligence Dashboard)

### 18.2 Preporuceni sljedeci korak

Kad bi se radio test pass u buducoj sesiji (S11?), prioriteti:

1. **Unit testovi za business logic** (~20-30 testova):
   - `Bet.actualProfit` za sve BetStatus vrijednosti
   - `BetAccumulator.correlationWarnings` edge cases
   - `OddsDrift.compute` + `dominantDrift` + `hasSignificantMove`
   - `parseRecommendationType` za razne Claude format-e
   - `ValuePreset.matches` i `edgeScore` za tri preseta
   - `FootballDataService._tokenize` i `_matchScore`
   - `IntelligenceCategory` klasifikacija po confluence score-u

2. **Integration testovi** (~10-15):
   - Odds API cache roundtrip (fetch → save → load)
   - Hive persistence (save bet → restart → load)
   - Service error paths (401/429/timeout)

3. **Widget testovi** (~10-15):
   - TierModeSelector tap switching
   - TradeActionBar prikazuje se samo ispod VALUE response-a
   - BetsFilterBar filter application
   - AccumulatorBuilderScreen correlation warning rendering
   - PlSummaryWidget per-sport breakdown

---

## 19. Performance napomene

### 19.1 Rebuild triggers

Provider-i koji **najcesce notifyListeners-aju** (i time trigger rebuild):
- `MatchesProvider` — pri svakom fetchMatches, selection toggle, watched toggle, value preset
- `AnalysisProvider` — pri svakoj novoj poruci, isLoading flag, staged changes
- `TelegramProvider` — pri svakom novom signalu (10s polling interval)

Optimizacije:
- **Consumer pattern** (ne `context.watch`) — rebuild-a samo child, ne cijeli tree
- **Const widgets** gdje god moguce
- **ListView.builder** (lazy) za bet/match lists
- **Hive is synchronous** za read, asynchronous za write — read getter-i ne blokiraju UI

### 19.2 Memory footprint

Typical memory usage:
- Startup: ~80-120 MB (Flutter VM + plugin init)
- Watched lista 5 mecva: +20-30 MB (provider data + Hive lazy load)
- Intelligence Dashboard s 5 reports: +10-20 MB

Skalira linearno s brojem watched matches + snapshots. Scheduled cleanup drzi Hive baze razumne velicine (briše >7d data).

### 19.3 Network calls

Worst case pri normalnom koristenju:
- Startup: 0 network calls (Hive is local)
- Prvi Matches fetch: 3 API calls (1 per sport)
- Intelligence refresh for 5 watched: 1 (Odds) + 5×(Football-Data ~5 calls) + 5×(NBA ~3 calls) + 5×(Reddit ~2 calls) = ~55 calls
- Cached: 0 calls (dok TTL nije expiran)

Rate limit managed:
- Odds API: 500/mj free — ~1 fetch/h × 24h × 30d = 720 (BetSight cache smanjuje na ~150)
- Football-Data: 10/min — BetSight aggregator je serijski
- Reddit: 60/h unauth — 2 subreddita × 5 mecva = 10 req per refresh

---

## 20. Zavrsna rijec

BetSight v3.1.2 je **potpuno izgraden sport betting intelligence sustav** paralelan CoinSight crypto inteligence-u. Feature parity (3 tiera, 5 izvora, charts, push, detail screens) + dokumentacijski parity (4 MD fajla, ~4000 linija) ostvaren kroz 10 sesija.

**0 otvorenih bugova. 1 by-design ogranicenje (Telegram).**

Za development log vidjeti [WORKLOG.md](WORKLOG.md) — 1297 linija povijesti od scratch-a do v3.1.2.

Za pocetnike — [NEWBIE_GUIDE.md](NEWBIE_GUIDE.md).

Za power-user-e — [MANUAL.md](MANUAL.md).

Sretno s kladenjem.

---

*BetSight v3.1.2 | OVERVIEW.md | 2026-04-18*
