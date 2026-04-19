import 'package:betsight/models/accumulator.dart';
import 'package:betsight/models/bet.dart';
import 'package:betsight/models/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 4, 18);

  AccumulatorLeg leg({
    String matchId = 'm-1',
    Sport sport = Sport.soccer,
    String league = 'EPL',
    String home = 'Arsenal',
    String away = 'Liverpool',
    BetSelection selection = BetSelection.home,
    double odds = 2.0,
    DateTime? kickoff,
  }) =>
      AccumulatorLeg(
        matchId: matchId,
        sport: sport,
        league: league,
        home: home,
        away: away,
        selection: selection,
        odds: odds,
        kickoff: kickoff ?? DateTime(2026, 4, 20),
      );

  BetAccumulator build({
    List<AccumulatorLeg>? legs,
    double stake = 10,
    AccumulatorStatus status = AccumulatorStatus.building,
    DateTime? placedAt,
    DateTime? settledAt,
    String? notes,
  }) =>
      BetAccumulator(
        id: 'acc-1',
        legs: legs ?? [leg(), leg(matchId: 'm-2', home: 'X', away: 'Y')],
        stake: stake,
        status: status,
        createdAt: createdAt,
        placedAt: placedAt,
        settledAt: settledAt,
        notes: notes,
      );

  group('AccumulatorStatus', () {
    test('has 5 values', () {
      expect(AccumulatorStatus.values, hasLength(5));
    });
    test('display maps all statuses', () {
      expect(AccumulatorStatus.building.display, 'Building');
      expect(AccumulatorStatus.placed.display, 'Placed');
      expect(AccumulatorStatus.won.display, 'Won');
      expect(AccumulatorStatus.lost.display, 'Lost');
      expect(AccumulatorStatus.partial.display, 'Partial');
    });
    test('isSettled only for won/lost/partial', () {
      expect(AccumulatorStatus.building.isSettled, isFalse);
      expect(AccumulatorStatus.placed.isSettled, isFalse);
      expect(AccumulatorStatus.won.isSettled, isTrue);
      expect(AccumulatorStatus.lost.isSettled, isTrue);
      expect(AccumulatorStatus.partial.isSettled, isTrue);
    });
  });

  group('AccumulatorLeg.toMap + fromMap', () {
    test('roundtrips all fields', () {
      final original = leg(
        selection: BetSelection.away,
        odds: 2.5,
        kickoff: DateTime(2026, 5, 1, 14),
      );
      final parsed = AccumulatorLeg.fromMap(original.toMap());
      expect(parsed.matchId, original.matchId);
      expect(parsed.sport, original.sport);
      expect(parsed.league, original.league);
      expect(parsed.home, original.home);
      expect(parsed.away, original.away);
      expect(parsed.selection, BetSelection.away);
      expect(parsed.odds, 2.5);
      expect(parsed.kickoff, DateTime(2026, 5, 1, 14));
    });
  });

  group('BetAccumulator.combinedOdds', () {
    test('single leg = its odds', () {
      final acc = build(legs: [leg(odds: 2.5)]);
      expect(acc.combinedOdds, 2.5);
    });
    test('two legs 2.0 * 3.0 = 6.0', () {
      final acc = build(legs: [leg(odds: 2.0), leg(matchId: 'm2', odds: 3.0)]);
      expect(acc.combinedOdds, 6.0);
    });
    test('empty legs = 1.0 (identity)', () {
      final acc = build(legs: []);
      expect(acc.combinedOdds, 1.0);
    });
  });

  group('BetAccumulator.potentialPayout / potentialProfit', () {
    test('stake 10, combined 6.0 → payout 60, profit 50', () {
      final acc = build(
        legs: [leg(odds: 2.0), leg(matchId: 'm2', odds: 3.0)],
        stake: 10,
      );
      expect(acc.potentialPayout, 60);
      expect(acc.potentialProfit, 50);
    });
  });

  group('BetAccumulator.actualProfit', () {
    test('building → null', () {
      expect(
        build(status: AccumulatorStatus.building).actualProfit,
        isNull,
      );
    });
    test('placed → null (not yet settled)', () {
      expect(
        build(status: AccumulatorStatus.placed).actualProfit,
        isNull,
      );
    });
    test('won → potentialProfit', () {
      final acc = build(
        legs: [leg(odds: 2.0), leg(matchId: 'm2', odds: 3.0)],
        stake: 10,
        status: AccumulatorStatus.won,
      );
      expect(acc.actualProfit, 50);
    });
    test('lost → -stake', () {
      final acc = build(status: AccumulatorStatus.lost, stake: 20);
      expect(acc.actualProfit, -20);
    });
    test('partial → 0', () {
      expect(build(status: AccumulatorStatus.partial).actualProfit, 0.0);
    });
  });

  group('BetAccumulator.correlationWarnings', () {
    test('unique matches, different leagues → no warnings', () {
      final acc = build(legs: [
        leg(matchId: 'm-1', league: 'EPL', kickoff: DateTime(2026, 4, 20)),
        leg(matchId: 'm-2', league: 'NBA', kickoff: DateTime(2026, 4, 21)),
      ]);
      expect(acc.correlationWarnings, isEmpty);
    });
    test('same match twice → warning about same match', () {
      final acc = build(legs: [
        leg(matchId: 'm-1', selection: BetSelection.home),
        leg(matchId: 'm-1', selection: BetSelection.away),
      ]);
      expect(
        acc.correlationWarnings,
        contains('Contains multiple legs from the same match'),
      );
    });
    test('same league same day → warning', () {
      final acc = build(legs: [
        leg(matchId: 'm-1', league: 'EPL', kickoff: DateTime(2026, 4, 20, 14)),
        leg(matchId: 'm-2', league: 'EPL', kickoff: DateTime(2026, 4, 20, 16)),
      ]);
      expect(
        acc.correlationWarnings.any((w) => w.contains('EPL')),
        isTrue,
      );
    });
    test('same league different days → no warning', () {
      final acc = build(legs: [
        leg(matchId: 'm-1', league: 'EPL', kickoff: DateTime(2026, 4, 20)),
        leg(matchId: 'm-2', league: 'EPL', kickoff: DateTime(2026, 4, 21)),
      ]);
      expect(acc.correlationWarnings, isEmpty);
    });
    test('single leg → no warnings', () {
      final acc = build(legs: [leg()]);
      expect(acc.correlationWarnings, isEmpty);
    });
  });

  group('BetAccumulator.copyWith', () {
    test('status update preserves legs, stake, id, createdAt', () {
      final acc = build();
      final c = acc.copyWith(status: AccumulatorStatus.placed);
      expect(c.status, AccumulatorStatus.placed);
      expect(c.legs, acc.legs);
      expect(c.stake, acc.stake);
      expect(c.id, acc.id);
      expect(c.createdAt, acc.createdAt);
    });
  });

  group('BetAccumulator.toMap + fromMap roundtrip', () {
    test('minimal acc', () {
      final original = build();
      final parsed = BetAccumulator.fromMap(original.toMap());
      expect(parsed.id, original.id);
      expect(parsed.legs, hasLength(2));
      expect(parsed.stake, original.stake);
      expect(parsed.status, original.status);
      expect(parsed.createdAt, original.createdAt);
      expect(parsed.placedAt, isNull);
      expect(parsed.settledAt, isNull);
      expect(parsed.notes, isNull);
    });
    test('fully settled acc', () {
      final now = DateTime(2026, 4, 21, 20);
      final original = build(
        status: AccumulatorStatus.won,
        placedAt: DateTime(2026, 4, 20),
        settledAt: now,
        notes: 'clean 2-leg',
      );
      final parsed = BetAccumulator.fromMap(original.toMap());
      expect(parsed.status, AccumulatorStatus.won);
      expect(parsed.placedAt, DateTime(2026, 4, 20));
      expect(parsed.settledAt, now);
      expect(parsed.notes, 'clean 2-leg');
    });
  });
}
