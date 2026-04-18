import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/match.dart';
import '../models/nba_stats_signal.dart';
import '../models/sport.dart';

class BallDontLieService {
  final http.Client _client;

  static const _baseUrl = 'https://www.balldontlie.io/api/v1';
  static const _timeout = Duration(seconds: 15);

  /// Cache team ID lookups across calls (NBA teams se rijetko mijenjaju).
  final Map<String, int> _teamIdCache = {};

  BallDontLieService({http.Client? client})
      : _client = client ?? http.Client();

  /// Last word of full team name as key — "Los Angeles Lakers" → "lakers".
  static String _normalize(String name) =>
      name.toLowerCase().split(' ').last.trim();

  Future<int?> _getTeamId(String name) async {
    final norm = _normalize(name);
    if (_teamIdCache.containsKey(norm)) return _teamIdCache[norm];

    try {
      final uri = Uri.parse('$_baseUrl/teams');
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final teams = data['data'] as List<dynamic>;
      for (final t in teams) {
        final map = t as Map<String, dynamic>;
        final fullName = map['full_name'] as String;
        final nickname = map['name'] as String;
        _teamIdCache[_normalize(fullName)] = map['id'] as int;
        _teamIdCache[_normalize(nickname)] = map['id'] as int;
      }
      return _teamIdCache[norm];
    } catch (_) {
      return null;
    }
  }

  Future<NbaStatsSignal> getSignalForMatch(Match match) async {
    if (match.sport != Sport.basketball) {
      throw BallDontLieException('Not an NBA match');
    }

    final homeId = await _getTeamId(match.home);
    final awayId = await _getTeamId(match.away);
    if (homeId == null || awayId == null) {
      throw BallDontLieException('Team not found in BallDontLie');
    }

    final season = DateTime.now().year;
    final homeGames = await _getTeamLast10Games(homeId, season);
    final awayGames = await _getTeamLast10Games(awayId, season);

    final homeLast10 = _gamesToForm(homeGames, homeId);
    final awayLast10 = _gamesToForm(awayGames, awayId);

    int? homeRest;
    int? awayRest;
    if (homeGames.isNotEmpty) {
      final lastGameDate =
          DateTime.parse(homeGames.first['date'] as String);
      homeRest = match.commenceTime.difference(lastGameDate).inDays;
    }
    if (awayGames.isNotEmpty) {
      final lastGameDate =
          DateTime.parse(awayGames.first['date'] as String);
      awayRest = match.commenceTime.difference(lastGameDate).inDays;
    }

    return NbaStatsSignal(
      matchId: match.id,
      homeTeam: match.home,
      awayTeam: match.away,
      homeLast10: homeLast10,
      awayLast10: awayLast10,
      homeRestDays: homeRest,
      awayRestDays: awayRest,
      homeStandingsRank: null,
      awayStandingsRank: null,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> _getTeamLast10Games(
      int teamId, int season) async {
    try {
      final uri = Uri.parse('$_baseUrl/games').replace(queryParameters: {
        'team_ids[]': teamId.toString(),
        'seasons[]': season.toString(),
        'per_page': '15',
      });
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return const [];
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final games = (data['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((g) => g['status'] == 'Final')
          .toList()
        ..sort((a, b) =>
            (b['date'] as String).compareTo(a['date'] as String));
      return games.take(10).toList();
    } catch (_) {
      return const [];
    }
  }

  List<String> _gamesToForm(
      List<Map<String, dynamic>> games, int teamId) {
    final form = <String>[];
    for (final g in games) {
      final homeTeam = g['home_team'] as Map<String, dynamic>;
      final isHome = homeTeam['id'] == teamId;
      final homeScore = g['home_team_score'] as int;
      final visitorScore = g['visitor_team_score'] as int;
      final won =
          isHome ? homeScore > visitorScore : visitorScore > homeScore;
      form.add(won ? 'W' : 'L');
    }
    return form;
  }

  void dispose() => _client.close();
}

class BallDontLieException implements Exception {
  final String message;
  BallDontLieException(this.message);
  @override
  String toString() => 'BallDontLieException: $message';
}
