import 'bet.dart';
import 'sport.dart';

class AccumulatorLeg {
  final String matchId;
  final Sport sport;
  final String league;
  final String home;
  final String away;
  final BetSelection selection;
  final double odds;
  final DateTime kickoff;

  const AccumulatorLeg({
    required this.matchId,
    required this.sport,
    required this.league,
    required this.home,
    required this.away,
    required this.selection,
    required this.odds,
    required this.kickoff,
  });

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'sport': sport.name,
        'league': league,
        'home': home,
        'away': away,
        'selection': selection.name,
        'odds': odds,
        'kickoff': kickoff.toIso8601String(),
      };

  factory AccumulatorLeg.fromMap(Map<dynamic, dynamic> map) =>
      AccumulatorLeg(
        matchId: map['matchId'] as String,
        sport: Sport.values.firstWhere((s) => s.name == map['sport']),
        league: map['league'] as String,
        home: map['home'] as String,
        away: map['away'] as String,
        selection: BetSelection.values
            .firstWhere((s) => s.name == map['selection']),
        odds: (map['odds'] as num).toDouble(),
        kickoff: DateTime.parse(map['kickoff'] as String),
      );
}

enum AccumulatorStatus { building, placed, won, lost, partial }

extension AccumulatorStatusMeta on AccumulatorStatus {
  String get display => switch (this) {
        AccumulatorStatus.building => 'Building',
        AccumulatorStatus.placed => 'Placed',
        AccumulatorStatus.won => 'Won',
        AccumulatorStatus.lost => 'Lost',
        AccumulatorStatus.partial => 'Partial',
      };

  bool get isSettled =>
      this == AccumulatorStatus.won ||
      this == AccumulatorStatus.lost ||
      this == AccumulatorStatus.partial;
}

class BetAccumulator {
  final String id;
  final List<AccumulatorLeg> legs;
  final double stake;
  final AccumulatorStatus status;
  final DateTime createdAt;
  final DateTime? placedAt;
  final DateTime? settledAt;
  final String? notes;

  const BetAccumulator({
    required this.id,
    required this.legs,
    required this.stake,
    required this.status,
    required this.createdAt,
    this.placedAt,
    this.settledAt,
    this.notes,
  });

  double get combinedOdds =>
      legs.fold(1.0, (acc, leg) => acc * leg.odds);

  double get potentialPayout => stake * combinedOdds;
  double get potentialProfit => stake * (combinedOdds - 1);

  double? get actualProfit {
    return switch (status) {
      AccumulatorStatus.building ||
      AccumulatorStatus.placed =>
        null,
      AccumulatorStatus.won => potentialProfit,
      AccumulatorStatus.lost => -stake,
      AccumulatorStatus.partial => 0.0,
    };
  }

  /// Detects potential correlation issues between legs.
  /// Returns human-readable warnings, empty list if none.
  List<String> get correlationWarnings {
    final warnings = <String>[];

    final matchIds = legs.map((l) => l.matchId).toSet();
    if (matchIds.length < legs.length) {
      warnings.add('Contains multiple legs from the same match');
    }

    for (var i = 0; i < legs.length; i++) {
      for (var j = i + 1; j < legs.length; j++) {
        final a = legs[i];
        final b = legs[j];
        if (a.league == b.league &&
            a.kickoff.year == b.kickoff.year &&
            a.kickoff.month == b.kickoff.month &&
            a.kickoff.day == b.kickoff.day &&
            a.matchId != b.matchId) {
          warnings.add('Multiple legs from ${a.league} on same day');
          return warnings;
        }
      }
    }

    return warnings;
  }

  BetAccumulator copyWith({
    List<AccumulatorLeg>? legs,
    double? stake,
    AccumulatorStatus? status,
    DateTime? placedAt,
    DateTime? settledAt,
    String? notes,
  }) {
    return BetAccumulator(
      id: id,
      legs: legs ?? this.legs,
      stake: stake ?? this.stake,
      status: status ?? this.status,
      createdAt: createdAt,
      placedAt: placedAt ?? this.placedAt,
      settledAt: settledAt ?? this.settledAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'legs': legs.map((l) => l.toMap()).toList(),
        'stake': stake,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'placedAt': placedAt?.toIso8601String(),
        'settledAt': settledAt?.toIso8601String(),
        'notes': notes,
      };

  factory BetAccumulator.fromMap(Map<dynamic, dynamic> map) =>
      BetAccumulator(
        id: map['id'] as String,
        legs: (map['legs'] as List<dynamic>)
            .map((l) =>
                AccumulatorLeg.fromMap(l as Map<dynamic, dynamic>))
            .toList(),
        stake: (map['stake'] as num).toDouble(),
        status: AccumulatorStatus.values
            .firstWhere((s) => s.name == map['status']),
        createdAt: DateTime.parse(map['createdAt'] as String),
        placedAt: map['placedAt'] == null
            ? null
            : DateTime.parse(map['placedAt'] as String),
        settledAt: map['settledAt'] == null
            ? null
            : DateTime.parse(map['settledAt'] as String),
        notes: map['notes'] as String?,
      );
}
