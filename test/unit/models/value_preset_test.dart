import 'package:betsight/models/match.dart';
import 'package:betsight/models/odds.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/models/value_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Match matchWithOdds({
    double home = 2.0,
    double? draw,
    double away = 2.0,
    double margin = 0.04,
  }) {
    // Construct H2HOdds with specified total margin.
    // margin is computed from actual values — passed in only as documentation.
    return Match(
      id: 'test',
      sport: Sport.soccer,
      league: 'EPL',
      sportKey: 'soccer_epl',
      home: 'Home',
      away: 'Away',
      commenceTime: DateTime(2026, 5, 1),
      h2h: H2HOdds(
        home: home,
        draw: draw,
        away: away,
        lastUpdate: DateTime(2026, 4, 18),
        bookmaker: 'Test',
      ),
    );
  }

  Match matchNoOdds() => Match(
        id: 'no-odds',
        sport: Sport.soccer,
        league: 'EPL',
        sportKey: 'soccer_epl',
        home: 'X',
        away: 'Y',
        commenceTime: DateTime(2026, 5, 1),
        h2h: null,
      );

  group('ValuePreset enum values', () {
    test('has conservative, standard, aggressive', () {
      expect(ValuePreset.values, hasLength(3));
    });
    test('conservative is strictest (margin 5%, odds 1.5-3.0, spread 2.5)', () {
      expect(ValuePreset.conservative.marginMax, 0.05);
      expect(ValuePreset.conservative.oddsMin, 1.50);
      expect(ValuePreset.conservative.oddsMax, 3.00);
      expect(ValuePreset.conservative.spreadMax, 2.5);
    });
    test('standard (margin 8%, odds 1.4-5.0, spread 4.0)', () {
      expect(ValuePreset.standard.marginMax, 0.08);
      expect(ValuePreset.standard.oddsMin, 1.40);
      expect(ValuePreset.standard.oddsMax, 5.00);
      expect(ValuePreset.standard.spreadMax, 4.0);
    });
    test('aggressive is loosest (margin 12%, odds 1.2-10.0, spread 10.0)', () {
      expect(ValuePreset.aggressive.marginMax, 0.12);
      expect(ValuePreset.aggressive.oddsMin, 1.20);
      expect(ValuePreset.aggressive.oddsMax, 10.0);
      expect(ValuePreset.aggressive.spreadMax, 10.0);
    });
  });

  group('ValuePreset.matches', () {
    test('match without h2h never matches any preset', () {
      final m = matchNoOdds();
      expect(ValuePreset.conservative.matches(m), isFalse);
      expect(ValuePreset.standard.matches(m), isFalse);
      expect(ValuePreset.aggressive.matches(m), isFalse);
    });

    test('standard matches typical soft-favourite spread (1.8 / 2.1, margin ~3.8%)',
        () {
      final m = matchWithOdds(home: 1.80, away: 2.10);
      expect(ValuePreset.standard.matches(m), isTrue);
    });

    test('conservative rejects high margin (>5%)', () {
      // 1.80 / 1.90 → margin ~8.2%
      final m = matchWithOdds(home: 1.80, away: 1.90);
      expect(ValuePreset.conservative.matches(m), isFalse);
    });

    test('conservative rejects extreme odds out of range', () {
      // oddsMin = 1.50, so 1.45 fails
      final m = matchWithOdds(home: 1.45, away: 4.0);
      expect(ValuePreset.conservative.matches(m), isFalse);

      // oddsMax = 3.00, so 3.50 fails
      final m2 = matchWithOdds(home: 1.90, away: 3.50);
      expect(ValuePreset.conservative.matches(m2), isFalse);
    });

    test('standard accepts odds up to 5.0', () {
      final m = matchWithOdds(home: 1.50, away: 4.0);
      expect(ValuePreset.standard.matches(m), isTrue);
    });

    test('aggressive accepts wider spread (up to 10x)', () {
      // spread 1.2 vs 8.0 → ratio 6.67 < 10
      final m = matchWithOdds(home: 1.22, away: 8.0);
      expect(ValuePreset.aggressive.matches(m), isTrue);
    });

    test('aggressive rejects spread > 10', () {
      final m = matchWithOdds(home: 1.25, away: 15.0);
      expect(ValuePreset.aggressive.matches(m), isFalse);
    });
  });

  group('ValuePreset.edgeScore', () {
    test('match without h2h returns 0', () {
      expect(ValuePreset.standard.edgeScore(matchNoOdds()), 0.0);
    });
    test('score inversely proportional to margin (lower margin = higher score)', () {
      // Sharp: 1.95/1.95 → margin ~2.5% → score ~1/0.026 ≈ 38
      final sharp = matchWithOdds(home: 1.95, away: 1.95);
      final sharpScore = ValuePreset.standard.edgeScore(sharp);

      // Soft: 1.80/1.80 → margin ~11% → score ~1/0.112 ≈ 8.9
      final soft = matchWithOdds(home: 1.80, away: 1.80);
      final softScore = ValuePreset.standard.edgeScore(soft);

      expect(sharpScore, greaterThan(softScore));
    });
  });

  group('ValuePreset.fromString', () {
    test('"conservative" → ValuePreset.conservative', () {
      expect(ValuePreset.fromString('conservative'), ValuePreset.conservative);
    });
    test('"standard" → ValuePreset.standard', () {
      expect(ValuePreset.fromString('standard'), ValuePreset.standard);
    });
    test('"aggressive" → ValuePreset.aggressive', () {
      expect(ValuePreset.fromString('aggressive'), ValuePreset.aggressive);
    });
    test('null → default standard', () {
      expect(ValuePreset.fromString(null), ValuePreset.standard);
    });
    test('unknown string → default standard', () {
      expect(ValuePreset.fromString('foo'), ValuePreset.standard);
      expect(ValuePreset.fromString(''), ValuePreset.standard);
    });
  });
}
