# BetSight SESSION 9 — Backlog Cleanup + Tennis Minimal + Accumulator Rename

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` (pravila, autonomni režim, redoslijed unutar faze)
- `WORKLOG.md` (S1–S8 povijest — posebno `## Identified Issues` sekcija na kraju — to je PRIMARNI input za S9)

**Nakon čitanja napiši kratki summary (3–5 rečenica) što ćeš raditi, potom nastavi autonomno kroz svih 4 zadataka bez čekanja na developerovu potvrdu.**

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues
2. `flutter build windows` — mora proći (za Task 4 pokreni i `flutter build apk --debug`)
3. Dodaj unos u `WORKLOG.md` pod novu sekciju `## Session 9: YYYY-MM-DD — Backlog Cleanup + Tennis Minimal + Accumulator Rename`
4. Tek onda prelazi na sljedeći zadatak

**Git:** Claude Code **NE radi git commit ni git push.** Developer preuzima.

**Verzija:** u Tasku 1 ažuriraj `pubspec.yaml` na `version: 3.1.1+10` (**patch bump** — samo cleanup i jedan mali feature, nema nove funkcionalnosti koja opravdava minor).

**S9 je organizacijska sesija.** Manji opseg od S7/S8. Očekivano 0 novih Dart fajlova, ~8-10 ažuriranih (uglavnom rename-povezani).

---

## Projektni kontekst

S8 je doveo Identified Issues backlog s 10 na 3. Preostali 3 imaju različite karaktere:

1. **Telegram Bot API limitation** — fundamentalno ograničenje platforme, ne bug. MTProto migracija zahtijeva 3-4 sesije rada, user-level auth (security concern), i nije u aktivnom održavanju u Dart ekosistemu. **Odluka: formalno prekvalificirati kao "by-design — will not fix" s jasnim obrazloženjem.**

2. **MatchDetailScreen Charts tab ne pokriva tennis** — Charts tab trenutno prikazuje Form Chart samo kad postoji `FootballDataSignal` (soccer). Tennis nema dedicated service. **Odluka: minimalno rješenje bez novog servisa — koristi Odds API podatke (rank, bookmaker favorite) i rječitu kontekstualnu poruku u MatchDetailScreen-u kad je tennis match otvoren.**

3. **Material Accumulator name collision** — cosmetic. Flutter Material library ima `Accumulator` widget (rijetko korišten), naš model ima isti naziv. Trenutni fix je `import 'package:flutter/material.dart' hide Accumulator;` u 2 fajla. **Odluka: rename `Accumulator` → `BetAccumulator` kroz cijeli codebase za čišći kod.**

**S9 cilj:** backlog na **1 issue** (Telegram), sa jasnim "will not fix" označenjem. Nakon S9, real-world test može krenuti bez ikakvog tehničkog duga u pozadini.

---

## TASK 1 — Pubspec Bump + Telegram Issue Reclassification

**Cilj:** Verzija na 3.1.1+10. Telegram Bot API issue prekvalificiran s jasnim obrazloženjem u WORKLOG-u.

### Ažuriraj fajlove

**`pubspec.yaml`** — version bump na `3.1.1+10`.

**`WORKLOG.md`** — u `## Identified Issues` sekciji, zamijeniti postojeći Telegram unos s:

```markdown
## Identified Issues

### By-Design (Will Not Fix)

- **Telegram Bot API limitation** *(resolved as by-design in S9)*
  - **Status:** Formal decision to not migrate to MTProto
  - **Ograničenje:** Bot API (Telegram Bot platform) prima poruke samo iz kanala gdje je bot dodan kao član. Public tipster kanali koji ne dozvoljavaju bot-ove nedostupni su.
  - **Zašto ne rješavamo:**
    1. **Platformski razlog:** Telegram je namjerno dizajnirao Bot API i User API (MTProto) kao dvije odvojene pristupne rute. Bot API je za bot programe (subscribing), MTProto za user-level clients. To nije bug Bot API-ja — to je dizajnska odluka.
    2. **Tehnički razlog:** MTProto u Dart ekosistemu nema produkcijski spreman SDK. `telegram_client` paket je eksperimentalni, `td_plugin` je Android-only i neaktivno održavan. Alternativa (C++ tdlib bindings kroz FFI) je nerazmjerno kompleksna za mobile MVP.
    3. **Security razlog:** MTProto zahtijeva korisnikov API ID + API Hash + phone number + SMS verification. BetSight bi tako dobio pristup cijelom korisnikovom Telegram računu — ozbiljan security/privacy footprint koji ne opravdava korist.
    4. **Arhitekturalni razlog:** BetSight od S6 koristi 5-source intelligence layer (Odds, Football-Data, BallDontLie, Reddit, Telegram). Telegram je 1 od 5 izvora, **ne primary**. Diverzifikacija kompenzira ograničenost pojedinačnog izvora — pattern direktno posuđen iz CoinSight-a koji do v8.0.0 nikad nije dotakao MTProto i nije ga trebao.
  - **Preporučeni workflow za korisnika:** kreirati vlastiti Telegram bot preko `@BotFather`, dodati bot kao admin u vlastite kanale (gdje agregira tipster content koji prati) ili u manje zajednice koje prihvaćaju bot-ove. Za "big public" tipster kanale koji ne dopuštaju bot-ove, BetSight ne nudi ekstrakciju — korisnik neka koristi Reddit i Football-Data kao alternativne izvore za tu vrstu intelligencea.
```

### Verifikacija Taska 1

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 2 — Tennis Minimal: MatchDetailScreen Charts tab poboljšanje

**Cilj:** Kad korisnik otvori MatchDetailScreen → Charts tab za tennis match, umjesto prazne sekcije (ili "no form data") prikazuje **minimalno ali korisno**:

- OddsMovementChart (već radi za sve sportove — nema promjene)
- Umjesto FormChart koji ne postoji — tennis-specific info panel s:
  - Bookmaker favourite badge (koji igrač ima niže kvote)
  - Implied probability tile (za oba igrača)
  - Ranking info (ako Odds API response sadrži — tipski ne, ali pokušamo)
  - Informativna poruka zašto nema detaljne forme

### Kreiraj fajlove

**`lib/widgets/charts/tennis_info_panel.dart`:**

```dart
class TennisInfoPanel extends StatelessWidget {
  final Match match;
  
  const TennisInfoPanel({super.key, required this.match});
  
  @override
  Widget build(BuildContext context) {
    final h2h = match.h2h;
    if (h2h == null) {
      return _buildNoData();
    }
    
    // Implied probabilities
    final homeImplied = (1.0 / h2h.home) * 100;
    final awayImplied = (1.0 / h2h.away) * 100;
    final margin = (homeImplied + awayImplied) - 100;
    
    final homeIsFav = h2h.home < h2h.away;
    
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_tennis, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Tennis Match Info',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Bookmaker favourite highlight
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bookmaker favourite: ${homeIsFav ? match.home : match.away}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Implied probability tiles
            Row(
              children: [
                Expanded(
                  child: _ProbTile(
                    label: match.home,
                    odds: h2h.home,
                    probability: homeImplied,
                    isFav: homeIsFav,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProbTile(
                    label: match.away,
                    odds: h2h.away,
                    probability: awayImplied,
                    isFav: !homeIsFav,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Margin indicator
            Row(
              children: [
                Text(
                  'Bookmaker margin: ',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
                Text(
                  '${margin.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: margin < 5 ? Colors.green : margin < 8 ? Colors.orange : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  margin < 5 ? '(sharp)' : margin < 8 ? '(normal)' : '(soft)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Info note — why no form chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Detailed player form (recent matches, H2H, surface stats) not available — '
                    'BetSight does not integrate a dedicated tennis data source. '
                    'For deep analysis, reference ATP/WTA official sites or a tennis-specific tool.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoData() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No odds data for this tennis match',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbTile extends StatelessWidget {
  final String label;
  final double odds;
  final double probability;
  final bool isFav;
  
  const _ProbTile({
    required this.label,
    required this.odds,
    required this.probability,
    required this.isFav,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFav ? Colors.green.withValues(alpha: 0.5) : Colors.grey[800]!,
          width: isFav ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                odds.toStringAsFixed(2),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(
                '(${probability.toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Ažuriraj fajlove

**`lib/screens/match_detail_screen.dart`** — u Charts tab renderer-u:

```dart
Widget _buildChartsTab() {
  return ListView(
    padding: const EdgeInsets.all(12),
    children: [
      // Odds movement chart — vrijedi za sve sportove
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Odds Movement', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: OddsMovementChart(
                  snapshots: StorageService.getSnapshotsForMatch(match.id),
                  showDraw: match.sport.hasDraw,
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Sport-specific form/stats
      if (match.sport == Sport.soccer) ...[
        // Existing Football-Data form chart rendering (as before)
        _buildFootballFormSection(),
      ] else if (match.sport == Sport.basketball) ...[
        // Existing NBA stats rendering (if any)
        _buildBasketballStatsSection(),
      ] else if (match.sport == Sport.tennis) ...[
        // NEW — TennisInfoPanel
        TennisInfoPanel(match: match),
      ],
    ],
  );
}
```

Razdvojiti postojeće soccer/basketball renderere u helper metode ako još nisu (`_buildFootballFormSection`, `_buildBasketballStatsSection`) kako bi main renderer bio clean.

### Verifikacija Taska 2

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Manual check: otvori tennis match iz Matches screen-a → Detail → Charts tab → mora prikazati OddsMovementChart + TennisInfoPanel. Za soccer/basketball i dalje radi kao prije.

---

## TASK 3 — Accumulator → BetAccumulator Rename (Global)

**Cilj:** Rename `Accumulator` klase u `BetAccumulator` kroz cijeli codebase. Ukloni `hide Accumulator` iz Material import-a jer kolizija više ne postoji.

### Rename koraci

**Potrebna preimenovanja:**

1. `Accumulator` klasa → `BetAccumulator` (u `lib/models/accumulator.dart`)
2. `AccumulatorLeg` → ostaje kao što jest (nema kolizije)
3. `AccumulatorStatus` enum → ostaje kao što jest (nema kolizije)
4. `AccumulatorsProvider` → ostaje kao što jest (nema kolizije — Provider su u drugom kontekstu)
5. `AccumulatorCard` widget → ostaje kao što jest
6. `AccumulatorBuilderScreen` → ostaje kao što jest

**Fajl rename:**
- `lib/models/accumulator.dart` → `lib/models/bet_accumulator.dart` (novi fajl)
- Stari fajl obrisati (nakon svih import path update-a)

**Alternativa:** Zadržati `accumulator.dart` filename jer drugi identifikatori (AccumulatorLeg, AccumulatorStatus) ostaju — samo klasa unutar nje se preimenuje u `BetAccumulator`. **Ovo je čišće — Claude Code neka ide tim putem.**

### Koraci za Claude Code

1. **U `lib/models/accumulator.dart`:**
   - `class Accumulator` → `class BetAccumulator`
   - `Accumulator({...})` constructor → `BetAccumulator({...})`
   - `Accumulator copyWith(...)` → `BetAccumulator copyWith(...)`
   - `factory Accumulator.fromMap(...)` → `factory BetAccumulator.fromMap(...)`
   - Svi `return Accumulator(...)` → `return BetAccumulator(...)`

2. **U `lib/models/accumulators_provider.dart`:**
   - `List<Accumulator> _accumulators` → `List<BetAccumulator> _accumulators`
   - `Accumulator? _currentDraft` → `BetAccumulator? _currentDraft`
   - Svi ostali referenci na `Accumulator` → `BetAccumulator`
   - **Getter `currentDraft` return type** → `BetAccumulator?`

3. **U `lib/services/storage_service.dart`:**
   - `List<Accumulator> getAllAccumulators()` → `List<BetAccumulator> getAllAccumulators()`
   - `Future<void> saveAccumulator(Accumulator acca)` → `Future<void> saveAccumulator(BetAccumulator acca)`
   - Unutar tijela metoda — sve `Accumulator.fromMap(...)` → `BetAccumulator.fromMap(...)`

4. **U `lib/screens/accumulator_builder_screen.dart`:**
   - Ukloni `hide Accumulator` iz Material import-a: `import 'package:flutter/material.dart';` (back to normal)
   - Sve reference na `Accumulator` tip → `BetAccumulator`

5. **U `lib/widgets/accumulator_card.dart`:**
   - Ukloni `hide Accumulator` iz Material import-a
   - `final Accumulator accumulator;` field → `final BetAccumulator accumulator;`
   - Sve reference → `BetAccumulator`

6. **U `lib/screens/bets_screen.dart`:**
   - Bilo koja eksplicitna `Accumulator` tipizacija → `BetAccumulator`

7. **U `test/widget_test.dart`:**
   - Ako postoji bilo kakav Accumulator-specific test setup, update-ati

**Strategija:** Claude Code neka koristi **global find-and-replace** u IDE ili kroz bash `sed` komandu:
```bash
# Za svaki fajl u lib/ — samo klasu `Accumulator` (ne AccumulatorLeg / AccumulatorStatus / AccumulatorsProvider / AccumulatorCard / AccumulatorBuilderScreen)
# Preciznije: traži "Accumulator" koji NIJE praćen s Leg/Status/s/Card/Builder
```

Regex pattern za pažljivo nalazi: `\bAccumulator\b(?!Leg|Status|s|Card|Builder)`

Ali jednostavnije (i sigurnije) je ručno prolaziti fajl po fajl — nije puno referenci.

### Verifikacija Taska 3

- `flutter analyze` → 0 issues (posebno pazi da nema preostalih referenci na staro ime)
- `flutter test` → 2/2 passed
- `flutter build windows` → uspješan
- **Grep check:** `grep -rn "class Accumulator[^a-zA-Z]" lib/` ne smije vratiti rezultate (samo `class BetAccumulator`). `grep -rn "hide Accumulator" lib/` ne smije vratiti rezultate.

---

## TASK 4 — Final Identified Issues Cleanup + Verification

**Cilj:** Finalno čišćenje WORKLOG-a. Zadnji sanity pass cijelog codebase-a.

### Ažuriraj WORKLOG

U `## Identified Issues` sekciji, nakon svih promjena iz Task 1/2/3, finalna struktura:

```markdown
## Identified Issues

### By-Design (Will Not Fix)

- **Telegram Bot API limitation** *(resolved as by-design in S9)*
  [...full objašnjenje iz Task 1...]

### Resolved in S9

- ~~MatchDetailScreen Charts tab ne pokriva tennis~~ — resolved with TennisInfoPanel (Task 2)
- ~~Material Accumulator name collision~~ — resolved with BetAccumulator rename (Task 3)

*Note: backlog drastično smanjen tijekom projekta. S4 je imao 1 issue, S5.5 ostao 1, S6 dodao 3 (total 4), S7 dodao 6 (total 10), S8 riješio 7 (total 3), S9 riješio 2 i re-klasificirao 1 (total 1 — by-design).*
```

### Finalna sanity provjera

Claude Code neka izvrši sljedeće provjere:

1. **Grep za stare reference:**
   ```bash
   grep -rn "hide Accumulator" lib/
   # Mora biti prazno
   
   grep -rn "class Accumulator[^a-zA-Z_]" lib/
   # Mora biti prazno (samo BetAccumulator)
   ```

2. **Import provjera:**
   ```bash
   grep -rn "package:flutter/material.dart" lib/ | grep -v "hide"
   # Sve importi moraju biti regularni (bez hide klauzula)
   ```

3. **TennisInfoPanel vidljivost:**
   - Otvoriti `lib/screens/match_detail_screen.dart`
   - Potvrditi da `TennisInfoPanel` se imports (`import '../widgets/charts/tennis_info_panel.dart';`)

4. **Version provjera:**
   ```bash
   grep "^version:" pubspec.yaml
   # Mora biti: version: 3.1.1+10
   ```

### Finalna verifikacija Session 9

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK u root: `betsight-v3.1.1.apk`
- Verzija: **`3.1.1+10`** (patch bump)
- Identified Issues: **1** (samo by-design Telegram)
- Git: Claude Code **NE commita/pusha** — developer preuzima

---

## FINALNI WORKLOG UNOS

Na kraju `WORKLOG.md`-a, nakon postojeće Session 8 sekcije, dodaj:

```markdown
---
---

## Session 9: YYYY-MM-DD — Backlog Cleanup + Tennis Minimal + Accumulator Rename

**Kontekst:** S8 je doveo Identified Issues backlog na 3. S9 rješava preostala 2 (tennis charts coverage + Accumulator import collision) i formalno prekvalificira treći (Telegram Bot API) kao by-design. Patch bump na 3.1.1+10 — cleanup + jedan mali feature (TennisInfoPanel). Nakon S9, BetSight ima 0 otvorenih bugova i 1 dokumentirano by-design ograničenje.

---

### Task 1 — Pubspec Bump + Telegram Issue Reclassification
[detalji]

### Task 2 — Tennis Minimal: TennisInfoPanel
[detalji]

### Task 3 — Accumulator → BetAccumulator Rename
[detalji]

### Task 4 — Final Identified Issues Cleanup + Verification
[detalji]

---

### Finalna verifikacija Session 9:
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v3.1.1.apk
- Verzija: 3.1.1+10 (patch bump)
- Identified Issues: 1 (by-design only)
- Git: Claude Code NE commit-a/push-a — developer preuzima
```

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši sažetak:

- Ukupno zadataka izvršeno: 4
- Novih Dart fajlova: **1** (tennis_info_panel)
- Ažuriranih Dart fajlova: [broj, očekivano ~6-8 zbog rename-a]
- Ukupno Dart fajlova u lib/: [novi total, očekivano 64]
- Flutter analyze: 0 issues
- Flutter test: 2/2 passed
- Builds: Windows ✓, Android APK ✓ (betsight-v3.1.1.apk)
- **Version: 3.1.1+10 (patch bump)**
- **Identified Issues: 1 (by-design Telegram only)**
- Sljedeći predloženi korak: **Developer commit-a i push-a S9 na GitHub.** BetSight je sada tehnički u najboljem mogućem stanju — 0 otvorenih bugova, svi relevantni Identified Issues riješeni, 1 formalno označen "will not fix" s obrazloženjem. **Sljedeća sesija S10 planira se isključivo na osnovu real-world feedback-a** nakon instaliranja APK-a. Bez realističnog ciljnog use case-a, daljnje sesije bi bile "grading na slijepo". Preporučuje se: instalirati `betsight-v3.1.1.apk`, konfigurirati API ključeve (Anthropic, Odds API, eventualno Football-Data), proveden 3-7 dana aktivnog korištenja kroz sva tri tier-a (PRE-MATCH / LIVE / ACCUMULATOR), bilježiti u BETLOG.md stvarne ishode Claude preporuka. Nakon toga S10 donosi konkretne prompt calibration, UX fixes, ili moguće nove sportove na osnovu realnih frustracija.

Kraj SESSION 9.
