# BetSight SESSION 10 — Documentation Final (Završnica)

## UPUTA ZA CLAUDE CODE

**Prije početka OBAVEZNO pročitaj:**
- `CLAUDE.md` (pravila, autonomni režim)
- `WORKLOG.md` **CIJELI** (svih 1297 linija — to je primarni izvor za OVERVIEW.md u Tasku 4; od S1 do S9 moraš razumijeti sve arhitekturalne odluke i evoluciju)
- **`lib/` direktorij** u cijelosti — čitaj sve .dart fajlove redom da razumiješ kompletnu arhitekturu

**S10 je čista dokumentacijska sesija.** Nema novog koda. Verzija se bumpa samo za completeness (patch bump na 3.1.2+11). Rezultat: 4 kompletna dokumentacijska fajla koji paralelno postoje CoinSight-u ali su potpuno napisani za BetSight kontekst.

**Nakon čitanja napiši kratki summary (5-7 rečenica) što ćeš raditi, potom nastavi autonomno kroz svih 5 zadataka bez čekanja na developerovu potvrdu.**

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues (unatoč tome što nema code changes, provjeri)
2. Dodaj unos u `WORKLOG.md` pod novu sekciju `## Session 10: YYYY-MM-DD — Documentation Final`
3. Tek onda prelazi na sljedeći zadatak

**Git:** Claude Code **NE radi git commit ni git push.** Developer preuzima.

**Verzija:** u Tasku 1 ažuriraj `pubspec.yaml` na `version: 3.1.2+11`.

**Izvor istine:** za BetSight-specific kontekst, uvijek referiraj sebe WORKLOG-om, `lib/` kodom, i postojećom strukturom. **NE kopiraj direktno iz CoinSight-a** — mnogo toga je drugačije (sportovi vs coins, bookmakeri vs exchangeovi, Odds API vs CoinGecko, itd.).

**Jezik dokumentacije:** hrvatski, uz engleske tehničke termine gdje je prirodno (npr. "Claude API ključ", "pull-to-refresh", "VALUE marker"). Točno kako CoinSight to radi.

---

## Projektni kontekst

S1-S9 su izgradili kompletan BetSight kod. Verzija 3.1.1+10. 64 Dart fajla. 1297-line WORKLOG s punom poviješću svih promjena. **Ali dokumentacija je doslovno default Flutter template** iz `flutter create`. README kaže "A new Flutter project."

S10 rješava taj potpuni dokumentacijski jaz tako što generira 4 ključna dokumenta paralelna CoinSight-u:

| Dokument | Ciljni opseg | Svrha |
|---|---|---|
| `README.md` | ~150 linija | Prvi dojam na GitHub-u, badges, quick overview |
| `NEWBIE_GUIDE.md` | **~1200-1400 linija** | Korak-po-korak za potpuno novog korisnika (od registracije API ključa do prvog bet-a) |
| `MANUAL.md` | **~1500-1800 linija** | Priručnik sa svakom funkcionalnošću, tier-specific korištenje, troubleshooting |
| `OVERVIEW.md` | **~1000-1200 linija** | Arhitekturalni dokument — session-by-session BetSight povijest, dependency graph, Hive boxes, API-ji |

Ukupno ~3850-4550 linija dokumentacije.

---

## TASK 1 — README.md (Prvi dojam na GitHub-u)

**Cilj:** Profesionalni README s badges-ima koji odmah daje korisniku sliku što BetSight radi. Analog CoinSight README-u (140 linija) ali za sport betting.

### Obriši postojeći README.md i zamijeni s novim

**Struktura (provjeri CoinSight README za točan format, adaptiraj za BetSight):**

```markdown
<div align="center">

# BetSight

### AI-powered Three-Tier Sports Betting Intelligence Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-3.1.2-blue)](pubspec.yaml)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://android.com)

**BetSight** kombinira multi-source sport intelligence monitoring, Claude AI analizu,
i bet tracking organizirano kroz tri investicijska horizonta.

[Preuzmi APK](#instalacija) | [Vodič za početnike](NEWBIE_GUIDE.md) | [Priručnik](MANUAL.md) | [Arhitektura](OVERVIEW.md)

</div>

---

## Što je BetSight?

BetSight je Android aplikacija koja kombinira **5 izvora sport intelligence-a** (Odds API, Football-Data, BallDontLie NBA, Reddit, Telegram) s Claude AI analizom kako bi korisniku pomogla pronaći **value bet-ove** kroz **tri različita betting pristupa**.

### Tri tiera — jedna aplikacija

| | **PRE-MATCH** | **LIVE** | **ACCUMULATOR** |
|---|---|---|---|
| **Vremenski horizont** | 24-48h prije kickoff-a | In-play, tijekom meča | Multi-match build (2-5 legs) |
| **Fokus analize** | Deep DYOR, forma, H2H, statistika | Momentum reads, odds drift | Correlation-aware combinations |
| **Primary Action** | LOG BET | LOG BET (matchStartedAt tracking) | BUILD ACCUMULATOR |
| **Claude prompt** | Tier-specifični kontekst | Tier-specifični kontekst | Tier-specifični kontekst |

## Značajke

### Intelligence Layer (5 izvora)
- **Odds API** — kvote, margins, bookmaker analysis
- **Football-Data.org** — forma, H2H, standings za EPL/CL
- **BallDontLie** — NBA statistika, last 10, rest days
- **Reddit** — community sentiment iz r/soccer, r/NBA, r/sportsbook
- **Telegram** — tipster signali s reliability scoring-om

Confluence score 0-6.0 agregira svih 5 izvora u jedan Intelligence Report per watched match.

### Betting & Tracking
- Bet logging s pre-match i live distinkcijom
- Accumulator builder s correlation warning-ima
- Bankroll management
- Per-sport P&L breakdown
- Filter/search po datumu, sportu, statusu

### Grafovi i Vizualizacija
- Odds Movement Chart (history drift-a po watched match)
- Form Chart (W/D/L vizualizacija za soccer)
- Equity Curve (kumulativna P&L krivulja)

### Push Notifications
- Kickoff reminders (24h / 1h / 15 min)
- Odds drift alerts (>5% move)
- VALUE signal alerts (kad Claude flagira nešto)

### Detail Screens
- MatchDetailScreen — 4 taba (Overview / Intelligence / Charts / Notes)
- IntelligenceDashboardScreen — per-match intelligence s per-source breakdown
- BotManagerScreen — Telegram channel reliability stats
- AccumulatorBuilderScreen — leg picker s correlation warnings

## Instalacija

### Preuzimanje APK-a
Najnovija verzija: `betsight-v3.1.2.apk`

[Instrukcije za install na Android-u]

### Iz izvora
```bash
git clone https://github.com/nroxa92/claude_betsight.git
cd claude_betsight
flutter pub get
flutter build apk --release
```

## Konfiguracija

Potrebni API ključevi (svi besplatni osim Anthropic-a):
1. **Anthropic Claude API** (obavezan) — https://console.anthropic.com
2. **The Odds API** (obavezan) — https://the-odds-api.com (free 500 req/mj)
3. **Football-Data.org** (opcionalan) — https://football-data.org (free, neograničen)
4. **Telegram Bot Token** (opcionalan) — kreiraj preko @BotFather

Detaljne upute u [NEWBIE_GUIDE.md](NEWBIE_GUIDE.md).

## Tehnički stack

- **Flutter 3.41+** s Dart 3.11+
- **State management:** Provider pattern, 8 ChangeNotifier-a
- **Local storage:** Hive (13 boxes)
- **Chart library:** fl_chart 0.69.0
- **Push notifications:** flutter_local_notifications 18.0.0
- **HTTP client:** http package

## Dokumentacija

- [NEWBIE_GUIDE.md](NEWBIE_GUIDE.md) — sve-od-nule vodič za novog korisnika
- [MANUAL.md](MANUAL.md) — detaljni priručnik (tier walkthrough, troubleshooting, FAQ)
- [OVERVIEW.md](OVERVIEW.md) — arhitekturalni dokument (session history, file structure, API integrations)
- [WORKLOG.md](WORKLOG.md) — chronology svih razvojnih sesija (S1-S10)
- [BETLOG.md](BETLOG.md) — template za bilježenje ishoda Claude preporuka

## Licenca

MIT License — vidi [LICENSE](LICENSE) fajl.

---

**BetSight nije financijski savjet.** App je alat za pattern analizu i edukaciju. Kladite se odgovorno. Never bet more than you can afford to lose. DYOR.
```

### Verifikacija Taska 1

- `flutter analyze` → 0 issues
- `ls README.md` → postoji
- `wc -l README.md` → ~140-160 linija

---

## TASK 2 — NEWBIE_GUIDE.md (Korak-po-korak za novog korisnika)

**Cilj:** Potpuni vodič od instalacije do prvog bet-a. Ciljna veličina: **1200-1400 linija**.

Tretiraj čitatelja kao **nekog tko nikada nije kladio i tko je prvi put vidi BetSight**. Svaki pojam treba objasniti kad se prvi put spominje.

### Struktura (analog CoinSight NEWBIE_GUIDE — adaptirano za betting domain)

```markdown
# BetSight — Vodič za početnike

## Sadržaj
1. Što je BetSight i što radi
2. Što ti treba za početak
3. Claude AI postavljanje
4. The Odds API postavljanje
5. Football-Data.org postavljanje (opcionalno)
6. Telegram Bot postavljanje (opcionalno)
7. Reddit (bez konfiguracije — automatski radi)
8. Prvi koraci u BetSightu
9. Razumijevanje tri tiera (PRE-MATCH/LIVE/ACCUMULATOR)
10. Tvoja prva analiza s Claudeom
11. Tvoj prvi bet
12. Razumijevanje grafikona
13. Rječnik pojmova
14. Sigurnosna pravila i odgovorno kladenje
15. Završna riječ
```

### Content guide za Claude Code

Svaka sekcija mora imati:
- **Kratak opis** — što ćemo raditi i zašto
- **Prerequisities** — što korisnik mora imati spremno
- **Korak po korak** — numerirani koraci s screen-by-screen uputama
- **Rješavanje problema** — tipski "što ako..." scenariji

**Detaljne specifikacije za svaku sekciju:**

#### Sekcija 1 — Što je BetSight (~50-80 linija)
- Objasni koncept value bet-inga
- 3 tiera u jednoj rečenici svaki
- Što BetSight NIJE (npr. "nije automatska kladionica", "nije garancija dobitka")

#### Sekcija 2 — Što ti treba (~80-100 linija)
- Minimalni zahtjevi (Android 8.0+, 150MB slobodno, internet)
- Što ćeš registrirati redoslijedom
- Preporučeni raspored (5 min Claude, 10 min Odds API, 15 min Football-Data, 20 min Telegram...)

#### Sekcija 3 — Claude AI (~100-150 linija)
- Što je Claude AI i zašto ga koristimo
- Korak po korak registracija na console.anthropic.com
- Kako dobiti API ključ (screen uputama)
- Kako unijeti u BetSight Settings
- Troubleshooting (invalid key, rate limit, itd.)

#### Sekcija 4 — The Odds API (~80-120 linija)
- Što je Odds API i zašto ga koristimo (jer CoinGecko za crypto, ali za kvote nemaju analog — jedini way)
- Registracija na the-odds-api.com
- Free tier ograničenje (500 req/mj) i kako BetSight to upravlja
- Unos ključa

#### Sekcija 5 — Football-Data.org (~100-140 linija)
- Što je, zašto je korisno
- Free tier (neograničen mjesečno, 10 req/min)
- Registracija
- Podržane lige (EPL, Champions League)

#### Sekcija 6 — Telegram Bot (~120-160 linija, uključujući limitaciju)
- Što je Telegram Monitor
- Kreiranje bot-a preko @BotFather (detaljno — ovo je većina korisnika tu padne)
- **JASNO objašnjenje Bot API ograničenja** (bot mora biti član kanala — referenca na WORKLOG by-design section)
- Preporučeni workflow: vlastiti kanal + dodavanje bot-a

#### Sekcija 7 — Reddit (~30-50 linija)
- Koji subreddit-i se skeniraju (r/sportsbook, r/soccer, r/NBA, r/tennis)
- Bez konfiguracije — automatski radi

#### Sekcija 8 — Prvi koraci u BetSightu (~100-150 linija)
- Navigacija (4 main taba + tier selector iznad)
- Settings konfiguracija (redoslijed unosa ključeva)
- Dodavanje mečeva na watched listu (star toggle)

#### Sekcija 9 — Razumijevanje tri tiera (~150-200 linija)
- **PRE-MATCH** — Duboki analitičar, 24-48h prije
  - Kada koristiti
  - Primjer workflow-a
- **LIVE** — Reactive mode, in-play
  - Kada koristiti (oprez — veliki rizik)
  - Razlike od PRE-MATCH-a
- **ACCUMULATOR** — Multi-match builder
  - Kada koristiti (rijetko — korelacije)
  - Primjer: kako graditi 3-leg accumulator
- **Usporedba** table (horizont, WIN rate očekivanja, disciplina)

#### Sekcija 10 — Prva analiza s Claudeom (~100-130 linija)
- Odaberi match iz Matches screen-a
- Tap "Analyze" ili copy-paste u Analysis screen
- Što očekivati od Claude odgovora (VALUE/WATCH/SKIP format)
- Kako tumačiti odgovor
- Context injection — [SELECTED MATCHES], [TIPSTER SIGNALS], [BETTING HISTORY], [INTELLIGENCE REPORT]

#### Sekcija 11 — Prvi bet (~100-130 linija)
- Nakon VALUE preporuke, tap "LOG BET" u Trade Action Bar-u
- Bet Entry Sheet — stake, odds, outcome pre-filled
- Potvrdi save
- Settlement flow (Won/Lost/Void)
- Razlika LIVE vs PRE-MATCH bet-ova (matchStartedAt)

#### Sekcija 12 — Razumijevanje grafikona (~150-200 linija)
- **Odds Movement Chart** — što prikazuje, kako tumačiti drift
- **Form Chart** — W/D/L vizualizacija, samo soccer
- **Equity Curve** — kumulativni P&L, plava krivulja za profit, crvena za gubitak
- Kako otvoriti chart (MatchDetailScreen → Charts tab)

#### Sekcija 13 — Rječnik pojmova (~100-150 linija)
Alfabetski:
- Asian Handicap
- Bankroll
- Decimal Odds
- Equity Curve
- H2H (Head-to-head)
- Implied Probability
- Kvota (decimal/fractional/American)
- Margin (bookmaker)
- Moneyline
- Over/Under
- ROI
- Settlement
- Sharp book / Soft book
- Spread
- Stake
- Value Bet

#### Sekcija 14 — Sigurnost + Odgovorno kladenje (~120-180 linija)
- **Zlatna pravila:**
  1. Nikad više nego što si spreman izgubiti
  2. Nikad ne juri za gubicima (chasing losses)
  3. Stake veličina = mali postotak bankroll-a (1-5%)
  4. DYOR — uvijek istražuj sam, Claude je alat ne guru
  5. Tracking — bilježi sve u BETLOG.md
  6. Pauze — ako ne ide, prestani za taj dan
- **API ključevi — sigurnost**
- **Što napraviti ako ti se čini da imaš problem kladenja** — linkovi na gambling help resurse (GA, Begambleaware)

#### Sekcija 15 — Završna riječ (~30-50 linija)
- Rezime ključnih točaka
- Pozivnica na BETLOG.md za long-term kalibraciju

### Verifikacija Taska 2

- `flutter analyze` → 0 issues
- `ls NEWBIE_GUIDE.md` → postoji
- `wc -l NEWBIE_GUIDE.md` → minimum 1000 linija, target 1200-1400

---

## TASK 3 — MANUAL.md (Feature-by-feature priručnik)

**Cilj:** Priručnik za power-user-e. Ciljna veličina: **1500-1800 linija**.

Razlika od NEWBIE_GUIDE: **NEWBIE** je korak-po-korak za novog, **MANUAL** je reference za postojećeg korisnika koji želi znati sve detalje svake funkcionalnosti.

### Struktura

```markdown
# BetSight Manual

## Kako čitati ovaj priručnik

## Sadržaj
1. Što je BetSight
2. Osnovni betting pojmovi
3. Three-Tier Investment Framework
4. Intelligence Layer (5 izvora)
5. Prvo pokretanje aplikacije
6. Turneja po aplikaciji
7. Postavljanje API ključeva
8. Tvoja prva analiza
9. Kako čitati Claudeov odgovor
10. Tvoj prvi bet
11. Praćenje pozicija i settlement
12. Bankroll management i risk
13. Accumulator strategija
14. Telegram Monitor — detaljno
15. Intelligence Dashboard — detaljno
16. Charts i vizualizacija
17. Push notifikacije
18. Bot Manager
19. Tipični scenariji
20. Problemi i rješenja
21. Sigurnost
22. FAQ
23. Rječnik pojmova
```

### Kako svaki poglavlje treba izgledati

Koristi **CoinSight MANUAL.md strukturu** — Claude Code neka čita `/mnt/user-data/uploads/` ili direktno iz coinsight repozitorija ako je dostupan (inače se referiraj na WORKLOG).

**Ključno:** Svaki feature iz koda (S1-S9) mora biti opisan u MANUAL-u. Claude Code neka **krene kroz `lib/screens/` fajlove jedan po jedan** i za svaki napiše user-facing opis u MANUAL-u.

**Sekcije koje su BetSight-specific i trebaju detaljni content:**

#### Sekcija 3 — Three-Tier Framework
- Što su tier-ovi i kako prebaciti (TierModeSelector)
- Per-tier suggestion chips (iz TierProvider-a)
- Per-tier Claude prompt context appendix (pokazati stvarne tekstove)
- Per-tier Bets screen filter (isPreMatchBet vs isLiveBet)

#### Sekcija 4 — Intelligence Layer
- 5 izvora s detaljnim opisom weightinga:
  - Odds (0-2.0) — scoring logika: base + sharp margin + drift
  - Football-Data (0-1.5) — form + H2H + standings
  - BallDontLie NBA (0-1.0) — last 10 + rest days
  - Reddit (0-1.0) — mentions + sentiment bias + viral posts
  - Telegram (0-0.5, weighted by reliability) — per-channel score
- Confluence score (0-6.0) i kategorije (STRONG_VALUE / POSSIBLE_VALUE / WEAK / SKIP / INSUFFICIENT_DATA)
- Intelligence Dashboard screen navigacija
- 1h auto-refresh + on-demand Refresh button

#### Sekcija 9 — Kako čitati Claudeov odgovor
- VALUE marker format (MUST specify outcome, odds, probability, next step)
- WATCH marker (marginal edge, nepotpuno data)
- SKIP marker (no edge ili too uncertain)
- Trade Action Bar (LOG BET / SKIP / ASK MORE) — ASK MORE prefillа input
- UserFeedback logging (svi feedback se logira za buduću prompt kalibraciju)

#### Sekcija 13 — Accumulator strategija
- Minimum 2 legs, maksimum realan 4-5
- Correlation warnings:
  - Same match (impossible)
  - Same day/league (weak correlation)
- Combined odds multiplikacija
- Realistic max combined odds (>20 je unlikely value)

#### Sekcija 14 — Telegram Monitor
- Detaljno objasni Bot API ograničenje s obrazloženjem (reference WORKLOG by-design section)
- Keyword filter (`tip`, `bet`, `value`, `odds`, `lock`, `pick`, itd.)
- MonitoredChannel reliability scoring:
  - Novo (< 10 signals) — grey
  - Niska (< 0.1 ratio) — red
  - Srednja (0.1-0.3) — orange
  - Visoka (>0.3) — green

#### Sekcija 20 — Problemi i rješenja
Tipičan scenariji:
- Claude ne odgovara / rate limited
- Odds API quota exhausted (kako riješiti)
- Football-Data fuzzy match error (ambiguous team name)
- Reddit rate limit hit
- Push notifications ne rade (permission check)
- Intelligence Dashboard "Loading..." zauvijek
- Tier switch ne mijenja sadržaj

#### Sekcija 21 — Sigurnost
- API ključevi — local only, ne šalju se nikud osim servisu
- Bet data — lokalno u Hive, nije cloud
- Bankroll privacy
- Responsible gambling resources

### Verifikacija Taska 3

- `flutter analyze` → 0 issues
- `ls MANUAL.md` → postoji
- `wc -l MANUAL.md` → minimum 1400 linija, target 1500-1800

---

## TASK 4 — OVERVIEW.md (Arhitekturalni dokument)

**Cilj:** Session-by-session BetSight povijest + file structure + API integrations + dependency graph + Hive boxes. Ciljna veličina: **1000-1200 linija**.

Ovaj dokument služi dvjema publikama:
1. **Tebi sebi u budućnosti** — kad za 6 mjeseci budeš zaboravio detalje S6 Intelligence Aggregator scoring logike
2. **Novim developerima/klonerima** — koji žele razumjeti arhitekturu prije contribute-anja

### Struktura

```markdown
# BetSight Overview

## 0. Svrha ovog dokumenta

## 1. Što je BetSight
### 1.1 Kratki opis
### 1.2 Core value proposition
### 1.3 Što BetSight NIJE i neće biti

## 2. Stack, arhitektura, ovisnosti
### 2.1 Tech stack
### 2.2 Struktura fajlova (lib/)
### 2.3 Dependency graph
### 2.4 Providers (state management)
### 2.5 Hive box-ovi
### 2.6 Eksterni API-ji

## 3. Session 1 — Scaffold + Odds API + Matches + Claude + Hive + Polish
## 4. Session 2 — Value Bets + Markers + Logging + Android + Match Selection
## 5. Session 3 — Bet Tracking + Manual Entry + Settlement + Bankroll
## 6. Session 4 — Telegram Tipster Monitor + Odds Snapshot Engine
## 7. Session 5 — Infrastructure Hardening
## 8. Session 5.5 FIX — Prompt Redesign + Trade Action Bar + Bot Manager + Context Enhancements
## 9. Session 6 — Multi-Source Intelligence Layer (v2.0.0)
## 10. Session 7 — Three-Tier Framework + Charts + Push + Detail Screens (v3.0.0)
## 11. Session 8 — Stabilization + P&L Breakdown + Filter/Search
## 12. Session 9 — Backlog Cleanup + Tennis Minimal + Accumulator Rename
## 13. Session 10 — Documentation Final (ovaj dokument)

## 14. Konačan pregled arhitekture
### 14.1 Multi-source intelligence flow
### 14.2 Three-tier investment strategy
### 14.3 Cache + rate limit management
### 14.4 Claude AI prompt design

## 15. Poznata ograničenja i by-design odluke
```

### Content guide za Claude Code

**Sekcija 2.2 (file structure)** — generiraj sa `tree lib/ -L 2` output-om:

```
lib/
├── main.dart
├── models/
│   ├── accumulator.dart                       # BetAccumulator + AccumulatorLeg + AccumulatorStatus
│   ├── accumulators_provider.dart
│   ├── analysis_log.dart                      # +UserFeedback enum za prompt kalibraciju
│   ├── analysis_provider.dart                 # ChangeNotifier: Claude chat + system prompt + context injection
│   ├── bankroll.dart
│   ├── bet.dart                               # +matchStartedAt za live vs pre-match distinction
│   ├── bets_provider.dart                     # +filter state + per-sport breakdown
│   ...
├── screens/ [8 screens]
├── services/ [9 services]
└── widgets/ [15+ widgets]
```

Sastavi iz pravog `lib/` contentsa.

**Sekcija 2.4 (Providers):**

| Provider | State drži | Metode |
|---|---|---|
| TierProvider | currentTier, suggestionChips | setTier, claudeContextAppendix |
| NavigationController | currentIndex | setTab |
| MatchesProvider | allMatches, watched, fromCache, rate limit | fetchMatches, toggleWatched, driftForMatch |
| AnalysisProvider | messages, staged matches/signals, lastLogId | sendMessage, recordFeedback, setInputPrefill |
| BetsProvider | allBets, bankroll, filters | addBet, settleBet, filter methods, perSportBreakdown |
| TelegramProvider | signals, channels, monitoring state | addChannel, removeChannel, testConnection |
| IntelligenceProvider | reports map, generating set, autoRefreshTimer | generateReport, refreshAllWatched, startAutoRefresh |
| AccumulatorsProvider | accumulators, currentDraft | startNewDraft, addLegToDraft, saveDraftAsAccumulator |

**Sekcija 2.5 (Hive boxes):**

| Box | Sadržaj | Key pattern |
|---|---|---|
| settings | API keys, preferences, tier, cache TTL | field names |
| analysis_logs | AnalysisLog zapisi | id (UUID) |
| bets | Bet zapisi | id (UUID) |
| tipster_signals | TipsterSignal zapisi | id (UUID) |
| odds_snapshots | OddsSnapshot zapisi | matchId_ISOtimestamp |
| odds_cache | CachedMatchesEntry (fix key) | "all_matches" |
| monitored_channels_detail | MonitoredChannel s reliability | username |
| intelligence_reports | IntelligenceReport zapisi | matchId |
| football_signals_cache | FootballDataSignal cache | matchId |
| nba_signals_cache | NbaStatsSignal cache | matchId |
| reddit_signals_cache | RedditSignal cache | matchId |
| accumulators | BetAccumulator zapisi | id (UUID) |
| match_notes | MatchNote zapisi | matchId |

**Sekcija 2.6 (External APIs):**

| API | Svrha | Free tier | Rate limit |
|---|---|---|---|
| Anthropic Claude | AI analiza | Per tokens pricing | 1000 req/min |
| The Odds API | Kvote za mečeve | 500 req/mj | ~60 req/min |
| Football-Data.org | Form, H2H, standings (soccer) | Neograničen mjesečno | 10 req/min |
| BallDontLie | NBA statistike | Neograničen | No official |
| Reddit public JSON | Community sentiment | 60 req/h (unauth) | Strict |
| Telegram Bot API | Tipster signali (member channels) | Neograničen | ~30 msg/s |

**Sekcije 3-13 (per-session history):**

Za svaku sesiju, struktura:
- **Kontekst** — što je postojalo prije sesije
- **Ciljevi sesije**
- **Fajlovi koji su dodani**
- **Fajlovi koji su ažurirani** 
- **Ključne arhitekturalne odluke**
- **Rezultat / version**

Izvor: WORKLOG.md — **direktno čitaj i summary-aj**. Cilj nije doslovno kopirati WORKLOG, nego sintetizirati u 60-100 linija per sesija.

**Sekcija 14 (konačni pregled):**

Ovo je sinteza — kako sve komponente zajedno rade u v3.1.2. Arhitekturalna narracija koja se čita kao priča, ne kao lista. ~150-200 linija.

**Sekcija 15 (poznata ograničenja):**

- Telegram Bot API limitation (by-design, full obrazloženje iz WORKLOG)
- Tennis coverage (no dedicated service)
- Odds API 500 req/mj cap (mitigated via 15-min cache)

### Verifikacija Taska 4

- `flutter analyze` → 0 issues
- `ls OVERVIEW.md` → postoji
- `wc -l OVERVIEW.md` → minimum 900 linija, target 1000-1200

---

## TASK 5 — pubspec bump + WORKLOG final + Final Verification

**Cilj:** Verzija na 3.1.2+11, WORKLOG dobija zadnji unos, build verification.

### Ažuriraj fajlove

**`pubspec.yaml`** — `version: 3.1.2+11`

**`WORKLOG.md`** — dodaj Session 10 finalnu sekciju:

```markdown
---
---

## Session 10: YYYY-MM-DD — Documentation Final

**Kontekst:** S1-S9 izgradili kompletan BetSight kod (64 Dart fajla, verzija 3.1.1+10). Ali dokumentacija je bila doslovno default Flutter template. S10 zatvara taj jaz s 4 ključna dokumentna fajla paralelna CoinSight-u: README.md (prvi dojam), NEWBIE_GUIDE.md (korak-po-korak za novog korisnika), MANUAL.md (feature reference), OVERVIEW.md (arhitekturalni dokument s session-by-session poviješću).

---

### Task 1 — README.md
[Opis — ~150 linija, profesionalni README s badges, 3-tier table, značajke, instalacija, konfiguracija, tech stack]

### Task 2 — NEWBIE_GUIDE.md
[Opis — ~1200-1400 linija, 15 sekcija, korak-po-korak od Claude API registracije do prvog bet-a]

### Task 3 — MANUAL.md
[Opis — ~1500-1800 linija, 23 poglavlja, feature-by-feature priručnik s troubleshooting-om]

### Task 4 — OVERVIEW.md
[Opis — ~1000-1200 linija, arhitekturalni dokument, session-by-session povijest S1-S10, dependency graph, Hive boxes, API-ji]

### Task 5 — Final verification
[Opis — version bump, WORKLOG, build tests]

---

### Finalna verifikacija Session 10:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v3.1.2.apk
- Verzija: 3.1.2+11 (patch bump)
- **Dokumentacija: 4 nova fajla ukupno ~4000+ linija**
- Git: Claude Code NE commit-a/push-a — developer preuzima

**BetSight 3.1.2 status:**
- 0 otvorenih bugova
- 1 dokumentirano by-design ograničenje (Telegram)
- 64 Dart fajla + ~4000 linija dokumentacije
- Feature parity s CoinSight-om za intelligence platform + dokumentacijski parity
```

### Grep sanity checks

Claude Code neka provjeri:
```bash
# Nema više "A new Flutter project" u README
grep -n "A new Flutter project" README.md
# (Mora biti prazno)

# Svi 4 dokumenta postoje i imaju značajan content
for f in README.md NEWBIE_GUIDE.md MANUAL.md OVERVIEW.md; do
  echo "$f: $(wc -l < $f) lines"
done
# Output mora biti nešto kao:
# README.md: ~150 lines
# NEWBIE_GUIDE.md: ~1200 lines
# MANUAL.md: ~1500 lines
# OVERVIEW.md: ~1000 lines
```

### Finalna verifikacija Session 10

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK u root: `betsight-v3.1.2.apk`
- Verzija: **`3.1.2+11`**
- **Dokumentacija: README + NEWBIE_GUIDE + MANUAL + OVERVIEW svi prisutni, ukupno ~4000+ linija**
- Git: Claude Code **NE commita/pusha** — developer preuzima

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši sažetak:

- Ukupno zadataka izvršeno: 5
- Novih MD fajlova: **4** (README, NEWBIE_GUIDE, MANUAL, OVERVIEW)
- Ažuriranih fajlova: pubspec, WORKLOG
- **Ukupno novih linija dokumentacije: ~4000+**
- Flutter analyze: 0 issues
- Flutter test: 2/2 passed
- Builds: Windows ✓, Android APK ✓ (betsight-v3.1.2.apk)
- **Version: 3.1.2+11 (patch bump — dokumentacija only)**
- **BetSight je sada potpuno dokumentiran kao CoinSight** — parity ostvaren i u kodu i u dokumentaciji
- Sljedeći predloženi korak: **Developer commit-a i push-a S10 na GitHub.** Ovo je **finalna sesija** — BetSight je kompletan software projekt spreman za javnu publiku. Preporučuje se: Review svih 4 dokumenta, potencijalno manji edit-i (tvoji osobni detalji, screenshots dodavanje), i potom **stvarno instalirati APK i početi testirati**. Svaka buduća sesija (S11+) će biti čisto iterativni polish ili nove funkcionalnosti bazirane na real-world feedback-u. BetSight je završio svoju "greenfield" fazu.

Kraj SESSION 10.
