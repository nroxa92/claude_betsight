import 'dart:convert';

import 'package:betsight/models/sport.dart';
import 'package:betsight/models/tipster_signal.dart';
import 'package:betsight/services/telegram_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  http.Response jsonOk(dynamic data) => http.Response(
        json.encode(data),
        200,
        headers: {'content-type': 'application/json'},
      );

  group('TelegramMonitor — setup', () {
    test('hasToken false by default', () {
      final m = TelegramMonitor(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(m.hasToken, isFalse);
    });
    test('setBotToken flips hasToken', () {
      final m = TelegramMonitor(
        client: MockClient((_) async => http.Response('', 200)),
      );
      m.setBotToken('abc');
      expect(m.hasToken, isTrue);
    });
    test('isMonitoring false by default', () {
      final m = TelegramMonitor(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(m.isMonitoring, isFalse);
    });
    test('startMonitoring without token is no-op', () {
      final m = TelegramMonitor(
        client: MockClient((_) async => http.Response('', 200)),
      );
      m.startMonitoring();
      expect(m.isMonitoring, isFalse);
    });
  });

  group('TelegramMonitor.testConnection', () {
    test('throws if no token set', () {
      final m = TelegramMonitor(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(() => m.testConnection(), throwsA(isA<TelegramException>()));
    });
    test('returns result on successful connection', () async {
      final m = TelegramMonitor(
        client: MockClient(
          (_) async => jsonOk({
            'ok': true,
            'result': {'username': 'mybot', 'first_name': 'MyBot'},
          }),
        ),
      );
      m.setBotToken('token');
      final result = await m.testConnection();
      expect(result['username'], 'mybot');
    });
    test('throws with description on ok: false', () async {
      final m = TelegramMonitor(
        client: MockClient(
          (_) async => jsonOk({'ok': false, 'description': 'invalid token'}),
        ),
      );
      m.setBotToken('bad');
      expect(
        () => m.testConnection(),
        throwsA(
          isA<TelegramException>().having(
            (e) => e.message,
            'message',
            contains('invalid token'),
          ),
        ),
      );
    });
    test('throws on malformed response', () async {
      final m = TelegramMonitor(
        client: MockClient(
          (_) async => http.Response('not json', 200,
              headers: {'content-type': 'application/json'}),
        ),
      );
      m.setBotToken('t');
      expect(
        () => m.testConnection(),
        throwsA(isA<TelegramException>()),
      );
    });
  });

  group('TelegramMonitor — signal detection via _poll', () {
    test('detects EPL mention and marks soccer', () async {
      TipsterSignal? received;
      final m = TelegramMonitor(
        client: MockClient(
          (req) async => jsonOk({
            'ok': true,
            'result': [
              {
                'update_id': 1,
                'channel_post': {
                  'message_id': 100,
                  'chat': {'username': 'channel1', 'title': 'Tipster 1'},
                  'text': 'EPL: Arsenal value bet at 2.10',
                },
              }
            ],
          }),
        ),
      );
      m.setBotToken('t');
      m.onSignalReceived = (s) => received = s;
      m.startMonitoring();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      m.stopMonitoring();

      expect(received, isNotNull);
      expect(received!.detectedSport, Sport.soccer);
      expect(received!.detectedLeague, 'EPL');
      expect(received!.isRelevant, isTrue);
      expect(received!.channelUsername, '@channel1');
    });

    test('detects NBA and marks basketball', () async {
      TipsterSignal? received;
      final m = TelegramMonitor(
        client: MockClient(
          (req) async => jsonOk({
            'ok': true,
            'result': [
              {
                'update_id': 2,
                'channel_post': {
                  'message_id': 101,
                  'chat': {'username': 'ch', 'title': 'T'},
                  'text': 'NBA pick Lakers',
                },
              }
            ],
          }),
        ),
      );
      m.setBotToken('t');
      m.onSignalReceived = (s) => received = s;
      m.startMonitoring();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      m.stopMonitoring();

      expect(received, isNotNull);
      expect(received!.detectedSport, Sport.basketball);
      expect(received!.detectedLeague, 'NBA');
    });

    test('marks isRelevant false for unrelated text', () async {
      TipsterSignal? received;
      final m = TelegramMonitor(
        client: MockClient(
          (req) async => jsonOk({
            'ok': true,
            'result': [
              {
                'update_id': 3,
                'channel_post': {
                  'message_id': 102,
                  'chat': {'username': 'ch', 'title': 'T'},
                  'text': 'Just random chatter',
                },
              }
            ],
          }),
        ),
      );
      m.setBotToken('t');
      m.onSignalReceived = (s) => received = s;
      m.startMonitoring();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      m.stopMonitoring();

      expect(received!.isRelevant, isFalse);
      expect(received!.detectedSport, isNull);
    });

    test('skips posts without username', () async {
      TipsterSignal? received;
      final m = TelegramMonitor(
        client: MockClient(
          (req) async => jsonOk({
            'ok': true,
            'result': [
              {
                'update_id': 4,
                'channel_post': {
                  'message_id': 103,
                  'chat': {'title': 'No username'},
                  'text': 'test',
                },
              }
            ],
          }),
        ),
      );
      m.setBotToken('t');
      m.onSignalReceived = (s) => received = s;
      m.startMonitoring();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      m.stopMonitoring();

      expect(received, isNull);
    });

    test('skips posts with empty text', () async {
      TipsterSignal? received;
      final m = TelegramMonitor(
        client: MockClient(
          (req) async => jsonOk({
            'ok': true,
            'result': [
              {
                'update_id': 5,
                'channel_post': {
                  'message_id': 104,
                  'chat': {'username': 'x', 'title': 'y'},
                  'text': '',
                },
              }
            ],
          }),
        ),
      );
      m.setBotToken('t');
      m.onSignalReceived = (s) => received = s;
      m.startMonitoring();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      m.stopMonitoring();

      expect(received, isNull);
    });
  });

  group('TelegramException', () {
    test('toString includes message', () {
      expect(TelegramException('m').toString(), contains('m'));
    });
  });
}
