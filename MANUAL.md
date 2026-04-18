# BetSight — Korisnicki prirucnik

**Za koga je ovaj prirucnik:** netko tko prvi put otvara BetSight. Ne pretpostavljamo da znas sto je implied probability, koje su razlike izmedju PRE-MATCH i LIVE marketa, ili kako funkcionira API kljuc. Sve se objasnjava u hodu.

**Verzija aplikacije:** 3.1.2
**Licenca:** Proprietary
**Platforma:** Android (primarno) + Windows desktop (build)
**Datum prirucnika:** 2026-04-18

---

## Kako citati ovaj prirucnik

- Prodji **redom od 1 do 11**. Svaka se sekcija nadovezuje na prethodnu.
- Sekcije **12 nadalje** (Accumulator, Telegram, Intelligence Dashboard, scenariji) citaj po potrebi.
- Gdje god vidis ▶ **to napravi sad** — to je korak koji bi trebao izvrsiti dok citas.
- Ako nesto ne razumijes, potrazi pojam u **Rjeniku** na kraju (sekcija 23).

---

## Sadrzaj

1. [Sto je BetSight i koji je cilj](#1-sto-je-betsight)
2. [Osnovni betting pojmovi koje trebas razumjeti](#2-osnovni-betting-pojmovi)
3. [Three-Tier Investment Framework](#3-three-tier-investment-framework)
4. [Intelligence Layer — 5 izvora obavjestajnog skeniranja](#4-intelligence-layer)
5. [Prvo pokretanje aplikacije — sto ces vidjeti](#5-prvo-pokretanje-aplikacije)
6. [Turneja po aplikaciji — 4 taba + tier selector](#6-turneja-po-aplikaciji)
7. [Postavljanje API kljuceva](#7-postavljanje-api-kljuceva)
8. [Tvoja prva analiza — tutorijal](#8-tvoja-prva-analiza)
9. [Kako citati Claudeov odgovor](#9-kako-citati-claudeov-odgovor)
10. [Tvoj prvi bet — tutorijal](#10-tvoj-prvi-bet)
11. [Pracenje pozicija i settlement](#11-pracenje-pozicija-i-settlement)
12. [Bankroll management i risk](#12-bankroll-management-i-risk)
13. [Accumulator strategija](#13-accumulator-strategija)
14. [Telegram Monitor — detaljno](#14-telegram-monitor)
15. [Intelligence Dashboard — detaljno](#15-intelligence-dashboard)
16. [Charts i vizualizacija](#16-charts-i-vizualizacija)
17. [Push notifikacije](#17-push-notifikacije)
18. [Bot Manager — upravljanje kanalima](#18-bot-manager)
19. [Tipicni scenariji — sto se dogadja tijekom dana](#19-tipicni-scenariji)
20. [Problemi i rjesenja](#20-problemi-i-rjesenja)
21. [Sigurnost — sto moras znati](#21-sigurnost)
22. [Cesto postavljana pitanja](#22-cesto-postavljana-pitanja)
23. [Rjecnik pojmova](#23-rjecnik-pojmova)

---

## 1. Sto je BetSight

### 1.1 U jednoj recenici

BetSight je aplikacija koja ti pomaze **pronaci value bet-ove** u nogometu, kosarci i tenisu, **pitati Claude AI** je li postoji edge, i **zabiljeziti klade** koje napravis — sve unutar iste app-e.

### 1.2 Sto rjesava (ili zasto postoji)

Zamisli uobicajeni proces kad netko zeli naci value bet:

1. Otvara kladionicin sajt, pretrazuje raspored
2. Usporedjuje kvote izmedju 3-4 kladionice
3. Otvara Google za H2H povijest
4. Prebacuje se u Twitter/Reddit da vidi mišljenja
5. Otvara Telegram kanal tipster-a, cita sto kazu
6. Manualno racuna implied probability
7. Pokusa procijeniti je li kvota "sharp"
8. Konacno klada, pamti mozda ili ne
9. Nakon meca — ako se sjeti — biljezi u neki notebook

Traje 15-30 min po mecu. **BetSight sve to radi u jednoj app-i u 2-5 minuta.**

Verzija 1.0.0 (S1) imala je osnovu: Matches screen, Claude chat, Settings. Verzije od tada:
- **v1.1.0 (S2)** — VALUE/WATCH/SKIP markeri, Value Bets filter s 3 preseta
- **v1.2.0 (S3)** — Bet tracking, bankroll, P&L summary
- **v1.3.0 (S4)** — Telegram tipster monitor, Odds Snapshot Engine s drift indicator
- **v1.3.1 (S5)** — Cache layer, rate limit protection, snapshot dedup
- **v1.3.2 (S5.5)** — Prompt redesign, Trade Action Bar, MonitoredChannel reliability
- **v2.0.0 (S6)** — Multi-Source Intelligence Layer (5 izvora, confluence score 0-6.0)
- **v3.0.0 (S7)** — Three-Tier Framework (PRE-MATCH/LIVE/ACCUMULATOR), Charts, Push, Detail screens
- **v3.1.0 (S8)** — Stabilization, per-sport P&L, filter/search
- **v3.1.1 (S9)** — Tennis info panel, Accumulator rename, backlog cleanup
- **v3.1.2 (S10)** — Documentation final (ovaj prirucnik)

> Ako si potpuni pocetnik u kladjenju, pogledaj [NEWBIE_GUIDE.md](NEWBIE_GUIDE.md) za pojednostavljen uvod.

### 1.3 Sto BetSight NIJE

- **Nije kladionica.** Ne moze primiti uplatu, ne isplacuje dobitke. To radis preko svoje kladionice.
- **Nije magija.** Ne zna buducnost. Claude-ova procjena je korisna u ~55-65% slucajeva (ovisno o tvom follow-up-u), ne 100%.
- **Nije pasivni "tipster bot".** Ne radi analizu dok ti ne pitas. Nema auto-bet-inga. Ti odlucujes sve.
- **Nije finansijski savjet.** Ti odlucujes, ti snosis gubitke.
- **Nije automatska kladionica.** BetSight ti daje informacije; ti ideš kladioncinom app-om da stvarno stavis stake.

### 1.4 Koji AI se koristi

**Claude** od Anthropica — jedan od najnaprednijih AI asistenata. BetSight ga koristi kroz sluzbeni Anthropic API. AI dobiva strukturirane podatke o mecu (kvote, H2H, forma, tipster signali, tvoja povijest) i vraca procjenu: **VALUE / WATCH / SKIP** s argumentacijom.

U v2.0.0+, Claude automatski prima **Intelligence Report** iz 5 izvora — Odds API, Football-Data, BallDontLie NBA, Reddit, Telegram — te ih koristi za precizniju analizu. U v3.0.0 Claude dodatno prilagodjava analizu ovisno o aktivnom tieru (PRE-MATCH/LIVE/ACCUMULATOR) — svaki tier ima vlastite suggestion chipove, fokus analize i Claude system prompt appendix.

### 1.5 Licenca

BetSight je pod **Proprietary Software License** — vidi LICENSE fajl. Trenutno je za osobnu uporabu, bez obveza o open-source distribuciji.

---

## 2. Osnovni betting pojmovi

Pojmovi koje moras razumjeti prije korištenja app-e. Ako ti je sve poznato, preskoci na sekciju 3.

### 2.1 Decimal Odds (kvote)

Europska norma za kvote. **BetSight koristi iskljucivo decimal format.**

Formula: `potencijalni povrat = stake × odds`.

Primjeri:
- Odds 2.00 — stake 10 → povrat 20 (profit 10)
- Odds 1.50 — stake 10 → povrat 15 (profit 5)
- Odds 5.00 — stake 10 → povrat 50 (profit 40)

Visa kvota = manji favorit = rijedji dobitak ali veci payout.

### 2.2 Implied Probability

Vjerojatnost koju kvota "implicira". Formula: `p = 1 / odds`.

- Odds 2.00 → implied probability 0.50 = **50%**
- Odds 1.50 → implied probability 0.667 = **67%** (favorit)
- Odds 5.00 → implied probability 0.20 = **20%** (underdog)

Ako **tvoja** procjena stvarne vjerojatnosti je **veca od implied**, to je **value**.

Primjer: Claude procjenjuje da Arsenal ima 55% sanse za pobjedu, a kvota je 2.00 (implied 50%) → **5 percentage points edge** (+5pp).

### 2.3 Bookmaker Margin

Ugradjeni profit kladionice. Za 2-way market (tenis):
- Ako Home = 2.00 i Away = 2.00, sum implied probabilities = 50% + 50% = 100% → 0% margin (fair odds, rijetko se vidi)
- Ako Home = 1.95 i Away = 1.95, sum = ~103% → 3% margin (sharp book)
- Ako Home = 1.80 i Away = 1.80, sum = ~111% → 11% margin (soft book)

Pravilo:
- **<5% margin = sharp book** (Pinnacle, Betfair exchange) — najbolja mjesta za value
- **5-8% = normalno** (vecina euro kladionica)
- **>8% = soft book** (reatail kladionice, rijetko bolje od PinnacIe kroz value)

BetSight prikazuje margin za svaki meč — Intelligence Dashboard odus flaga soft book kao "inactive" odds source.

### 2.4 Tri sporta koje BetSight podrzava

**Soccer (⚽):**
- English Premier League (EPL)
- UEFA Champions League
- Forma + H2H kroz Football-Data (ako postavis token)

**Basketball (🏀):**
- NBA (regular season + playoffs)
- Last 10 W/L + rest days kroz BallDontLie (automatski)

**Tennis (🎾):**
- ATP Singles
- Nema dedicated data source-a — koristi se Odds API (implied probability + margin) + TennisInfoPanel u detail screenu

Niza liga, NHL, MMA, eSports — **nisu pokriveni** u BetSight v3.1.2.

### 2.5 Market / Selection

Sto klades na meč. BetSight trenutno podrzava **head-to-head (h2h)** market:
- **Home** — domaci tim pobjeduje
- **Away** — gostujuci tim pobjeduje
- **Draw** — nerjeseno (samo soccer, NBA i ATP nemaju)

Ostale markete (Over/Under, Asian Handicap, Both Teams To Score) BetSight ne dohvaca direktno, ali mozes ih unijeti **rucno** u Bet Entry Sheet.

### 2.6 Pre-Match vs Live

- **Pre-Match:** Klade se prije pocetka meca. Kvote stabilne, imas vremena za DYOR. **Preporuca za pocetnike.**
- **Live (In-play):** Klade se tijekom meca. Kvote se mijenjaju svake sekunde ovisno o rezultatu. Vece varijance, vise stress-a, vece sanse za emotional decisions.

BetSight razlikuje ova dva kroz `matchStartedAt` field na Bet objektu:
- `placedAt > matchStartedAt` → live bet
- `placedAt <= matchStartedAt` → pre-match bet

### 2.7 Stake

Koliko klades. Pravilo pocetnika: **1-5% bankroll-a po stake-u**.

Primjer: Bankroll 200 EUR, default stake 5% = 10 EUR. Imas 20 bet-ova prije nego sto si u rizici zadnjeg novca.

### 2.8 ROI (Return on Investment)

`ROI = (total profit / total staked on settled bets) * 100`

- Pozitivan ROI (npr. +5%) = dugorocno profitabilan
- Negativan ROI (-2%) = gubis, BetSight to prepoznaje i pokazuje crvenu P/L u Bets tabu

Profesionalni tipsteri tipicno imaju **+3% do +8% ROI**. Veci od 15% je tipsko nesustain — varijance ili samplebias.

### 2.9 Value Bet

Bet gdje je implied probability < tvoja procjena stvarne vjerojatnosti. Dugorocno, **konzistentno kladenje value bet-ova = pozitivan ROI**.

BetSight cijela filozofija vrti se oko prepoznavanja value bet-ova kroz:
1. Intelligence layer (5 izvora daju objektivne signale)
2. Claude AI (subjektivna analiza i sinteza)
3. Value Bets filter preset (3 deterministicka kriterija)

### 2.10 Accumulator (Acca / Parlay)

Kombinacija 2+ bet-ova gdje **svi** moraju pogoditi da se dobije. Kvote se multipliciraju:
- 3-leg acca s kvotama 2.0, 1.8, 1.5 → combined 5.40
- Stake 10 EUR → potencijalni povrat 54 EUR (profit 44)

**Rizik:** Ako samo **jedan** leg izgubi, cela acca izgubi. S 3 nezavisna leg-a s 60% sanse svaki, ukupna sansa = 0.6 × 0.6 × 0.6 = **21.6%** — vrlo niska.

BetSight ima dedicated **Accumulator Builder Screen** s correlation warnings (vidi sekciju 13).

---

## 3. Three-Tier Investment Framework

Glavna osobitost BetSight-a — umjesto jednog pristupa za sve, imas **tri tier-a** svaki sa svojim promptom, UI-jem i strategijom.

### 3.1 Kako prebaciti tier

**Tier Mode Selector** je horizontalni selector **ispod AppBar-a**, iznad svih screen-ova:

```
+----------------------------------------+
|  BetSight                              |  <- AppBar
+----------------------------------------+
|  ⚽ Pre-Match  🔴 Live  🏆 Accumulator |  <- Tier Selector
+----------------------------------------+
|  ... screen content (Matches/Bets/...)|
```

Tapni na tier button. Aktivan tier se oznacava sa:
- **Boja (purple / red / orange)**
- **Border** i blazi fill
- **Font weight bold**

Perzistira se — zatvor aplikacije, ponovno otvori — tier ostane na zadnjem izabranom.

### 3.2 PRE-MATCH (⚽ default)

**Horizont:** 24-48 sati prije kickoff-a.
**Filozofija:** Deep DYOR (Do Your Own Research). Imas vremena za istraziti sve.
**Rizik:** Niski — najstabilniji stil kladjenja.

**Ponasanje app-e:**
- **Analysis tab** suggestion chips:
  - "Analyze tomorrow's EPL"
  - "Best value bets this weekend"
  - "Underdog picks under 4.0 odds"
- **Claude system prompt** appendix: "Focus on deep pre-kickoff analysis. Consider form, H2H, injuries, weather, team news. Flag value where bookmaker implied probability < your estimate by at least 3 percentage points."
- **Bets tab** filter: samo bet-ovi gdje `placedAt <= matchStartedAt`
- **Bet Entry Sheet** postavlja `matchStartedAt = kickoff time`

**Kad koristiti:** Vecerinju analizu za sutrasnje mecve. Vikend-review za predstojeci tjedan.

### 3.3 LIVE (🔴)

**Horizont:** Tijekom meca (in-play).
**Filozofija:** Reagiraj na momentum shifts i odds drift.
**Rizik:** Visok — emotivno, kratak prozor odlucivanja, nagle kvote.

**Ponasanje app-e:**
- **Analysis tab** suggestion chips:
  - "Live odds movement on watched"
  - "In-play value — which matches look mispriced now?"
  - "Momentum shift detection"
- **Claude prompt appendix:** "Focus on momentum reads and in-play odds drift. If odds data shows recent shift, weigh that heavily. Short decision windows. Favor clear, concise recommendations. Skip if data is ambiguous — no time for user to deliberate."
- **Bets tab** filter: samo bet-ovi gdje `placedAt > matchStartedAt`
- **Bet Entry Sheet** postavlja `matchStartedAt = now - 1 min` (simulacija da je mec vec pocneo)

**Kad koristiti:** Za iskusne kladjenje. In-play market je brzi — BetSight ti pomaze ali ti si onaj koji reagira.

### 3.4 ACCUMULATOR (🏆)

**Horizont:** Multi-match build.
**Filozofija:** Combine 2-5 legs s correlation awareness.
**Rizik:** Najvisi — sve mora pogoditi.

**Ponasanje app-e:**
- **Analysis tab** suggestion chips:
  - "Build a 3-leg accumulator from my watched matches"
  - "Check correlation in my current selections"
  - "Conservative acca — all favorites under 2.0"
- **Claude prompt appendix:** "User is building a multi-bet combo. For each leg, consider correlation: avoid legs that share dependencies. Total odds multiply — flag if combined odds exceed 20.0 (unrealistic value territory). Encourage 2-4 legs, not 10."
- **Bets tab** kompletno mijenja izgled:
  - Umjesto Open/Settled tabova, pokazuje **Building / Placed / Settled** za accumulator-e
  - FAB otvara **Accumulator Builder Screen**
- Ne prikazuje pojedinacne bet-ove (oni su u Pre-Match ili Live tieru)

**Kad koristiti:** Rijetko. Accumulator-i su visoko-rizicni — za "fun" klade s malo stake-a (1-2% bankroll-a), ne za serious value hunting.

### 3.5 Usporedba tri tiera

| | **PRE-MATCH** | **LIVE** | **ACCUMULATOR** |
|---|---|---|---|
| **Horizont** | 24-48h | Tijekom meca | Build unaprijed |
| **Claude ton** | Duboka analiza | Koncizna, brza | Correlation-aware |
| **Expected WIN rate** | 40-55% | 30-45% | 10-25% (veci payout) |
| **Disciplinski horizont** | Dugorocno | Trenutacno | Srednjorocno |
| **Primary action** | LOG BET | LOG BET (live) | BUILD ACCUMULATOR |
| **Preporuceni stake** | 3-5% bankroll | 1-3% | 0.5-2% (visok rizik) |

**Preporuka za pocetnike:** Pocni s Pre-Match. Ignoriraj Live i Accumulator dok ne budes imao 30+ settled bet-ova.

---

## 4. Intelligence Layer

**Intelligence Layer** je BetSight-ov multi-source scoring engine. Agregira podatke iz 5 razlicitih izvora u jedan **confluence score (0-6.0)** po **watched mecu**.

### 4.1 Pet izvora

Svaki izvor ima **maksimalni score** (weighted po pouzdanosti):

| Izvor | Max | Napomene |
|-------|-----|----------|
| 📊 **The Odds API** | 2.0 | Primarni — kvote, margin, drift |
| ⚽ **Football-Data.org** | 1.5 | Soccer only — forma, H2H, standings |
| 🏀 **BallDontLie NBA** | 1.0 | Basketball only — last 10, rest days |
| 💬 **Reddit** | 1.0 | Community sentiment |
| 📡 **Telegram** | 0.5 | Tipster signali, weighted by reliability |

**Suma:** 6.0 maximum. Ovo je isti pattern kao CoinSight v3.0.0 — agregacija 5 heterogenih izvora u jedan score.

### 4.2 Odds API scoring (0-2.0)

Logika:
- **Base 0.5** za meč sa h2h kvotama
- **+0.5** ako margin < 5% (sharp book)
- **+0.5** ako postoji significant drift (>3% move na nekom outcome-u izmedju 2+ snapshota)
- **+0.5** ako drift smjer je **non-Home** (manje ocito — smart money ide prema draw ili away outcome-u)

Primjer reasoning string:
```
"margin 4.2%, sharp book, drift Home +2.3%"
```

### 4.3 Football-Data scoring (0-1.5, soccer only)

Zahtjeva Football-Data.org API token.

Logika:
- **Base 0.3** ako imas FootballDataSignal (fetched in last 3h, cache)
- **+0.4** ako jedna strana ima strong form (≥4 wins u zadnjih 5)
- **+0.4** ako H2H jasno favorizira jednu stranu (≥3 wins u zadnjih 5)
- **+0.4** ako standings gap ≥8 pozicija (underdog potential)

Primjer:
```
"home strong form, home H2H dominant, standings gap 11, form HWDLW ADLWW"
```

### 4.4 NBA Stats scoring (0-1.0, basketball only)

Koristi BallDontLie.io (besplatno, bez API key-a).

Logika:
- **Base 0.3** ako imas NbaStatsSignal cached
- **+0.35** ako jedna strana ima ≥7/10 recent wins (hot streak)
- **+0.35** ako rest days difference ≥3 dana (fatigue arbitrage)

### 4.5 Reddit scoring (0-1.0)

Koristi public Reddit JSON (bez API key-a).

Logika:
- **Inactive** ako mention count < 3
- **Base 0.2** ako je aktivan
- **+0.3** ako mention count ≥ 10 (high buzz)
- **+0.3** ako sentiment bias |x| > 0.3 (clear tilt home/away)
- **+0.2** ako top post ima ≥500 upvotes (viral)

### 4.6 Telegram scoring (0-0.5, weighted)

Koristi Telegram Bot API preko tvog bota.

Logika: signal-ovi iz tvojih kanala koji spominju timove. Svaki signal ponderiran po reliability kanala:
- **Visoka** = 1.0 weight
- **Srednja** = 0.7
- **Niska** = 0.3
- **Novo** = 0.5

`score = clamp(weighted_sum × 0.25, 0, 0.5)`

### 4.7 Confluence score → Kategorija

| Score | Kategorija | Boja | Interpretacija |
|-------|-----------|------|----------------|
| ≥ 4.5 | **STRONG_VALUE** | Zelena | Multiple sources align. Worth deep analysis. |
| 3.0 - 4.4 | **POSSIBLE_VALUE** | Svijetlo-zelena | Some signals present. Confirm. |
| 1.5 - 2.9 | **WEAK_SIGNAL** | Narancasta | Weak indications. Not clearly actionable. |
| < 1.5 | **LIKELY_SKIP** | Crvena | Sources suggest no edge. |
| < 2 active | **INSUFFICIENT_DATA** | Siva | Nedovoljno izvora da se odluci. |

### 4.8 Auto-refresh

BetSight automatski osvjezava reports svake 1 sat (Timer.periodic) — ali **samo za watched mecve** i **samo ako imas API kljuceve**. To je hibrid pristup: auto-refresh drzi reports svjeze, a **on-demand Generate button** u Dashboard-u je za kad ti treba odmah.

---

## 5. Prvo pokretanje aplikacije

Kad prvi put otvoriš BetSight, vidjet ceš:

1. **AppBar** na vrhu — "BetSight" title
2. **Tier Mode Selector** ispod — tri button-a (Pre-Match / Live / Accumulator), aktivan je **Pre-Match** (default)
3. **Matches tab** content:
   - Sport filter chip-ovi: All / ⚽ Soccer / 🏀 Basketball / 🎾 Tennis
   - TabBar: **Value Bets** | **All Matches**
   - Glavno podrucje — ako nisi jos postavio Odds API kljuc, vidjet ces empty state s key-off ikonom i porukom "The Odds API key required — Go to Settings to add your key"
4. **Bottom navigation** — 4 tab-a: Matches / Analysis / Bets / Settings

**Sto NE vidis (jos):**
- Mecve u Value Bets i All Matches — nema kljuc za Odds API
- Chat poruke u Analysis — nema kljuc za Anthropic
- Bet-ove u Bets — nista nije jos dodano
- Intelligence Dashboard shortcut button — samo kad imas zvjezdicane mecve

### Prvi obavezni korak

Idi na **Settings** i dodaj:
1. **Anthropic API Key** (obavezno — za Claude)
2. **The Odds API Key** (obavezno — za kvote)

Detalji u sekciji 7 i NEWBIE_GUIDE.md.

---

## 6. Turneja po aplikaciji

### 6.1 Matches tab

**Elementi na ekranu:**

1. **AppBar:** title "BetSight"
2. **Sport filter:** horizontal chip selector (All / Soccer / Basketball / Tennis). Default = All.
3. **API limit banner (conditional):** Ako su ti API requests-i ispod 20, vidis orange warning. Ispod 1 → red banner "API quota exhausted".
4. **Cached badge (conditional):** "Cached (5m ago) — pull to refresh". Prikazuje se kad data iz cache-a.
5. **Intelligence shortcut (conditional):** "Intelligence for N watched" button — vidi se kad ima ≥1 zvjezdicani meč.
6. **TabBar:** **Value Bets** (default, prikazuje mecve koji prolaze value preset filter) | **All Matches** (kompletna lista).
7. **Match lista (ListView):** svaki match je MatchCard widget s:
   - Sport icon + league name
   - LIVE badge ili countdown do kickoff-a
   - Star toggle za watched
   - Team names ("Home vs Away")
   - OddsWidget (2-3 chipa)
   - (If watched i ima drift) Drift indicator

**Akcije:**
- **Pull-to-refresh:** povuci list prema dolje → forceRefresh API fetch (bypass cache)
- **Tap na karticu:** otvara **MatchDetailScreen** (4 taba)
- **Star toggle:** dodaje/uklanja iz watched listi
- **Sport filter chips:** filtrira prikaz po sportu
- **Value Bets tab:** prikazuje samo mecve koji prolaze aktivni value preset (Conservative/Standard/Aggressive)

### 6.2 Analysis tab

**Elementi:**

1. **AppBar:** title "Analysis"
2. **Signal banner (conditional):** Ako postoje recent tipster signali (< 6h), banner "X recent tipster signals — View →"
3. **Chat area:** ListView chat bubbles (user + assistant)
4. **Empty state (when chat is empty):** Tier icon + "X analysis" title + philosophy + 3 tier-specific suggestion chips
5. **Typing indicator (conditional):** "Thinking..." s CircularProgressIndicator kad je `isLoading`
6. **Staged matches bar (conditional):** "X matches staged for next question" — kad si stage-ao matches kroz Matches → select → FAB
7. **Staged signals bar (conditional):** "X tipster signals staged for next question"
8. **Error bar (conditional):** Red bar s error porukom, Dismissible
9. **Input bar:** delete_outline button + TextField + send button

**Akcije:**
- **Tapni ActionChip:** postavlja text u input i salje odmah
- **Delete button:** otvara confirm dialog "Clear chat?" → clearChat()
- **Send:** salje poruku Claude-u (uz injected kontekst)
- **Tap "View →" u signal banneru:** otvara `_SignalSheet` full-screen modal
- **Tap "LOG BET" u Trade Action Bar-u:** otvara Bet Entry Sheet
- **Tap "SKIP":** biljezi feedback + SnackBar
- **Tap "ASK MORE":** pre-filla input "Why do you think this is value?"

### 6.3 Bets tab

**U Pre-Match ili Live tier-u:**

1. **AppBar:** title "Bets"
2. **P&L Summary Card:** 4 metrics (Total / Win rate / ROI / Total P/L)
3. **Equity Curve Card (conditional):** ako ≥2 settled bets
4. **Per-Sport Breakdown Card (conditional):** tabular breakdown po sportu
5. **Bets Filter Bar:** search TextField + 3 chip-a (Sport / Status / Date) + Clear chip (conditional)
6. **TabBar:** Open | Settled
7. **Bet lista:** BetCard widgets

**U Accumulator tier-u:**

1. **AppBar:** title "Accumulators"
2. **TabBar:** Building | Placed | Settled
3. **Accumulator lista:** AccumulatorCard widgets

**FAB:**
- Pre-Match/Live: otvara manual Bet Entry Sheet
- Accumulator: otvara Accumulator Builder Screen

### 6.4 Settings tab

**Sekcije (redom odgore):**

1. **Anthropic API Key** (obavezno za Claude)
2. **The Odds API Key** (obavezno za Matches)
3. **Football-Data.org API** (opcionalno, za soccer Intelligence)
4. **Value Bets Filter** — RadioGroup s 3 preseta (Conservative/Standard/Aggressive)
5. **Cache & Limits** — API usage progress bar + TTL chip selector
6. **Bankroll** — total + default stake + currency
7. **Notifications** — 3 SwitchListTile toggles
8. **Telegram Monitor** — token + "Manage Channels" button + monitoring switch
9. **About** — version + links + disclaimer

---

## 7. Postavljanje API kljuceva

Detalji u [NEWBIE_GUIDE.md](NEWBIE_GUIDE.md) sekcije 3-6. Kratak summary:

| API | Obavezno? | Gdje registrirati | Sto dobivas |
|-----|-----------|-------------------|-------------|
| Anthropic Claude | Da | console.anthropic.com | AI analiza |
| The Odds API | Da | the-odds-api.com | Kvote (500 req/mj free) |
| Football-Data.org | Preporuceno | football-data.org | Soccer form + H2H |
| Telegram Bot | Opcionalno | @BotFather | Tipster signali |
| BallDontLie | Automatski | - | NBA stats |
| Reddit | Automatski | - | Community sentiment |

### Dynamic re-wire

Ako promijenis Football-Data kljuc u Settings:
- **Prije v3.1.0 (S8):** trebao si restart-ati app
- **Nakon S8:** IntelligenceProvider re-wire aggregator odmah → novi key je "active" bez restart-a

Za druga 2 obavezna kljuca (Anthropic, Odds) promjena ne zahtijeva restart — provideri cache-iraju cuvanje u Storage i next call koristi novi kljuc.

---

## 8. Tvoja prva analiza

### Prerequisities
- Anthropic + Odds API kljucevi dodani
- Barem 1 meč u Matches listi
- (Opcionalno) 1 zvjezdican meč

### Korak po korak

**Korak 8.1 — Odaberi meč**

Dva nacina:

**A) Iz Matches → MatchDetailScreen (preporucen):**
1. Tapni na karticu u Matches
2. Otvara MatchDetailScreen s 4 taba
3. Overview tab — tapni "Analyze in AI" button
4. Prebacujes se na Analysis tab

**B) Iz Matches → multi-select:**
1. Dugi tap (ili checkbox u select mode) na karticu
2. Odaberi 1-3 mecva
3. FAB "Analyze N matches" → stage matches → switch na Analysis tab

**C) Direktno Analysis tab:**
1. Idi na Analysis tab
2. Postavi pitanje bez context-a

**Korak 8.2 — Postavi pitanje**

Empty state pokazuje tier-specific suggestion chips. Tapni jedan ili tipkaj rucno.

Primjeri:
- "Daj mi svoju analizu"
- "Gdje vidis edge ako postoji?"
- "Koliki je bookmaker margin i je li knjiga sharp?"
- "Ako bih kladio, koja je tvoja preporuka?"

Tap send (✈).

**Korak 8.3 — Pricekaj odgovor**

Tipicno 5-15 sekundi. Tijekom odgovaranja:
- Input je disabled (hint: "Waiting for response...")
- TypingIndicator ispod zadnje poruke

### Sto Claude vidi (context injection)

BetSight salje Claude-u strukturirani blok:

```
[SELECTED MATCHES]
EPL: Arsenal vs Liverpool | kickoff 2026-04-20T14:00:00Z |
odds H/D/A: 2.10/3.40/3.20 | bookmaker Pinnacle
  [drift] Home +2.3% since last snapshot
[/SELECTED MATCHES]

[INTELLIGENCE REPORT — confluence 3.8/6.0 — POSSIBLE_VALUE]
Odds (1.5/2.0): margin 4.2%, sharp book, drift Home +2.3%
Football-Data (1.1/1.5): home strong form, H2H balanced
...
[/INTELLIGENCE REPORT]

[TIPSTER SIGNALS]
[45m ago] @tipsmaster (Soccer): Arsenal home value play 1.95+
[/TIPSTER SIGNALS]

[BETTING HISTORY — last 5 bets]
...
[/BETTING HISTORY]

[TIER: PRE-MATCH — 24-48h horizon]
Focus on deep pre-kickoff analysis...

<tvoje pitanje>
```

Svaki blok je **opcionalan** — ako nema staged matches, `[SELECTED MATCHES]` se izostavlja. Ako nema Intelligence report za taj meč, `[INTELLIGENCE REPORT]` se izostavlja.

Tier appendix je **uvijek prisutan** — Claude vidi koji je trenutni tier.

---

## 9. Kako citati Claudeov odgovor

Svaki Claude odgovor ima **3 dijela**:

### 9.1 Narrative

Claude-ova argumentacija, tipski 2-4 paragrafa. Pokriva:
- Implied probabilities iz kvota
- Forma i H2H ako imas Intelligence report
- Tipster signal interpretacija ako ih stagerio
- Tvoja betting history (potential confirmation bias warning)
- Tier-specific fokus

### 9.2 Specific outcome recommendation

Ako je Claude pronasao edge, mora **eksplicitno navesti:**
- **Koji outcome** (Home / Draw / Away)
- **Na kojim kvotama** (current odds iz konteksta)
- **Tvoja procjena probability vs implied** (≥3pp edge)
- **Concrete next step** ("stake 2% of bankroll", "wait for odds to rise above 2.10")

### 9.3 Marker (zadnja linija)

Tocno jedan od tri markera, **sam na liniji**:

| Marker | Znacenje | Tvoja akcija |
|--------|----------|-------------|
| `**VALUE**` | Clear edge | Razmotri bet. Trade Action Bar se pojavljuje. |
| `**WATCH**` | Marginal edge ili nepotpuno | Ne klada jos. Prati. |
| `**SKIP**` | Nema edge ili too uncertain | Idi dalje. |

### 9.4 Trade Action Bar

Pojavljuje se **samo ispod zadnje assistant poruke kad je VALUE detektiran** i postoji lastLogId u provider-u.

Izgleda:
```
+------------------------------------------+
|  🏁 VALUE signal detected                |
|                                          |
|  [LOG BET]  [SKIP]  [ASK MORE]           |
+------------------------------------------+
```

- **LOG BET** (zeleno) — otvara Bet Entry Sheet s prefill iz stagedMatches.first. Biljezi `UserFeedback.logged` u AnalysisLog.
- **SKIP** — biljezi `UserFeedback.skipped` + SnackBar "Recommendation skipped — logged for calibration". Koristi kad se NE slazes s Claude-om.
- **ASK MORE** — biljezi `UserFeedback.askedMore` + pre-fill input "Why do you think this is value? What's the main risk?"

**Zasto tri opcije, ne samo LOG BET?**

- SKIP daje BetSight-u podatak da je Claude pogrijesio u procjeni — tokom vremena mozes analizirati `getFeedbackStats()` u Storage-u i vidjeti kalibrirnost
- ASK MORE daje Claude-u priliku da argumentira dublje

### 9.5 Marker parsing

BetSight parser **`parseRecommendationType(response)`** iz `lib/models/recommendation.dart`:

1. Split by newline, trim each line
2. Trazi EKSACTNO `**VALUE**` na posebnoj liniji → return VALUE
3. Fallback: `**WATCH**` → WATCH
4. Fallback: `**SKIP**` → SKIP
5. Ako ni jedan ne nadje kao line, trazi inline (contains) istim redom
6. Inace return NONE

Logicno: VALUE provjerava prvi jer je najspecificnija preporuka.

---

## 10. Tvoj prvi bet

### Korak 10.1 — Osiguraj bankroll

OBVEZNO prije prvog bet-a. Settings → Bankroll → upisi Total + Default Stake Unit + Currency → Save.

### Korak 10.2 — Odaberi ulazni point

- **Iz Trade Action Bar-a** nakon VALUE (preporuceno) — prefilled iz staged matcha
- **FAB u Bets tabu** (u Pre-Match ili Live tieru) — prazan Bet Entry Sheet

### Korak 10.3 — Popuni Bet Entry Sheet

Polja:
- **Sport** (dropdown) — disabled ako je prefilled
- **League** (text) — obavezno
- **Home team / Away team** (text) — obavezno
- **Selection** (ChoiceChip Row) — Home/Draw/Away (Draw samo soccer)
- **Odds** (decimal input) — must be > 1.0
- **Stake** (decimal input, prefilled s default stake unit)
- **Bookmaker** (optional text)
- **Notes** (optional, multiline)

### Korak 10.4 — Save

Tap **"Save Bet"** button. Validacija:
- Obavezna polja nisu prazna
- Odds > 1.0
- Stake > 0
- Selection = Draw samo ako je Sport = soccer

Uspjeh → SnackBar "Bet logged" + bet se pojavljuje u Bets tab → Open subtab.

### Korak 10.5 — matchStartedAt logic

Ovisno o aktivnom tieru:

- **PRE-MATCH:** `matchStartedAt = prefilledMatch.commenceTime` (ili null ako je manual bez prefilled)
- **LIVE:** `matchStartedAt = now - 1 min` (forces isLiveBet = true)

Ovo osigurava da se bet prikazuje u ispravnom tier filter-u u Bets tabu.

---

## 11. Pracenje pozicija i settlement

### 11.1 Bets tab — tier view

| Tier | Open subtab | Settled subtab |
|------|-------------|---------------|
| Pre-Match | Pending pre-match bets | Settled pre-match bets (won/lost/void) |
| Live | Pending live bets | Settled live bets |
| Accumulator | **Building / Placed** sub-tabovi | Settled accumulators |

### 11.2 BetCard

Svaki pending bet prikazuje:
- Header: sport icon + league + StatusChip (Pending/Won/Lost/Void)
- Teams + Pick + Odds
- Meta chips: Odds / Stake / Bookmaker
- (Settled) P&L row s ±predznakom i bojom
- (Pending) "Settle" button (ElevatedButton s check_circle_outline)

### 11.3 Settle flow

Tap na pending bet (ili Settle button) otvara **bottom sheet** s 3 opcije:

```
+------------------------------------------+
|  Settle bet                              |
|                                          |
|  Arsenal vs Liverpool                    |
|  Pick: Home @ 1.95                       |
|                                          |
|  [✓ Won]      (zeleno)                   |
|  [✗ Lost]     (crveno)                   |
|  [— Void]     (sivo)                     |
+------------------------------------------+
```

Tap odgovarajuce → bet prelazi u Settled subtab. SnackBar "Bet settled as Won/Lost/Void".

### 11.4 Kalkulacija profita

- **Won:** `profit = stake * (odds - 1)`
- **Lost:** `profit = -stake`
- **Void:** `profit = 0` (povrat stakeа)
- **Pending:** `profit = null` (ne uracunava se u P&L)

### 11.5 Swipe-to-delete

Ako pogrijesis unos:
1. Lista bet-ova → **Swipe** slijeva na desno na kartici
2. Confirm dialog "Delete bet?"
3. Potvrdi

### 11.6 Error handling

Ako Hive write faila (rijetko, but):
- BetsProvider postavlja `_error = "Failed to save bet"` (ili slicno)
- Bets screen pokazuje SnackBar s action "Dismiss"
- Debounced (`_lastShownError`) da ne prikazuje duplikat

---

## 12. Bankroll management i risk

### 12.1 Zašto bankroll

Bankroll je **tvoj ukupni betting kapital**. Ne mijesa se s placama, stanarinom, groom — to je posebni iznos kojim si spreman "igrati" znajući da mozes izgubiti sve.

### 12.2 Stake velicina (Kelly-lite)

Pravilo: **1-5% bankroll-a po bet-u**.

- Konzervativno: 1-2% (idealno za large bankroll-e ili pocetnike)
- Standardno: 2-3%
- Agresivno: 4-5% (samo za iskusne s +ROI track record)

BetSight **upozorava** kad postavis default stake > 5% bankroll-a:
> ⚠️ "Industry recommendation: 1-3% per bet"

### 12.3 Kelly Criterion (nije u BetSightu)

Napredni tipsteri koriste **Kelly Criterion formulu:**
`f = (bp - q) / b`
gdje je:
- f = fraction bankroll-a
- b = net odds (decimal - 1)
- p = procijenjena probability
- q = 1 - p

**BetSight ne implementira Kelly automatski** — korisnik rucno odlucuje stake. Razlog: Kelly zahtijeva tvoju procjenu probability (subjektivna), koja se ne moze automatizirati. Ako zelis Kelly, racuna rucno i koristi kao smjernicu za stake.

### 12.4 Bankroll u BetSight-u

Settings → Bankroll sekcija:
- **Total bankroll** — ukupno (npr. 500 EUR)
- **Default stake unit** — default po bet-u (npr. 15 EUR = 3%)
- **Currency** — EUR/USD/GBP/HRK/CHF/BAM/RSD

Default stake automatski se prefilla u Bet Entry Sheet-u.

### 12.5 Re-balancing

Nakon uspjesnog mjeseca (positive ROI), neki kladjenje su re-balance-aju:
- Bankroll 500 EUR → nakon mjesec +50 EUR → total je sad 550
- Podigni default stake s 15 EUR na 16 EUR (3% od 550)

**Obrnuto:** Nakon losig mjeseca (-50 EUR), smanji default stake.

Ovo BetSight ne radi automatski — moras manualno updejtati u Settings.

---

## 13. Accumulator strategija

### 13.1 Osnovi

Accumulator je bet gdje kombiniras 2+ legs, a **svaki mora pogoditi** da acca dobije.

**Kombinacije kvota:**
- 2 legs s 2.0 svaki → combined 4.0
- 3 legs s 1.8 svaki → combined 5.83
- 5 legs s 1.5 svaki → combined 7.59

**Probability:**
- 2 legs, 60% svaki → 36% ukupna
- 3 legs, 60% svaki → 21.6%
- 5 legs, 60% svaki → 7.8%

### 13.2 Kada accumulator ima smisao

**Ima smisao:**
- Correlation-nezavisni legs (razliciti sportovi, razliciti dani)
- Mali stake (<2% bankroll-a)
- Entertainment + mala nada za veliki payout

**Nema smisla:**
- 10+ legs (prakticno nemoguce pogoditi svih)
- Korelirani legs (npr. 2 leg-a iz istog meca)
- Veliki stake (ocekivana vrijednost tipski negativna)

### 13.3 Accumulator Builder Screen

Pristup: Accumulator tier → Bets tab → FAB (+) → otvara screen.

**Layout:**

```
+------------------------------------------+
|  Build Accumulator            [×]        |  <- AppBar
+------------------------------------------+
|                                          |
|  Legs (2)                                |
|  ┌─ Leg 1: Arsenal vs Liverpool          |
|  │  EPL · Home @ 1.95  [×]               |
|  └─                                      |
|  ┌─ Leg 2: Lakers vs Warriors            |
|  │  NBA · Home @ 2.10  [×]               |
|  └─                                      |
|                                          |
|  Pick from watched matches               |
|  [Chelsea vs United] [...]  (horizontal) |
|                                          |
|  Stake: [____10.00____]                  |
|                                          |
|  Summary:                                |
|  | Legs | Combined | Payout   |          |
|  |   2  |  4.10    | 41.00 EUR |          |
|                                          |
|  ⚠️ Correlation warning (if any)         |
|                                          |
|  [Save accumulator]                      |
+------------------------------------------+
```

### 13.4 Correlation warnings

BetSight detektira dvije vrste korelacije:

1. **Same match:** Dva leg-a iz istog meca (npr. Home + Over 2.5 golova) — tehnicki moze, ali BetSight to oznacava jer je rijetko dobra ideja
2. **Same day/league:** Vise leg-a iz istog natjecanja istog dana (npr. 3 EPL mecve subotu) — weak correlation jer iste vremenske/povezane faktore djeluju na sve

Orange warning banner prikazuje listu warning-a:
```
⚠️ Correlation warning
• Multiple legs from EPL on same day
```

BetSight **ne odbija** sejvati acca s warning-ima — samo te upozorava. Ti odlucujes.

### 13.5 Status flow

```
Building → (tap Place) → Placed → (tap Settle, pick outcome) → Won/Lost/Partial
   |                                    |
   v                                    v
 (tap Delete)                      Settled (final)
```

- **Building:** Draft, moze se jos mijenjati
- **Placed:** Spremljeno (simulira da si stvarno stavio u kladioncinoj app)
- **Won:** Svi legs pogodili
- **Lost:** Barem jedan leg izgubio
- **Partial:** Cash-out ili partial win (pojednostavljeno — profit = 0)

### 13.6 Combined odds realnost

Ako combined odds > 20.0, Claude ce te upozoriti da je to "unrealistic value territory". Tipicno korelirani legs sa fake-high combined kvotama su opasni.

Preporuka: **2-4 legs max**, svaki s kvotama 1.5-2.5, combined u rasponu 4-15.

---

## 14. Telegram Monitor

### 14.1 Kako radi

BetSight koristi **Telegram Bot API**:
1. Ti kreiras bot preko @BotFather
2. Bot dobije token (npr. `123456789:AAF-aBcDe...`)
3. Ti unosis token u BetSight Settings
4. BetSight pokrene **polling loop** — svakih 10 sekundi poziva `getUpdates` endpoint i trazi nove poruke
5. Bot moze primati poruke **samo iz kanala gdje je dodan kao clan** (Telegram dizajnska odluka)

### 14.2 VAZNO — Bot API ogranicenje

Bot API NE moze pristupati svim Telegram kanalima. Samo onima gdje je bot clan.

Posljedica: **Veliki javni tipster kanali** (X betting tips, Y kladionicari s 10k+ clanova) tipski NE dopustaju bot-ove → BetSight ne moze citati njihov content.

Za full obrazlozenje vidi [WORKLOG.md](WORKLOG.md) "By-Design (Will Not Fix) → Telegram Bot API limitation".

### 14.3 Praktican workflow

Buduci da vecini tipster kanala bot ne moze pristupiti, radi se ovako:

1. **Kreiraj vlastiti privatni Telegram kanal** (Nov kanal, samo ti)
2. **Dodaj svoj bot** kao admin
3. Kad vidish interesantnu poruku u nekom (nedostupnom) kanalu, **forward** ili **copy-paste** je u svoj privatni kanal
4. BetSight automatski pokupi tu poruku (jer je bot clan tvog kanala)

Efektivno — ti si "kurator" signala, a bot je "skupljac".

### 14.4 Relevance filter

Ne sve poruke iz kanala se prikazuju u BetSight-u. Postoji **keyword filter:**

Poruka se smatra "relevantna" ako sadrzi bilo koju rijec:
- `tip`, `bet`, `value`, `lock`, `odds`, `pick`, `stake`
- `vs`, `home`, `away`, `draw`, `over`, `under`, `handicap`
- `epl`, `nba`, `atp`, `wta`, `champions`

Ako poruka ne sadrzi ni jednu od ovih, ignorira se (ali se statistika kanala ipak update-a — vidi sljedeca sekcija).

### 14.5 Reliability scoring

Svaki monitored channel dobiva automatski **reliability score** na osnovu:
- `signalsReceived` — ukupno primljeno poruka (relevantne + ne)
- `signalsRelevant` — koliko je proslo keyword filter
- `ratio = signalsRelevant / signalsReceived`

| Label | Kriterij | Boja |
|-------|----------|------|
| Novo | < 10 signals total | Sivi |
| Niska | < 10% ratio | Crveni |
| Srednja | 10-30% | Narancasti |
| Visoka | > 30% | Zeleni |

Koristis za odluku — **kick-aj kanale s Niska reliability** (samo bucni, malo signal) i **zadrzi Visoka** (signal-heavy).

### 14.6 Signal u Analysis

Kad imas recent signale (< 6h), Analysis tab pokazuje banner:

```
📡 3 recent tipster signals    [View →]
```

Tapni "View →" → otvara **Signal Sheet** (DraggableScrollableSheet 0.85-0.95 height):
- Header: "Recent Signals" + close
- Sport filter chips (All/Soccer/Basketball/Tennis)
- ListView SignalCard-ova (sport icon + channel title + time + preview + checkbox)
- Footer: "X selected" + "Use as context" FilledButton

Odaberi (checkbox) relevantne signale → "Use as context" → signali su **staged** → sljedeca Claude poruka ih ukljucuje.

---

## 15. Intelligence Dashboard

### 15.1 Pristup

Matches tab → (watched matches exist) → "Intelligence for N watched" button → otvara **IntelligenceDashboardScreen** (push route).

### 15.2 Layout

```
+------------------------------------------+
|  Intelligence Dashboard      [refresh]   |  <- AppBar
+------------------------------------------+
|                                          |
|  ┌─ Arsenal vs Liverpool (EPL)           |
|  │  [3.8 — POSSIBLE VALUE]               |
|  │  📊 Odds         [1.5/2.0]  [bar]    |
|  │  ⚽ Football-Data [1.1/1.5]  [bar]    |
|  │  🏀 NBA Stats    inactive              |
|  │  💬 Reddit       [0.8/1.0]  [bar]    |
|  │  📡 Telegram     [0.4/0.5]  [bar]    |
|  │  Generated 12m ago                    |
|  └─                                      |
|                                          |
|  ┌─ Lakers vs Warriors (NBA)             |
|  │  [2.3 — WEAK SIGNAL]                  |
|  │  📊 Odds         [1.0/2.0]            |
|  │  ...                                  |
|  └─                                      |
+------------------------------------------+
```

### 15.3 Per-match card

Svaka kartica prikazuje:
- Header: sport icon + league + teams
- **ConfluenceBadge** — boja po kategoriji, format "X.X — CATEGORY_NAME"
- **5 source rows:** emoji + source name + progress bar + score/max
- **Footer:** "Generated Xm/h ago"

Ako report jos nije generiran, pokazuje **"Generate" OutlinedButton**.

Ako je u tijeku, **CircularProgressIndicator**.

### 15.4 Refresh

**Ikona refresh u AppBar-u** — `refreshAllWatched(force: true)` za sve watched mecve.

**Pull-to-refresh** na ListView → isto.

**Per-match "Generate" button** — samo taj meč.

### 15.5 Auto-refresh (background)

Timer.periodic 1 sat (MainNavigation didChangeDependencies pokrece ga jednom). Automatski refresh-a sve watched reports.

Ne prikazuje loading UI — samo update-a reports u pozadini.

### 15.6 Cache

Intelligence Reports se cache-iraju 1 sat (default TTL). `generateReport(force: false)` vraca cached ako nije expired.

Per-source signal cache:
- FootballDataSignal: 3h TTL
- NbaStatsSignal: 3h TTL
- RedditSignal: 3h TTL

Tako svaki report koji se generira ~15 min reuse-a svezi data ako je vec fetched.

### 15.7 Cleanup

Stari reports (>6h) i stari signal cache (>3 dana) se brisu automatski kroz `runScheduledCleanup` koji se poziva u main.dart pri startup-u (24h gate — cleanup samo jednom dnevno).

---

## 16. Charts i vizualizacija

### 16.1 Odds Movement Chart

**Gdje:** MatchDetailScreen → Charts tab
**Input:** `StorageService.getSnapshotsForMatch(matchId)`

Line chart s 2-3 linije:
- **Plava** = Home odds
- **Narancasta** = Draw odds (samo soccer)
- **Crvena** = Away odds

X-axis: hours offset od prvog snapshot-a
Y-axis: decimalne kvote

Kako se generira: svaki put kad refreshаs Matches (ili auto-refresh Intelligence) na **watched** meč, BetSight biljezi snapshot kvota. Treba ≥2 snapshot-a za chart.

Dedup: BetSight ne biljezi identicne snapshote (`saveSnapshotIfChanged`) — samo kad se kvote promijene.

### 16.2 Form Chart

**Gdje:** MatchDetailScreen → Charts tab (samo soccer s FootballDataSignal cached)
**Input:** `homeFormLast5` / `awayFormLast5` listovi W/D/L stringova

Horizontal Row-ovi:
- Zeleni badge = W
- Sivi = D
- Crveni = L

### 16.3 Tennis Info Panel

**Gdje:** MatchDetailScreen → Charts tab (samo tennis)

Umjesto chart-a (nema tennis form data), prikazuje:
- **Bookmaker favourite badge** (zelena boja, igrač s nizom kvotom)
- **Two prob tiles** (implied probability za oba igrača, favorit ima zelenu border)
- **Margin indikator** s label-om "sharp" (<5%) / "normal" (<8%) / "soft" (≥8%)
- Info note: "Detailed player form not available — BetSight does not integrate a dedicated tennis data source..."

### 16.4 Equity Curve

**Gdje:** Bets tab → ispod 4-metric P&L card (ako ≥2 settled bets)
**Input:** `bets.settledBets` sortiran po `settledAt`

Line chart cumulativnog P&L-a:
- Zelena krivulja + light area fill = pozitivan end
- Crvena + area = negativan

X-axis: bet # (redoslijed)
Y-axis: cumulative P/L u currency

### 16.5 Responsive sizing

Na ekranima <360dp BetSight smanjuje:
- leftTitles reservedSize
- fontSize
- decimal precision (OddsMovement → 1 decimal umjesto 2)

Chart labeli se tako ne preklapaju na malim telefonima.

---

## 17. Push notifikacije

BetSight koristi `flutter_local_notifications` library za lokalne notifikacije (ne push iz cloud-a — sve je local schedule).

### 17.1 Tri tipa

| Tip | Kada | Kanal |
|-----|------|-------|
| **Kickoff reminder** | 24h / 1h / 15min prije kickoff-a | `kickoff_channel` |
| **Odds drift alert** | Kad snapshot pokaze >5% move na watched matchu | `drift_channel` |
| **VALUE signal** | Kad Claude vrati VALUE marker s staged matchom | `value_channel` |

### 17.2 Kickoff reminders

Kad zvjezdicaš mec (`toggleWatched` → add), BetSight pokrece `scheduleKickoffReminders(match)`:
- Zakazuje 3 reminders (24h, 1h, 15min before)
- Prosle reminders se preskaču (ako zvjezdicaš meč za 30 min, samo 15min reminder se zakaze)

Kad unzvjezdicaš meč → `cancelKickoffReminders(matchId)` → svi scheduled se cancela-ju.

### 17.3 Drift alerts

Tijekom `_captureSnapshotsForWatched` u MatchesProvider-u, ako novi snapshot se razlikuje od prethodnog i drift.hasSignificantMove s |%| ≥ 5:
- Pokrene `showDriftAlert(match, drift)` → immediate notification

Notification sadrzi: "⚡ Drift on X vs Y" + "Home +5.3%"

### 17.4 VALUE alerts

U AnalysisProvider.sendMessage, nakon successful response:
- Parse recommendation type
- Ako je VALUE i postoji effectiveContext s prvim matchom → `showValueAlert(match)`

Notification: "🎯 VALUE detected" + "X vs Y — tap to see Claude analysis"

### 17.5 Per-type toggle

Settings → **Notifications** sekcija → 3 SwitchListTile:
- Kickoff reminders ON/OFF
- Odds drift alerts ON/OFF
- VALUE signal alerts ON/OFF

NotificationsService provjerava flag u StorageService pred emit. Ako je off, early-return bez slanja.

### 17.6 Permissions

Pri prvom pokretanju (main.dart) BetSight pokrece `requestPermissions()` — Android trazi dozvolu za notifikacije. Ako odbijes, notifikacije nece raditi ali app i dalje radi.

### 17.7 Testiranje

Na Windows-u notifikacije ne rade (flutter_local_notifications je mobile-first). Testiraj na Android-u:
1. Instaliraj APK
2. Daj notification permission
3. Zvjezdicaj meč blizu kickoff-a
4. Ceka se reminder (provjera Settings → Apps → BetSight → Notifications → vidjeti dolazi li)

---

## 18. Bot Manager

### 18.1 Pristup

Settings → **Telegram Monitor** sekcija → **"Manage Channels (N)"** OutlinedButton → otvara **BotManagerScreen** (push route).

### 18.2 Layout

```
+------------------------------------------+
|  Bot Manager                             |  <- AppBar
+------------------------------------------+
|  Channels: 3  |  Total signals: 127 |   |
|  Relevant: 42                            |
+------------------------------------------+
|                                          |
|  Add channel (e.g., @tipsmaster)         |
|  [_______________________] [Add]        |
|                                          |
+------------------------------------------+
|                                          |
|  ┌─ TipsterMaster                        |
|  │  @tipsmaster            [Visoka]  ×  |
|  │  🟢 45 received  22 relevant          |
|  │  Last: 12m ago                        |
|  └─                                      |
|                                          |
|  ┌─ NoiseBot                             |
|  │  @noisebot             [Niska]   ×   |
|  │  🔴 82 received  4 relevant           |
|  │  Last: 3h ago                         |
|  └─                                      |
+------------------------------------------+
```

### 18.3 Add channel

Input field + Add button:
- Mora poceti s `@` (auto-prepend ako ne pocinje)
- Minimum 5 znakova
- Ne smije vec biti dodan

Tap Add → kanal se pojavljuje u listi sa status "Novo" (siva badge).

### 18.4 Remove channel

Tap X ikona na kartici → confirm dialog "Remove channel? Stats for this channel will be lost." → potvrdi → kanal uklonjen + svi stats izbrisani.

### 18.5 Reliability evolucija

Dok BetSight polling-om prima signale:
- `signalsReceived++` svaki primljen signal iz tog kanala
- `signalsRelevant++` samo ako signal prolazi keyword filter
- `lastSignalAt` / `lastRelevantAt` timestamp-ovi se azuriraju

Nakon 10+ signala, status prelazi iz "Novo" u Niska/Srednja/Visoka.

---

## 19. Tipicni scenariji

### 19.1 Weekly routine (preporucena)

**Petak navecer:**
1. Otvori BetSight → Matches
2. Pregledaj nedjeljne mecve za EPL/Champions League/NBA/ATP
3. Zvjezdicaj 2-5 mecva koji te zanimaju
4. Idi na IntelligenceDashboard → "Refresh all" (dopusti 30-60 sec)
5. Zabiljezi u BETLOG.md pocetne confluence scoreове

**Subota navecer:**
1. IntelligenceDashboard → ponovo refresh (nakon day's odds movements)
2. Uocis drift? Notification ti je tipski vec rekla.
3. Otvori Analysis → odaberi jedan od watched mecva
4. Pitaj Claude-u (PRE-MATCH tier): "Daj mi svoju analizu koristeci intel iznad"
5. Ako VALUE → LOG BET
6. Stvarni bet u tvojoj kladionici
7. Biljezi u BETLOG.md

**Nedjelja navecer:**
1. Settle sve zavrsene mecve (Bets tab)
2. Review Equity Curve + Per-Sport Breakdown
3. Biljezi ishode u BETLOG.md (Claude tocan? pogresan?)

### 19.2 Live betting scenario

**Tijekom meca koji pratis:**
1. Prebaci tier na **🔴 Live**
2. Otvori Matches → pronadji LIVE badge na mecu (ili MatchDetailScreen kickoff countdown je < 0)
3. Drift se pojavljuje — ako > 5%, notification te vec probudila
4. Analysis tab → pitaj "Live momentum check for [match]"
5. Claude je brzi u Live modu — 1-2 paragrafa + marker
6. Ako VALUE → LOG BET (auto-postavi matchStartedAt = now-1min)
7. Stvarni live bet u tvojoj kladionici

### 19.3 Accumulator build scenario

**U Petak, razmisljas o subotnjem 3-leg acca:**
1. Prebaci tier na **🏆 Accumulator**
2. Bets tab → FAB (+) → otvara Accumulator Builder
3. Tap "Start new accumulator"
4. Horizontal ListView watched mecva → tap na karticu → outcome picker (Home/Draw/Away)
5. Ponovi za 2-3 mecva
6. Stake → default 2-5% bankroll-a
7. Summary pokazuje combined odds + payout
8. Ako Correlation warning — razmisli, mozda drop jedan leg
9. Save accumulator → status **Building**
10. Kasnije (u kladionicnoj app) stavljas stvarnu acca
11. Vrati se u BetSight → Bets tab → tap na Building acca → Place button → status **Placed**
12. Nakon svih mecva → Settle (Won/Lost/Partial)

### 19.4 Nakon izgubljenog mjeseca

Losa serija:
1. Bets tab → Equity Curve pokazuje downward trend
2. Per-Sport Breakdown — koji sport je najvise izgubio?
3. Filter Bar → search/filter tvoje losile bet-ove — postoji li pattern?
4. **Zaustavi se.** Idi na pauzu — tjedan dana bez betting-a.
5. Review BETLOG.md — koje Claude preporuke si ignorirao a bile su tocne? Koje si followao a bile krive?
6. Moze biti da tvoj stake management pogresan — smanji default stake za 30-50%
7. Povratak s jos strozim kriterijem (samo STRONG_VALUE confluence, samo <5% margin kvote)

---

## 20. Problemi i rjesenja

### 20.1 Matches screen

| Problem | Rjesenje |
|---------|----------|
| Empty state "The Odds API key required" | Settings → dodaj Odds API kljuc |
| Matches lista prazna nakon save-a kljuca | Pull-to-refresh (povuci prema dolje) |
| "Invalid API key" | Provjeri kopiranje — mozda je razmak prije/poslije |
| "Rate limit exceeded" | Cekaj 1 min, ili povecaj Cache TTL u Settings |
| "API quota exhausted" (red banner) | Premjesto 500 req/mj. Povecaj TTL na 30-60 min, cekaj 1. u mjesecu |
| Drift indicator se ne pojavljuje | Treba ≥2 snapshot-a sa razlicitim kvotama. Refresh-aj vise puta tokom dana |

### 20.2 Analysis screen

| Problem | Rjesenje |
|---------|----------|
| "Anthropic API key required" | Settings → dodaj Anthropic kljuc |
| "Invalid API key" | Kopiraj ponovno iz console.anthropic.com |
| "Rate limit exceeded" | Anthropic throttling — cekaj 1 min |
| Response bez VALUE/WATCH/SKIP markera | Rijetko. Pitaj Claude-u ponovo. System prompt zahtijeva marker. |
| Trade Action Bar se ne pojavljuje | Samo ispod ZADNJE assistant poruke s VALUE-om |
| Staged matches bar nakon send-a ostaje | Bug, ne bi trebalo. Pokreni app ponovo. |

### 20.3 Bets screen

| Problem | Rjesenje |
|---------|----------|
| LIVE tier pokazuje iste bet-ove kao PRE-MATCH | Postojeci bet-ovi iz pre-S8 vremena nemaju matchStartedAt → tretiraju se kao pre-match. Novi bet-ovi unijeti u LIVE tieru imat ce ispravan tier. |
| Accumulator view ne pokazuje Build/Placed/Settled | Provjeri tier — mora biti 🏆 Accumulator. Inace se vidi Pre-Match/Live view. |
| Equity Curve ne crta | Potreban minimum 2 settled bet-a |
| Per-Sport breakdown prazno | Potrebno ≥1 settled bet |
| Filter ne radi | Clear filters (crveni chip) → provjeri da nije active filter |

### 20.4 Intelligence Dashboard

| Problem | Rjesenje |
|---------|----------|
| Empty state "No watched matches" | Zvjezdicaj bar jedan meč iz Matches |
| "Generate" button ne radi | Provjeri API kljuceve (Anthropic, Odds). Football-Data je opcionalan. |
| Generate se zavrsava instantno bez report-a | Vjerojatno se configuration greska — restart app |
| Football-Data ostaje inactive | Provjeri je li FD token save-an (Settings → Active badge) |
| "Match not found in Football-Data" | Odds API i FD imaju razlicite team names. Ako nije big liga, moze ne biti FD support. |
| "Ambiguous team names" | Dva tima slicnog imena — BetSight je odbacio match da izbjegne krivo |
| NBA score uvijek 0.3 (baseline) | NbaStatsSignal jos fetcha ili NBA nema games u zadnjih 15 igara za tim — tipski van sezone |
| Auto-refresh ne radi | Treba watched matches i API kljuceve. Timer je 1 sat — prvi refresh tek nakon sat vremena od otvaranja app-e. |

### 20.5 Push notifications

| Problem | Rjesenje |
|---------|----------|
| Notifikacije se ne pojavljuju | Android Settings → BetSight → Notifications → Allow |
| Kickoff reminder se ne trigger-a | Reminder je scheduled tek kad zvjezdicaš meč. Ako ga zvjezdicaš 5 min prije kickoff-a, samo 15min reminder (vec prosao) → nista |
| Drift alert ne dolazi | Drift must be >5% move. Stavimo snapshot dedup — ako kvote se nisu promijenile, nema snapshot → nema drift. |
| VALUE alert je gluplji nego trebao | System prompt zahtijeva VALUE samo za jasne edge-ove. Ako Claude je strog, malo VALUE markera → malo alert-a |

### 20.6 Telegram Monitor

| Problem | Rjesenje |
|---------|----------|
| "Test failed: Invalid token" | Provjeri kopiranje tokena iz BotFather poruke |
| Monitoring enabled ali nema signala | Bot nije clan kanala. BotFather dokumentacija za dodavanje bot-a kao admin. |
| Signali ne dolaze i kad je bot clan | Poruka mora sadrzavati keyword (`tip`, `bet`, `value`, `odds`...). Reference sekcija 14.4. |
| Reliability ostaje "Novo" | Treba minimum 10 signala ukupno. Treba vremena. |
| Channel se ne dodaje iz BotManager-a | Mora poceti s `@` i imati minimum 5 znakova. Ne smije vec postojati. |

### 20.7 Charts

| Problem | Rjesenje |
|---------|----------|
| "Not enough snapshots yet (1/2)" | Pull-to-refresh Matches vise puta tijekom dana |
| Form chart placeholder "Generate intelligence report first" | Open Intelligence Dashboard → Generate za taj meč |
| Chart labels preklapaju na malim ekranima | Rotiraj phone horizontally ili nadograduj na veci display |
| Equity curve ne pokazuje nista | Nije jos 2+ settled bet-ova |

---

## 21. Sigurnost

### 21.1 API kljucevi

**BetSight cuva sve API kljuceve lokalno u Hive bazi** (settings box).

- Kljucevi se ne salju na BetSight server (ne postoji)
- Ne backupaju se u cloud kroz BetSight
- Salju se DIREKTNO na servise (Anthropic API, Odds API, Football-Data, Telegram) preko HTTPS

**Ako izgubish telefon:**
- Anthropic console → revoke-aj specifican API kljuc koji si koristio za BetSight
- Odds API → login → regenerate key
- Football-Data → slicno
- Telegram Bot → BotFather → `/revoke` ili delete bot

**Preporuke:**
- Svaki servis posebni kljuc (ne dijeli Anthropic kljuc s drugim appsima)
- Monthly check billing dashboard-a za anomalije
- Ne dijeli kljuc s nikim

### 21.2 Bet data

Svi bet-ovi, bankroll, settings — lokalno u Hive bazi.

**Android backup mehanizmi:**
- Google Drive backup (app data) — backup ide u Google account (shifted encrypted during upload, razultant encryption je u Google hands)
- **Alternativa:** manualni export to BETLOG.md

### 21.3 Responsible gambling

- **Nikad vise nego sto si spreman izgubiti**
- **Nikad ne juri gubitke**
- **Ako osjecash stres, pauza**

Ako prepoznajes problem: Udruga KLUB "Kocka" (Hrvatska), BeGambleAware (UK), Gamblers Anonymous (svijet).

---

## 22. Cesto postavljana pitanja

**Q: Je li BetSight legalan u Hrvatskoj/Europi?**
A: BetSight sam po sebi nije kladionica. Aplikacija analize + biljezenja je legalno. Same uplate u kladionicama su regulirane po drzavi — provjeri lokalne zakone.

**Q: Moze li Claude garantirati dobitak?**
A: Ne. Claude je analytical tool, **ne prediktor buducnosti**. Dugorocni win rate s BetSight-om tipski 45-60% ovisno o disciplini — to je bolje nego retail kladioncica (<45% prosjek), ali daleko od "garantiranog dobitka".

**Q: Koliko kosta koristiti BetSight?**
A: 1-3 USD mjesecno za Anthropic API (normalno koristenje). Odds API, Football-Data, BallDontLie, Reddit, Telegram su besplatni.

**Q: Moze li se BetSight koristi na iPhone-u?**
A: BetSight je **primarno Android**. iOS build nije testiran ni distribuiran. Flutter source kod je cross-platform — teoretski moguce, ali ne oficijalno podrzano.

**Q: Radi li BetSight ako imas samo Anthropic kljuc?**
A: Analysis tab radi, ali nema matcheva (nema Odds API → Matches empty). Ogranicno.

**Q: Sto ako Claude ne razumije hrvatski?**
A: Claude razumije hrvatski odlicno. Odgovara na jeziku na kojem pitas. System prompt kaze "Respond in the language the user uses" + "Sport terminology stays in English".

**Q: Zasto nema eSports / NHL / MMA?**
A: The Odds API pokriva vise sportova ali BetSight u v3.1.2 targetra specificno EPL, Champions League, NBA, ATP. Proširenje je moguce u buducoj sesiji.

**Q: Kako se BetSight razlikuje od Pinnacle-a ili drugih kladionica?**
A: BetSight **nije kladionica**. Ne prihvaca uplate. Ne isplacuje. Stave se u kladionicu prema svome izboru. BetSight je **pre-bet analitika** + post-bet tracking.

**Q: Sto ako Intelligence Dashboard pokazuje "insufficient data"?**
A: Tipski znaci < 2 aktivna izvora. Probaj: (a) zvjezdicaj meč i refresh vise puta (odds snapshot + drift), (b) dodaj Football-Data token (pokriva soccer), (c) pricekaj neko vrijeme (auto-refresh fetcha Reddit + NBA data tokom dana).

**Q: Mogu li dodati vlastite kladionice u comparison?**
A: Ne u v3.1.2. The Odds API vraca **best odds from bookmakers** — ne dopusta filtriranje po specific bookmaker-u u free tieru. Mozda u budude.

**Q: Zasto je Tennis tako slabo podrzan?**
A: Tennis tracking API-ji uglavnom su placeni i kompleksni. BetSight koristi samo odds + TennisInfoPanel (implied probabilities). Za deep tennis analysis, pogledaj dedicated tools kao Tennis Abstract ili ATPWorldTour.

**Q: Moze li BetSight automatski staviti bet?**
A: Ne. BetSight je **read-only prema kladionicama**. Ti moraš otvoriti svoju kladionicu posebno i stvarno staviti bet. BetSight samo biljezi da si to napravio.

---

## 23. Rjecnik pojmova

Alfabetski poredano.

**Asian Handicap (AH)** — Fractional handicap koji eliminira draw. "Arsenal -1.5" = Arsenal mora pobijediti s 2+ gola razlike.

**Bankroll** — Ukupni betting kapital. Ne mijesa s osobnim troškovima.

**BetAccumulator** — BetSight-ov model za multi-bet kombinaciju. Renamed iz `Accumulator` u S9 zbog collision-a s Flutter Material Accumulator widgetom.

**Bookmaker** — Kladionica. Entitet koji postavlja kvote i prihvaca uplate.

**Bookmaker margin** — Profitna marža kladionice. Sum implied probabilities - 100%.

**BotFather** — Telegram bot za kreiranje drugih bot-ova. Osnovna usluga za Telegram Monitor setup.

**Cache TTL (Time To Live)** — Vrijeme koliko je cached podatak vazeci. BetSight default: 15 min za Odds API cache, 3h za source signal cache, 1h za Intelligence reports.

**Claude** — Anthropic-ov AI koji BetSight koristi za analizu.

**Combined odds** — Multiplikacija svih leg odds u accumulator-u. 3 × 2.0 legs = 8.0 combined.

**Confluence score** — BetSight-ov aggregate 0-6.0 score iz 5 intelligence izvora.

**Correlation warning** — Upozorenje o potencijalnoj korelaciji izmedju accumulator legs (isti meč, isti dan/liga).

**Decimal Odds** — Europska norma za kvote. BetSight koristi iskljucivo.

**DYOR** (Do Your Own Research) — Istrazi sam. Claude nije guru.

**Edge** — Razlika izmedju tvoje procjene probability i implied probability. Cilj: ≥3pp.

**Equity Curve** — Grafikon kumulativnog P&L-a kroz vrijeme.

**FootballDataSignal** — BetSight-ov model za form + H2H + standings data (soccer only).

**H2H (Head-to-Head)** — Povijest medjusobnih mecva.

**Hive** — NoSQL lokalna baza za Flutter. BetSight koristi 13 boxa.

**Implied Probability** — `1 / odds`. 50% za odds 2.00.

**In-play** — Vidi Live.

**IntelligenceAggregator** — Service koji paralelno score-a 5 izvora.

**IntelligenceReport** — Agregat s 5 SourceScore objektima + category + reasoning.

**Kelly Criterion** — Formula za optimalni stake size. BetSight ne implementira automatski.

**Kickoff** — Pocetak meca.

**LEG** — Pojedini bet u accumulator-u.

**Live / In-play** — Kladenje tijekom meca.

**LOG BET** — Primarna akcija u BetSight-u kad se prihvaca Claude VALUE.

**Market** — Vrsta bet-a. BetSight podrzava h2h (moneyline) + accumulator od h2h-ova.

**matchStartedAt** — Bet polje, kickoff time meca. Koristi se za isLiveBet determinaciju.

**Over/Under (O/U)** — Market na ukupan broj golova/poena. BetSight ne fetcha automatski, moze se rucno unijeti.

**P&L (Profit and Loss)** — Neto rezultat.

**parseRecommendationType** — BetSight parser koji trazi VALUE/WATCH/SKIP marker u Claude odgovoru.

**Pinnacle** — Sharp book s low margin (~3%). Industry benchmark.

**Provider** — Flutter pattern za state management. BetSight ima 8 ChangeNotifier providera.

**Pull-to-refresh** — UI pattern za manual refresh.

**ROI** — `(total profit / total staked) * 100`. Pozitivan = profitabilan.

**Settle / Settlement** — Finalizacija bet-a kao Won/Lost/Void.

**Sharp book** — <5% margin kladionica.

**Snapshot** — Zabiljezena kvota iz Odds API u odredeni trenutak. BetSight koristi za drift detekciju.

**Soft book** — >8% margin kladionica. Lose value.

**SourceScore** — BetSight model za jedan od 5 intelligence izvora.

**Stake** — Iznos koji klades. 1-5% bankroll-a preporuka.

**TabController** — Flutter widget za TabBar navigation.

**Tier** — PRE-MATCH / LIVE / ACCUMULATOR. BetSight specific.

**TipsterSignal** — BetSight model za Telegram poruku koja je prosla keyword filter.

**TL;DR (Too Long; Didn't Read)** — "Ukratko".

**TradeActionBar** — Widget ispod VALUE responsa s 3 button-a.

**UserFeedback** — Enum (none/logged/skipped/askedMore) za AnalysisLog calibration data.

**Value Bet** — Bet gdje tvoj procjenjena probability > implied probability.

**Void** — Neutralni ishod. Povrat stakeа. Nista ne pogoditi.

**Watched** — BetSight stanje meca nakon star toggle-a. Intelligence reports se generiraju samo za watched matches.

**Weighted** — Score weighted prema pouzdanosti izvora (Telegram max 0.5, Odds max 2.0).

---

*BetSight v3.1.2 — Korisnicki prirucnik*
*2026 | Izradjeno s Claude AI*
