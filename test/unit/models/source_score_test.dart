import 'package:betsight/models/source_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SourceType enum', () {
    test('has 5 sources', () {
      expect(SourceType.values, hasLength(5));
    });
  });

  group('SourceTypeMeta.display', () {
    test('maps all sources', () {
      expect(SourceType.odds.display, 'Odds');
      expect(SourceType.footballData.display, 'Football-Data');
      expect(SourceType.nbaStats.display, 'NBA Stats');
      expect(SourceType.reddit.display, 'Reddit');
      expect(SourceType.telegram.display, 'Telegram');
    });
  });

  group('SourceTypeMeta.maxScore', () {
    test('odds is weighted heaviest (2.0)', () {
      expect(SourceType.odds.maxScore, 2.0);
    });
    test('footballData 1.5, nbaStats 1.0, reddit 1.0, telegram 0.5', () {
      expect(SourceType.footballData.maxScore, 1.5);
      expect(SourceType.nbaStats.maxScore, 1.0);
      expect(SourceType.reddit.maxScore, 1.0);
      expect(SourceType.telegram.maxScore, 0.5);
    });
    test('sum of all max scores is 6.0 (full confluence)', () {
      final total = SourceType.values.fold<double>(
          0, (acc, s) => acc + s.maxScore);
      expect(total, 6.0);
    });
  });

  group('SourceTypeMeta.icon', () {
    test('each source has distinct icon', () {
      final icons = SourceType.values.map((s) => s.icon).toSet();
      expect(icons, hasLength(SourceType.values.length));
    });
  });

  group('SourceScore.percentage', () {
    test('odds 2.0 / maxScore 2.0 → 100%', () {
      const s = SourceScore(
        source: SourceType.odds,
        score: 2.0,
        reasoning: '',
        isActive: true,
      );
      expect(s.percentage, 100);
    });
    test('odds 1.0 / maxScore 2.0 → 50%', () {
      const s = SourceScore(
        source: SourceType.odds,
        score: 1.0,
        reasoning: '',
        isActive: true,
      );
      expect(s.percentage, 50);
    });
    test('zero score → 0%', () {
      const s = SourceScore(
        source: SourceType.reddit,
        score: 0,
        reasoning: '',
        isActive: true,
      );
      expect(s.percentage, 0);
    });
  });

  group('SourceScore.inactive factory', () {
    test('sets score to 0, isActive false, reasoning passed through', () {
      final s = SourceScore.inactive(SourceType.telegram, 'no channels');
      expect(s.source, SourceType.telegram);
      expect(s.score, 0);
      expect(s.isActive, isFalse);
      expect(s.reasoning, 'no channels');
    });
  });

  group('SourceScore.toMap + fromMap roundtrip', () {
    test('active score roundtrips', () {
      const original = SourceScore(
        source: SourceType.footballData,
        score: 1.2,
        reasoning: 'good signal',
        isActive: true,
      );
      final parsed = SourceScore.fromMap(original.toMap());
      expect(parsed.source, SourceType.footballData);
      expect(parsed.score, 1.2);
      expect(parsed.reasoning, 'good signal');
      expect(parsed.isActive, isTrue);
    });
    test('inactive score roundtrips', () {
      final original = SourceScore.inactive(SourceType.reddit, 'no posts');
      final parsed = SourceScore.fromMap(original.toMap());
      expect(parsed.isActive, isFalse);
      expect(parsed.score, 0);
      expect(parsed.reasoning, 'no posts');
    });
    test('all source types roundtrip', () {
      for (final type in SourceType.values) {
        final original = SourceScore(
          source: type,
          score: 0.5,
          reasoning: 'test',
          isActive: true,
        );
        expect(SourceScore.fromMap(original.toMap()).source, type);
      }
    });
  });
}
