class OddsSnapshot {
  final String matchId;
  final DateTime capturedAt;
  final double home;
  final double? draw;
  final double away;
  final String bookmaker;

  const OddsSnapshot({
    required this.matchId,
    required this.capturedAt,
    required this.home,
    this.draw,
    required this.away,
    required this.bookmaker,
  });

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'capturedAt': capturedAt.toIso8601String(),
        'home': home,
        'draw': draw,
        'away': away,
        'bookmaker': bookmaker,
      };

  factory OddsSnapshot.fromMap(Map<dynamic, dynamic> map) => OddsSnapshot(
        matchId: map['matchId'] as String,
        capturedAt: DateTime.parse(map['capturedAt'] as String),
        home: (map['home'] as num).toDouble(),
        draw:
            map['draw'] == null ? null : (map['draw'] as num).toDouble(),
        away: (map['away'] as num).toDouble(),
        bookmaker: map['bookmaker'] as String,
      );
}

class OddsDrift {
  final double homePercent;
  final double? drawPercent;
  final double awayPercent;

  const OddsDrift({
    required this.homePercent,
    this.drawPercent,
    required this.awayPercent,
  });

  static OddsDrift compute(OddsSnapshot older, OddsSnapshot newer) {
    double pct(double o, double n) => ((n - o) / o) * 100;
    return OddsDrift(
      homePercent: pct(older.home, newer.home),
      drawPercent: (older.draw != null && newer.draw != null)
          ? pct(older.draw!, newer.draw!)
          : null,
      awayPercent: pct(older.away, newer.away),
    );
  }

  ({String side, double percent}) get dominantDrift {
    final candidates = <(String, double)>[
      ('Home', homePercent),
      if (drawPercent != null) ('Draw', drawPercent!),
      ('Away', awayPercent),
    ];
    candidates.sort((a, b) => b.$2.abs().compareTo(a.$2.abs()));
    return (side: candidates.first.$1, percent: candidates.first.$2);
  }

  bool get hasSignificantMove =>
      homePercent.abs() > 3 ||
      awayPercent.abs() > 3 ||
      (drawPercent?.abs() ?? 0) > 3;
}
