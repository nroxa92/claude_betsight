<div align="center">

# BetSight

### AI-powered Three-Tier Sports Betting Intelligence Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-3.1.2-blue)](pubspec.yaml)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://android.com)

**BetSight** kombinira multi-source sport intelligence monitoring, Claude AI analizu
i bet tracking organizirano kroz tri investicijska horizonta.

[Preuzmi APK](#instalacija) | [Vodic za pocetnike](NEWBIE_GUIDE.md) | [Prirucnik](MANUAL.md) | [Arhitektura](OVERVIEW.md)

</div>

---

## Sto je BetSight?

BetSight je Android aplikacija koja agregira **5 izvora sport intelligence-a** i kombinira ih s Claude AI analizom kako bi korisniku pomogla pronaci **value bet-ove**. Trenutno pokriva tri sporta: nogomet (EPL, Champions League), kosarku (NBA), tenis (ATP).

Razlika od klasicnih kladionickih app-ova: BetSight **ne namjesta kvote** i **ne primaju uplate**. Alat je za analizu — pomaze korisniku prepoznati gdje bookmakerova implicirana vjerojatnost odstupa od stvarne, i bilježi sto je korisnik kladio da bi s vremenom naucio vlastite patterne.

### Tri tiera — jedna aplikacija

| | **PRE-MATCH** | **LIVE** | **ACCUMULATOR** |
|---|---|---|---|
| **Horizont** | 24-48h prije kickoff-a | In-play, tijekom meca | Multi-match build (2-5 legs) |
| **Filozofija** | Duboka DYOR analiza | Reagiraj na momentum | Correlation-aware combo |
| **Intelligence** | Form, H2H, lineup news | Odds drift, momentum shift | Per-leg odds i overlap check |
| **Primary action** | LOG BET | LOG BET (live flag) | BUILD ACCUMULATOR |

Jedan tap na **Tier Mode Selector** ispod AppBara — cijela aplikacija se adaptira aktivnom tieru (prompt, suggestion chips, Bets screen filter, empty states).

---

## Znacajke

### Intelligence Layer
Simultano skenira **5 izvora** i kalkulira **confluence score (0-6.0)** po watched mecu:

- **The Odds API** (0-2.0) — decimalne kvote, bookmaker margin, drift iz S4 snapshot engine-a
- **Football-Data.org** (0-1.5) — form last 5, H2H, standings za EPL/CL
- **BallDontLie NBA** (0-1.0) — last 10 W/L, rest days
- **Reddit** (0-1.0) — community sentiment iz r/soccer, r/NBA, r/sportsbook
- **Telegram** (0-0.5) — tipster signali s reliability scoring-om po kanalu

Kategorije ishoda: **STRONG_VALUE** (>=4.5) / **POSSIBLE_VALUE** (>=3.0) / **WEAK_SIGNAL** (>=1.5) / **LIKELY_SKIP** / **INSUFFICIENT_DATA** (<2 aktivna izvora).

### Betting i tracking
- Manual bet entry iz 2 tocke (FAB u Bets tabu + LOG BET iz Trade Action Bar-a)
- Live vs pre-match distinction preko `matchStartedAt` polja
- Settlement flow (Won / Lost / Void) s automatskim P&L racunom
- Accumulator builder s correlation warnings (isti mec, isti dan/liga)
- Bankroll management (total + default stake unit + valuta)
- Per-sport P&L breakdown (win rate, ROI, totalP&L po sportu)
- Filter i search (sport, status, datum range, text search)

### Grafovi i vizualizacija
- **Odds Movement Chart** — drift line chart na watched matches (iz S4 snapshot historijata)
- **Form Chart** — W/D/L bar sequence za zadnjih 5 mecva (soccer, iz Football-Data)
- **Equity Curve** — kumulativna P&L krivulja kroz settled bets
- **Tennis Info Panel** — bookmaker favourite + implied probabilities + margin

### Push notifikacije
- Kickoff reminders (24h / 1h / 15 min prije)
- Odds drift alerts (>5% move na watched match)
- VALUE signal alerts (kad Claude vrati `**VALUE**` marker)
- Per-tip on/off toggle u Settings

### Detail screens
- **MatchDetailScreen** — 4 taba (Overview / Intelligence / Charts / Notes)
- **IntelligenceDashboardScreen** — per-match confluence s per-source breakdown
- **BotManagerScreen** — Telegram channel reliability stats (Novo/Niska/Srednja/Visoka)
- **AccumulatorBuilderScreen** — leg picker iz watched matches + correlation warnings

---

## Instalacija

### Preuzimanje APK-a
1. Preuzmi najnoviji `betsight-v3.1.2.apk` iz repozitorija ili release-a
2. Android: Postavke -> Sigurnost -> Dopusti nepoznate izvore
3. Instaliraj i pokreni

### Iz izvora
```bash
git clone https://github.com/nroxa92/claude_betsight.git
cd claude_betsight
flutter pub get
flutter build apk --debug
```

---

## Konfiguracija

| Servis | Obavezno | Namjena |
|--------|----------|---------|
| **Anthropic API Key** | Da | Claude AI analiza |
| **The Odds API Key** | Da | Kvote za mecve |
| **Football-Data.org Token** | Preporuceno | Forma, H2H, standings za soccer |
| **Telegram Bot Token** | Opcionalno | Tipster channel monitoring |
| **BallDontLie NBA** | Automatski | Bez registracije |
| **Reddit** | Automatski | Public JSON endpoint |

BallDontLie i Reddit rade bez konfiguracije. Novi korisnik? -> [NEWBIE_GUIDE.md](NEWBIE_GUIDE.md)

---

## Tehnicki stack

| Komponenta | Tehnologija |
|-----------|-------------|
| Framework | Flutter 3.41+ / Dart 3.11+ |
| State management | Provider (8 ChangeNotifier-a) |
| AI | Anthropic Claude API (claude-sonnet-4) |
| Odds data | The Odds API v4 |
| Sport data | Football-Data.org v4, BallDontLie, Reddit JSON |
| Tipster signals | Telegram Bot API (getUpdates polling) |
| Charts | fl_chart 0.69 |
| Notifications | flutter_local_notifications 18.0 + timezone |
| Local storage | Hive (13 boxes) |
| HTTP client | http 1.4 |

---

## Dokumentacija

| Dokument | Namjena |
|----------|---------|
| [NEWBIE_GUIDE.md](NEWBIE_GUIDE.md) | Vodic za pocetnike (korak-po-korak od registracije do prvog bet-a) |
| [MANUAL.md](MANUAL.md) | Korisnicki prirucnik (tier walkthrough, troubleshooting, FAQ) |
| [OVERVIEW.md](OVERVIEW.md) | Tehnicka arhitektura (session history, dependency graph, Hive boxes) |
| [WORKLOG.md](WORKLOG.md) | Development log (S1-S10, svih 10 sesija) |
| [BETLOG.md](BETLOG.md) | Template za biljezenje ishoda Claude preporuka |

---

## Licenca

Proprietary Software License — All Rights Reserved. Vidi [LICENSE](LICENSE).

---

**BetSight nije financijski savjet i nije kladionica.** App je alat za pattern analizu i edukaciju. Klada odgovorno. Never bet more than you can afford to lose. DYOR.

<div align="center">
Izradeno s Claude AI
</div>
