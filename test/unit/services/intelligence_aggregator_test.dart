import 'package:betsight/models/match.dart';
import 'package:betsight/models/odds.dart';
import 'package:betsight/models/odds_snapshot.dart';
import 'package:betsight/models/source_score.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/models/telegram_provider.dart';
import 'package:betsight/services/intelligence_aggregator.dart';
import 'package:betsight/services/storage_service.dart';
import 'package:betsight/services/telegram_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  TelegramProvider emptyTg() => TelegramProvider(
        monitor: TelegramMonitor(
          client: MockClient((_) async => http.Response('', 200)),
        ),
      );

  Match match({
    String id = 'm-1',
    Sport sport = Sport.soccer,
    H2HOdds? h2h,
    String home = 'A',
    String away = 'B',
  }) =>
      Match(
        id: id,
        sport: sport,
        league: 'EPL',
        sportKey: sport == Sport.basketball ? 'basketball_nba' : 'soccer_epl',
        home: home,
        away: away,
        commenceTime: DateTime(2026, 5, 1),
        h2h: h2h,
      );

  group('Odds source scoring', () {
    test('inactive when no h2h data', () async {
      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final report = await agg.buildReport(match());
      final oddsScore = report.sources.firstWhere((s) => s.source == SourceType.odds);
      expect(oddsScore.isActive, isFalse);
    });

    test('base 0.5 for having h2h, + 0.5 for sharp margin < 5%', () async {
      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final m = match(
        h2h: H2HOdds(
          home: 1.95,
          away: 1.95,
          lastUpdate: DateTime(2026, 4, 18),
          bookmaker: 'T',
        ),
      );
      final report = await agg.buildReport(m);
      final oddsScore = report.sources.firstWhere((s) => s.source == SourceType.odds);
      expect(oddsScore.isActive, isTrue);
      expect(oddsScore.score, 1.0); // base 0.5 + sharp 0.5
      expect(oddsScore.reasoning, contains('sharp book'));
    });

    test('soft book (>5% margin) gets only base 0.5', () async {
      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final m = match(
        h2h: H2HOdds(
          home: 1.80,
          away: 1.80,
          lastUpdate: DateTime(2026, 4, 18),
          bookmaker: 'T',
        ),
      );
      final report = await agg.buildReport(m);
      final oddsScore = report.sources.firstWhere((s) => s.source == SourceType.odds);
      expect(oddsScore.score, 0.5);
      expect(oddsScore.reasoning, isNot(contains('sharp book')));
    });

    test('+0.5 for significant drift, +0.5 more for non-Home direction',
        () async {
      // Save 2 snapshots with Away moving significantly (not Home)
      await StorageService.saveSnapshot(OddsSnapshot(
        matchId: 'drift-m',
        capturedAt: DateTime(2026, 4, 18, 10),
        home: 2.0,
        away: 2.0,
        bookmaker: 'T',
      ));
      await StorageService.saveSnapshot(OddsSnapshot(
        matchId: 'drift-m',
        capturedAt: DateTime(2026, 4, 18, 12),
        home: 2.0,
        away: 1.8,
        bookmaker: 'T',
      ));

      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final m = match(
        id: 'drift-m',
        h2h: H2HOdds(
          home: 2.0,
          away: 1.8,
          lastUpdate: DateTime(2026, 4, 18),
          bookmaker: 'T',
        ),
      );
      final report = await agg.buildReport(m);
      final oddsScore = report.sources.firstWhere((s) => s.source == SourceType.odds);
      expect(oddsScore.score, greaterThan(0.5));
      expect(oddsScore.reasoning, contains('drift'));
      expect(oddsScore.reasoning, contains('non-favourite'));
    });
  });

  group('Football-Data source', () {
    test('inactive when no service', () async {
      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final report = await agg.buildReport(match());
      final s = report.sources.firstWhere((x) => x.source == SourceType.footballData);
      expect(s.isActive, isFalse);
      expect(s.reasoning, contains('No API key'));
    });

    test('inactive for non-soccer match', () async {
      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final m = match(id: 'nba-1', sport: Sport.basketball);
      final report = await agg.buildReport(m);
      final s = report.sources.firstWhere((x) => x.source == SourceType.footballData);
      expect(s.isActive, isFalse);
    });
  });

  group('NBA source', () {
    test('inactive when no nbaService', () async {
      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final report = await agg.buildReport(match());
      final s = report.sources.firstWhere((x) => x.source == SourceType.nbaStats);
      expect(s.isActive, isFalse);
    });
  });

  group('Reddit source', () {
    test('inactive when no redditMonitor', () async {
      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final report = await agg.buildReport(match());
      final s = report.sources.firstWhere((x) => x.source == SourceType.reddit);
      expect(s.isActive, isFalse);
    });
  });

  group('Telegram source', () {
    test('inactive when no signals', () async {
      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final report = await agg.buildReport(match());
      final s = report.sources.firstWhere((x) => x.source == SourceType.telegram);
      expect(s.isActive, isFalse);
      expect(s.reasoning, contains('No signals'));
    });
  });

  group('Report assembly', () {
    test('report contains all 5 source entries', () async {
      final agg = IntelligenceAggregator(
        footballService: null,
        nbaService: null,
        redditMonitor: null,
        telegramProvider: emptyTg(),
      );
      final report = await agg.buildReport(match());
      expect(report.sources, hasLength(5));
      expect(report.sources.map((s) => s.source).toSet(),
          SourceType.values.toSet());
    });
  });
}
