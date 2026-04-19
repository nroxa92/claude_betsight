import 'package:betsight/models/odds_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t1 = DateTime(2026, 4, 18, 10, 0);
  final t2 = DateTime(2026, 4, 18, 14, 0);

  OddsSnapshot snap({
    String matchId = 'm1',
    DateTime? at,
    double home = 2.0,
    double? draw,
    double away = 2.0,
    String bookmaker = 'Pinnacle',
  }) =>
      OddsSnapshot(
        matchId: matchId,
        capturedAt: at ?? t1,
        home: home,
        draw: draw,
        away: away,
        bookmaker: bookmaker,
      );

  group('OddsSnapshot.toMap + fromMap roundtrip', () {
    test('2-way market (no draw)', () {
      final original = snap(home: 1.95, away: 2.05);
      final parsed = OddsSnapshot.fromMap(original.toMap());
      expect(parsed.matchId, 'm1');
      expect(parsed.home, 1.95);
      expect(parsed.away, 2.05);
      expect(parsed.draw, isNull);
      expect(parsed.bookmaker, 'Pinnacle');
      expect(parsed.capturedAt, t1);
    });
    test('3-way market (with draw)', () {
      final original = snap(home: 2.5, draw: 3.4, away: 3.0);
      final parsed = OddsSnapshot.fromMap(original.toMap());
      expect(parsed.draw, 3.4);
    });
  });

  group('OddsDrift.compute', () {
    test('no change → 0% on all sides', () {
      final a = snap(home: 2.0, draw: 3.0, away: 2.5, at: t1);
      final b = snap(home: 2.0, draw: 3.0, away: 2.5, at: t2);
      final drift = OddsDrift.compute(a, b);
      expect(drift.homePercent, 0);
      expect(drift.awayPercent, 0);
      expect(drift.drawPercent, 0);
    });
    test('home odds 2.0 → 1.8 = -10%', () {
      final a = snap(home: 2.0, away: 2.0, at: t1);
      final b = snap(home: 1.8, away: 2.2, at: t2);
      final drift = OddsDrift.compute(a, b);
      expect(drift.homePercent, closeTo(-10, 0.01));
      expect(drift.awayPercent, closeTo(10, 0.01));
    });
    test('drawPercent null if either snapshot lacks draw', () {
      final a = snap(home: 2.0, away: 2.0, at: t1);
      final b = snap(home: 2.0, draw: 3.0, away: 2.0, at: t2);
      final drift = OddsDrift.compute(a, b);
      expect(drift.drawPercent, isNull);
    });
    test('drawPercent computed when both present', () {
      final a = snap(home: 2.0, draw: 3.0, away: 3.0, at: t1);
      final b = snap(home: 2.0, draw: 3.3, away: 3.0, at: t2);
      final drift = OddsDrift.compute(a, b);
      expect(drift.drawPercent, closeTo(10, 0.01));
    });
  });

  group('OddsDrift.dominantDrift', () {
    test('picks side with largest abs() percent', () {
      const drift = OddsDrift(
        homePercent: -10,
        drawPercent: 3,
        awayPercent: 5,
      );
      expect(drift.dominantDrift.side, 'Home');
      expect(drift.dominantDrift.percent, -10);
    });
    test('away wins when it moves more', () {
      const drift = OddsDrift(
        homePercent: 2,
        awayPercent: 8,
      );
      expect(drift.dominantDrift.side, 'Away');
    });
    test('draw considered in dominance calc', () {
      const drift = OddsDrift(
        homePercent: 1,
        drawPercent: 15,
        awayPercent: -2,
      );
      expect(drift.dominantDrift.side, 'Draw');
      expect(drift.dominantDrift.percent, 15);
    });
  });

  group('OddsDrift.hasSignificantMove', () {
    test('under 3% all sides → false', () {
      const drift = OddsDrift(
        homePercent: 2,
        drawPercent: 2,
        awayPercent: 2,
      );
      expect(drift.hasSignificantMove, isFalse);
    });
    test('home > 3 → true', () {
      const drift = OddsDrift(homePercent: 4, awayPercent: 0);
      expect(drift.hasSignificantMove, isTrue);
    });
    test('negative movement > 3 abs → true', () {
      const drift = OddsDrift(homePercent: -5, awayPercent: 1);
      expect(drift.hasSignificantMove, isTrue);
    });
    test('draw > 3 triggers significant', () {
      const drift = OddsDrift(
        homePercent: 1,
        drawPercent: 10,
        awayPercent: 1,
      );
      expect(drift.hasSignificantMove, isTrue);
    });
    test('null drawPercent treated as 0', () {
      const drift = OddsDrift(homePercent: 1, awayPercent: 1);
      expect(drift.hasSignificantMove, isFalse);
    });
  });
}
