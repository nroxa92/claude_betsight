import 'package:betsight/models/accumulator.dart';
import 'package:betsight/models/analysis_log.dart';
import 'package:betsight/models/bet.dart';
import 'package:betsight/models/cached_matches_entry.dart';
import 'package:betsight/models/football_data_signal.dart';
import 'package:betsight/models/intelligence_report.dart';
import 'package:betsight/models/match.dart';
import 'package:betsight/models/match_note.dart';
import 'package:betsight/models/monitored_channel.dart';
import 'package:betsight/models/nba_stats_signal.dart';
import 'package:betsight/models/odds.dart';
import 'package:betsight/models/odds_snapshot.dart';
import 'package:betsight/models/recommendation.dart';
import 'package:betsight/models/reddit_signal.dart';
import 'package:betsight/models/source_score.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/models/tipster_signal.dart';
import 'package:betsight/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  group('API key storage', () {
    test('anthropic key save/get/delete', () async {
      expect(StorageService.getAnthropicApiKey(), isNull);
      await StorageService.saveAnthropicApiKey('sk-ant-xxx');
      expect(StorageService.getAnthropicApiKey(), 'sk-ant-xxx');
      await StorageService.deleteAnthropicApiKey();
      expect(StorageService.getAnthropicApiKey(), isNull);
    });
    test('odds key save/get/delete', () async {
      await StorageService.saveOddsApiKey('odds-key');
      expect(StorageService.getOddsApiKey(), 'odds-key');
      await StorageService.deleteOddsApiKey();
      expect(StorageService.getOddsApiKey(), isNull);
    });
    test('football-data key save/get/delete', () async {
      await StorageService.saveFootballDataApiKey('fd-key');
      expect(StorageService.getFootballDataApiKey(), 'fd-key');
      await StorageService.deleteFootballDataApiKey();
      expect(StorageService.getFootballDataApiKey(), isNull);
    });
    test('telegram token save/get/delete', () async {
      await StorageService.saveTelegramToken('tg-token');
      expect(StorageService.getTelegramToken(), 'tg-token');
      await StorageService.deleteTelegramToken();
      expect(StorageService.getTelegramToken(), isNull);
    });
  });

  group('Value preset / tier / notifications', () {
    test('value preset roundtrip', () async {
      expect(StorageService.getValuePreset(), isNull);
      await StorageService.saveValuePreset('aggressive');
      expect(StorageService.getValuePreset(), 'aggressive');
    });
    test('current tier roundtrip', () async {
      expect(StorageService.getCurrentTier(), isNull);
      await StorageService.saveCurrentTier('live');
      expect(StorageService.getCurrentTier(), 'live');
    });
    test('notification flags default to true', () {
      expect(StorageService.getNotifKickoffEnabled(), isTrue);
      expect(StorageService.getNotifDriftEnabled(), isTrue);
      expect(StorageService.getNotifValueEnabled(), isTrue);
    });
    test('notification flags roundtrip', () async {
      await StorageService.saveNotifKickoffEnabled(false);
      await StorageService.saveNotifDriftEnabled(false);
      await StorageService.saveNotifValueEnabled(false);
      expect(StorageService.getNotifKickoffEnabled(), isFalse);
      expect(StorageService.getNotifDriftEnabled(), isFalse);
      expect(StorageService.getNotifValueEnabled(), isFalse);
    });
    test('telegram enabled defaults false', () {
      expect(StorageService.getTelegramEnabled(), isFalse);
    });
    test('telegram enabled roundtrip', () async {
      await StorageService.saveTelegramEnabled(true);
      expect(StorageService.getTelegramEnabled(), isTrue);
    });
  });

  group('Bets storage', () {
    Bet makeBet(String id) => Bet(
          id: id,
          sport: Sport.soccer,
          league: 'EPL',
          home: 'A',
          away: 'B',
          selection: BetSelection.home,
          odds: 2.0,
          stake: 10,
          placedAt: DateTime(2026, 4, 18),
          status: BetStatus.pending,
        );

    test('empty list initially', () {
      expect(StorageService.getAllBets(), isEmpty);
    });
    test('save + retrieve', () async {
      await StorageService.saveBet(makeBet('b-1'));
      await StorageService.saveBet(makeBet('b-2'));
      final all = StorageService.getAllBets();
      expect(all, hasLength(2));
      expect(all.map((b) => b.id).toSet(), {'b-1', 'b-2'});
    });
    test('save idempotent by id', () async {
      await StorageService.saveBet(makeBet('b-1'));
      await StorageService.saveBet(makeBet('b-1'));
      expect(StorageService.getAllBets(), hasLength(1));
    });
    test('delete removes bet', () async {
      await StorageService.saveBet(makeBet('b-1'));
      await StorageService.deleteBet('b-1');
      expect(StorageService.getAllBets(), isEmpty);
    });
  });

  group('Analysis logs', () {
    AnalysisLog makeLog(String id, {RecommendationType rec = RecommendationType.value}) =>
        AnalysisLog(
          id: id,
          timestamp: DateTime(2026, 4, 18).add(Duration(minutes: id.hashCode)),
          userMessage: 'u',
          assistantResponse: 'a',
          contextMatchIds: const [],
          recommendationType: rec,
        );

    test('empty initially', () {
      expect(StorageService.getAllAnalysisLogs(), isEmpty);
    });
    test('save + retrieve in DESC timestamp order', () async {
      final older = AnalysisLog(
        id: 'log-old',
        timestamp: DateTime(2026, 4, 17),
        userMessage: 'u',
        assistantResponse: 'a',
        contextMatchIds: const [],
        recommendationType: RecommendationType.none,
      );
      final newer = AnalysisLog(
        id: 'log-new',
        timestamp: DateTime(2026, 4, 18),
        userMessage: 'u',
        assistantResponse: 'a',
        contextMatchIds: const [],
        recommendationType: RecommendationType.value,
      );
      await StorageService.saveAnalysisLog(older);
      await StorageService.saveAnalysisLog(newer);
      final all = StorageService.getAllAnalysisLogs();
      expect(all.first.id, 'log-new');
      expect(all.last.id, 'log-old');
    });
    test('delete one log', () async {
      await StorageService.saveAnalysisLog(makeLog('l-1'));
      await StorageService.saveAnalysisLog(makeLog('l-2'));
      await StorageService.deleteAnalysisLog('l-1');
      expect(StorageService.getAllAnalysisLogs(), hasLength(1));
    });
    test('clearAllAnalysisLogs empties box', () async {
      await StorageService.saveAnalysisLog(makeLog('l-1'));
      await StorageService.saveAnalysisLog(makeLog('l-2'));
      await StorageService.clearAllAnalysisLogs();
      expect(StorageService.getAllAnalysisLogs(), isEmpty);
    });
    test('updateAnalysisLogFeedback sets feedback + feedbackAt', () async {
      await StorageService.saveAnalysisLog(makeLog('l-1'));
      await StorageService.updateAnalysisLogFeedback('l-1', UserFeedback.logged);
      final log = StorageService.getAllAnalysisLogs().first;
      expect(log.userFeedback, UserFeedback.logged);
      expect(log.feedbackAt, isNotNull);
    });
    test('updateAnalysisLogFeedback missing id is no-op', () async {
      await StorageService.updateAnalysisLogFeedback('ghost', UserFeedback.logged);
      expect(StorageService.getAllAnalysisLogs(), isEmpty);
    });
    test('getLogsByRecommendation filters correctly', () async {
      await StorageService.saveAnalysisLog(makeLog('l-1', rec: RecommendationType.value));
      await StorageService.saveAnalysisLog(makeLog('l-2', rec: RecommendationType.skip));
      final values = StorageService.getLogsByRecommendation(RecommendationType.value);
      expect(values, hasLength(1));
      expect(values.first.id, 'l-1');
    });
    test('getFeedbackStats aggregates per recommendation+feedback', () async {
      await StorageService.saveAnalysisLog(makeLog('l-1', rec: RecommendationType.value));
      await StorageService.updateAnalysisLogFeedback('l-1', UserFeedback.logged);
      await StorageService.saveAnalysisLog(makeLog('l-2', rec: RecommendationType.skip));
      final stats = StorageService.getFeedbackStats();
      expect(stats[RecommendationType.value]![UserFeedback.logged], 1);
      expect(stats[RecommendationType.skip]![UserFeedback.none], 1);
    });
  });

  group('Bankroll config', () {
    test('null initially', () {
      expect(StorageService.getBankrollConfig(), isNull);
    });
    test('save + retrieve config map', () async {
      await StorageService.saveBankrollConfig({
        'totalBankroll': 1000.0,
        'defaultStakeUnit': 20.0,
        'currency': 'EUR',
      });
      final c = StorageService.getBankrollConfig();
      expect(c!['totalBankroll'], 1000.0);
      expect(c['currency'], 'EUR');
    });
  });

  group('Monitored channels', () {
    test('legacy list: empty + roundtrip', () async {
      expect(StorageService.getMonitoredChannels(), isEmpty);
      await StorageService.saveMonitoredChannels(['@a', '@b']);
      expect(StorageService.getMonitoredChannels(), ['@a', '@b']);
    });
    test('detailed channels empty initially', () {
      expect(StorageService.getAllMonitoredChannels(), isEmpty);
    });
    test('save + get + delete monitored channel', () async {
      final c = MonitoredChannel(
        username: '@tipster',
        addedAt: DateTime(2026, 4, 1),
      );
      await StorageService.saveMonitoredChannel(c);
      final all = StorageService.getAllMonitoredChannels();
      expect(all, hasLength(1));
      expect(all.first.username, '@tipster');
      await StorageService.deleteMonitoredChannel('@tipster');
      expect(StorageService.getAllMonitoredChannels(), isEmpty);
    });
    test('getAllMonitoredChannels sorted ASC by addedAt', () async {
      await StorageService.saveMonitoredChannel(MonitoredChannel(
        username: '@late',
        addedAt: DateTime(2026, 4, 2),
      ));
      await StorageService.saveMonitoredChannel(MonitoredChannel(
        username: '@early',
        addedAt: DateTime(2026, 4, 1),
      ));
      final all = StorageService.getAllMonitoredChannels();
      expect(all.first.username, '@early');
    });

    test('migrateMonitoredChannels moves legacy list into detail box', () async {
      await StorageService.saveMonitoredChannels(['@legacy1', '@legacy2']);
      await StorageService.migrateMonitoredChannels();
      final all = StorageService.getAllMonitoredChannels();
      expect(all, hasLength(2));
      expect(all.map((c) => c.username).toSet(), {'@legacy1', '@legacy2'});
    });
    test('migrateMonitoredChannels no-op when detail box non-empty', () async {
      await StorageService.saveMonitoredChannel(MonitoredChannel(
        username: '@existing',
        addedAt: DateTime(2026, 4, 1),
      ));
      await StorageService.saveMonitoredChannels(['@legacy']);
      await StorageService.migrateMonitoredChannels();
      expect(StorageService.getAllMonitoredChannels(), hasLength(1));
    });
  });

  group('Tipster signals', () {
    TipsterSignal makeSignal(String id, {DateTime? at}) => TipsterSignal(
          id: id,
          telegramMessageId: 1,
          channelUsername: '@ch',
          channelTitle: 'c',
          text: 't',
          receivedAt: at ?? DateTime(2026, 4, 18),
          isRelevant: true,
        );

    test('empty initially', () {
      expect(StorageService.getAllSignals(), isEmpty);
    });
    test('save + get in DESC receivedAt', () async {
      await StorageService.saveSignal(
        makeSignal('s-1', at: DateTime(2026, 4, 10)),
      );
      await StorageService.saveSignal(
        makeSignal('s-2', at: DateTime(2026, 4, 18)),
      );
      final all = StorageService.getAllSignals();
      expect(all.first.id, 's-2');
    });
    test('clearOldSignals removes signals older than keepFor', () async {
      await StorageService.saveSignal(
        makeSignal('old', at: DateTime.now().subtract(const Duration(days: 10))),
      );
      await StorageService.saveSignal(
        makeSignal('new', at: DateTime.now().subtract(const Duration(days: 1))),
      );
      final count = await StorageService.clearOldSignals(
        keepFor: const Duration(days: 7),
      );
      expect(count, 1);
      final all = StorageService.getAllSignals();
      expect(all, hasLength(1));
      expect(all.first.id, 'new');
    });
  });

  group('Accumulators', () {
    BetAccumulator makeAcc(String id, {DateTime? createdAt}) => BetAccumulator(
          id: id,
          legs: [],
          stake: 10,
          status: AccumulatorStatus.building,
          createdAt: createdAt ?? DateTime(2026, 4, 18),
        );

    test('empty initially', () {
      expect(StorageService.getAllAccumulators(), isEmpty);
    });
    test('save + get sorted DESC by createdAt', () async {
      await StorageService.saveAccumulator(
        makeAcc('old', createdAt: DateTime(2026, 4, 1)),
      );
      await StorageService.saveAccumulator(
        makeAcc('new', createdAt: DateTime(2026, 4, 18)),
      );
      final all = StorageService.getAllAccumulators();
      expect(all.first.id, 'new');
    });
    test('delete accumulator', () async {
      await StorageService.saveAccumulator(makeAcc('a-1'));
      await StorageService.deleteAccumulator('a-1');
      expect(StorageService.getAllAccumulators(), isEmpty);
    });
  });

  group('Match notes', () {
    test('missing note returns null', () {
      expect(StorageService.getMatchNote('missing'), isNull);
    });
    test('save + get + delete', () async {
      final note = MatchNote(
        matchId: 'm-1',
        text: 'injury',
        updatedAt: DateTime(2026, 4, 18),
      );
      await StorageService.saveMatchNote(note);
      expect(StorageService.getMatchNote('m-1')!.text, 'injury');
      await StorageService.deleteMatchNote('m-1');
      expect(StorageService.getMatchNote('m-1'), isNull);
    });
  });

  group('Intelligence reports', () {
    IntelligenceReport makeReport(String matchId, double score,
            {DateTime? generatedAt}) =>
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

    test('missing report null', () {
      expect(StorageService.getReport('missing'), isNull);
    });
    test('save + retrieve', () async {
      await StorageService.saveReport(makeReport('m-1', 2.0));
      expect(StorageService.getReport('m-1')!.confluenceScore, 2.0);
    });
    test('getAllReports sorted DESC by confluenceScore', () async {
      await StorageService.saveReport(makeReport('m-low', 0.5));
      await StorageService.saveReport(makeReport('m-high', 2.0));
      final all = StorageService.getAllReports();
      expect(all.first.matchId, 'm-high');
      expect(all.last.matchId, 'm-low');
    });
    test('delete report', () async {
      await StorageService.saveReport(makeReport('m-1', 1.0));
      await StorageService.deleteReport('m-1');
      expect(StorageService.getReport('m-1'), isNull);
    });
    test('clearOldReports removes stale', () async {
      await StorageService.saveReport(makeReport('stale', 1.0,
          generatedAt: DateTime.now().subtract(const Duration(hours: 10))));
      await StorageService.saveReport(makeReport('fresh', 2.0,
          generatedAt: DateTime.now()));
      final n = await StorageService.clearOldReports(
          keepFor: const Duration(hours: 6));
      expect(n, 1);
      expect(StorageService.getReport('stale'), isNull);
      expect(StorageService.getReport('fresh'), isNotNull);
    });
  });

  group('Source signal caches', () {
    FootballDataSignal makeFd(String matchId, {DateTime? at}) =>
        FootballDataSignal(
          matchId: matchId,
          homeTeam: 'H',
          awayTeam: 'A',
          competition: 'EPL',
          homeFormLast5: const ['W'],
          awayFormLast5: const ['L'],
          h2hHomeWins: 1,
          h2hDraws: 0,
          h2hAwayWins: 0,
          fetchedAt: at ?? DateTime.now(),
        );

    NbaStatsSignal makeNba(String matchId, {DateTime? at}) => NbaStatsSignal(
          matchId: matchId,
          homeTeam: 'H',
          awayTeam: 'A',
          homeLast10: const ['W'],
          awayLast10: const ['L'],
          fetchedAt: at ?? DateTime.now(),
        );

    RedditSignal makeReddit(String matchId, {DateTime? at}) => RedditSignal(
          matchId: matchId,
          mentionCount: 5,
          topUpvotes: 100,
          teamMentions: const {'H': 3, 'A': 2},
          fetchedAt: at ?? DateTime.now(),
        );

    test('football signal save/get/null', () async {
      expect(StorageService.getFootballSignal('m'), isNull);
      await StorageService.saveFootballSignal(makeFd('m'));
      expect(StorageService.getFootballSignal('m')!.matchId, 'm');
    });
    test('nba signal save/get/null', () async {
      expect(StorageService.getNbaSignal('m'), isNull);
      await StorageService.saveNbaSignal(makeNba('m'));
      expect(StorageService.getNbaSignal('m')!.matchId, 'm');
    });
    test('reddit signal save/get/null', () async {
      expect(StorageService.getRedditSignal('m'), isNull);
      await StorageService.saveRedditSignal(makeReddit('m'));
      expect(StorageService.getRedditSignal('m')!.matchId, 'm');
    });
  });

  group('Odds snapshots', () {
    OddsSnapshot snap(String matchId, DateTime at, double home) => OddsSnapshot(
          matchId: matchId,
          capturedAt: at,
          home: home,
          away: 2.0,
          bookmaker: 'Test',
        );

    test('empty initially', () {
      expect(StorageService.getSnapshotsForMatch('m'), isEmpty);
      expect(StorageService.getLatestSnapshotForMatch('m'), isNull);
    });

    test('saveSnapshot + getSnapshotsForMatch returns ASC by capturedAt', () async {
      await StorageService.saveSnapshot(snap('m-1', DateTime(2026, 4, 18, 10), 2.0));
      await StorageService.saveSnapshot(snap('m-1', DateTime(2026, 4, 18, 11), 1.9));
      final all = StorageService.getSnapshotsForMatch('m-1');
      expect(all, hasLength(2));
      expect(all.first.capturedAt.hour, 10);
      expect(all.last.capturedAt.hour, 11);
    });

    test('getSnapshotsForMatch returns only matching matchId', () async {
      await StorageService.saveSnapshot(snap('m-1', DateTime(2026, 4, 18, 10), 2.0));
      await StorageService.saveSnapshot(snap('m-2', DateTime(2026, 4, 18, 10), 2.0));
      expect(StorageService.getSnapshotsForMatch('m-1'), hasLength(1));
    });

    test('getLatestSnapshotForMatch returns newest', () async {
      await StorageService.saveSnapshot(snap('m-1', DateTime(2026, 4, 18, 10), 2.0));
      await StorageService.saveSnapshot(snap('m-1', DateTime(2026, 4, 18, 12), 1.85));
      final latest = StorageService.getLatestSnapshotForMatch('m-1');
      expect(latest!.home, 1.85);
    });

    test('saveSnapshotIfChanged saves on first snapshot', () async {
      final saved = await StorageService.saveSnapshotIfChanged(
        snap('m-1', DateTime(2026, 4, 18, 10), 2.0),
      );
      expect(saved, isTrue);
      expect(StorageService.getSnapshotsForMatch('m-1'), hasLength(1));
    });

    test('saveSnapshotIfChanged skips identical odds', () async {
      final s1 = snap('m-1', DateTime(2026, 4, 18, 10), 2.0);
      await StorageService.saveSnapshotIfChanged(s1);
      final same = snap('m-1', DateTime(2026, 4, 18, 11), 2.0);
      final saved = await StorageService.saveSnapshotIfChanged(same);
      expect(saved, isFalse);
      expect(StorageService.getSnapshotsForMatch('m-1'), hasLength(1));
    });

    test('saveSnapshotIfChanged saves when odds differ', () async {
      await StorageService.saveSnapshotIfChanged(
        snap('m-1', DateTime(2026, 4, 18, 10), 2.0),
      );
      final changed = await StorageService.saveSnapshotIfChanged(
        snap('m-1', DateTime(2026, 4, 18, 11), 1.9),
      );
      expect(changed, isTrue);
      expect(StorageService.getSnapshotsForMatch('m-1'), hasLength(2));
    });

    test('clearOldSnapshots removes stale', () async {
      await StorageService.saveSnapshot(
        snap('m-1', DateTime.now().subtract(const Duration(days: 10)), 2.0),
      );
      await StorageService.saveSnapshot(
        snap('m-1', DateTime.now(), 2.0),
      );
      final n = await StorageService.clearOldSnapshots(keepFor: const Duration(days: 7));
      expect(n, 1);
      expect(StorageService.getSnapshotsForMatch('m-1'), hasLength(1));
    });
  });

  group('Watched match ids', () {
    test('empty initially', () {
      expect(StorageService.getWatchedMatchIds(), isEmpty);
    });
    test('save + get roundtrip', () async {
      await StorageService.saveWatchedMatchIds({'m-1', 'm-2'});
      expect(StorageService.getWatchedMatchIds(), {'m-1', 'm-2'});
    });
  });

  group('Cached matches', () {
    CachedMatchesEntry makeEntry() => CachedMatchesEntry(
          matches: [
            Match(
              id: 'a',
              sport: Sport.soccer,
              league: 'EPL',
              sportKey: 'soccer_epl',
              home: 'A',
              away: 'B',
              commenceTime: DateTime(2026, 5, 1),
              h2h: H2HOdds(
                home: 2.0,
                away: 2.0,
                lastUpdate: DateTime(2026, 4, 18),
                bookmaker: 'T',
              ),
            ),
          ],
          fetchedAt: DateTime.now(),
          remainingRequests: 490,
        );

    test('null initially', () {
      expect(StorageService.getCachedMatches(), isNull);
    });
    test('save + retrieve + clear', () async {
      await StorageService.saveCachedMatches(makeEntry());
      final e = StorageService.getCachedMatches();
      expect(e!.remainingRequests, 490);
      expect(e.matches, hasLength(1));
      await StorageService.clearCachedMatches();
      expect(StorageService.getCachedMatches(), isNull);
    });
    test('cache ttl default 15', () {
      expect(StorageService.getCacheTtlMinutes(), 15);
    });
    test('cache ttl roundtrip', () async {
      await StorageService.saveCacheTtlMinutes(60);
      expect(StorageService.getCacheTtlMinutes(), 60);
    });
  });

  group('Cleanup scheduler', () {
    test('lastCleanupAt null initially', () {
      expect(StorageService.getLastCleanupAt(), isNull);
    });
    test('lastCleanupAt roundtrip', () async {
      final t = DateTime(2026, 4, 18, 10);
      await StorageService.saveLastCleanupAt(t);
      expect(StorageService.getLastCleanupAt(), t);
    });
    test('runScheduledCleanup gates on 24h since last run', () async {
      await StorageService.saveLastCleanupAt(
        DateTime.now().subtract(const Duration(hours: 1)),
      );
      final counts = await StorageService.runScheduledCleanup();
      expect(counts['signals_cleaned'], 0);
      expect(counts['snapshots_cleaned'], 0);
    });
    test('runScheduledCleanup runs when never run before', () async {
      expect(StorageService.getLastCleanupAt(), isNull);
      final counts = await StorageService.runScheduledCleanup();
      expect(counts, isNotNull);
      expect(StorageService.getLastCleanupAt(), isNotNull);
    });
  });
}
