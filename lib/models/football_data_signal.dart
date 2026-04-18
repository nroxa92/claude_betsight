class FootballDataSignal {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final String competition;

  final List<String> homeFormLast5;
  final List<String> awayFormLast5;

  final int h2hHomeWins;
  final int h2hDraws;
  final int h2hAwayWins;

  final int? homePosition;
  final int? awayPosition;

  final DateTime fetchedAt;

  const FootballDataSignal({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.competition,
    required this.homeFormLast5,
    required this.awayFormLast5,
    required this.h2hHomeWins,
    required this.h2hDraws,
    required this.h2hAwayWins,
    this.homePosition,
    this.awayPosition,
    required this.fetchedAt,
  });

  int get homeWinsForm => homeFormLast5.where((r) => r == 'W').length;
  int get homeDrawsForm => homeFormLast5.where((r) => r == 'D').length;
  int get homeLossesForm => homeFormLast5.where((r) => r == 'L').length;
  int get awayWinsForm => awayFormLast5.where((r) => r == 'W').length;
  int get awayDrawsForm => awayFormLast5.where((r) => r == 'D').length;
  int get awayLossesForm => awayFormLast5.where((r) => r == 'L').length;

  double get homeFormScore => (homeWinsForm - homeLossesForm) / 5.0;
  double get awayFormScore => (awayWinsForm - awayLossesForm) / 5.0;

  String toClaudeContext() {
    final homeForm = homeFormLast5.join();
    final awayForm = awayFormLast5.join();
    final h2h =
        'H2H last 5: ${h2hHomeWins}W ${h2hDraws}D ${h2hAwayWins}L (from home perspective)';
    final positions = (homePosition != null && awayPosition != null)
        ? 'Standings: $homeTeam #$homePosition, $awayTeam #$awayPosition'
        : '';
    return '$homeTeam form $homeForm | $awayTeam form $awayForm\n$h2h${positions.isNotEmpty ? "\n$positions" : ""}';
  }

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'competition': competition,
        'homeFormLast5': homeFormLast5,
        'awayFormLast5': awayFormLast5,
        'h2hHomeWins': h2hHomeWins,
        'h2hDraws': h2hDraws,
        'h2hAwayWins': h2hAwayWins,
        'homePosition': homePosition,
        'awayPosition': awayPosition,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory FootballDataSignal.fromMap(Map<dynamic, dynamic> map) =>
      FootballDataSignal(
        matchId: map['matchId'] as String,
        homeTeam: map['homeTeam'] as String,
        awayTeam: map['awayTeam'] as String,
        competition: map['competition'] as String,
        homeFormLast5: (map['homeFormLast5'] as List<dynamic>).cast<String>(),
        awayFormLast5: (map['awayFormLast5'] as List<dynamic>).cast<String>(),
        h2hHomeWins: map['h2hHomeWins'] as int,
        h2hDraws: map['h2hDraws'] as int,
        h2hAwayWins: map['h2hAwayWins'] as int,
        homePosition: map['homePosition'] as int?,
        awayPosition: map['awayPosition'] as int?,
        fetchedAt: DateTime.parse(map['fetchedAt'] as String),
      );
}
