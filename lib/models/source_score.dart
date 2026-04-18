enum SourceType { odds, footballData, nbaStats, reddit, telegram }

extension SourceTypeMeta on SourceType {
  String get display => switch (this) {
        SourceType.odds => 'Odds',
        SourceType.footballData => 'Football-Data',
        SourceType.nbaStats => 'NBA Stats',
        SourceType.reddit => 'Reddit',
        SourceType.telegram => 'Telegram',
      };

  double get maxScore => switch (this) {
        SourceType.odds => 2.0,
        SourceType.footballData => 1.5,
        SourceType.nbaStats => 1.0,
        SourceType.reddit => 1.0,
        SourceType.telegram => 0.5,
      };

  String get icon => switch (this) {
        SourceType.odds => '📊',
        SourceType.footballData => '⚽',
        SourceType.nbaStats => '🏀',
        SourceType.reddit => '💬',
        SourceType.telegram => '📡',
      };
}

class SourceScore {
  final SourceType source;
  final double score;
  final String reasoning;
  final bool isActive;

  const SourceScore({
    required this.source,
    required this.score,
    required this.reasoning,
    required this.isActive,
  });

  double get percentage =>
      source.maxScore == 0 ? 0 : (score / source.maxScore) * 100;

  factory SourceScore.inactive(SourceType source, String reason) =>
      SourceScore(
        source: source,
        score: 0,
        reasoning: reason,
        isActive: false,
      );

  Map<String, dynamic> toMap() => {
        'source': source.name,
        'score': score,
        'reasoning': reasoning,
        'isActive': isActive,
      };

  factory SourceScore.fromMap(Map<dynamic, dynamic> map) => SourceScore(
        source: SourceType.values.firstWhere((s) => s.name == map['source']),
        score: (map['score'] as num).toDouble(),
        reasoning: map['reasoning'] as String,
        isActive: map['isActive'] as bool,
      );
}
