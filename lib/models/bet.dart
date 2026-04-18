import 'sport.dart';

enum BetSelection { home, draw, away }

extension BetSelectionMeta on BetSelection {
  String get display => switch (this) {
        BetSelection.home => 'Home',
        BetSelection.draw => 'Draw',
        BetSelection.away => 'Away',
      };
}

enum BetStatus { pending, won, lost, void_ }

extension BetStatusMeta on BetStatus {
  String get display => switch (this) {
        BetStatus.pending => 'Pending',
        BetStatus.won => 'Won',
        BetStatus.lost => 'Lost',
        BetStatus.void_ => 'Void',
      };

  bool get isSettled => this != BetStatus.pending;
}

class Bet {
  final String id;
  final Sport sport;
  final String league;
  final String home;
  final String away;
  final BetSelection selection;
  final double odds;
  final double stake;
  final String? bookmaker;
  final String? notes;
  final DateTime placedAt;
  final DateTime? matchStartedAt;
  final BetStatus status;
  final DateTime? settledAt;
  final String? linkedMatchId;

  const Bet({
    required this.id,
    required this.sport,
    required this.league,
    required this.home,
    required this.away,
    required this.selection,
    required this.odds,
    required this.stake,
    required this.placedAt,
    required this.status,
    this.bookmaker,
    this.notes,
    this.matchStartedAt,
    this.settledAt,
    this.linkedMatchId,
  });

  double get potentialPayout => stake * odds;
  double get potentialProfit => stake * (odds - 1);

  double? get actualProfit {
    return switch (status) {
      BetStatus.pending => null,
      BetStatus.won => stake * (odds - 1),
      BetStatus.lost => -stake,
      BetStatus.void_ => 0.0,
    };
  }

  double get impliedProbability => 1 / odds;

  /// True if stake was placed after kickoff (live bet).
  /// Bets without matchStartedAt data are treated as pre-match (backward-compat).
  bool get isLiveBet {
    if (matchStartedAt == null) return false;
    return placedAt.isAfter(matchStartedAt!);
  }

  bool get isPreMatchBet => !isLiveBet;

  Bet copyWith({
    BetStatus? status,
    DateTime? settledAt,
    String? notes,
  }) {
    return Bet(
      id: id,
      sport: sport,
      league: league,
      home: home,
      away: away,
      selection: selection,
      odds: odds,
      stake: stake,
      bookmaker: bookmaker,
      notes: notes ?? this.notes,
      placedAt: placedAt,
      matchStartedAt: matchStartedAt,
      status: status ?? this.status,
      settledAt: settledAt ?? this.settledAt,
      linkedMatchId: linkedMatchId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sport': sport.name,
        'league': league,
        'home': home,
        'away': away,
        'selection': selection.name,
        'odds': odds,
        'stake': stake,
        'bookmaker': bookmaker,
        'notes': notes,
        'placedAt': placedAt.toIso8601String(),
        'matchStartedAt': matchStartedAt?.toIso8601String(),
        'status': status.name,
        'settledAt': settledAt?.toIso8601String(),
        'linkedMatchId': linkedMatchId,
      };

  factory Bet.fromMap(Map<dynamic, dynamic> map) => Bet(
        id: map['id'] as String,
        sport: Sport.values.firstWhere((s) => s.name == map['sport']),
        league: map['league'] as String,
        home: map['home'] as String,
        away: map['away'] as String,
        selection: BetSelection.values
            .firstWhere((s) => s.name == map['selection']),
        odds: (map['odds'] as num).toDouble(),
        stake: (map['stake'] as num).toDouble(),
        bookmaker: map['bookmaker'] as String?,
        notes: map['notes'] as String?,
        placedAt: DateTime.parse(map['placedAt'] as String),
        matchStartedAt: map['matchStartedAt'] == null
            ? null
            : DateTime.parse(map['matchStartedAt'] as String),
        status: BetStatus.values.firstWhere((s) => s.name == map['status']),
        settledAt: map['settledAt'] == null
            ? null
            : DateTime.parse(map['settledAt'] as String),
        linkedMatchId: map['linkedMatchId'] as String?,
      );
}
