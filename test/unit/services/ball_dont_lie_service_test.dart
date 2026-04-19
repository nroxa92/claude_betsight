import 'dart:convert';

import 'package:betsight/models/match.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/services/ball_dont_lie_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Match nbaMatch({
    String home = 'Los Angeles Lakers',
    String away = 'Golden State Warriors',
    DateTime? commence,
  }) =>
      Match(
        id: 'nba-1',
        sport: Sport.basketball,
        league: 'NBA',
        sportKey: 'basketball_nba',
        home: home,
        away: away,
        commenceTime: commence ?? DateTime(2026, 5, 1),
        h2h: null,
      );

  Map<String, dynamic> teamsPayload() => {
        'data': [
          {'id': 14, 'full_name': 'Los Angeles Lakers', 'name': 'Lakers'},
          {'id': 10, 'full_name': 'Golden State Warriors', 'name': 'Warriors'},
        ],
      };

  Map<String, dynamic> gamesPayload(int teamId, int winCount) {
    final games = <Map<String, dynamic>>[];
    for (var i = 0; i < 10; i++) {
      final won = i < winCount;
      final day = (10 - i).toString().padLeft(2, '0');
      games.add({
        'id': i,
        'status': 'Final',
        'date': '2026-04-$day',
        'home_team': {'id': teamId},
        'home_team_score': won ? 110 : 95,
        'visitor_team_score': won ? 95 : 110,
      });
    }
    return {'data': games};
  }

  group('BallDontLieService.getSignalForMatch', () {
    test('throws for non-basketball sport', () {
      final svc = BallDontLieService(
        client: MockClient((_) async => http.Response('', 200)),
      );
      final match = Match(
        id: 'm-1',
        sport: Sport.soccer,
        league: 'EPL',
        sportKey: 'soccer_epl',
        home: 'A',
        away: 'B',
        commenceTime: DateTime(2026, 5, 1),
        h2h: null,
      );
      expect(
        () => svc.getSignalForMatch(match),
        throwsA(isA<BallDontLieException>()),
      );
    });

    test('throws if team not found', () {
      final svc = BallDontLieService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/teams')) {
            return http.Response(
              json.encode({'data': []}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('', 200);
        }),
      );
      expect(
        () => svc.getSignalForMatch(nbaMatch()),
        throwsA(isA<BallDontLieException>()),
      );
    });

    test('computes last10 wins from finalised games', () async {
      final svc = BallDontLieService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/teams')) {
            return http.Response(
              json.encode(teamsPayload()),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          final teamIds = req.url.queryParameters['team_ids[]'];
          final teamId = int.parse(teamIds!);
          final wins = teamId == 14 ? 7 : 3;
          return http.Response(
            json.encode(gamesPayload(teamId, wins)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final signal = await svc.getSignalForMatch(nbaMatch());
      expect(signal.homeWinsLast10, 7);
      expect(signal.awayWinsLast10, 3);
    });

    test('computes rest days from most recent game', () async {
      final svc = BallDontLieService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/teams')) {
            return http.Response(
              json.encode(teamsPayload()),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            json.encode(gamesPayload(14, 5)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final signal = await svc.getSignalForMatch(
        nbaMatch(commence: DateTime(2026, 4, 15)),
      );
      expect(signal.homeRestDays, isNotNull);
      expect(signal.awayRestDays, isNotNull);
    });

    test('standings ranks are null (not supported)', () async {
      final svc = BallDontLieService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/teams')) {
            return http.Response(
              json.encode(teamsPayload()),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            json.encode(gamesPayload(14, 5)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final signal = await svc.getSignalForMatch(nbaMatch());
      expect(signal.homeStandingsRank, isNull);
      expect(signal.awayStandingsRank, isNull);
    });
  });

  group('BallDontLieException', () {
    test('toString includes message', () {
      expect(BallDontLieException('x').toString(), contains('x'));
    });
  });
}
