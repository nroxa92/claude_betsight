import 'dart:convert';

import 'package:betsight/models/match.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/services/football_data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Match eplMatch({String home = 'Arsenal', String away = 'Liverpool'}) =>
      Match(
        id: 'm-1',
        sport: Sport.soccer,
        league: 'EPL',
        sportKey: 'soccer_epl',
        home: home,
        away: away,
        commenceTime: DateTime(2026, 5, 1),
        h2h: null,
      );

  http.Response jsonOk(dynamic data) => http.Response(
        json.encode(data),
        200,
        headers: {'content-type': 'application/json'},
      );

  Map<String, dynamic> matchesResponse({
    int fdId = 100,
    int homeId = 57,
    int awayId = 64,
    String homeName = 'Arsenal FC',
    String awayName = 'Liverpool FC',
  }) {
    return {
      'matches': [
        {
          'id': fdId,
          'homeTeam': {'id': homeId, 'name': homeName},
          'awayTeam': {'id': awayId, 'name': awayName},
          'competition': {'name': 'Premier League'},
        },
      ],
    };
  }

  Map<String, dynamic> h2hResponse(int h, int d, int a) {
    return {
      'resultSet': {'wins': h, 'draws': d, 'losses': a},
    };
  }

  Map<String, dynamic> teamFormResponse(int teamId, List<String> results) {
    return {
      'matches': [
        for (var i = 0; i < results.length; i++)
          {
            'score': {
              'winner': results[i] == 'W'
                  ? 'HOME_TEAM'
                  : results[i] == 'L'
                      ? 'AWAY_TEAM'
                      : 'DRAW'
            },
            'homeTeam': {'id': teamId},
          },
      ],
    };
  }

  Map<String, dynamic> standingsResponse(int homeId, int homePos, int awayId,
      int awayPos) {
    return {
      'standings': [
        {
          'type': 'TOTAL',
          'table': [
            {'team': {'id': homeId}, 'position': homePos},
            {'team': {'id': awayId}, 'position': awayPos},
          ],
        },
      ],
    };
  }

  group('setup', () {
    test('hasApiKey false by default', () {
      final svc = FootballDataService(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(svc.hasApiKey, isFalse);
    });
    test('setApiKey toggles hasApiKey', () {
      final svc = FootballDataService(
        client: MockClient((_) async => http.Response('', 200)),
      );
      svc.setApiKey('k');
      expect(svc.hasApiKey, isTrue);
    });
  });

  group('getSignalForMatch error paths', () {
    test('throws when no API key', () {
      final svc = FootballDataService(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(
        () => svc.getSignalForMatch(eplMatch()),
        throwsA(isA<FootballDataException>()),
      );
    });

    test('throws for unsupported sport key', () {
      final svc = FootballDataService(
        client: MockClient((_) async => http.Response('', 200)),
      );
      svc.setApiKey('k');
      final unsupported = Match(
        id: 'x',
        sport: Sport.tennis,
        league: 'ATP',
        sportKey: 'tennis_atp_singles',
        home: 'a',
        away: 'b',
        commenceTime: DateTime(2026, 5, 1),
        h2h: null,
      );
      expect(
        () => svc.getSignalForMatch(unsupported),
        throwsA(isA<FootballDataException>()),
      );
    });

    test('throws on 403 (invalid key)', () {
      final svc = FootballDataService(
        client: MockClient((_) async => http.Response('', 403)),
      );
      svc.setApiKey('bad');
      expect(
        () => svc.getSignalForMatch(eplMatch()),
        throwsA(
          isA<FootballDataException>()
              .having((e) => e.message, 'message', contains('Invalid API key')),
        ),
      );
    });

    test('throws on 429 (rate limit)', () {
      final svc = FootballDataService(
        client: MockClient((_) async => http.Response('', 429)),
      );
      svc.setApiKey('k');
      expect(
        () => svc.getSignalForMatch(eplMatch()),
        throwsA(
          isA<FootballDataException>()
              .having((e) => e.message, 'message', contains('Rate limited')),
        ),
      );
    });

    test('throws when match not in API response', () {
      final svc = FootballDataService(
        client: MockClient((_) async => jsonOk({'matches': []})),
      );
      svc.setApiKey('k');
      expect(
        () => svc.getSignalForMatch(eplMatch()),
        throwsA(isA<FootballDataException>()),
      );
    });
  });

  group('happy path', () {
    test('matches EPL teams by fuzzy token name → builds full signal',
        () async {
      final svc = FootballDataService(
        client: MockClient((req) async {
          final path = req.url.path;
          if (path.contains('/competitions/PL/matches')) {
            return jsonOk(matchesResponse(
              fdId: 100,
              homeId: 57,
              awayId: 64,
              homeName: 'Arsenal FC',
              awayName: 'Liverpool FC',
            ));
          } else if (path.contains('/head2head')) {
            return jsonOk(h2hResponse(2, 1, 1));
          } else if (path.contains('/teams/57/matches')) {
            return jsonOk(teamFormResponse(57, ['W', 'W', 'D', 'L', 'W']));
          } else if (path.contains('/teams/64/matches')) {
            return jsonOk(teamFormResponse(64, ['L', 'W', 'L', 'L', 'L']));
          } else if (path.contains('/competitions/PL/standings')) {
            return jsonOk(standingsResponse(57, 2, 64, 5));
          }
          return http.Response('', 404);
        }),
      );
      svc.setApiKey('k');
      final signal = await svc.getSignalForMatch(eplMatch());

      expect(signal.matchId, 'm-1');
      expect(signal.homeTeam, 'Arsenal FC');
      expect(signal.awayTeam, 'Liverpool FC');
      expect(signal.competition, 'Premier League');
      expect(signal.homeFormLast5, hasLength(5));
      expect(signal.h2hHomeWins, 2);
      expect(signal.h2hDraws, 1);
      expect(signal.h2hAwayWins, 1);
      expect(signal.homePosition, 2);
      expect(signal.awayPosition, 5);
    });

    test('strips FC/AFC suffixes in fuzzy match', () async {
      // Odds API says "Liverpool", Football-Data API says "Liverpool FC" — should still match.
      final svc = FootballDataService(
        client: MockClient((req) async {
          final path = req.url.path;
          if (path.contains('/competitions/PL/matches')) {
            return jsonOk(matchesResponse(
              homeName: 'Manchester United FC',
              awayName: 'Manchester City FC',
            ));
          } else if (path.contains('/head2head')) {
            return jsonOk(h2hResponse(1, 1, 1));
          } else if (path.contains('/teams/')) {
            return jsonOk({'matches': []});
          } else if (path.contains('/standings')) {
            return jsonOk({'standings': []});
          }
          return http.Response('', 404);
        }),
      );
      svc.setApiKey('k');
      final signal = await svc.getSignalForMatch(
        eplMatch(home: 'Manchester United', away: 'Manchester City'),
      );
      expect(signal.homeTeam, 'Manchester United FC');
      expect(signal.awayTeam, 'Manchester City FC');
    });

    test('standings optional — missing standings → null positions', () async {
      final svc = FootballDataService(
        client: MockClient((req) async {
          final path = req.url.path;
          if (path.contains('/competitions/PL/matches')) {
            return jsonOk(matchesResponse());
          } else if (path.contains('/head2head')) {
            return jsonOk(h2hResponse(0, 0, 0));
          } else if (path.contains('/teams/')) {
            return jsonOk({'matches': []});
          }
          // standings returns 500 → skipped
          return http.Response('', 500);
        }),
      );
      svc.setApiKey('k');
      final signal = await svc.getSignalForMatch(eplMatch());
      expect(signal.homePosition, isNull);
      expect(signal.awayPosition, isNull);
    });
  });

  group('FootballDataException', () {
    test('toString includes message', () {
      expect(FootballDataException('m').toString(), contains('m'));
    });
  });
}
