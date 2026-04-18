class H2HOdds {
  final double home;
  final double away;
  final double? draw;
  final DateTime lastUpdate;
  final String bookmaker;

  const H2HOdds({
    required this.home,
    required this.away,
    this.draw,
    required this.lastUpdate,
    required this.bookmaker,
  });

  double get impliedHomeProb => 1 / home;
  double get impliedAwayProb => 1 / away;
  double? get impliedDrawProb => draw == null ? null : 1 / draw!;

  double get bookmakerMargin {
    final sum = impliedHomeProb + impliedAwayProb + (impliedDrawProb ?? 0);
    return sum - 1;
  }
}
