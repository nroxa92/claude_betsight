import 'package:betsight/models/investment_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvestmentTier enum', () {
    test('has 3 values', () {
      expect(InvestmentTier.values, hasLength(3));
    });
  });

  group('InvestmentTierMeta.display', () {
    test('preMatch → "Pre-Match"', () {
      expect(InvestmentTier.preMatch.display, 'Pre-Match');
    });
    test('live → "Live"', () {
      expect(InvestmentTier.live.display, 'Live');
    });
    test('accumulator → "Accumulator"', () {
      expect(InvestmentTier.accumulator.display, 'Accumulator');
    });
  });

  group('InvestmentTierMeta.icon', () {
    test('preMatch → ⚽', () => expect(InvestmentTier.preMatch.icon, '⚽'));
    test('live → 🔴', () => expect(InvestmentTier.live.icon, '🔴'));
    test('accumulator → 🏆', () => expect(InvestmentTier.accumulator.icon, '🏆'));
  });

  group('InvestmentTierMeta.horizon', () {
    test('preMatch has pre-kickoff horizon', () {
      expect(InvestmentTier.preMatch.horizon, contains('kickoff'));
    });
    test('live is in-play', () {
      expect(InvestmentTier.live.horizon, 'In-play');
    });
    test('accumulator mentions multi-match', () {
      expect(InvestmentTier.accumulator.horizon, contains('Multi-match'));
    });
  });

  group('InvestmentTierMeta.philosophy', () {
    test('preMatch mentions pre-kickoff value', () {
      expect(InvestmentTier.preMatch.philosophy, contains('pre-kickoff'));
    });
    test('live mentions momentum', () {
      expect(InvestmentTier.live.philosophy, contains('momentum'));
    });
    test('accumulator mentions correlated', () {
      expect(InvestmentTier.accumulator.philosophy, contains('correlated'));
    });
  });

  group('InvestmentTierMeta.colorValue', () {
    test('preMatch purple', () {
      expect(InvestmentTier.preMatch.colorValue, 0xFF6C63FF);
    });
    test('live red', () {
      expect(InvestmentTier.live.colorValue, 0xFFEF5350);
    });
    test('accumulator orange', () {
      expect(InvestmentTier.accumulator.colorValue, 0xFFFFA726);
    });
  });

  group('InvestmentTierMeta.fromString', () {
    test('"preMatch" → preMatch', () {
      expect(InvestmentTierMeta.fromString('preMatch'), InvestmentTier.preMatch);
    });
    test('"live" → live', () {
      expect(InvestmentTierMeta.fromString('live'), InvestmentTier.live);
    });
    test('"accumulator" → accumulator', () {
      expect(InvestmentTierMeta.fromString('accumulator'),
          InvestmentTier.accumulator);
    });
    test('null → preMatch default', () {
      expect(InvestmentTierMeta.fromString(null), InvestmentTier.preMatch);
    });
    test('unknown → preMatch default', () {
      expect(InvestmentTierMeta.fromString('xxx'), InvestmentTier.preMatch);
      expect(InvestmentTierMeta.fromString(''), InvestmentTier.preMatch);
    });
  });

  group('InvestmentTierMeta.claudeContextAppendix', () {
    test('preMatch contains TIER header and 24-48h', () {
      final s = InvestmentTier.preMatch.claudeContextAppendix;
      expect(s, contains('PRE-MATCH'));
      expect(s, contains('24-48h'));
    });
    test('live mentions in-play and momentum', () {
      final s = InvestmentTier.live.claudeContextAppendix;
      expect(s, contains('LIVE'));
      expect(s, contains('momentum'));
    });
    test('accumulator mentions correlation and combined odds threshold', () {
      final s = InvestmentTier.accumulator.claudeContextAppendix;
      expect(s, contains('ACCUMULATOR'));
      expect(s, contains('correlation'));
      expect(s, contains('20'));
    });
  });
}
