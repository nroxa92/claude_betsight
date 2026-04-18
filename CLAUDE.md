# BetSight — Claude Code Instructions

## Identitet
BetSight je AI-powered sports betting intelligence platforma. Flutter/Dart,
Provider state management, Hive lokalna pohrana. Verzija 3.1.3.

## Pravila rada
- Ako Claude Code primijeti bug koji nije dio zadatka koji rješava, dodaje ga pod
  sekciju Identified Issues u WORKLOG.md ali ga ne popravlja bez pitanja.
- Ne refaktoriraš ono što radi. Ne mijenjaš arhitekturu bez zahtjeva.
- `flutter analyze` mora biti 0 issues nakon svake promjene.
- API ključevi se nikad ne hardkodiraju u source — samo kroz Settings -> Hive storage.

## Arhitektura (lib/)
- `models/` — Match, H2HOdds, Bet, Bankroll, BetAccumulator, AccumulatorLeg,
  AccumulatorStatus, TipsterSignal, MonitoredChannel, OddsSnapshot, OddsDrift,
  CachedMatchesEntry, AnalysisLog, Recommendation (WATCH/SKIP/VALUE parser),
  UserFeedback, ValuePreset, InvestmentTier, Sport, MatchNote, SourceScore,
  FootballDataSignal, NbaStatsSignal, RedditSignal, IntelligenceReport, SportPl,
  NavigationController, MatchesProvider, AnalysisProvider, BetsProvider,
  TelegramProvider, IntelligenceProvider, AccumulatorsProvider, TierProvider
- `services/` — OddsApiService, ClaudeService, StorageService, TelegramMonitor,
  FootballDataService, BallDontLieService, RedditMonitor, IntelligenceAggregator,
  NotificationsService
- `screens/` — MatchesScreen, AnalysisScreen, BetsScreen, SettingsScreen
  (4 main tab-a), BotManagerScreen, IntelligenceDashboardScreen, MatchDetailScreen
  (4 taba: Overview/Intelligence/Charts/Notes), AccumulatorBuilderScreen
- `widgets/` — MatchCard, ChatBubble, OddsWidget, SignalCard, BetCard,
  BetEntrySheet, PlSummaryWidget, AccumulatorCard, TradeActionBar,
  TierModeSelector, SportSelector, BetsFilterBar, charts/OddsMovementChart,
  charts/FormChart, charts/EquityCurveChart, charts/TennisInfoPanel
- `theme/` — AppTheme (dark, primary #6C63FF, secondary #03DAC6, surface #1E1E1E)

## API integracije
- **Anthropic Claude** — claude-sonnet-4, 30s timeout, engleski system prompt
  s tier-specific context appendix-om
- **The Odds API** — besplatni tier (500 req/mj), 15-min cache, rate limit tracking
- **Football-Data.org** — besplatni tier (10 req/min, neograničen mjesečno),
  soccer form + H2H + standings za EPL/CL
- **BallDontLie.io** — besplatan bez API ključa, NBA last 10 + rest days
- **Reddit public JSON** — 60 req/h neauth, r/sportsbook/r/soccer/r/NBA/r/tennis
- **Telegram Bot API** — TelegramMonitor čita samo iz kanala gdje je bot član
  (by-design ograničenje, MTProto neće biti implementiran)

## Hive boxovi
settings, analysis_logs, bets, tipster_signals, odds_snapshots, odds_cache,
monitored_channels_detail, intelligence_reports, football_signals_cache,
nba_signals_cache, reddit_signals_cache, accumulators, match_notes

## Providers (state management)
TierProvider, NavigationController, MatchesProvider, AnalysisProvider,
BetsProvider, TelegramProvider, IntelligenceProvider, AccumulatorsProvider

## Intelligence Layer (v2.0.0+)
5 izvora, confluence score 0-6.0, kategorije STRONG_VALUE (≥4.5) /
POSSIBLE_VALUE (≥3.0) / WEAK_SIGNAL (≥1.5) / LIKELY_SKIP (<1.5) /
INSUFFICIENT_DATA (<2 aktivna izvora). Weight mapping:
- Odds 0-2.0 (primary — dominira analizu)
- Football-Data 0-1.5 (strong secondary — forma/H2H)
- BallDontLie NBA 0-1.0
- Reddit 0-1.0
- Telegram 0-0.5 (weighted by MonitoredChannel.reliabilityLabel)

## Three-Tier Framework (v3.0.0+)
Tier-aware cijela app. TierModeSelector iznad IndexedStack-a.
- **PRE-MATCH** — 24-48h horizon, deep DYOR, default tier
- **LIVE** — in-play, momentum reads, LIVE bet-ovi filtrirani po matchStartedAt
- **ACCUMULATOR** — multi-match build, correlation warnings, combined odds

## Redoslijed implementacije
Implementacija ide fazno i svaka faza mora biti funkcionalna prije prelaska
na sljedeću. Unutar faze redoslijed je: pubspec dependencies → model →
service → provider → widget → screen.

Claude Code prolazi sve faze autonomno, bez čekanja developerove potvrde.
Nakon svake faze pokreće `flutter analyze` (mora biti 0 issues) i
`flutter build apk --debug` (nakon S10.5 — prije je bio `flutter build windows`
dok su postojali platformski direktoriji), te piše WORKLOG unos s popisom
Kreirani / Ažurirani fajlovi i Verifikacija.

## WORKLOG format
Svaka sesija ima sekciju u WORKLOG.md s fazama, promijenjenim fajlovima
i verifikacijom (analyze + test + build).

## Git workflow
Claude Code NE radi git commit ni git push. Developer preuzima.
Izuzetak: S10.5 HYGIENE sesija koristi `git rm --cached` i `git rm -rf`
za cleanup SESSION_*.md fajlova i platformskih direktorija — ovo su priprema
za commit koji developer radi sam.
