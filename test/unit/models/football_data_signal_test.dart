import 'package:betsight/models/football_data_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FootballDataSignal build({
    List<String>? homeForm,
    List<String>? awayForm,
    int h2hH = 1,
    int h2hD = 1,
    int h2hA = 1,
    int? homePos,
    int? awayPos,
  }) =>
      FootballDataSignal(
        matchId: 'm-1',
        homeTeam: 'Arsenal',
        awayTeam: 'Liverpool',
        competition: 'EPL',
        homeFormLast5: homeForm ?? ['W', 'W', 'D', 'W', 'L'],
        awayFormLast5: awayForm ?? ['L', 'D', 'W', 'L', 'L'],
        h2hHomeWins: h2hH,
        h2hDraws: h2hD,
        h2hAwayWins: h2hA,
        homePosition: homePos,
        awayPosition: awayPos,
        fetchedAt: DateTime(2026, 4, 18),
      );

  group('form counts', () {
    test('homeWinsForm = 3', () {
      expect(build().homeWinsForm, 3);
    });
    test('homeDrawsForm = 1', () {
      expect(build().homeDrawsForm, 1);
    });
    test('homeLossesForm = 1', () {
      expect(build().homeLossesForm, 1);
    });
    test('awayWinsForm = 1', () {
      expect(build().awayWinsForm, 1);
    });
    test('awayLossesForm = 3', () {
      expect(build().awayLossesForm, 3);
    });
  });

  group('form scores', () {
    test('home form (W-L)/5 = (3-1)/5 = 0.4', () {
      expect(build().homeFormScore, 0.4);
    });
    test('away form (1-3)/5 = -0.4', () {
      expect(build().awayFormScore, -0.4);
    });
    test('empty form → 0/5 = 0', () {
      expect(build(homeForm: [], awayForm: []).homeFormScore, 0);
    });
    test('all wins → 1.0', () {
      expect(build(homeForm: ['W', 'W', 'W', 'W', 'W']).homeFormScore, 1.0);
    });
    test('all losses → -1.0', () {
      expect(build(homeForm: ['L', 'L', 'L', 'L', 'L']).homeFormScore, -1.0);
    });
  });

  group('toClaudeContext', () {
    test('includes concatenated form strings', () {
      final ctx = build().toClaudeContext();
      expect(ctx, contains('WWDWL'));
      expect(ctx, contains('LDWLL'));
    });
    test('includes H2H summary', () {
      final ctx = build(h2hH: 2, h2hD: 1, h2hA: 2).toClaudeContext();
      expect(ctx, contains('2W'));
      expect(ctx, contains('1D'));
      expect(ctx, contains('2L'));
    });
    test('omits standings when positions null', () {
      final ctx = build().toClaudeContext();
      expect(ctx, isNot(contains('Standings')));
    });
    test('includes standings when both positions present', () {
      final ctx = build(homePos: 2, awayPos: 5).toClaudeContext();
      expect(ctx, contains('Standings'));
      expect(ctx, contains('#2'));
      expect(ctx, contains('#5'));
    });
  });

  group('toMap + fromMap roundtrip', () {
    test('without positions', () {
      final original = build();
      final parsed = FootballDataSignal.fromMap(original.toMap());
      expect(parsed.matchId, 'm-1');
      expect(parsed.homeFormLast5, ['W', 'W', 'D', 'W', 'L']);
      expect(parsed.awayFormLast5, ['L', 'D', 'W', 'L', 'L']);
      expect(parsed.h2hHomeWins, 1);
      expect(parsed.homePosition, isNull);
      expect(parsed.awayPosition, isNull);
    });
    test('with positions', () {
      final original = build(homePos: 3, awayPos: 7);
      final parsed = FootballDataSignal.fromMap(original.toMap());
      expect(parsed.homePosition, 3);
      expect(parsed.awayPosition, 7);
    });
  });
}
