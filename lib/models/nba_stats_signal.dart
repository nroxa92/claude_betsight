class NbaStatsSignal {
  final String matchId;
  final String homeTeam;
  final String awayTeam;

  final List<String> homeLast10;
  final List<String> awayLast10;

  final int? homeRestDays;
  final int? awayRestDays;

  final int? homeStandingsRank;
  final int? awayStandingsRank;

  final DateTime fetchedAt;

  const NbaStatsSignal({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLast10,
    required this.awayLast10,
    this.homeRestDays,
    this.awayRestDays,
    this.homeStandingsRank,
    this.awayStandingsRank,
    required this.fetchedAt,
  });

  int get homeWinsLast10 => homeLast10.where((r) => r == 'W').length;
  int get awayWinsLast10 => awayLast10.where((r) => r == 'W').length;

  String toClaudeContext() {
    final homeStr = '$homeTeam: $homeWinsLast10/10 last 10';
    final awayStr = '$awayTeam: $awayWinsLast10/10 last 10';
    final restStr = (homeRestDays != null && awayRestDays != null)
        ? 'Rest days: $homeTeam ${homeRestDays}d, $awayTeam ${awayRestDays}d'
        : '';
    final standingsStr =
        (homeStandingsRank != null && awayStandingsRank != null)
            ? 'Standings: $homeTeam #$homeStandingsRank, $awayTeam #$awayStandingsRank'
            : '';
    final parts = <String>[homeStr, awayStr];
    if (restStr.isNotEmpty) parts.add(restStr);
    if (standingsStr.isNotEmpty) parts.add(standingsStr);
    return parts.join('\n');
  }

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'homeLast10': homeLast10,
        'awayLast10': awayLast10,
        'homeRestDays': homeRestDays,
        'awayRestDays': awayRestDays,
        'homeStandingsRank': homeStandingsRank,
        'awayStandingsRank': awayStandingsRank,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory NbaStatsSignal.fromMap(Map<dynamic, dynamic> map) => NbaStatsSignal(
        matchId: map['matchId'] as String,
        homeTeam: map['homeTeam'] as String,
        awayTeam: map['awayTeam'] as String,
        homeLast10: (map['homeLast10'] as List<dynamic>).cast<String>(),
        awayLast10: (map['awayLast10'] as List<dynamic>).cast<String>(),
        homeRestDays: map['homeRestDays'] as int?,
        awayRestDays: map['awayRestDays'] as int?,
        homeStandingsRank: map['homeStandingsRank'] as int?,
        awayStandingsRank: map['awayStandingsRank'] as int?,
        fetchedAt: DateTime.parse(map['fetchedAt'] as String),
      );
}
