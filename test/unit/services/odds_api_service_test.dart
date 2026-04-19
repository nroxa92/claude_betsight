import 'dart:convert';

import 'package:betsight/services/odds_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  http.Response jsonResponse(
    dynamic data, {
    int status = 200,
    Map<String, String>? headers,
  }) {
    return http.Response(
      json.encode(data),
      status,
      headers: {'content-type': 'application/json', ...?headers},
    );
  }

  final validOddsResponse = [
    {
      'id': 'abc123',
      'home_team': 'Arsenal',
      'away_team': 'Liverpool',
      'commence_time': '2026-05-01T14:00:00Z',
      'bookmakers': [
        {
          'title': 'Pinnacle',
          'markets': [
            {
              'key': 'h2h',
              'outcomes': [
                {'name': 'Arsenal', 'price': 2.10},
                {'name': 'Liverpool', 'price': 3.20},
                {'name': 'Draw', 'price': 3.40},
              ],
            },
          ],
        },
      ],
    },
  ];

  group('OddsApiService — setup', () {
    test('hasApiKey false by default', () {
      final svc = OddsApiService(client: MockClient((_) async => http.Response('', 200)));
      expect(svc.hasApiKey, isFalse);
    });
    test('setApiKey makes hasApiKey true', () {
      final svc = OddsApiService(client: MockClient((_) async => http.Response('', 200)));
      svc.setApiKey('key-1');
      expect(svc.hasApiKey, isTrue);
    });
    test('remainingRequests is null before first call', () {
      final svc = OddsApiService(client: MockClient((_) async => http.Response('', 200)));
      expect(svc.remainingRequests, isNull);
    });
  });

  group('OddsApiService.getMatches', () {
    test('throws OddsApiException if no API key', () async {
      final svc = OddsApiService(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(
        () => svc.getMatches(sportKeys: ['soccer_epl']),
        throwsA(isA<OddsApiException>()),
      );
    });

    test('parses valid response into Match list', () async {
      final svc = OddsApiService(
        client: MockClient((req) async => jsonResponse(validOddsResponse)),
      );
      svc.setApiKey('k');
      final matches = await svc.getMatches(sportKeys: ['soccer_epl']);
      expect(matches, hasLength(1));
      expect(matches.first.home, 'Arsenal');
      expect(matches.first.h2h!.home, 2.10);
    });

    test('updates remainingRequests from response header', () async {
      final svc = OddsApiService(
        client: MockClient(
          (_) async => jsonResponse(
            validOddsResponse,
            headers: {'x-requests-remaining': '490'},
          ),
        ),
      );
      svc.setApiKey('k');
      await svc.getMatches(sportKeys: ['soccer_epl']);
      expect(svc.remainingRequests, 490);
    });

    test('throws on 401 Unauthorized', () async {
      final svc = OddsApiService(
        client: MockClient((_) async => http.Response('denied', 401)),
      );
      svc.setApiKey('bad');
      expect(
        () => svc.getMatches(sportKeys: ['soccer_epl']),
        throwsA(isA<OddsApiException>()),
      );
    });

    test('throws on 429 rate-limited', () async {
      final svc = OddsApiService(
        client: MockClient((_) async => http.Response('', 429)),
      );
      svc.setApiKey('k');
      expect(
        () => svc.getMatches(sportKeys: ['soccer_epl']),
        throwsA(isA<OddsApiException>()),
      );
    });

    test('422 skips the sport silently, returns empty from that sport', () async {
      final svc = OddsApiService(
        client: MockClient((_) async => http.Response('', 422)),
      );
      svc.setApiKey('k');
      final matches = await svc.getMatches(sportKeys: ['soccer_epl']);
      expect(matches, isEmpty);
    });

    test('500 skips the sport silently, returns empty', () async {
      final svc = OddsApiService(
        client: MockClient((_) async => http.Response('server err', 500)),
      );
      svc.setApiKey('k');
      final matches = await svc.getMatches(sportKeys: ['soccer_epl']);
      expect(matches, isEmpty);
    });

    test('malformed JSON skipped, does not throw', () async {
      final svc = OddsApiService(
        client: MockClient(
          (_) async => http.Response('not json', 200,
              headers: {'content-type': 'application/json'}),
        ),
      );
      svc.setApiKey('k');
      final matches = await svc.getMatches(sportKeys: ['soccer_epl']);
      expect(matches, isEmpty);
    });

    test('malformed individual match skipped, valid matches included', () async {
      final mixed = [
        {'id': 'missing fields'},
        ...validOddsResponse,
      ];
      final svc = OddsApiService(
        client: MockClient((_) async => jsonResponse(mixed)),
      );
      svc.setApiKey('k');
      final matches = await svc.getMatches(sportKeys: ['soccer_epl']);
      expect(matches, hasLength(1));
      expect(matches.first.id, 'abc123');
    });

    test('matches returned sorted by commenceTime', () async {
      final two = [
        {
          'id': 'late',
          'home_team': 'A',
          'away_team': 'B',
          'commence_time': '2026-05-02T14:00:00Z',
        },
        {
          'id': 'early',
          'home_team': 'C',
          'away_team': 'D',
          'commence_time': '2026-05-01T14:00:00Z',
        },
      ];
      final svc = OddsApiService(
        client: MockClient((_) async => jsonResponse(two)),
      );
      svc.setApiKey('k');
      final matches = await svc.getMatches(sportKeys: ['soccer_epl']);
      expect(matches.map((m) => m.id).toList(), ['early', 'late']);
    });

    test('multiple sport keys aggregated', () async {
      var callCount = 0;
      final svc = OddsApiService(
        client: MockClient((req) async {
          callCount++;
          final key = callCount == 1 ? 'soccer_epl' : 'basketball_nba';
          return jsonResponse([
            {
              'id': '$key-1',
              'home_team': 'H',
              'away_team': 'A',
              'commence_time': '2026-05-0${callCount}T14:00:00Z',
            }
          ]);
        }),
      );
      svc.setApiKey('k');
      final matches = await svc.getMatches(
        sportKeys: ['soccer_epl', 'basketball_nba'],
      );
      expect(matches, hasLength(2));
      expect(callCount, 2);
    });
  });

  group('OddsApiException', () {
    test('toString includes message', () {
      final e = OddsApiException('Custom error');
      expect(e.toString(), contains('Custom error'));
      expect(e.toString(), contains('OddsApiException'));
    });
  });
}
