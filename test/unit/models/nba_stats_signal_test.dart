import 'package:betsight/models/nba_stats_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NbaStatsSignal build({
    List<String>? home,
    List<String>? away,
    int? homeRest,
    int? awayRest,
    int? homeRank,
    int? awayRank,
  }) =>
      NbaStatsSignal(
        matchId: 'm-1',
        homeTeam: 'Lakers',
        awayTeam: 'Warriors',
        homeLast10: home ??
            ['W', 'W', 'W', 'L', 'W', 'W', 'L', 'W', 'W', 'L'],
        awayLast10: away ??
            ['L', 'W', 'L', 'L', 'L', 'W', 'L', 'W', 'L', 'L'],
        homeRestDays: homeRest,
        awayRestDays: awayRest,
        homeStandingsRank: homeRank,
        awayStandingsRank: awayRank,
        fetchedAt: DateTime(2026, 4, 18),
      );

  group('winsLast10 counts', () {
    test('home 7 wins', () {
      expect(build().homeWinsLast10, 7);
    });
    test('away 3 wins', () {
      expect(build().awayWinsLast10, 3);
    });
    test('empty list → 0', () {
      expect(build(home: [], away: []).homeWinsLast10, 0);
    });
  });

  group('toClaudeContext', () {
    test('includes team names and records', () {
      final ctx = build().toClaudeContext();
      expect(ctx, contains('Lakers: 7/10'));
      expect(ctx, contains('Warriors: 3/10'));
    });
    test('omits rest/standings when null', () {
      final ctx = build().toClaudeContext();
      expect(ctx, isNot(contains('Rest days')));
      expect(ctx, isNot(contains('Standings')));
    });
    test('includes rest days when both set', () {
      final ctx = build(homeRest: 2, awayRest: 1).toClaudeContext();
      expect(ctx, contains('Rest days'));
      expect(ctx, contains('2d'));
      expect(ctx, contains('1d'));
    });
    test('includes standings when both ranks set', () {
      final ctx = build(homeRank: 5, awayRank: 12).toClaudeContext();
      expect(ctx, contains('Standings'));
      expect(ctx, contains('#5'));
      expect(ctx, contains('#12'));
    });
    test('omits one-sided data (only home rest set)', () {
      final ctx = build(homeRest: 2, awayRest: null).toClaudeContext();
      expect(ctx, isNot(contains('Rest days')));
    });
  });

  group('toMap + fromMap roundtrip', () {
    test('minimal signal', () {
      final original = build();
      final parsed = NbaStatsSignal.fromMap(original.toMap());
      expect(parsed.matchId, 'm-1');
      expect(parsed.homeTeam, 'Lakers');
      expect(parsed.homeLast10, original.homeLast10);
      expect(parsed.awayLast10, original.awayLast10);
      expect(parsed.homeRestDays, isNull);
      expect(parsed.awayStandingsRank, isNull);
    });
    test('fully populated', () {
      final original = build(
        homeRest: 2,
        awayRest: 1,
        homeRank: 3,
        awayRank: 9,
      );
      final parsed = NbaStatsSignal.fromMap(original.toMap());
      expect(parsed.homeRestDays, 2);
      expect(parsed.awayRestDays, 1);
      expect(parsed.homeStandingsRank, 3);
      expect(parsed.awayStandingsRank, 9);
    });
  });
}
