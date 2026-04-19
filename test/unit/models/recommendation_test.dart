import 'package:betsight/models/recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecommendationType enum', () {
    test('has 4 values: value, watch, skip, none', () {
      expect(RecommendationType.values, hasLength(4));
    });
  });

  group('RecommendationTypeMeta.display', () {
    test('maps each value to uppercase', () {
      expect(RecommendationType.value.display, 'VALUE');
      expect(RecommendationType.watch.display, 'WATCH');
      expect(RecommendationType.skip.display, 'SKIP');
      expect(RecommendationType.none.display, 'NONE');
    });
  });

  group('parseRecommendationType — line-level parsing', () {
    test('exact **VALUE** on own line returns value', () {
      const resp = '''
This match has a clear edge on Home.
Estimated probability 55% vs implied 50%.

**VALUE**
''';
      expect(parseRecommendationType(resp), RecommendationType.value);
    });

    test('exact **WATCH** on own line returns watch', () {
      const resp = 'Some analysis.\n\n**WATCH**';
      expect(parseRecommendationType(resp), RecommendationType.watch);
    });

    test('exact **SKIP** on own line returns skip', () {
      const resp = 'Nope.\n\n**SKIP**';
      expect(parseRecommendationType(resp), RecommendationType.skip);
    });

    test('trims whitespace around marker line', () {
      const resp = 'analysis\n   **VALUE**   \n';
      expect(parseRecommendationType(resp), RecommendationType.value);
    });
  });

  group('parseRecommendationType — specificity ordering', () {
    test('VALUE beats WATCH if both appear as standalone lines', () {
      const resp = '**WATCH**\nmore text\n**VALUE**';
      expect(parseRecommendationType(resp), RecommendationType.value);
    });

    test('WATCH beats SKIP if both appear as standalone lines', () {
      const resp = '**SKIP**\nmore\n**WATCH**';
      expect(parseRecommendationType(resp), RecommendationType.watch);
    });

    test('VALUE beats SKIP if both appear', () {
      const resp = '**SKIP**\n...\n**VALUE**';
      expect(parseRecommendationType(resp), RecommendationType.value);
    });
  });

  group('parseRecommendationType — inline fallback', () {
    test('**VALUE** inline (not on own line) still matches', () {
      const resp = 'I think **VALUE** applies here.';
      expect(parseRecommendationType(resp), RecommendationType.value);
    });

    test('**WATCH** inline matches when no standalone markers', () {
      const resp = 'Probably **WATCH** this one.';
      expect(parseRecommendationType(resp), RecommendationType.watch);
    });

    test('**SKIP** inline matches when no standalone markers', () {
      const resp = 'I would **SKIP** this.';
      expect(parseRecommendationType(resp), RecommendationType.skip);
    });
  });

  group('parseRecommendationType — none fallback', () {
    test('empty string returns none', () {
      expect(parseRecommendationType(''), RecommendationType.none);
    });

    test('response without any marker returns none', () {
      const resp = 'Some long analysis without any recommendation marker.';
      expect(parseRecommendationType(resp), RecommendationType.none);
    });

    test('partial marker (missing asterisks) returns none', () {
      const resp = 'VALUE is good';
      expect(parseRecommendationType(resp), RecommendationType.none);
    });

    test('lowercase marker returns none (case-sensitive)', () {
      const resp = '**value**';
      expect(parseRecommendationType(resp), RecommendationType.none);
    });
  });

  group('parseRecommendationType — real Claude output patterns', () {
    test('typical VALUE response with structured recommendation', () {
      const resp = '''
Arsenal vs Liverpool analysis:
- Implied probability: Home 48%, Draw 29%, Away 31%
- My estimate: Home 55% based on recent form and injuries
- Edge: +7pp on Home outcome
- Recommendation: Stake 2% of bankroll on Home at 2.10

**VALUE**
''';
      expect(parseRecommendationType(resp), RecommendationType.value);
    });

    test('typical SKIP response', () {
      const resp = '''
Margin is 11% — this is a soft book.
No clear edge on any outcome.

**SKIP**
''';
      expect(parseRecommendationType(resp), RecommendationType.skip);
    });
  });
}
