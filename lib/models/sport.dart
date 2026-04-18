enum Sport {
  soccer,
  basketball,
  tennis,
}

extension SportMeta on Sport {
  String get display => switch (this) {
        Sport.soccer => 'Soccer',
        Sport.basketball => 'Basketball',
        Sport.tennis => 'Tennis',
      };

  String get icon => switch (this) {
        Sport.soccer => '⚽',
        Sport.basketball => '🏀',
        Sport.tennis => '🎾',
      };

  bool get hasDraw => this == Sport.soccer;

  List<String> get defaultSportKeys => switch (this) {
        Sport.soccer => const ['soccer_epl', 'soccer_uefa_champs_league'],
        Sport.basketball => const ['basketball_nba'],
        Sport.tennis => const ['tennis_atp_singles'],
      };

  static Sport? fromSportKey(String key) {
    if (key.startsWith('soccer_')) return Sport.soccer;
    if (key.startsWith('basketball_')) return Sport.basketball;
    if (key.startsWith('tennis_')) return Sport.tennis;
    return null;
  }
}
