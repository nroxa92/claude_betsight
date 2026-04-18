# BetSight v3.1.2 — Vodic za pocetnike

**Verzija:** 3.1.2 | **Datum:** 2026
**Jezik:** Hrvatski (HR)
**Ciljna publika:** Potpuni pocetnici — netko tko se nije aktivno kladio ili ne razumije sto su kvote, value bet ili bookmaker margin

> Ovaj vodic objasnjava SVE sto trebas znati da postavis i koristis BetSight,
> cak i ako nikad nisi podnio uplatu ni na jednu kladionicu. Krecemo polako,
> korak po korak.

---

## Sadrzaj

1. [Sto je BetSight i sto radi](#1-sto-je-betsight-i-sto-radi)
2. [Sto ti treba za pocetak](#2-sto-ti-treba-za-pocetak)
3. [Claude AI postavljanje](#3-claude-ai-postavljanje)
4. [The Odds API postavljanje](#4-the-odds-api-postavljanje)
5. [Football-Data.org postavljanje (opcionalno)](#5-football-dataorg-postavljanje-opcionalno)
6. [Telegram Bot postavljanje (opcionalno)](#6-telegram-bot-postavljanje-opcionalno)
7. [Reddit (bez konfiguracije)](#7-reddit-bez-konfiguracije)
8. [Prvi koraci u BetSightu](#8-prvi-koraci-u-betsightu)
9. [Razumijevanje tri tiera (PRE-MATCH/LIVE/ACCUMULATOR)](#9-razumijevanje-tri-tiera)
10. [Tvoja prva analiza s Claudeom](#10-tvoja-prva-analiza-s-claudeom)
11. [Tvoj prvi bet](#11-tvoj-prvi-bet)
12. [Razumijevanje grafikona](#12-razumijevanje-grafikona)
13. [Rjecnik pojmova](#13-rjecnik-pojmova)
14. [Sigurnosna pravila i odgovorno kladenje](#14-sigurnosna-pravila-i-odgovorno-kladenje)
15. [Zavrsna rijec](#15-zavrsna-rijec)

---

## 1. Sto je BetSight i sto radi

BetSight je tvoj **pametni asistent za analizu sportskih mecva**.

Zamisli ga ovako: umjesto da sam satima citas forumske tipstere, pratis statistiku tri razlicita sporta, usporedjujes kvote izmedju kladionica i pokusavas zakljuciti gdje se skriva **value** — BetSight to radi za tebe.

**Kako to funkcionira?**

```
+---------------------+     +------------------+     +------------------+
|  IZVORI PODATAKA    | --> |    BETSIGHT      | --> |   TI ODLUCUJES   |
|                     |     |                  |     |                  |
| - The Odds API      |     | - Skuplja kvote  |     | - Klada ne klada |
| - Football-Data.org |     | - Salje Claudeu  |     | - Velicina stake |
| - BallDontLie NBA   |     | - Prikazuje      |     | - Settled / live |
| - Reddit (public)   |     |   analizu        |     | - Koji tier      |
| - Telegram (bot)    |     | - Biljezi bet    |     |                  |
+---------------------+     +------------------+     +------------------+
```

**Jednostavno receno:**
- BetSight **prikuplja** kvote i sport data iz 5 izvora
- **Salje** to Claude AI-u u strukturiranom formatu
- **Prikazuje** ti odgovor s VALUE / WATCH / SKIP preporukom
- **Biljezi** bet ako ga odlucis napraviti
- **Ti odlucujes** — BetSight nikad ne stavlja klade umjesto tebe

BetSight **nije kladionica**. Ne moze primiti uplatu, ne isplacuje dobitke. To radis preko svoje kladionice. BetSight samo pomaze da **bolje razumijes sto se nudi** i **bolje pratis vlastitu povijest**.

BetSight **nije** automatski tipster bot. Claude nece raditi analizu dok ti ne otvoris Analysis tab i pitas nesto.

### Tri tiera — tri razlicita pristupa

BetSight ima tri odvojena nacina rada za tri razlicita stila kladenja:

| Tier | Naziv | Kad koristiti | Rizik |
|------|-------|---------------|-------|
| ⚽ | **PRE-MATCH** | 24-48h prije meca | Niski (ima vremena za DYOR) |
| 🔴 | **LIVE** | Tijekom meca (in-play) | Visoki (emocije, nagle kvote) |
| 🏆 | **ACCUMULATOR** | Kad hoces kombinirati 2-5 mecva | Najvisi (sve mora pogoditi) |

Vise o svakom tieru u [poglavlju 9](#9-razumijevanje-tri-tiera).

---

## 2. Sto ti treba za pocetak

> **Kratka verzija za nestrpljive:**
> Obavezno je **Anthropic API kljuc** (sekcija 3) i **The Odds API kljuc** (sekcija 4).
> Sve ostalo (Football-Data, Telegram, Reddit) dodaje se po potrebi. Mozes poceti s samo
> 2 kljuca i imati funkcionalnu app.

### Minimalni zahtjevi

- 📱 **Android telefon** (Android 8.0 ili noviji) — primarna platforma
- 🌐 **Internet konekcija** — stabilna, ne mora biti brza
- 📧 **Email adresa** — za registraciju na Anthropic i Odds API
- 💳 **Kartica** (Visa/Mastercard) — samo za Anthropic (Odds API ima besplatan plan)
- 📦 **~150 MB slobodnog prostora** — za instalaciju APK-a
- 🎯 **Kladionica u kojoj stvarno igras** — BetSight pomaze u analizi, ali uplate idu preko tvoje kladionice

### Sto ces registrirati (redoslijedom)

```
+-------+-------------------------------+------------+---------------+
| Korak | Servis                        | Obavezno?  | Traje         |
+-------+-------------------------------+------------+---------------+
|   1   | Anthropic (Claude AI)         | DA         | 5 minuta      |
|   2   | The Odds API                  | DA         | 5 minuta      |
|   3   | Football-Data.org (soccer)    | Preporuceno| 5 minuta      |
|   4   | Telegram Bot (@BotFather)     | Opcionalno | 10-15 minuta  |
|   5   | Reddit                        | Automatski | 0 minuta      |
|   6   | BallDontLie NBA (bez registr) | Automatski | 0 minuta      |
+-------+-------------------------------+------------+---------------+
```

### Preporuceni raspored

Nemoj pokusavati sve odjednom. Idi dan po dan ili podijeli jutarnji kavu na dva dana:

```
Dan 1:  Anthropic API kljuc --> The Odds API kljuc --> instaliraj BetSight
        --> testiraj Matches screen --> testiraj prvu Claude analizu
Dan 2:  Football-Data token --> napravi prvi Intelligence report na watched mec
Dan 3:  Telegram bot (ako te zanima tipster feed) --> dodaj u vlastiti kanal
Dan 4+: Pocni s testnim bet-ovima (malo ili nista stakea) --> prati BETLOG.md
```

### Ocekivani troskovi

**Anthropic Claude AI:**
- Svaka analiza ~0.003-0.01 USD (manje od lipe)
- 30-40 analiza mjesecno = ~0.30 USD mjesecno
- Prvi put se tipicno dobije $5 besplatnog kredita
- Za normalno koristenje: **1-3 USD mjesecno**

**The Odds API:**
- Besplatan tier: 500 requestova mjesecno
- BetSight ima cache od 15 min default — znaci 1 fetch je 1 request i pokriva sve sportove
- 500 / 30 dana = ~16 requestova dnevno — vise nego dovoljno

**Football-Data.org:**
- Besplatan, neograniceno mjesecno
- Rate limit 10 req/min (BetSight serijski fetcha, ne problem)

**Telegram, Reddit, BallDontLie:** Besplatno.

**Ukupno mjesecno:** ~1-3 USD za normalno koristenje.

---

## 3. Claude AI postavljanje

### Sto je Claude AI?

Claude je umjetna inteligencija koju je napravila kompanija Anthropic. BetSight koristi Claudea za analizu kladjenja — salje mu kvote, H2H statistiku, forma, tipster signale, i Claude vraca strukturiranu analizu s preporukom: **VALUE**, **WATCH** ili **SKIP**.

**Razlika od obicnog ChatGPT-a:**
- Claude je treniran da bude oprezan i transparentan
- BetSight koristi poseban **system prompt** (koji salje Claude-u pri svakoj analizi) da ga fokusira na sportske kladenje i value detekciju
- Claude dobiva i **tier kontekst** (pre-match / live / accumulator) pa prilagodjava fokus

### Svaki put kad Claude odgovori, kosta te oko 0.003-0.01 USD

To je manje od lipe. Cak i 100 analiza dnevno iznosi oko 0.30 USD dnevno (~2 kune).

### Korak po korak: Registracija i API kljuc

▶ **Napravi sad:**

**Korak 3.1 — Otvori Anthropic Console**

1. Otvori browser i idi na: **https://console.anthropic.com**
2. Klikni **"Sign Up"** (ili "Get Started")
3. Unesi svoju email adresu
4. Postavi lozinku (snaznu, barem 12 znakova)
5. Potvrdi email — otvori inbox i klikni link za verifikaciju

**Korak 3.2 — Dodaj nacin placanja**

1. Nakon login-a, idi na **"Billing"** u lijevom meniju
2. Klikni **"Add Payment Method"**
3. Unesi podatke kartice (Visa ili Mastercard)
4. Nista ti se nece odmah naplatiti — placa se samo ono sto potrosis.

> 💡 **Savjet:** Anthropic obicno daje $5 besplatnog kredita novim korisnicima.
> To je dovoljno za ~500-800 analiza.

**Korak 3.3 — Generiraj API kljuc**

1. U lijevom meniju klikni **"API Keys"**
2. Klikni **"Create Key"**
3. Daj kljucu ime, npr. `BetSight-Mobile`
4. Klikni **"Create"**
5. Pojavit ce se kljuc koji izgleda ovako:

```
sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

6. **ODMAH GA KOPIRAJ!** Ovo je jedini put kad ces ga vidjeti u cijelosti.

> ⚠️ **VAZNO:** Ako zatvoris prozor bez kopiranja, moras generirati novi kljuc.
> Stari vise neces moci vidjeti.

**Korak 3.4 — Unesi kljuc u BetSight**

1. Otvori BetSight aplikaciju
2. Idi na **Settings** tab (zadnji tab, ikona zupcanika)
3. Pronadi prvu sekciju **"Anthropic API Key"**
4. Tapni na input polje (ako pise `••••••` znaci da vec ima ocuvan kljuc — tap ce ga ocistiti)
5. Zalijepi kopirani kljuc (`sk-ant-...`)
6. Tapni **"Save"**
7. Vidjet ces SnackBar **"Anthropic API key saved"** i status badge u headeru ce promijeniti iz "Not set" (narancasto) u "Active" (zeleno)

```
+------------------------------------------+
|  Settings                                |
+------------------------------------------+
|                                          |
|  🔑 Anthropic API Key    [Active ✅]    |
|  +------------------------------------+  |
|  | sk-ant-api03-••••••••••••••••••••• |  |
|  +------------------------------------+  |
|                                          |
|  [Save]         [Remove]                 |
|                                          |
+------------------------------------------+
```

### Rjesavanje problema

| Problem | Rjesenje |
|---------|----------|
| "Invalid API key" u Analysis screenu | Provjeri da si kopirao cijeli kljuc ukljucujuci `sk-ant-` prefiks |
| "Rate limit exceeded" | Anthropic ima throttling — sacekaj 1 min i pokusaj ponovo |
| "Request timed out" | Provjeri internet konekciju. Ako je brz mobilni tj slab WiFi, neka je brzi |
| "Malformed response" | Ova se pojavljuje vrlo rijetko. Pokreni aplikaciju iznova. |
| Status badge ostaje "Not set" | Tapni Save ponovno nakon unosa (ponekad prvi klik ne "uhvati" fokus) |

---

## 4. The Odds API postavljanje

### Sto je The Odds API?

The Odds API je servis koji agregira decimalne kvote iz desetaka svjetskih kladionica i izlaze ih kroz jedinstveni JSON endpoint. BetSight koristi njega da dohvati **trenutne kvote** za pred-nocne mecve u sva tri sporta (soccer EPL + Champions League, basketball NBA, tennis ATP).

### Zasto ovo? Zasto ne scrape-aj sa kladionicinog sajta?

1. **Pravno:** Scrape-anje bookmaker-a nije dozvoljeno (ToS violation)
2. **Tehnicki:** Svaka kladionica ima svoj format, mijenjaju se stalno
3. **Odds API** vraca cijele podatke o matchu (id, teams, kickoff, odds iz vise bookmaker-a) na standardizirani nacin

### Free tier — 500 requestova mjesecno

BetSight je dizajniran da to bude vise nego dovoljno:

- **Cache** drzi kvote 15 min po fetch-u (ti mijenjas TTL u Settings ako zelis — 5/15/30/60 min)
- Svaki fetch dohvaca sva 3 sporta odjednom (3 API call-a po refresh, ne 3x vise)
- Pri normalnom koristenju: **2-5 refresha dnevno** je sasvim dovoljno za pokrivanje novog dana mecva
- 5 refresha * 3 sporta * 30 dana = 450 req (pod 500 free cap)

Ako ipak potrosis kvotu pri kraju mjeseca, BetSight ti pokaze crveni warning banner u Matches screenu i preskoci fetch — pokazuje cache umjesto toga.

### Korak po korak: Registracija i API kljuc

▶ **Napravi sad:**

**Korak 4.1 — Otvori the-odds-api.com**

1. Otvori browser i idi na: **https://the-odds-api.com**
2. Klikni **"Get API Key"** (ili "Register")
3. Unesi email
4. Dobit ces **verifikacijski email** — tamo je vec tvoj API kljuc

**Korak 4.2 — Pronadji API kljuc u emailu**

Email izgleda otprilike ovako:

```
From: The Odds API
Subject: Welcome to The Odds API

Your API key is:

abc123def456ghi789jkl012mno345

You have 500 requests/month on the free tier.
```

Kopiraj cijeli kljuc (tipski 30-40 znakova).

**Korak 4.3 — Unesi kljuc u BetSight**

1. Otvori BetSight → **Settings**
2. Skrolaj do sekcije **"The Odds API Key"** (druga api sekcija)
3. Zalijepi kljuc
4. Tapni **"Save"**
5. Trebao bi vidjeti SnackBar **"Odds API key saved"**
6. Status badge postaje "Active" (zeleno)

**Korak 4.4 — Testiraj**

1. Idi na **Matches** tab (prvi tab, scoreboard ikona)
2. Ako sve radi, vidjet ces listu mecva iz EPL / CL / NBA / ATP
3. Ako nema ni jednog meca, danas nema rasporeda — pokusaj sutra

> 💡 **Savjet:** Cvrsto ti preporucam stedjeti kvotu. Cim imas listu mecva koju
> zelis pratiti, zvjezdicaj (star toggle) do 5 mecva. BetSight ce se fokusirati
> na njih kad radis Intelligence reports.

### Koji sportovi i lige?

| Sport | Liga | Sezona |
|-------|------|--------|
| ⚽ Soccer | English Premier League (EPL) | Aug - May |
| ⚽ Soccer | UEFA Champions League | Sep - Jun |
| 🏀 Basketball | NBA | Oct - Jun |
| 🎾 Tennis | ATP Singles | cijela godina |

Ako je sezona neaktivna za liga, ona se jednostavno ne pojavi u Matches listi — nije bug.

### Rjesavanje problema

| Problem | Rjesenje |
|---------|----------|
| Matches lista prazna | Provjeri je li Odds API key saved. Pull-to-refresh (povuci list prema dolje). |
| "Invalid API key" | Ponovno provjeri da nisi slucajno stavio razmak prije/poslije kljuca |
| Warning banner "API quota exhausted" | Potrosio si 500 req za mjesec. Cekaj 1. u mjesecu ili povecaj Cache TTL na 30-60 min |
| "Rate limit exceeded" | Throttling — sacekaj minutu |

---

## 5. Football-Data.org postavljanje (opcionalno)

### Sto je Football-Data.org?

Football-Data.org je besplatni servis koji izlaze **dubinske sportske podatke** za europske nogometne lige — forma zadnjih 5 mecva, H2H povijest, trenutne standings, lineup news.

BetSight koristi Football-Data za **Intelligence layer** (Task 6 multi-source scoring) — agregat forma + H2H daje "Football-Data score" koji doprinosi ukupnom confluence score-u.

### Zasto je opcionalno?

Ako ne postavis Football-Data kljuc:
- Matches screen i dalje radi (Odds API je obavezan)
- Analysis chat radi
- Intelligence Dashboard ce pokazati Football-Data kao "inactive" izvor (nece doprinijeti confluence score-u)
- Samo soccer mecevi su pogodjeni — NBA i ATP rade normalno bez FD-a

Ako je **postaviš**:
- Intelligence Dashboard dobija bogatije reporte za EPL i Champions League mecve
- Claude ima form + H2H u kontekstu — mogu bolje argumentirati VALUE preporuke

### Korak po korak

▶ **Napravi sad:**

**Korak 5.1 — Otvori football-data.org**

1. Otvori browser → **https://football-data.org**
2. Klikni **"Register"** (gore desno)
3. Unesi ime, email, postavi lozinku
4. Verificiraj email

**Korak 5.2 — Preuzmi API Token**

1. Log in
2. Idi na **"Account"** → **"API Token"**
3. Ako ti jos nije generiran, klikni **"Generate New Token"**
4. Token izgleda kao 32-znamenkasti hex string:

```
abcdef1234567890abcdef1234567890
```

5. Kopiraj ga

**Korak 5.3 — Unesi u BetSight**

1. BetSight → **Settings**
2. Scrollaj do sekcije **"Football-Data.org API"** (treca api sekcija)
3. Zalijepi token
4. Tapni **"Save"**
5. SnackBar: **"Football-Data API key saved and active"**

```
+------------------------------------------+
|  ⚽ Football-Data.org API   [Active ✅]  |
|  +------------------------------------+  |
|  | abcd••••••••••••••••••••••••••••90 |  |
|  +------------------------------------+  |
|                                          |
|  [Save]         [Remove]                 |
|                                          |
+------------------------------------------+
```

**Korak 5.4 — Testiraj (nakon sto imas zvjezdicani meč)**

1. Idi na **Matches** tab
2. Zvjezdicaj (star toggle) neki soccer meč (EPL ili Champions League)
3. Tapni "Intelligence for 1 watched" button iznad TabBar-a
4. U Intelligence Dashboard-u tapni **"Generate"** za taj meč
5. Nakon ~10-30 sec, report ce pokazati Football-Data (0-1.5) aktivno sa objasnjenjem "form H... A... H2H..."

### Ogranicenje

Football-Data free tier pokriva:
- Premier League (EPL)
- UEFA Champions League
- UEFA Europa League (ali BetSight ne koristi)
- Jos par drugih liga (ali BetSight samo EPL + CL)

NBA, tennis i niža liga soccer-a nece biti pokriveni — BallDontLie radi za NBA, tennis nema dedicated izvor.

### Rjesavanje problema

| Problem | Rjesenje |
|---------|----------|
| Report pokazuje "Football-Data (inactive): No API key" | Tvoj token jos nije snimljen. Settings → Save ponovno |
| "Rate limited" tijekom Generate | Football-Data ima 10 req/min. BetSight serijski fetcha 4-5 req po matchu. Ako generirаš 3+ mecva odjednom, cekaj 1 min. |
| "Match not found in Football-Data" | Odds API i Football-Data koriste razlicita imena timova. BetSight ima token-based fuzzy match, ali ponekad ne nadje — npr. ako mec danas nije u FD bazi jer je za tjedan dana |
| "Match not found (ambiguous team names)" | Dva tima slicnog imena (npr. 2 Manchester-a). BetSight odbija match umjesto da krivo pogodi. Skip za taj mec. |

---

## 6. Telegram Bot postavljanje (opcionalno)

### Sto je Telegram Monitor?

Telegram Monitor je dio BetSight-a koji prati tvoje Telegram kanale (obicno tipstere) i prepoznaje poruke koje lice na bet signale — npr. "EPL tip: Arsenal @ 1.85". Te signale prikazuje u Analysis screenu kao dodatni kontekst za Claude analizu.

### VAZNO: Bot API ogranicenje

> ⚠️ **Ovo je najvaznije razumijeti prije nego pocnes postavljanje.**

Telegram ima dvije odvojene platforme za developer-e:
1. **Bot API** (ono sto BetSight koristi)
2. **MTProto** (user-level API, kao da si ti logged in)

Bot API ima **jedno bitno ogranicenje:** Bot moze primati poruke samo iz kanala **gdje je dodan kao clan** (admin).

To znaci:
- ✅ **Vlastiti kanal** — ti si admin, dodaj svoj bot, sve radi
- ✅ **Kanal prijatelja/zajednica koja prihvaca bot-ove** — pitaj admin-a da doda tvoj bot
- ❌ **Big public tipster kanali** (npr. "@X Betting Tips" s 50k clanova) — tipski ne dopustaju bot-ove, znaci nista

**Rjesenje u praksi:** Kreiraj vlastiti kanal gdje ti forwardas interesantne poruke iz drugih kanala, a bot cita iz tvog kanala. Ili pronadji manje zajednice koje prihvacaju bot-ove.

Za full obrazloženje zasto BetSight ne ide na MTProto: vidi [WORKLOG.md](WORKLOG.md) "Identified Issues → Telegram Bot API limitation" sekciju.

### Ako te sve to ne zasmeta — nastavi

▶ **Napravi sad:**

**Korak 6.1 — Kreiraj bota preko BotFathera**

1. Otvori **Telegram** aplikaciju (mobilni ili desktop)
2. U trazilici upisi: `@BotFather`
3. Otvori razgovor s BotFatherom (plava kvacica ✅)
4. Posalji: `/newbot`
5. BotFather trazi ime:
   ```
   MyBetSightBot
   ```
6. Potom username (mora zavrsiti na `bot`):
   ```
   my_betsight_bot
   ```
7. BotFather ti salje token:

```
Done! Your bot was created.
Token: 123456789:AAF-aBcDeFgHiJkLmNoPqRsTuVwXyZ
```

8. **Kopiraj token!** (cijeli string ukljucujuci broj, dvotocku i slova)

**Korak 6.2 — Unesi token u BetSight**

1. BetSight → **Settings** → skrolaj do **"Telegram Monitor"** sekcije
2. Zalijepi token u input polje
3. Tapni **"Save"** → SnackBar "Token saved"
4. (Opcionalno) tapni **"Test"** → ako bot radi vidjet ces "Connected as @my_betsight_bot"

**Korak 6.3 — Dodaj bot u kanal**

Bot mora biti **clan (ili admin) kanala** koji zelis pratiti.

1. Otvori svoj Telegram kanal
2. Settings kanala → **Administrators** (ili **Add Members**)
3. Pretrazi username bota (`@my_betsight_bot`)
4. Dodaj ga s minimalnim dozvolama (read je dovoljno)

**Korak 6.4 — Dodaj kanal u BetSight**

1. BetSight Settings → Telegram Monitor sekcija → tap **"Manage Channels (0)"** button
2. Otvara se **Bot Manager Screen**
3. U input polju unesi `@my_channel` (s `@` prefiksom)
4. Tap **"Add"**
5. Kanal se pojavljuje u listi sa statusom **Novo** (jos nema dovoljno podataka za reliability scoring)

**Korak 6.5 — Ukljuci monitoring**

1. BetSight Settings → Telegram Monitor sekcija
2. SwitchListTile **"Monitoring enabled"** → ON
3. Pod hood-om, BetSight sad svakih 10 sekundi pinga Telegram API za nove poruke iz tvojih kanala
4. Kad stigne relevantna poruka (sadrzi `tip`, `bet`, `value`, `odds`...), pojavljuje se u **Analysis** tabu pod bannerom "X recent tipster signals"

### Preporuceni workflow

Buduci da Bot API ima ogranicenja, konkretni predlog:

1. Kreiraj **vlastiti privatni Telegram kanal** (samo ti i bot)
2. Dodaj svoj bot kao admin
3. Kad vidis zanimljivu poruku u nekom drugom (nedostupnom) kanalu, **copy-paste** ili **forward** je u svoj privatni kanal
4. BetSight automatski pokupi tu poruku i prikaze je u Analysis signal feed-u
5. Tako efektivno "uvodis" tipsterske signale iz bilo kojeg izvora u BetSight kontekst

### Reliability scoring (automatski, bez konfiguracije)

Svaki kanal koji pratis dobiva **per-channel reliability score** na osnovu:
- Koliko je ukupno poruka primio
- Koliko ih je prošlo "relevantnost" filter (sadrzi bet-related keyword)

| Label | Kriterij | Boja badge-a |
|-------|----------|-------------|
| Novo | < 10 poruka | Siva |
| Niska | < 10% relevantnih | Crvena |
| Srednja | 10-30% | Narancasta |
| Visoka | > 30% | Zelena |

Ovo ti pomaze identificirati koji kanali su stvarno korisni (high signal) a koji samo bucni (low ratio).

### Rjesavanje problema

| Problem | Rjesenje |
|---------|----------|
| "Test failed: Invalid token" | Provjeri kopiranje — Token mora biti cijeli (brojevi + dvotocka + slova) |
| Pokrenes monitoring ali nema signala | Bot nije clan kanala. BotFather dokumentacija. |
| Signali se ne pojavljuju ni kad postiras u kanal | Poruka mora sadrzavati keyword: `tip`, `bet`, `value`, `odds`, `pick`, `lock`, `stake`, `vs`, `over`, `under`, `handicap`, `epl`, `nba`, `atp`, `wta`, `champions` |
| Channel se ne prikazuje u Bot Manager-u | Mora poceti s `@` i biti minimum 5 znakova |

---

## 7. Reddit (bez konfiguracije)

Reddit radi automatski, bez registracije ili API kljuca.

BetSight koristi **public Reddit JSON endpoint** (npr. `https://www.reddit.com/r/NBA/hot.json`) da skenira top postove u sport-specific subreddit-ima. Trazi spominjanja timova iz tvojih **watched matches** i kalkulira sentiment bias (koji tim je vise spomenut).

### Koji subreddit-i se skeniraju?

| Sport | Subreddit-i |
|-------|-------------|
| Soccer | r/soccer, r/sportsbook |
| Basketball | r/nba, r/sportsbook |
| Tennis | r/tennis, r/sportsbook |

### Sto dobijes?

Za svaki watched mec, Intelligence Dashboard pokaze Reddit score (0-1.0) s razlogom:

- **Mention count** — koliko post-ova spominje barem jedan od timova
- **Sentiment bias** — koji tim je vise spomenut (home tilt / away tilt / balanced)
- **Top post** — najupvotan post koji spominje timove (ako postoji)

### Ogranicenje

- **Rate limit:** Reddit dopusta 60 req/h za unauthenticated useri-e. BetSight fetcha po 2 subreddit-a po matchu — ako imas 10 watched mecva i sve refreshes odjednom, to je 20 reqs = OK.
- **Inactive flag:** Ako mention count < 3, Reddit source se oznacava kao "inactive" (nema dovoljno signala za decision).

### Sto ne trebas

Ne trebas:
- Reddit account
- Reddit OAuth app
- API kljuc

BetSight koristi standardizirani `User-Agent: BetSight/1.0` header i to je dovoljno.

---

## 8. Prvi koraci u BetSightu

Sad kad imas bar Anthropic + Odds API (opcionalno Football-Data i Telegram), vrijeme je da istrzis aplikaciju.

### Navigacija

BetSight ima **4 main taba** na dnu + **Tier Mode Selector** odmah ispod AppBara:

```
+----------------------------------------+
|  BetSight                              |  <- AppBar
+----------------------------------------+
|  ⚽ Pre-Match  🔴 Live  🏆 Accumulator |  <- Tier Selector (GLOBAL)
+----------------------------------------+
|                                        |
|                                        |
|        Trenutni tab content            |
|                                        |
|                                        |
+----------------------------------------+
| 🎯 Matches | ✨ Analysis | 📋 Bets | ⚙ |  <- Bottom nav
+----------------------------------------+
```

**4 taba:**

| Tab | Ikona | Sto radi |
|-----|-------|----------|
| Matches | 🎯 | Lista mecva s kvotama, Value Bets filter, sport selector, star toggle |
| Analysis | ✨ | Claude chat — pitaj o mecvima, dobijes VALUE/WATCH/SKIP |
| Bets | 📋 | Tvoje klade (tier-aware: pre-match/live/accumulator) + P&L, filter, search |
| Settings | ⚙ | API kljucevi, bankroll, tier filter preset, notifications, telegram |

**Tier Selector:**

Tri button-a horizontalno: **⚽ Pre-Match**, **🔴 Live**, **🏆 Accumulator**.
- Aktivan tier je obojan (purple / red / orange)
- Tap — tier se mijenja, ali **ostale taba se ne mijenja, samo njihov sadrzaj**
- Primjerice: ako si u Bets tabu i prebacis iz Pre-Match u Live, filter se promijeni — ako si u Analysis-u, suggestion chips se promijene

### Settings konfiguracija (redoslijed)

Preporucen redoslijed unosa kljuceva u Settings (za cleanest UX):

1. **Anthropic API Key** (obavezno)
2. **The Odds API Key** (obavezno)
3. **Football-Data.org API** (ako planiras koristiti soccer Intelligence)
4. **Value Bets Filter** → odaberi preset (Conservative / Standard / Aggressive)
5. **Cache & Limits** → ostavi default 15 min TTL, vidi API usage progress bar
6. **Bankroll** → unesi total bankroll i default stake unit (vidi sekciju 11 ovog vodica)
7. **Notifications** → toggle (sve ON je default)
8. **Telegram Monitor** → samo ako imas bot setup

### Prvi test: zvjezdicaj mec

1. Idi na **Matches** tab
2. Ako sve radi, vidis listu mecva
3. Ako ne vidis, pull-to-refresh (povuci list prema dolje)
4. Pronadji mec koji zelis pratiti iduca 24-48h
5. Tapni **zvjezdicu** (star toggle) u gornjem desnom uglu kartice — pretvara se u zutu zvjezdicu
6. Gore ispod sport filtera pojavljuje se button **"Intelligence for 1 watched"**

### Ako Odds API daje error

| Error | Rjesenje |
|-------|----------|
| "API key not configured" | Settings → dodaj Odds API kljuc |
| "Invalid API key" | Provjeri kljuc — mogu biti razmaci |
| "Rate limit exceeded" | Sacekaj 1 min |
| "Monthly API quota exhausted" | Prerano si potrosio 500 req/mj. Povecaj cache TTL na 30-60 min u Settings. |

---

## 9. Razumijevanje tri tiera

BetSight-ova glavna distinkcija od obicne value-bet aplikacije je **tier system**. Umjesto jednog prompta koji pokriva sve stilove kladenja, BetSight ima tri **posebno kalibrirana** nacina rada.

### 9.1 PRE-MATCH (⚽ Pre-Match)

**Horizont:** 24-48 sati prije kickoff-a.
**Filozofija:** Deep DYOR. Imas vremena za istraziti sve.
**Aktivira se:** Default je Pre-Match. Tap 🏆 Live ili 🏆 Accumulator da prebacis.

**Claude prompt (skraceno):**
> Focus on deep pre-kickoff analysis. Consider form, H2H, injuries, weather,
> team news. Flag value where bookmaker implied probability < your estimate
> by at least 3 percentage points.

**Suggestion chips u Analysis empty state:**
- "Analyze tomorrow's EPL"
- "Best value bets this weekend"
- "Underdog picks under 4.0 odds"

**Bets screen:** Pokazuje samo bet-ove gdje `placedAt < matchStartedAt` (tj. ne-live bet-ovi).

**Kad koristiti:** Dan-dva prije meca kad mozes **pomno** proci forma, H2H, sastav, vremensku prognozu. Claude je kalibriran da flaga samo ciste edge signale (≥3pp).

**Primjer workflow-a:**
1. Petak navecer — idi na Matches, pronadji nedjeljni EPL meč
2. Zvjezdicaj ga
3. Otvori Intelligence Dashboard, generate report (Football-Data daje form + H2H + standings)
4. Procitaj reasoning za 5 izvora
5. Otvori Analysis, postavi pitanje: "Daj mi svoju analizu za Arsenal vs Liverpool nedjelju, koristi intel report iznad"
6. Claude vraca VALUE/WATCH/SKIP + argumentaciju
7. Ako je VALUE i tebi licni judgement se slaze, **LOG BET** kroz Trade Action Bar → Bet Entry Sheet

### 9.2 LIVE (🔴 Live)

**Horizont:** Tijekom meca (in-play).
**Filozofija:** Reagiraj na momentum shifts i odds drift.
**Rizik:** Visok — emotivno odlucivanje, nagle kvote, kratak prozor odlucivanja.

**Claude prompt (skraceno):**
> Focus on momentum reads and in-play odds drift. If odds data shows recent
> shift, weigh that heavily. Short decision windows. Favor clear, concise
> recommendations. Skip if data is ambiguous — no time for user to deliberate.

**Suggestion chips:**
- "Live odds movement on watched"
- "In-play value — which matches look mispriced now?"
- "Momentum shift detection"

**Bets screen:** Pokazuje samo bet-ove gdje `placedAt > matchStartedAt` (live klade).

**Specijalnost:** Ako kladis u Live tieru, BetEntrySheet automatski postavi `matchStartedAt = now - 1 min` — tako da se bet klasificira kao live.

**Kad koristiti:** Za iskusne kladjenje. In-play market je brzi — sam odluci hoce li biti to tvoj stil.

**Upozorenje:** Claude ce biti **strict** u live tieru. Ako nije kristalno jasno, dat ce SKIP. To je namjerno — live je i tako rizicno.

### 9.3 ACCUMULATOR (🏆 Accumulator)

**Horizont:** Multi-match build (cesto za vecji payout sa vecjim rizikom).
**Filozofija:** Combine 2-5 legs s correlation awareness.
**Rizik:** Najvisi — sve mora pogoditi da accumulator dobije.

**Claude prompt (skraceno):**
> User is building a multi-bet combo. For each leg, consider correlation:
> avoid legs that share dependencies. Total odds multiply — flag if combined
> odds exceed 20.0 (unrealistic value territory). Encourage 2-4 legs, not 10.

**Suggestion chips:**
- "Build a 3-leg accumulator from my watched matches"
- "Check correlation in my current selections"
- "Conservative acca — all favorites under 2.0"

**Bets screen:** Prebacuje se u **specijalan view**:
- Tri taba: **Building**, **Placed**, **Settled**
- FAB otvara **Accumulator Builder Screen** (full screen push route)

**Accumulator Builder:**
- Odaberi 2-5 watched mecva
- Za svaki leg — picker dialog za outcome (Home / Draw / Away)
- Unesi stake
- Vidish **combined odds** (multiplikacija svih leg odds), **potential payout**, i **correlation warnings** ako postoje

**Correlation warnings:**
- "Contains multiple legs from the same match" — unmoguca kombinacija
- "Multiple legs from EPL on same day" — weak correlation (ako isti dan veliki nestetak isto djeluje oba meca)

**Kad koristiti:** Rijetko. Accumulator-i su visoko-rizicni po definiciji — idealno za korelacijski nezavisne legs i mini stake (1-2% bankroll-a).

### 9.4 Usporedba tri tiera

| | **PRE-MATCH** | **LIVE** | **ACCUMULATOR** |
|---|---|---|---|
| **Kad** | 24-48h prije | Tijekom meca | Bilo kada (build unaprijed) |
| **Broj simultanih pozicija** | Vise | 1 (akitvan meč) | 1 (jedan acca draft) |
| **Claude ton** | Analyticni, detaljni | Koncizni, brzi | Correlation-aware |
| **Expected WIN rate** | 40-55% | 30-45% | 10-25% (ali veci payout) |
| **Disciplinski horizont** | Dugorocno | Trenutacno | Srednjorocno |
| **Primary action** | LOG BET | LOG BET (live flag) | BUILD ACCUMULATOR |

**Preporuka za pocetnike:** Pocni s **Pre-Match**. Ignoriraj Live i Accumulator dok ne budes imao 30+ settled bet-ova i razumijes svoj pattern. Live i Accumulator su za nakon sto znas sta se radi.

---

## 10. Tvoja prva analiza s Claudeom

### Prerequisities

- Anthropic API key dodan u Settings ✓
- Odds API key dodan ✓
- Barem 1 meč u Matches listi
- (Opcionalno, ali preporucljivo) 1 zvjezdican meč za Intelligence context

### Korak po korak

**Korak 10.1 — Odaberi meč**

1. Matches tab → pronadji meč koji te zanima
2. Tapni (tap na karticu) — otvara **Match Detail Screen**
3. Tamo imas 4 taba: **Overview** / **Intelligence** / **Charts** / **Notes**
4. **Overview** pokazuje kvote + countdown do kickoff-a
5. Tapni **"Analyze in AI"** button dolje

(Alternativno: mozes idu direktno na **Analysis** tab i rucno pitati — ali gore je brze i injecta meč u kontekst)

**Korak 10.2 — Stage match (ako ide kroz Analysis tab)**

1. Idi na Matches → zvjezdicaj meč ili koristi **select mode** (dugi tap na karticu u neko starije verzije, ili checkbox)
2. Tapni **"Analyze N matches"** FAB
3. Prebaciseste automatski u Analysis tab s meč "staged" u kontekstu

**Korak 10.3 — Pitaj nesto**

Claude empty state prikazuje suggestion chips za trenutni tier. Ili mozes tipkati rucno.

Primjeri pitanja:
- "Daj mi svoju analizu"
- "Gdje vidis edge ako postoji?"
- "Koliki je bookmaker margin i je li knjigu sharp?"
- "Ako bih se kladio, koja je tvoja preporuka?"

Tap send (✈ ikona).

**Korak 10.4 — Procitaj Claude odgovor**

Claude odgovor ima tri dijela:

1. **Narrative:** Claude-ova argumentacija (form, odds, tipster signali, tvoja povijest ako je relevantna)
2. **Implikacije za specifican outcome** (npr. "Home looks most mispriced, at 1.95 odds vs my estimated probability of ~55%")
3. **Marker** na zadnjoj liniji: `**VALUE**`, `**WATCH**`, ili `**SKIP**`

### Razumijevanje markera

| Marker | Znaci | Tvoja akcija |
|--------|-------|-------------|
| **VALUE** | Claude detektira jasan edge. Specifican outcome, specific odds, estimated vs implied probability (≥3pp edge). | Razmotri bet. Tap "LOG BET" u Trade Action Bar-u. |
| **WATCH** | Interesantno ali marginal edge ili data je nepotpuno. | Ne klada jos. Prati kvote, vrati se za 1-2 sata. |
| **SKIP** | Fair odds ili nema jasne analize. | Idi dalje, ne trosi stake na nejasnu situaciju. |

### Trade Action Bar

Kad Claude vrati `**VALUE**`, ispod njegova mjehurca pojavljuje se zeleni panel s tri button-a:

```
+------------------------------------------+
|  🏁 VALUE signal detected                |
|                                          |
|  [LOG BET]  [SKIP]  [ASK MORE]           |
+------------------------------------------+
```

- **LOG BET** — otvara Bet Entry Sheet s pre-filled podacima iz staged matcha. Ovo je preferencirana akcija kad se slozis s Claude-om.
- **SKIP** — biljezi "skipped" feedback (za buducu prompt kalibraciju u WORKLOG-u), pokazuje SnackBar "Recommendation skipped — logged for calibration". Koristis kad se NE slozis s Claude-om.
- **ASK MORE** — popunjava input polje s pitanjem "Why do you think this is value? What's the main risk?" — daj Claude-u priliku da se udubi. Korisno ako je samo VALUE marker bio dovoljan, ali zelis potvrdu.

Svaki klik na ova 3 dugmeta se **biljezi** u Hive kao `UserFeedback` — buducu verziju BetSight-a koristi za poboljsanje prompta.

### Context injection — sto Claude vidi?

Kad ti posaljes poruku, BetSight ne salje samo tvoj tekst Claudeu. Priprema **strukturirani blok** oko tvog pitanja:

```
[SELECTED MATCHES]
EPL: Arsenal vs Liverpool | kickoff 2026-04-20T14:00:00Z |
odds H/D/A: 2.10/3.40/3.20 | bookmaker Pinnacle
  [drift] Home +2.3% since last snapshot
[/SELECTED MATCHES]

[INTELLIGENCE REPORT — confluence 3.8/6.0 — POSSIBLE_VALUE]
Odds (1.5/2.0): margin 4.2%, sharp book, drift Home +2.3%, non-favourite direction
Football-Data (1.1/1.5): home strong form, H2H balanced, form HWDLW ADLWW
NBA Stats (inactive): Not an NBA match
Reddit (0.8/1.0): 15 mentions, home tilt
Telegram (0.4/0.5): @my_channel (Visoka), @tipsmaster (Srednja)
Hint: Some signals present. Confirm with additional reasoning.
[/INTELLIGENCE REPORT]

[TIPSTER SIGNALS]
[45m ago] @tipsmaster (Soccer): Arsenal home value play 1.95+
[/TIPSTER SIGNALS]

[BETTING HISTORY — last 5 bets]
2026-04-12 | Soccer | Arsenal vs Chelsea | Home @ 2.15 | stake 10.00 | won +11.50
2026-04-05 | Soccer | Liverpool vs Man City | Away @ 3.50 | stake 5.00 | lost -5.00
...
[/BETTING HISTORY]

[TIER: PRE-MATCH — 24-48h horizon]
Focus on deep pre-kickoff analysis...

Daj mi svoju analizu za Arsenal vs Liverpool
```

Claude vidi cijelu sliku — ne samo tvoje pitanje. To je razlog zasto analiza izgleda "pametnija" nego da postoji copy-paste u obicni ChatGPT.

### Rjesavanje problema

| Problem | Rjesenje |
|---------|----------|
| "Anthropic API key required" | Settings → dodaj kljuc |
| Claude odgovor ne sadrzi VALUE/WATCH/SKIP marker | Rijetko — tipski ponovno pitaj. System prompt zahtijeva marker. |
| Trade Action Bar se ne pojavljuje | Pojavljuje se SAMO ispod zadnje assistant poruke **kada je VALUE** detektiran. Za WATCH / SKIP nema bar. |
| Chat sporo | Claude tipski odgovara 5-15 sec. Ako je >30 sec, timeout error ce se prikazati. |

---

## 11. Tvoj prvi bet

Pretpostavimo da je Claude vratio **VALUE** i ti se slozis s preporukom.

### Prije prvog bet-a — bankroll

OBVEZNO prije bilo kojeg bet-a: **postavi bankroll**.

1. Settings → skrolaj do **Bankroll** sekcije
2. **Total bankroll:** koliko imas ukupno za kladenje (npr. 200 EUR)
3. **Default stake unit:** default stake po bet-u (npr. 10 EUR = 5% bankroll-a)
4. **Currency:** EUR (ili USD / GBP / HRK / CHF / BAM / RSD)
5. Tap **"Save"** → SnackBar "Bankroll saved"

> 💡 **Pravilo pocetnika:** Default stake ne bi trebao preci **3-5% bankroll-a**.
> BetSight automatski prikazuje warning kad stake prijede 5% ("Industry recommendation: 1-3% per bet").
> Smisao: jedan los bet ne smije te baciti iz igre.

### Korak po korak: unos bet-a

**Korak 11.1 — Iz Trade Action Bar-a (preporuceno)**

1. U Analysis chatu — nakon **VALUE** preporuke — tap **LOG BET**
2. Otvara se **Bet Entry Sheet** s pre-filled podacima:
   - Sport (zakljucano ako je staged match)
   - League, Home, Away (pre-filled)
   - Selection (Home/Draw/Away) — nisi pre-filled, moraš sam izabrati prema Claude preporuci
   - Odds (pre-filled ako je staged)
   - Stake (pre-filled s tvoj default stake unit)
3. Provjeri sve podatke. Ako Claude je preporucio "Home @ 1.95", provjeri Selection = Home i Odds = 1.95.
4. (Opcionalno) Dodaj Bookmaker i Notes
5. Tap **"Save Bet"**
6. SnackBar "Bet logged"

**Korak 11.2 — Rucno iz Bets tab-a**

1. Bets tab → FAB (+) dolje desno
2. BetEntrySheet se otvara prazan
3. Popuni sve manualno
4. Save

### Validacija

BetSight odbija nevazece podatke:
- Odds moraju biti > 1.0
- Stake mora biti > 0
- Pick mora biti izabran (Home / Draw / Away)
- Ako je Soccer — Draw je dostupan; inace ne
- Team names i League su obvezna

### Nakon save — sto slijedi?

Bet se pojavljuje u **Bets tab → Open** subtab-u. Status = Pending.

Ako si u **PRE-MATCH** tieru, bet se razlikuje od LIVE bet-ova:
- Pre-match: `matchStartedAt = kickoff time` (iz staged match)
- Live: `matchStartedAt = now - 1 min` (simulacija da je mec vec pocneo)

### Settlement (kad je mec zavrsen)

1. Bets tab → Open subtab → tap pending bet
2. Otvara se Settle bottom sheet s 3 dugmeta:
   - **✓ Won** (zeleno) — pogodio si
   - **✗ Lost** (crveno) — izgubio si
   - **— Void** (sivo) — mec otkazan, nepotpun ili pushed (povrat stakeа)
3. Tapni odgovarajuce
4. Bet prelazi u **Settled** subtab
5. Automatski se racunaju:
   - **actualProfit:** won = stake * (odds-1), lost = -stake, void = 0
   - **P&L summary** na vrhu Bets tab-a se update-a
   - **Equity curve chart** u P&L Dashboardu dobiva novu tocku

### Swipe to delete

Ako si napravio pogresku pri unosu (npr. krive kvote), mozes bet izbrisati:
1. Tab Bets → lista bet-ova
2. Swipe **slijeva na desno** na kartici (kao brisanje email-a)
3. Confirm dialog: "Delete bet?"
4. Potvrdi

### Per-sport breakdown

Nakon nekoliko settled bet-ova, vidjet ces **Per-sport breakdown** card ispod equity curve-a:

```
+------------------------------------------+
|  Per-sport breakdown                     |
|                                          |
|  Sport    Bets  Win%  ROI     P/L       |
|  ───────────────────────────────────────  |
|  ⚽ Soccer   12    58%  +8.3%  +45.20 EUR |
|  🏀 NBA      5    40%  -15.0% -12.50 EUR |
|  🎾 Tennis   3    67%  +22.1% +15.80 EUR |
+------------------------------------------+
```

Korisno za **prepoznati koji sport ti je profitabilan a koji nije** — dugorocno to su ozbiljni podaci.

### Rjesavanje problema

| Problem | Rjesenje |
|---------|----------|
| "Enter positive stake" | Upises decimalni stake > 0 |
| "Odds must be greater than 1.0" | Upises kvotu > 1 (nema losing odds) |
| "Draw only available for soccer" | Pick = Draw ali Sport = basketball/tennis. Promijeni sport ili pick. |
| Bet se pojavljuje u PRE-MATCH filteru iako je bio LIVE | Tier je bio PRE-MATCH kad si save-ao. Briši i ponovno unesi u Live tieru. |

---

## 12. Razumijevanje grafikona

BetSight ima tri razlicita grafikona u MatchDetailScreen → Charts tab + Bets tab.

### 12.1 Odds Movement Chart

**Sto prikazuje:** Kako su se kvote na tvom watched mecu mijenjale kroz vrijeme.

```
Odds
 3.5 ┤                    ╭──── Away
 3.0 ┤────────────────────╯
 2.5 ┤          ╭─────────────── Draw
 2.0 ┤──────────╯
 1.5 ┤  ╮─────────── Home
     └──┴───┴───┴───┴───┴───
      0h  6h  12h 18h 24h time
```

- **Plava linija** = Home odds
- **Narancasta** = Draw odds (samo soccer)
- **Crvena** = Away odds

**Kako citati:**
- Ako linija pada — implied probability raste → smart money ide prema tom outcome-u
- Ako linija raste — implied probability pada → odlazi s tog outcome-a (slabiji prilikama)
- Krizanje linija signalizira preokret expected valjanosti

**Kako se generira:**
- Moras imati meč **watched** (zvjezdicu)
- Svaki put kad refreshаs Matches (ili svaki Intelligence auto-refresh), BetSight biljezi **snapshot** kvota
- Chart se crta kad imas **≥2 snapshot-a** za meč

Ako imas 1 snapshot ili manje — chart pokazuje "Not enough snapshots yet".

### 12.2 Form Chart

**Sto prikazuje:** W/D/L rezultati zadnjih 5 mecva za svaki tim.

```
Arsenal form:  [W][W][D][L][W]
Liverpool form: [W][L][W][D][W]
```

- **Zeleni badge** = Win
- **Sivi** = Draw
- **Crveni** = Loss

**Kako citati:**
- Cista forma (WWWWW ili LLLLL) — jasan momentum
- Mjesavina — neutralno
- L-L-L kontra W-W-W — jasan mismatch (favorit po forma)

**Samo za:**
- **Soccer** (EPL + Champions League)
- Mora postojati **FootballDataSignal** cached (tj. generate Intelligence Report prije)

**Nista za:**
- NBA (pokazuje placeholder "NBA form data not yet visualized...")
- Tennis (pokazuje TennisInfoPanel umjesto toga)

### 12.3 Equity Curve Chart

**Sto prikazuje:** Kumulativni P&L kroz vrijeme (po redu bet-ova).

```
+EUR
  50 ┤                       ╭──
  25 ┤                  ╭────╯
   0 ┼──────────────────┤
 -25 ┤     ╭────────────╯
 -50 ┤ ────╯
     └─────┴────┴────┴────┴────
          #1   #5   #10  #15  #20 bets
```

- **Zelena krivulja + light fill** = pozitivan end state
- **Crvena krivulja + light fill** = negativan end state

**Kako citati:**
- Uzlazna krivulja — dobitnicka serija
- Ravna → profit stagnira, ali ne gubi
- Padajuca — losing streak, vrijeme za pauzu
- Volatile (zigzag) — inconsistent, need for analysis (log u BETLOG.md)

**Gdje se vidi:**
- **Bets tab** → iznad TabBar-a, ispod 4-metric card (totalBets/winRate/ROI/totalP&L)
- Prikazuje se **samo ako ima ≥2 settled bet-a** (manje = premalo podataka)

### Rjesavanje problema

| Problem | Rjesenje |
|---------|----------|
| "Not enough snapshots yet (1/2)" | Zvjezdicaj meč, pull-to-refresh 2x s razmakom od 15+ min |
| Form chart pokazuje "Form data not yet fetched" | Generate Intelligence Report za taj soccer meč |
| Equity curve ne crta | Manje od 2 settled bet-a. Settle par bet-ova prvo. |
| Chart labels se preklapaju | Na manjim Android ekranima (<360dp). BetSight ima responsive sizing, ali nekad i tako ostaje gusto. Rotate phone horizontally. |

---

## 13. Rjecnik pojmova

Alfabetski poredani termini koje cesto cujesh u kladenju.

**Asian Handicap (AH)** — Tip kvote s fractional handicapom za eliminaciju draw-a. Npr. "Arsenal -1.5" znaci Arsenal mora pobijediti s barem 2 gola razlike.

**Bankroll** — Ukupni iznos novca dodijeljen iskljucivo kladjenja. Ne mijesa se s osobnim trošckovima.

**Betting Exchange** — Alternativa kladionicama — trziste gdje kladionici i uplate direkno razmjenjuju pozicije. Primjer: Betfair. BetSight ne pokriva exchange kvote direktno (Odds API uglavnom pokriva klasicne bookmaker-e).

**Bookmaker (Kladionica)** — Kompanija koja postavlja kvote i prima uplate. Npr. Pinnacle, Bet365, William Hill.

**Bookmaker margin** — Ugradjena profitna marža kladionice. Za 2-way trzista (tenis), ideal je 0% margin ("fair odds"). Realno je 2-8%. Kladionice s margin < 5% su **sharp books** (Pinnacle). > 8% = soft book (lose value).

**Combined odds (Accumulator odds)** — Multiplikacija svih leg odds. 3-leg accumulator s kvotama 2.0, 1.8, 1.5 = 2.0 × 1.8 × 1.5 = 5.40 combined.

**Confluence score** — BetSight-ov aggregate 0-6.0 score koji kombinira 5 intelligence izvora. Vise = vise izvora se slaze.

**Decimal Odds** — Europski format kvote. "2.50" znaci: ako klades 10, potencijalni povrat je 25 (profit 15). BetSight koristi iskljucivo decimal odds.

**DYOR** (Do Your Own Research) — Klasican kriptografski/kladionicki term za "istraži sam". Claude je alat, ne guru.

**Edge** — Razlika izmedju tvoje procjene vjerojatnosti i implicirane vjerojatnosti. Npr. Odds 2.00 = 50% implied, ali ti procjenjujes 55% — edge je 5 percentage points (+5pp).

**Equity Curve** — Grafik kumulativnog P&L-a kroz vrijeme. Vizualno iskustvo trading/betting discipline.

**H2H (Head-to-Head)** — Povijest medjusobnih mecva dva tima. Npr. "Arsenal vs Liverpool zadnji 5 H2H: 2W 1D 2L".

**Implied Probability** — Probability prema kvoti. Formula: `p = 1 / decimal_odds`. Primjer: odds 2.00 → implied = 0.50 = 50%.

**In-play / Live** — Kladenje tijekom meca. Kvote se mijenjaju svake par sekundi.

**Kickoff** — Zapocetak meca.

**Kladionica** — Vidi Bookmaker.

**Kvota** — Vidi Decimal Odds.

**Leg** — Pojedinacni bet koji je dio accumulator-a. "3-leg acca" = 3 leg-a.

**LOG BET** — Primarna akcija u BetSight-u kad se slozis s Claude VALUE preporukom. Biljezi bet kao pending.

**Moneyline** — Americki termin za "ko ce pobijediti" market. Nema handicap, nema totala — samo ishod.

**Over/Under (O/U)** — Marketa pogadjas hoce li ukupan broj golova/poena biti IZNAD ili ISPOD zadate linije. "Over 2.5 goals" = pobjeda ako ima 3+ golova.

**P&L (Profit and Loss)** — Neto dobit ili gubitak.

**Pick** — Tvoj izabran ishod. "My pick is Home" = kladisе na kuce.

**Pinnacle** — Kladionica poznata po ultra-low margin (2-4%). Industry benchmark za "sharp odds".

**Pull-to-refresh** — UI pattern — povuci list prema dolje da trigger-s refresh. BetSight koristi za Matches screen.

**Push notifications** — Android sistem za pojavljivanje notifikacija u traci. BetSight koristi za kickoff reminders, drift alerts, VALUE alerts.

**ROI (Return on Investment)** — Profit kao postotak ulozenog. `roi = (totalProfit / totalStakedOnSettled) * 100`. Pozitivan ROI = profitabilan.

**Settle / Settlement** — Final-izacija bet-a nakon meca: Won / Lost / Void.

**Sharp book** — Kladionica s niskim margin-om (<5%). Kvote su "stvarnije" jer je kladionica kalibrirana profesionalcima.

**Soft book** — Kladionica s visokim margin-om (>8%). Najgore kvote za kladjenje, ali cesto imaju bonuse koji kompenziraju.

**Spread** — Razlika izmedju najvisih i najnizih kvota u meca. Npr. H 1.2 / A 10.0 ima spread 8.8 (visok — jedan tim veliki favorit).

**Stake** — Iznos koji kladim. Napravi pravilo: max 3-5% bankroll-a po stake-u.

**Staging** — BetSight mehanizam da "pripremi" mec za sljedecu Claude poruku. Staged match/signal se injecta u kontekst kao "[SELECTED MATCHES]".

**Tier** — BetSight-ov kategorijski sistem: PRE-MATCH / LIVE / ACCUMULATOR.

**Value Bet** — Bet gdje je implied probability kladionice nizi od tvoje procjene stvarne vjerojatnosti. Dugorocno, konzistentno kladenje value bet-ova = pozitivni ROI.

**Void** — Bet je otkazan (mec prekinut, pogresan market). Povrat stakeа, no profit.

**Watch list** — BetSight-ova lista mecva koji su zvjezdicani. Intelligence reports se generiraju samo za watched matches.

---

## 14. Sigurnosna pravila i odgovorno kladenje

### Zlatna pravila

1. **Nikad vise nego sto si spreman izgubiti.** Bankroll nije strvac zivota. Ako ostavimeš bez kave zato jer si sve potrošio na klade — prekasno je.

2. **Nikad ne juri gubitke (chasing losses).** Imas los dan? **Prestani.** Sutra, s cistom glavom. "Jednom još za povrat" nece ti vratiti, samo ce ti produbiti rupu.

3. **Stake velicina 1-5% bankroll-a.** To je industry standard. Veci stake = brzi varijance, brzi zeleni i brzi crveni streaks = vise stress.

4. **DYOR uvijek.** Claude je alat. Ne gura. Ako Claude kaze VALUE a ti "osjecaš" drugacije — skipuj. Tvoje znanje o specifičnom timu > Claude-ov general training.

5. **Tracking.** Biljezi sve u **BETLOG.md** — stvarni ishodi protiv Claude preporuka. Nakon 30-50 bet-ova imas podatak je li Claude dobro kalibriran ili ne.

6. **Pauze.** Ako gubiš 3-4 bet-a redom, **zatvori aplikaciju za dan**. Vrati se sutra. Emocije kladjenja su stvarne — pobjegnes od njih.

### API kljucevi — sigurnost

**Sto BetSight NE radi:**
- Ne salje tvoje API kljuceve na bilo koji BetSight-ov server (ne postoji)
- Ne logira ih u cloud
- Ne dijeli ih

**Sto BetSight RADI:**
- Cuva ih lokalno u Hive-u (enkriptirana lokalna baza)
- Salje ih DIRECTLY na servise (Anthropic, Odds API) — ide **iz tvog telefona → HTTPS → Anthropic**
- Ne prolaze preko nikakvog "BetSight cloud"-a

**Preporuke:**
- Koristi poseban API kljuc za BetSight (ne dijeli Anthropic kljuc s drugim servisima)
- Ako telefon izgubis — u **Anthropic console** revoke-aj taj specifican kljuc
- Redovno provjeravaj Anthropic billing za anomalije

### Bet data — lokalno

Sve tvoje klade, bankroll, settings — nista ne ide u cloud. Sve je u Hive bazi na tvom telefonu.

**Back up:**
- Androidove tipske backup mehanizme (Google Drive backup app data) — znaj da je moze biti encrypted in transit ali je krajnja enkripcija u Google hands
- Alternativa: redovno prepisivanje bet-ova u BETLOG.md (manualno ali robustno)

### Responsible gambling resources

**Ako ti se kladjenje vise nece pokazati kao hobi, nego kao problem:**

- **Hrvatska:** Udruga za rehabilitaciju kockara **KLUB "Kocka"** — https://klubkocka.hr
- **Europa:** **BeGambleAware** — https://www.begambleaware.org
- **Svijet:** **Gamblers Anonymous** — https://www.gamblersanonymous.org

**Znakovi problema:**
- Kladim da se osjecaš bolje kad si tuzno/ljutit
- Laze drugima o iznosima koje klades
- Pocinjem posudjati novac za klade
- Kladenje je stalna glavna briga (mislim na njega vise nego posao ili obitelj)

Ako prepoznajes barem jednog od ovih znakova — **BetSight nije za tebe**. Deinstaliraj app i kontaktiraj klinicku pomoc.

> BetSight ne moze detektirati addiction. Aplikacija pretpostavlja da je korisnik
> odgovoran odrasli covjek. Ako vidis da je kladjenje pocelo kontrolirati tebe
> umjesto obratno — disconnect.

---

## 15. Zavrsna rijec

Ovim vodicem si savladao osnove BetSight-a.

### Sta sada?

1. **Prvo:** Opustena sedmica bez pravih stakes-a. Zvjezdicaj 2-3 meca. Generate Intelligence reports. Citaj Claude analize. **Ne klada jos** — samo upoznaj UX.

2. **Drugo:** Prvi real bet s malim stake-om (1-2% bankroll-a). Bilo koji tier. Prati ga. Settle kada mec bude gotov. Biljezi u BETLOG.md:
   ```
   | Datum | Mec | Claude call | Moja odluka | Ishod | Biljeske |
   |-------|-----|-------------|-------------|-------|----------|
   | 2026-04-20 | Arsenal vs Liverpool | **VALUE** Home @ 1.95 | LOG BET @ 2u | Home won 2-1 | Claude tocan, margin 4% dobar signal |
   ```

3. **Trece:** Nakon 10-20 settled bet-ova — analiziraj rezultate. Sto je profitabilno? Koji tier ti pase? Koji sport ti ne odgovara?

4. **Cetvrto:** Long-term — BETLOG ti postaje tvoj **personal trading journal**. To je gdje prava vrijednost BetSight-a lezi. Aplikacija sama po sebi je alat — ali ti si onaj koji uci.

### Spomen — DYOR nikad ne odustaje

Koliko god Claude dobro analizirao, **nikad se nemoj slijepo oslanjati**. Svaka VALUE preporuka je **hipotetzа** — ti si onaj koji donosi konacnu odluku, s obzirom na tvoj znanja o specificnom timu, sezonskim trendovima, povredama.

### Za napredno korištenje

Kad budes spreman, pogledaj **[MANUAL.md](MANUAL.md)** za detaljne feature walkthrough-e — Accumulator strategije, Intelligence Dashboard power-user features, FAQ, napredni troubleshooting.

Za tehnicku arhitekturu — **[OVERVIEW.md](OVERVIEW.md)**.

Za development log — **[WORKLOG.md](WORKLOG.md)** (svih 10 development sesija od scratch-a do v3.1.2).

**Sretno s kladenjem — i sjeti se: klada odgovorno.**

---

*BetSight v3.1.2 | 2026 | Izrаdjeno s Claude AI*
