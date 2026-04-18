class RedditSignal {
  final String matchId;
  final int mentionCount;
  final int topUpvotes;
  final Map<String, int> teamMentions;
  final String? topPostTitle;
  final String? topPostSubreddit;
  final DateTime fetchedAt;

  const RedditSignal({
    required this.matchId,
    required this.mentionCount,
    required this.topUpvotes,
    required this.teamMentions,
    this.topPostTitle,
    this.topPostSubreddit,
    required this.fetchedAt,
  });

  /// -1 = home tilt, +1 = away tilt, 0 = balanced.
  double getSentimentBias(String homeTeam, String awayTeam) {
    final h = teamMentions[homeTeam] ?? 0;
    final a = teamMentions[awayTeam] ?? 0;
    final total = h + a;
    if (total == 0) return 0;
    return (a - h) / total;
  }

  String toClaudeContext(String homeTeam, String awayTeam) {
    final bias = getSentimentBias(homeTeam, awayTeam);
    final biasStr = bias.abs() < 0.2
        ? 'balanced sentiment'
        : bias > 0
            ? 'Reddit skewed toward $awayTeam'
            : 'Reddit skewed toward $homeTeam';
    final topStr = topPostTitle != null
        ? 'Top post on r/$topPostSubreddit ($topUpvotes upvotes): "$topPostTitle"'
        : '';
    return 'Reddit: $mentionCount mentions, $biasStr${topStr.isNotEmpty ? "\n$topStr" : ""}';
  }

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'mentionCount': mentionCount,
        'topUpvotes': topUpvotes,
        'teamMentions': teamMentions,
        'topPostTitle': topPostTitle,
        'topPostSubreddit': topPostSubreddit,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory RedditSignal.fromMap(Map<dynamic, dynamic> map) => RedditSignal(
        matchId: map['matchId'] as String,
        mentionCount: map['mentionCount'] as int,
        topUpvotes: map['topUpvotes'] as int,
        teamMentions: (map['teamMentions'] as Map<dynamic, dynamic>)
            .map((k, v) => MapEntry(k as String, v as int)),
        topPostTitle: map['topPostTitle'] as String?,
        topPostSubreddit: map['topPostSubreddit'] as String?,
        fetchedAt: DateTime.parse(map['fetchedAt'] as String),
      );
}
