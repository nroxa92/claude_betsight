import 'odds.dart';
import 'sport.dart';

class Match {
  final String id;
  final Sport sport;
  final String league;
  final String sportKey;
  final String home;
  final String away;
  final DateTime commenceTime;
  final H2HOdds? h2h;

  const Match({
    required this.id,
    required this.sport,
    required this.league,
    required this.sportKey,
    required this.home,
    required this.away,
    required this.commenceTime,
    required this.h2h,
  });

  static const Map<String, String> _leagueDisplayNames = {
    'soccer_epl': 'EPL',
    'soccer_uefa_champs_league': 'Champions League',
    'basketball_nba': 'NBA',
    'tennis_atp_singles': 'ATP',
  };

  factory Match.fromJson(Map<String, dynamic> json, String sportKey) {
    final sport = SportMeta.fromSportKey(sportKey);
    if (sport == null) {
      throw const FormatException('Unknown sport key');
    }

    final id = json['id'] as String?;
    final home = json['home_team'] as String?;
    final away = json['away_team'] as String?;
    final commence = json['commence_time'] as String?;
    if (id == null || home == null || away == null || commence == null) {
      throw const FormatException('Missing required match fields');
    }

    final commenceTime = DateTime.parse(commence);
    final league = _leagueDisplayNames[sportKey] ?? sportKey;

    H2HOdds? h2h;
    final bookmakers = json['bookmakers'];
    if (bookmakers is List && bookmakers.isNotEmpty) {
      for (final bookmakerRaw in bookmakers) {
        if (bookmakerRaw is! Map) continue;
        final bookmaker = bookmakerRaw.cast<String, dynamic>();
        final markets = bookmaker['markets'];
        if (markets is! List) continue;
        Map<String, dynamic>? h2hMarket;
        for (final m in markets) {
          if (m is Map && m['key'] == 'h2h') {
            h2hMarket = m.cast<String, dynamic>();
            break;
          }
        }
        if (h2hMarket == null) continue;

        final outcomes = h2hMarket['outcomes'];
        if (outcomes is! List) continue;

        double? homeOdd;
        double? awayOdd;
        double? drawOdd;
        for (final o in outcomes) {
          if (o is! Map) continue;
          final name = o['name'] as String?;
          final priceRaw = o['price'];
          final price = priceRaw is num ? priceRaw.toDouble() : null;
          if (name == null || price == null) continue;
          if (name == home) {
            homeOdd = price;
          } else if (name == away) {
            awayOdd = price;
          } else if (name == 'Draw') {
            drawOdd = price;
          }
        }

        if (homeOdd == null || awayOdd == null) continue;

        DateTime lastUpdate;
        final lastUpdateRaw = h2hMarket['last_update'] as String? ??
            bookmaker['last_update'] as String?;
        try {
          lastUpdate = lastUpdateRaw != null
              ? DateTime.parse(lastUpdateRaw)
              : DateTime.now();
        } on FormatException {
          lastUpdate = DateTime.now();
        }

        h2h = H2HOdds(
          home: homeOdd,
          away: awayOdd,
          draw: sport.hasDraw ? drawOdd : null,
          lastUpdate: lastUpdate,
          bookmaker: (bookmaker['title'] as String?) ??
              (bookmaker['key'] as String?) ??
              'unknown',
        );
        break;
      }
    }

    return Match(
      id: id,
      sport: sport,
      league: league,
      sportKey: sportKey,
      home: home,
      away: away,
      commenceTime: commenceTime,
      h2h: h2h,
    );
  }

  bool get isLive => DateTime.now().isAfter(commenceTime);
  Duration get timeToKickoff => commenceTime.difference(DateTime.now());

  Map<String, dynamic> toMap() => {
        'id': id,
        'sport': sport.name,
        'league': league,
        'sportKey': sportKey,
        'home': home,
        'away': away,
        'commenceTime': commenceTime.toIso8601String(),
        'h2h': h2h == null
            ? null
            : {
                'home': h2h!.home,
                'draw': h2h!.draw,
                'away': h2h!.away,
                'lastUpdate': h2h!.lastUpdate.toIso8601String(),
                'bookmaker': h2h!.bookmaker,
              },
      };

  factory Match.fromMap(Map<dynamic, dynamic> map) {
    final h2hMap = map['h2h'] as Map<dynamic, dynamic>?;
    return Match(
      id: map['id'] as String,
      sport: Sport.values.firstWhere((s) => s.name == map['sport']),
      league: map['league'] as String,
      sportKey: map['sportKey'] as String,
      home: map['home'] as String,
      away: map['away'] as String,
      commenceTime: DateTime.parse(map['commenceTime'] as String),
      h2h: h2hMap == null
          ? null
          : H2HOdds(
              home: (h2hMap['home'] as num).toDouble(),
              draw: h2hMap['draw'] == null
                  ? null
                  : (h2hMap['draw'] as num).toDouble(),
              away: (h2hMap['away'] as num).toDouble(),
              lastUpdate:
                  DateTime.parse(h2hMap['lastUpdate'] as String),
              bookmaker: h2hMap['bookmaker'] as String,
            ),
    );
  }
}
