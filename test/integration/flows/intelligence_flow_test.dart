import 'package:betsight/models/intelligence_provider.dart';
import 'package:betsight/models/match.dart';
import 'package:betsight/models/odds.dart';
import 'package:betsight/models/odds_snapshot.dart';
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

  Match match({String id = 'm-1'}) => Match(
        id: id,
        sport: Sport.soccer,
        league: 'EPL',
        sportKey: 'soccer_epl',
        home: 'Arsenal',
        away: 'Liverpool',
        commenceTime: DateTime(2026, 5, 1),
        h2h: H2HOdds(
          home: 1.95,
          away: 1.95,
          lastUpdate: DateTime(2026, 4, 18),
          bookmaker: 'T',
        ),
      );

  test('wireAggregator → generateReport → persist → reload', () async {
    final p = IntelligenceProvider();
    final agg = IntelligenceAggregator(
      footballService: null,
      nbaService: null,
      redditMonitor: null,
      telegramProvider: emptyTg(),
    );
    p.wireAggregator(agg);

    // Pre-seed drift snapshots so Odds source scores high (sharp + drift).
    await StorageService.saveSnapshot(OddsSnapshot(
      matchId: 'm-1',
      capturedAt: DateTime(2026, 4, 18, 10),
      home: 2.0,
      away: 2.0,
      bookmaker: 'T',
    ));
    await StorageService.saveSnapshot(OddsSnapshot(
      matchId: 'm-1',
      capturedAt: DateTime(2026, 4, 18, 12),
      home: 1.85,
      away: 2.15,
      bookmaker: 'T',
    ));

    await p.generateReport(match());
    final report = p.reportFor('m-1');
    expect(report, isNotNull);
    expect(report!.sources.length, 5);
    expect(report.confluenceScore, greaterThan(0));

    // Persisted across provider reconstruction
    final p2 = IntelligenceProvider();
    expect(p2.reportFor('m-1'), isNotNull);
  });

  test('generateReport without wiring surfaces config error', () async {
    final p = IntelligenceProvider();
    await p.generateReport(match());
    expect(p.error, contains('not configured'));
  });

  test('removeReportFor cleans in-memory and storage', () async {
    final agg = IntelligenceAggregator(
      footballService: null,
      nbaService: null,
      redditMonitor: null,
      telegramProvider: emptyTg(),
    );
    final p = IntelligenceProvider();
    p.wireAggregator(agg);
    await p.generateReport(match());
    expect(p.reportFor('m-1'), isNotNull);
    await p.removeReportFor('m-1');
    expect(p.reportFor('m-1'), isNull);
    expect(StorageService.getReport('m-1'), isNull);
  });
}

