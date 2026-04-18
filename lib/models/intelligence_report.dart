import 'source_score.dart';

enum IntelligenceCategory {
  strongValue,
  possibleValue,
  weakSignal,
  likelySkip,
  insufficientData,
}

extension IntelligenceCategoryMeta on IntelligenceCategory {
  String get display => switch (this) {
        IntelligenceCategory.strongValue => 'STRONG_VALUE',
        IntelligenceCategory.possibleValue => 'POSSIBLE_VALUE',
        IntelligenceCategory.weakSignal => 'WEAK_SIGNAL',
        IntelligenceCategory.likelySkip => 'LIKELY_SKIP',
        IntelligenceCategory.insufficientData => 'INSUFFICIENT_DATA',
      };

  int get colorValue => switch (this) {
        IntelligenceCategory.strongValue => 0xFF4CAF50,
        IntelligenceCategory.possibleValue => 0xFF66BB6A,
        IntelligenceCategory.weakSignal => 0xFFFFA726,
        IntelligenceCategory.likelySkip => 0xFFEF5350,
        IntelligenceCategory.insufficientData => 0xFF9E9E9E,
      };

  String get interpretation => switch (this) {
        IntelligenceCategory.strongValue =>
          'Multiple sources align on edge. Worth deep analysis.',
        IntelligenceCategory.possibleValue =>
          'Some signals present. Confirm with additional reasoning.',
        IntelligenceCategory.weakSignal =>
          'Weak indications. Not clearly actionable.',
        IntelligenceCategory.likelySkip =>
          'Sources suggest no edge. Consider skipping.',
        IntelligenceCategory.insufficientData =>
          'Not enough source coverage to decide.',
      };
}

class IntelligenceReport {
  final String matchId;
  final List<SourceScore> sources;
  final DateTime generatedAt;

  const IntelligenceReport({
    required this.matchId,
    required this.sources,
    required this.generatedAt,
  });

  double get confluenceScore => sources
      .where((s) => s.isActive)
      .fold(0.0, (sum, s) => sum + s.score);

  int get activeSourceCount => sources.where((s) => s.isActive).length;

  IntelligenceCategory get category {
    if (activeSourceCount < 2) return IntelligenceCategory.insufficientData;
    final score = confluenceScore;
    if (score >= 4.5) return IntelligenceCategory.strongValue;
    if (score >= 3.0) return IntelligenceCategory.possibleValue;
    if (score >= 1.5) return IntelligenceCategory.weakSignal;
    return IntelligenceCategory.likelySkip;
  }

  Duration get age => DateTime.now().difference(generatedAt);
  bool isExpired(Duration ttl) => age > ttl;

  String toClaudeContext() {
    final buf = StringBuffer();
    buf.writeln(
      '[INTELLIGENCE REPORT — confluence ${confluenceScore.toStringAsFixed(1)}/6.0 — ${category.display}]',
    );
    for (final s in sources) {
      if (!s.isActive) {
        buf.writeln('${s.source.display} (inactive): ${s.reasoning}');
      } else {
        buf.writeln(
          '${s.source.display} (${s.score.toStringAsFixed(1)}/${s.source.maxScore}): ${s.reasoning}',
        );
      }
    }
    buf.writeln('Hint: ${category.interpretation}');
    buf.writeln('[/INTELLIGENCE REPORT]');
    return buf.toString();
  }

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'sources': sources.map((s) => s.toMap()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory IntelligenceReport.fromMap(Map<dynamic, dynamic> map) =>
      IntelligenceReport(
        matchId: map['matchId'] as String,
        sources: (map['sources'] as List<dynamic>)
            .map((s) => SourceScore.fromMap(s as Map<dynamic, dynamic>))
            .toList(),
        generatedAt: DateTime.parse(map['generatedAt'] as String),
      );
}
