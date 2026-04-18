import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/football_data_signal.dart';
import '../models/match.dart';

class FootballDataService {
  final http.Client _client;
  String _apiKey = '';

  static const _baseUrl = 'https://api.football-data.org/v4';
  static const _timeout = Duration(seconds: 15);

  static const _competitionMap = {
    'soccer_epl': 'PL',
    'soccer_uefa_champs_league': 'CL',
  };

  FootballDataService({http.Client? client})
      : _client = client ?? http.Client();

  bool get hasApiKey => _apiKey.isNotEmpty;
  void setApiKey(String key) => _apiKey = key;

  /// Tokenises team name into a set of meaningful words for fuzzy
  /// matching with Odds API names. Strips club suffixes (FC, AFC, CF,
  /// SC, AC, CD, CB, SL, B.K.), non-alpha chars, and tokens shorter
  /// than 3 letters (drops "cd", "al", ...).
  ///
  /// "Liverpool FC" → {"liverpool"}
  /// "Manchester United" → {"manchester", "united"}
  /// "Real Madrid CF" → {"real", "madrid"}
  static Set<String> _tokenize(String name) {
    final cleaned = name
        .toLowerCase()
        .replaceAll(
            RegExp(r'\s+(fc|cf|afc|sc|ac|cd|cb|sl|b\.?k\.?)\b'), '')
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .trim();
    return cleaned
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 3)
        .toSet();
  }

  /// Number of shared tokens between two sets — the matching score.
  static int _matchScore(Set<String> a, Set<String> b) {
    return a.intersection(b).length;
  }

  Future<FootballDataSignal> getSignalForMatch(Match match) async {
    if (!hasApiKey) {
      throw FootballDataException('No API key');
    }
    final competition = _competitionMap[match.sportKey];
    if (competition == null) {
      throw FootballDataException('Sport not supported');
    }

    final dateFrom = match.commenceTime
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final dateTo = match.commenceTime
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    final matchesUri =
        Uri.parse('$_baseUrl/competitions/$competition/matches').replace(
      queryParameters: {
        'status': 'SCHEDULED,TIMED',
        'dateFrom': dateFrom,
        'dateTo': dateTo,
      },
    );

    final matchesResp = await _client
        .get(matchesUri, headers: {'X-Auth-Token': _apiKey})
        .timeout(_timeout);

    if (matchesResp.statusCode == 429) {
      throw FootballDataException('Rate limited');
    }
    if (matchesResp.statusCode == 403) {
      throw FootballDataException('Invalid API key');
    }
    if (matchesResp.statusCode != 200) {
      throw FootballDataException('HTTP ${matchesResp.statusCode}');
    }

    final matchesData = json.decode(matchesResp.body) as Map<String, dynamic>;
    final fdMatches = (matchesData['matches'] as List<dynamic>?) ?? [];

    final oddsHomeTokens = _tokenize(match.home);
    final oddsAwayTokens = _tokenize(match.away);

    Map<String, dynamic>? fdMatch;
    var bestScore = 0;
    for (final m in fdMatches) {
      final map = m as Map<String, dynamic>;
      final fdHomeTokens =
          _tokenize((map['homeTeam'] as Map)['name'] as String);
      final fdAwayTokens =
          _tokenize((map['awayTeam'] as Map)['name'] as String);

      final homeScore = _matchScore(oddsHomeTokens, fdHomeTokens);
      final awayScore = _matchScore(oddsAwayTokens, fdAwayTokens);

      if (homeScore >= 1 && awayScore >= 1) {
        final total = homeScore + awayScore;
        if (total > bestScore) {
          bestScore = total;
          fdMatch = map;
        }
      }
    }

    if (fdMatch == null) {
      throw FootballDataException('Match not found in Football-Data');
    }
    // Require at least 2 total token matches to dodge "Manchester"-only
    // collisions between "Manchester United" and "Manchester City".
    if (bestScore < 2) {
      throw FootballDataException(
          'Match not found (ambiguous team names)');
    }

    final fdMatchId = fdMatch['id'];
    final homeTeamObj = fdMatch['homeTeam'] as Map<String, dynamic>;
    final awayTeamObj = fdMatch['awayTeam'] as Map<String, dynamic>;
    final homeTeamId = homeTeamObj['id'] as int;
    final awayTeamId = awayTeamObj['id'] as int;

    final h2hUri =
        Uri.parse('$_baseUrl/matches/$fdMatchId/head2head?limit=5');
    final h2hResp = await _client
        .get(h2hUri, headers: {'X-Auth-Token': _apiKey})
        .timeout(_timeout);

    var h2hHomeWins = 0;
    var h2hDraws = 0;
    var h2hAwayWins = 0;
    if (h2hResp.statusCode == 200) {
      final h2hData = json.decode(h2hResp.body) as Map<String, dynamic>;
      final resultSet = h2hData['resultSet'] as Map<String, dynamic>?;
      if (resultSet != null) {
        h2hHomeWins = (resultSet['wins'] as int?) ?? 0;
        h2hDraws = (resultSet['draws'] as int?) ?? 0;
        h2hAwayWins = (resultSet['losses'] as int?) ?? 0;
      }
    }

    final homeForm = await _getTeamForm(homeTeamId);
    final awayForm = await _getTeamForm(awayTeamId);

    int? homePos;
    int? awayPos;
    try {
      final standingsUri =
          Uri.parse('$_baseUrl/competitions/$competition/standings');
      final standingsResp = await _client
          .get(standingsUri, headers: {'X-Auth-Token': _apiKey})
          .timeout(_timeout);
      if (standingsResp.statusCode == 200) {
        final data =
            json.decode(standingsResp.body) as Map<String, dynamic>;
        final standings = (data['standings'] as List<dynamic>?) ?? [];
        for (final s in standings) {
          if ((s as Map)['type'] == 'TOTAL') {
            final table = s['table'] as List<dynamic>;
            for (final row in table) {
              final team = (row as Map)['team'] as Map<String, dynamic>;
              if (team['id'] == homeTeamId) homePos = row['position'] as int?;
              if (team['id'] == awayTeamId) awayPos = row['position'] as int?;
            }
            break;
          }
        }
      }
    } catch (_) {
      // standings optional
    }

    return FootballDataSignal(
      matchId: match.id,
      homeTeam: homeTeamObj['name'] as String,
      awayTeam: awayTeamObj['name'] as String,
      competition:
          (fdMatch['competition'] as Map?)?['name'] as String? ?? 'Unknown',
      homeFormLast5: homeForm,
      awayFormLast5: awayForm,
      h2hHomeWins: h2hHomeWins,
      h2hDraws: h2hDraws,
      h2hAwayWins: h2hAwayWins,
      homePosition: homePos,
      awayPosition: awayPos,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<String>> _getTeamForm(int teamId) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/teams/$teamId/matches?status=FINISHED&limit=5');
      final resp = await _client
          .get(uri, headers: {'X-Auth-Token': _apiKey})
          .timeout(_timeout);
      if (resp.statusCode != 200) return const [];
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final matches = (data['matches'] as List<dynamic>?) ?? [];
      final form = <String>[];
      for (final m in matches.take(5)) {
        final map = m as Map<String, dynamic>;
        final score = map['score'] as Map<String, dynamic>?;
        final winner = score?['winner'];
        final isHome = (map['homeTeam'] as Map)['id'] == teamId;
        if (winner == 'DRAW') {
          form.add('D');
        } else if ((winner == 'HOME_TEAM' && isHome) ||
            (winner == 'AWAY_TEAM' && !isHome)) {
          form.add('W');
        } else {
          form.add('L');
        }
      }
      return form;
    } catch (_) {
      return const [];
    }
  }

  void dispose() => _client.close();
}

class FootballDataException implements Exception {
  final String message;
  FootballDataException(this.message);
  @override
  String toString() => 'FootballDataException: $message';
}
