enum InvestmentTier { preMatch, live, accumulator }

extension InvestmentTierMeta on InvestmentTier {
  String get display => switch (this) {
        InvestmentTier.preMatch => 'Pre-Match',
        InvestmentTier.live => 'Live',
        InvestmentTier.accumulator => 'Accumulator',
      };

  String get icon => switch (this) {
        InvestmentTier.preMatch => '⚽',
        InvestmentTier.live => '🔴',
        InvestmentTier.accumulator => '🏆',
      };

  String get horizon => switch (this) {
        InvestmentTier.preMatch => '24-48h before kickoff',
        InvestmentTier.live => 'In-play',
        InvestmentTier.accumulator => 'Multi-match build',
      };

  String get philosophy => switch (this) {
        InvestmentTier.preMatch =>
          'Deep analysis, find pre-kickoff value',
        InvestmentTier.live =>
          'React to momentum and in-play odds shifts',
        InvestmentTier.accumulator =>
          'Build correlated-aware multi-bets',
      };

  int get colorValue => switch (this) {
        InvestmentTier.preMatch => 0xFF6C63FF,
        InvestmentTier.live => 0xFFEF5350,
        InvestmentTier.accumulator => 0xFFFFA726,
      };

  static InvestmentTier fromString(String? name) {
    return InvestmentTier.values.firstWhere(
      (t) => t.name == name,
      orElse: () => InvestmentTier.preMatch,
    );
  }

  String get claudeContextAppendix => switch (this) {
        InvestmentTier.preMatch => '''
[TIER: PRE-MATCH — 24-48h horizon]
Focus on deep pre-kickoff analysis. User has time to DYOR. Consider form, H2H, injuries, weather (for outdoor sports), team news. Flag value where bookmaker implied probability < your estimate by at least 3 percentage points.
''',
        InvestmentTier.live => '''
[TIER: LIVE — in-play betting]
Focus on momentum reads and in-play odds drift. If odds data shows recent shift, weigh that heavily. Short decision windows. Favor clear, concise recommendations. Skip if data is ambiguous — no time for user to deliberate.
''',
        InvestmentTier.accumulator => '''
[TIER: ACCUMULATOR — multi-match build]
User is building a multi-bet combo. For each leg, consider correlation: avoid legs that are outcomes of the same match or share dependencies (e.g., both teams from the same league on same day). Total odds multiply — flag if combined odds exceed 20.0 (unrealistic value territory). Encourage 2-4 legs, not 10.
''',
      };
}
