import 'package:betsight/models/intelligence_provider.dart';
import 'package:betsight/models/intelligence_report.dart';
import 'package:betsight/models/match.dart';
import 'package:betsight/models/source_score.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  Match buildMatch({String id = 'm-1'}) => Match(
        id: id,
        sport: Sport.soccer,
        league: 'EPL',
        sportKey: 'soccer_epl',
        home: 'A',
        away: 'B',
        commenceTime: DateTime(2026, 5, 1),
        h2h: null,
      );

  IntelligenceReport fakeReport(String matchId,
          {double score = 3.0, DateTime? generatedAt}) =>
      IntelligenceReport(
        matchId: matchId,
        sources: [
          SourceScore(
            source: SourceType.odds,
            score: score,
            reasoning: 'r',
            isActive: true,
          ),
        ],
        generatedAt: generatedAt ?? DateTime.now(),
      );

  group('initialization', () {
    test('loads persisted reports into memory', () async {
      await StorageService.saveReport(fakeReport('m-1', score: 2.0));
      await StorageService.saveReport(fakeReport('m-2', score: 4.0));
      final p = IntelligenceProvider();
      expect(p.reportFor('m-1')!.confluenceScore, 2.0);
      expect(p.reportFor('m-2')!.confluenceScore, 4.0);
    });

    test('allReports sorted DESC by confluenceScore', () async {
      await StorageService.saveReport(fakeReport('low', score: 1.0));
      await StorageService.saveReport(fakeReport('high', score: 4.0));
      final p = IntelligenceProvider();
      expect(p.allReports.first.matchId, 'high');
    });
  });

  group('generateReport without aggregator', () {
    test('surfaces configuration error', () async {
      final p = IntelligenceProvider();
      await p.generateReport(buildMatch());
      expect(p.error, contains('not configured'));
    });

    test('clearError resets error', () async {
      final p = IntelligenceProvider();
      await p.generateReport(buildMatch());
      p.clearError();
      expect(p.error, isNull);
    });
  });

  group('cache hit skips generation', () {
    test('fresh report returns immediately (no error set)', () async {
      await StorageService.saveReport(fakeReport('cached', score: 3.0));
      final p = IntelligenceProvider();
      await p.generateReport(buildMatch(id: 'cached'));
      expect(p.error, isNull);
      expect(p.reportFor('cached'), isNotNull);
    });

    test('expired report triggers generation attempt (aggregator null error)',
        () async {
      await StorageService.saveReport(
        fakeReport('expired',
            score: 3.0,
            generatedAt: DateTime.now().subtract(const Duration(hours: 2))),
      );
      final p = IntelligenceProvider();
      await p.generateReport(buildMatch(id: 'expired'));
      expect(p.error, contains('not configured'));
    });
  });

  group('updateFootballDataApiKey', () {
    test('with null/empty just notifies', () {
      final p = IntelligenceProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.updateFootballDataApiKey(null);
      p.updateFootballDataApiKey('');
      expect(notified, 2);
    });
  });

  group('removeReportFor', () {
    test('deletes from memory + storage', () async {
      await StorageService.saveReport(fakeReport('m-1'));
      final p = IntelligenceProvider();
      await p.removeReportFor('m-1');
      expect(p.reportFor('m-1'), isNull);
      expect(StorageService.getReport('m-1'), isNull);
    });
  });

  group('isGeneratingFor', () {
    test('false by default', () {
      final p = IntelligenceProvider();
      expect(p.isGeneratingFor('m-1'), isFalse);
    });
  });
}
