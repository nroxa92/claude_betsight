# BetSight Test Suite

## Struktura

- `widget_test.dart` — top-level smoke test (Hive init + MultiProvider)
- `helpers/` — test fixtures, mock providers, test utils
- `unit/` — unit testovi za modele, servise, providere (izolirano)
- `widget/` — widget testovi (individualni widgeti)
- `integration/` — integration testovi (end-to-end flows)

## Trenutno stanje (v3.1.3)

Fokus dosadasnjeg razvoja bio je na funkcionalnoj implementaciji. Test suite
trenutno sadrzi samo osnovni smoke test u `widget_test.dart`. Dodatni testovi
su planirani za buduce sesije nakon real-world testiranja.

## Pokretanje

```bash
flutter test
# Trenutno: 2/2 passed (samo widget_test.dart)
```

## TODO (buduce sesije)

- [ ] `unit/` — testovi za OddsApiService, ClaudeService, IntelligenceAggregator,
      parseRecommendationType, OddsDrift.compute, ValuePreset.matches,
      Bet.actualProfit, BetAccumulator.correlationWarnings,
      FootballDataService._tokenize + _matchScore
- [ ] `widget/` — MatchCard, BetCard, TierModeSelector, TradeActionBar,
      BetsFilterBar, AccumulatorBuilderScreen, TennisInfoPanel
- [ ] `integration/` — full user flow (open app → analyze match → log bet → settle),
      cache layer roundtrip, Hive persistence, API service error paths (401/429/timeout)

## Helpers placeholder

`helpers/` je placeholder za buduce shared test utils — mock HTTP clients,
fixture data, provider builder helpers. Trenutno prazno.
