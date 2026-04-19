import 'package:betsight/models/match.dart';
import 'package:betsight/models/odds.dart';
import 'package:betsight/models/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final kickoff = DateTime(2026, 4, 20, 14, 0, 0);
  final lastUpdate = DateTime(2026, 4, 18, 10, 0, 0);

  Match buildMatch({
    String id = 'match-1',
    Sport sport = Sport.soccer,
    String league = 'EPL',
    String sportKey = 'soccer_epl',
    String home = 'Arsenal',
    String away = 'Liverpool',
    DateTime? commenceTime,
    H2HOdds? h2h,
  }) =>
      Match(
        id: id,
        sport: sport,
        league: league,
        sportKey: sportKey,
        home: home,
        away: away,
        commenceTime: commenceTime ?? kickoff,
        h2h: h2h,
      );

  group('Match.isLive', () {
    test('match with future commenceTime is not live', () {
      final m = buildMatch(
          commenceTime: DateTime.now().add(const Duration(hours: 1)));
      expect(m.isLive, isFalse);
    });
    test('match with past commenceTime is live', () {
      final m = buildMatch(
          commenceTime: DateTime.now().subtract(const Duration(minutes: 30)));
      expect(m.isLive, isTrue);
    });
  });

  group('Match.timeToKickoff', () {
    test('positive duration for future match', () {
      final m = buildMatch(
          commenceTime: DateTime.now().add(const Duration(hours: 2)));
      expect(m.timeToKickoff.inMinutes, greaterThan(60));
    });
    test('negative duration for past match', () {
      final m = buildMatch(
          commenceTime: DateTime.now().subtract(const Duration(hours: 1)));
      expect(m.timeToKickoff.isNegative, isTrue);
    });
  });

  group('Match.toMap + fromMap roundtrip', () {
    test('minimal match (no h2h) roundtrips', () {
      final original = buildMatch();
      final json = original.toMap();
      final parsed = Match.fromMap(json);

      expect(parsed.id, original.id);
      expect(parsed.sport, original.sport);
      expect(parsed.league, original.league);
      expect(parsed.sportKey, original.sportKey);
      expect(parsed.home, original.home);
      expect(parsed.away, original.away);
      expect(parsed.commenceTime, original.commenceTime);
      expect(parsed.h2h, isNull);
    });

    test('match with h2h roundtrips', () {
      final original = buildMatch(
        h2h: H2HOdds(
          home: 2.1,
          draw: 3.4,
          away: 3.2,
          lastUpdate: lastUpdate,
          bookmaker: 'Pinnacle',
        ),
      );
      final parsed = Match.fromMap(original.toMap());

      expect(parsed.h2h, isNotNull);
      expect(parsed.h2h!.home, 2.1);
      expect(parsed.h2h!.draw, 3.4);
      expect(parsed.h2h!.away, 3.2);
      expect(parsed.h2h!.bookmaker, 'Pinnacle');
      expect(parsed.h2h!.lastUpdate, lastUpdate);
    });

    test('match without draw roundtrips (tennis/basketball)', () {
      final original = buildMatch(
        sport: Sport.basketball,
        sportKey: 'basketball_nba',
        league: 'NBA',
        home: 'Lakers',
        away: 'Warriors',
        h2h: H2HOdds(
          home: 1.90,
          away: 1.90,
          lastUpdate: lastUpdate,
          bookmaker: 'Bet365',
        ),
      );
      final parsed = Match.fromMap(original.toMap());
      expect(parsed.h2h!.draw, isNull);
    });
  });

  group('Match.fromJson (Odds API response)', () {
    final apiResponseMinimal = {
      'id': 'abc123',
      'home_team': 'Arsenal',
      'away_team': 'Liverpool',
      'commence_time': '2026-04-20T14:00:00Z',
    };

    test('parses minimal response without h2h', () {
      final match = Match.fromJson(apiResponseMinimal, 'soccer_epl');
      expect(match.id, 'abc123');
      expect(match.sport, Sport.soccer);
      expect(match.sportKey, 'soccer_epl');
      expect(match.league, 'EPL');
      expect(match.home, 'Arsenal');
      expect(match.away, 'Liverpool');
      expect(match.h2h, isNull);
    });

    test('resolves league from _leagueDisplayNames mapping', () {
      final apiResponse = {...apiResponseMinimal};
      final cl = Match.fromJson(apiResponse, 'soccer_uefa_champs_league');
      expect(cl.league, 'Champions League');

      final nba = Match.fromJson(apiResponse, 'basketball_nba');
      expect(nba.league, 'NBA');

      final atp = Match.fromJson(apiResponse, 'tennis_atp_singles');
      expect(atp.league, 'ATP');
    });

    test('unknown sport key falls back to raw key as league', () {
      final m = Match.fromJson(apiResponseMinimal, 'soccer_mls');
      expect(m.league, 'soccer_mls');
      expect(m.sport, Sport.soccer);
    });

    test('throws FormatException for missing required fields', () {
      expect(
        () => Match.fromJson({'id': 'x'}, 'soccer_epl'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Match.fromJson({}, 'soccer_epl'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for unknown sport key prefix', () {
      expect(
        () => Match.fromJson(apiResponseMinimal, 'hockey_nhl'),
        throwsA(isA<FormatException>()),
      );
    });

    test('parses h2h market from bookmakers array', () {
      final response = {
        ...apiResponseMinimal,
        'bookmakers': [
          {
            'key': 'pinnacle',
            'title': 'Pinnacle',
            'last_update': '2026-04-18T10:00:00Z',
            'markets': [
              {
                'key': 'h2h',
                'last_update': '2026-04-18T10:00:00Z',
                'outcomes': [
                  {'name': 'Arsenal', 'price': 2.10},
                  {'name': 'Liverpool', 'price': 3.20},
                  {'name': 'Draw', 'price': 3.40},
                ],
              },
            ],
          },
        ],
      };
      final match = Match.fromJson(response, 'soccer_epl');
      expect(match.h2h, isNotNull);
      expect(match.h2h!.home, 2.10);
      expect(match.h2h!.away, 3.20);
      expect(match.h2h!.draw, 3.40);
      expect(match.h2h!.bookmaker, 'Pinnacle');
    });

    test('h2h is null when bookmakers list is empty', () {
      final response = {...apiResponseMinimal, 'bookmakers': []};
      final match = Match.fromJson(response, 'soccer_epl');
      expect(match.h2h, isNull);
    });

    test('h2h is null when home/away outcomes missing from bookmaker', () {
      final response = {
        ...apiResponseMinimal,
        'bookmakers': [
          {
            'title': 'Pinnacle',
            'markets': [
              {
                'key': 'h2h',
                'outcomes': [
                  {'name': 'SomeOtherName', 'price': 2.10},
                ],
              },
            ],
          },
        ],
      };
      final match = Match.fromJson(response, 'soccer_epl');
      expect(match.h2h, isNull);
    });

    test('basketball match gets h2h without draw even if outcomes include Draw', () {
      final response = {
        'id': 'nba-1',
        'home_team': 'Lakers',
        'away_team': 'Warriors',
        'commence_time': '2026-04-20T20:00:00Z',
        'bookmakers': [
          {
            'title': 'Bet365',
            'markets': [
              {
                'key': 'h2h',
                'outcomes': [
                  {'name': 'Lakers', 'price': 1.90},
                  {'name': 'Warriors', 'price': 1.90},
                  {'name': 'Draw', 'price': 20.0},
                ],
              },
            ],
          },
        ],
      };
      final match = Match.fromJson(response, 'basketball_nba');
      expect(match.h2h, isNotNull);
      expect(match.h2h!.draw, isNull, reason: 'basketball has hasDraw=false');
    });
  });
}
