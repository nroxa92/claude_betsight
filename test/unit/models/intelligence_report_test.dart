import 'package:betsight/models/intelligence_report.dart';
import 'package:betsight/models/source_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SourceScore active(SourceType type, double score) => SourceScore(
        source: type,
        score: score,
        reasoning: 'test',
        isActive: true,
      );

  IntelligenceReport build(List<SourceScore> sources) => IntelligenceReport(
        matchId: 'm-1',
        sources: sources,
        generatedAt: DateTime(2026, 4, 18),
      );

  group('IntelligenceCategory enum', () {
    test('has 5 categories', () {
      expect(IntelligenceCategory.values, hasLength(5));
    });
  });

  group('IntelligenceCategoryMeta.display', () {
    test('all categories have uppercase display', () {
      expect(IntelligenceCategory.strongValue.display, 'STRONG_VALUE');
      expect(IntelligenceCategory.possibleValue.display, 'POSSIBLE_VALUE');
      expect(IntelligenceCategory.weakSignal.display, 'WEAK_SIGNAL');
      expect(IntelligenceCategory.likelySkip.display, 'LIKELY_SKIP');
      expect(IntelligenceCategory.insufficientData.display, 'INSUFFICIENT_DATA');
    });
  });

  group('confluenceScore', () {
    test('inactive sources ignored', () {
      final r = build([
        active(SourceType.odds, 1.5),
        SourceScore.inactive(SourceType.telegram, 'no channels'),
      ]);
      expect(r.confluenceScore, 1.5);
    });
    test('sums only active scores', () {
      final r = build([
        active(SourceType.odds, 1.0),
        active(SourceType.footballData, 1.0),
        active(SourceType.reddit, 0.5),
      ]);
      expect(r.confluenceScore, 2.5);
    });
  });

  group('activeSourceCount', () {
    test('counts only active sources', () {
      final r = build([
        active(SourceType.odds, 1.0),
        SourceScore.inactive(SourceType.reddit, 'x'),
        SourceScore.inactive(SourceType.telegram, 'x'),
      ]);
      expect(r.activeSourceCount, 1);
    });
    test('empty sources → 0', () {
      expect(build([]).activeSourceCount, 0);
    });
  });

  group('category classification', () {
    test('< 2 active sources → insufficientData', () {
      expect(build([]).category, IntelligenceCategory.insufficientData);
      expect(
        build([active(SourceType.odds, 2.0)]).category,
        IntelligenceCategory.insufficientData,
      );
    });
    test('score >= 4.5 → strongValue', () {
      final r = build([
        active(SourceType.odds, 2.0),
        active(SourceType.footballData, 1.5),
        active(SourceType.nbaStats, 1.0),
      ]);
      expect(r.category, IntelligenceCategory.strongValue);
    });
    test('score 3.0 <= x < 4.5 → possibleValue', () {
      final r = build([
        active(SourceType.odds, 2.0),
        active(SourceType.footballData, 1.0),
      ]);
      expect(r.category, IntelligenceCategory.possibleValue);
    });
    test('score 1.5 <= x < 3.0 → weakSignal', () {
      final r = build([
        active(SourceType.odds, 1.0),
        active(SourceType.reddit, 0.8),
      ]);
      expect(r.category, IntelligenceCategory.weakSignal);
    });
    test('score < 1.5 → likelySkip', () {
      final r = build([
        active(SourceType.odds, 0.5),
        active(SourceType.reddit, 0.5),
      ]);
      expect(r.category, IntelligenceCategory.likelySkip);
    });
  });

  group('isExpired', () {
    test('generated 10min ago, 5min ttl → expired', () {
      final r = IntelligenceReport(
        matchId: 'm',
        sources: [],
        generatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(r.isExpired(const Duration(minutes: 5)), isTrue);
    });
    test('generated 1min ago, 10min ttl → not expired', () {
      final r = IntelligenceReport(
        matchId: 'm',
        sources: [],
        generatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(r.isExpired(const Duration(minutes: 10)), isFalse);
    });
  });

  group('toClaudeContext', () {
    test('includes confluence score and category header', () {
      final r = build([
        active(SourceType.odds, 2.0),
        active(SourceType.footballData, 1.5),
        active(SourceType.nbaStats, 1.0),
      ]);
      final ctx = r.toClaudeContext();
      expect(ctx, contains('INTELLIGENCE REPORT'));
      expect(ctx, contains('STRONG_VALUE'));
      expect(ctx, contains('4.5'));
    });
    test('marks inactive sources with "(inactive)"', () {
      final r = build([
        active(SourceType.odds, 1.0),
        active(SourceType.footballData, 1.0),
        SourceScore.inactive(SourceType.telegram, 'none'),
      ]);
      final ctx = r.toClaudeContext();
      expect(ctx, contains('Telegram (inactive)'));
    });
    test('includes category interpretation', () {
      final r = build([
        active(SourceType.odds, 0.5),
        active(SourceType.reddit, 0.5),
      ]);
      expect(r.toClaudeContext(), contains('no edge'));
    });
  });

  group('toMap + fromMap roundtrip', () {
    test('roundtrips sources and matchId', () {
      final original = build([
        active(SourceType.odds, 1.5),
        SourceScore.inactive(SourceType.telegram, 'no channels'),
      ]);
      final parsed = IntelligenceReport.fromMap(original.toMap());
      expect(parsed.matchId, 'm-1');
      expect(parsed.sources, hasLength(2));
      expect(parsed.sources[0].source, SourceType.odds);
      expect(parsed.sources[0].score, 1.5);
      expect(parsed.sources[1].isActive, isFalse);
    });
  });
}
