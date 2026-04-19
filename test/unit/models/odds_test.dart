import 'package:betsight/models/odds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('H2HOdds', () {
    final baseTime = DateTime(2026, 4, 18, 14, 0);

    H2HOdds buildOdds({
      double home = 2.0,
      double? draw,
      double away = 2.0,
      String bookmaker = 'Pinnacle',
    }) =>
        H2HOdds(
          home: home,
          draw: draw,
          away: away,
          lastUpdate: baseTime,
          bookmaker: bookmaker,
        );

    group('impliedHomeProb', () {
      test('2.0 odds → 0.5 (50%)', () {
        expect(buildOdds().impliedHomeProb, 0.5);
      });
      test('1.5 odds → 0.667 (~67%)', () {
        expect(buildOdds(home: 1.5).impliedHomeProb, closeTo(0.6667, 0.001));
      });
      test('5.0 odds → 0.2 (20%)', () {
        expect(buildOdds(home: 5.0).impliedHomeProb, 0.2);
      });
    });

    group('impliedAwayProb', () {
      test('2.0 odds → 0.5', () {
        expect(buildOdds(away: 2.0).impliedAwayProb, 0.5);
      });
      test('4.0 odds → 0.25', () {
        expect(buildOdds(away: 4.0).impliedAwayProb, 0.25);
      });
    });

    group('impliedDrawProb', () {
      test('null draw → null implied', () {
        expect(buildOdds().impliedDrawProb, isNull);
      });
      test('3.0 draw → 0.333', () {
        expect(buildOdds(draw: 3.0).impliedDrawProb, closeTo(0.333, 0.001));
      });
    });

    group('bookmakerMargin', () {
      test('2-way market fair odds (2.0 / 2.0) → 0% margin', () {
        final odds = buildOdds(home: 2.0, away: 2.0);
        expect(odds.bookmakerMargin, closeTo(0.0, 0.001));
      });
      test('2-way market 1.95/1.95 → ~2.56% margin (sharp)', () {
        final odds = buildOdds(home: 1.95, away: 1.95);
        expect(odds.bookmakerMargin, closeTo(0.0256, 0.001));
      });
      test('2-way market 1.80/1.80 → ~11.1% margin (soft)', () {
        final odds = buildOdds(home: 1.80, away: 1.80);
        expect(odds.bookmakerMargin, closeTo(0.111, 0.01));
      });
      test('3-way market 2.5/3.5/3.0 (includes draw)', () {
        final odds = buildOdds(home: 2.5, draw: 3.5, away: 3.0);
        // 1/2.5 + 1/3.5 + 1/3.0 = 0.4 + 0.286 + 0.333 = 1.019 → 1.9% margin
        expect(odds.bookmakerMargin, closeTo(0.019, 0.01));
      });
      test('draw=null treated as 0 in sum', () {
        final odds = buildOdds(home: 2.0, away: 2.0);
        expect(odds.bookmakerMargin, closeTo(0.0, 0.001));
      });
    });

    test('lastUpdate and bookmaker are stored verbatim', () {
      final odds = buildOdds(bookmaker: 'Bet365');
      expect(odds.lastUpdate, baseTime);
      expect(odds.bookmaker, 'Bet365');
    });
  });
}
