import 'package:betsight/models/sport.dart';
import 'package:betsight/models/telegram_provider.dart';
import 'package:betsight/models/tipster_signal.dart';
import 'package:betsight/services/storage_service.dart';
import 'package:betsight/services/telegram_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  TelegramProvider buildProvider({http.Client? client}) {
    final monitor = TelegramMonitor(
      client: client ?? MockClient((_) async => http.Response('', 200)),
    );
    return TelegramProvider(monitor: monitor);
  }

  group('initialization', () {
    test('empty when nothing in storage', () async {
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(p.signals, isEmpty);
      expect(p.channels, isEmpty);
      expect(p.enabled, isFalse);
      expect(p.hasToken, isFalse);
      expect(p.recentCount, 0);
    });

    test('loads persisted token and enabled flag', () async {
      await StorageService.saveTelegramToken('stored-token');
      await StorageService.saveTelegramEnabled(false);
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(p.hasToken, isTrue);
    });

    test('migrates legacy channel list on construction', () async {
      await StorageService.saveMonitoredChannels(['@legacy1', '@legacy2']);
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        p.channels.map((c) => c.username).toSet(),
        {'@legacy1', '@legacy2'},
      );
    });
  });

  group('channels', () {
    test('addChannel adds and persists', () async {
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.addChannel('@pro');
      expect(p.channels.map((c) => c.username), ['@pro']);
      expect(StorageService.getAllMonitoredChannels(), hasLength(1));
    });

    test('addChannel ignores empty and duplicates', () async {
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.addChannel('');
      await p.addChannel('   ');
      await p.addChannel('@pro');
      await p.addChannel('@pro');
      expect(p.channels, hasLength(1));
    });

    test('removeChannel removes and persists', () async {
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.addChannel('@pro');
      await p.removeChannel('@pro');
      expect(p.channels, isEmpty);
      expect(StorageService.getAllMonitoredChannels(), isEmpty);
    });

    test('channelUsernames derived from channels', () async {
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.addChannel('@a');
      await p.addChannel('@b');
      expect(p.channelUsernames, ['@a', '@b']);
    });
  });

  group('token management', () {
    test('setBotToken persists and exposes hasToken', () async {
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.setBotToken('tok');
      expect(p.hasToken, isTrue);
      expect(StorageService.getTelegramToken(), 'tok');
    });

    test('removeBotToken clears token, disables, persists', () async {
      await StorageService.saveTelegramToken('old');
      await StorageService.saveTelegramEnabled(true);
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.removeBotToken();
      expect(p.hasToken, isFalse);
      expect(p.enabled, isFalse);
      expect(StorageService.getTelegramToken(), isNull);
    });
  });

  group('setEnabled', () {
    test('persists flag', () async {
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.setEnabled(true);
      expect(p.enabled, isTrue);
      expect(StorageService.getTelegramEnabled(), isTrue);
    });
  });

  group('recentSignals / signalsForSport', () {
    TipsterSignal makeSignal({
      required String id,
      required DateTime at,
      Sport? sport,
    }) =>
        TipsterSignal(
          id: id,
          telegramMessageId: id.hashCode,
          channelUsername: '@ch',
          channelTitle: 'ch',
          text: 't',
          receivedAt: at,
          detectedSport: sport,
          isRelevant: true,
        );

    test('excludes signals older than 6h', () async {
      await StorageService.saveSignal(makeSignal(
        id: 'old',
        at: DateTime.now().subtract(const Duration(hours: 10)),
      ));
      await StorageService.saveSignal(makeSignal(
        id: 'recent',
        at: DateTime.now().subtract(const Duration(hours: 1)),
      ));
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final ids = p.recentSignals.map((s) => s.id).toList();
      expect(ids, ['recent']);
    });

    test('signalsForSport filters by detected sport', () async {
      await StorageService.saveSignal(makeSignal(
        id: 's-soccer',
        at: DateTime.now(),
        sport: Sport.soccer,
      ));
      await StorageService.saveSignal(makeSignal(
        id: 's-nba',
        at: DateTime.now(),
        sport: Sport.basketball,
      ));
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        p.signalsForSport(Sport.soccer).map((s) => s.id).toSet(),
        {'s-soccer'},
      );
    });

    test('signalsForSport(null) returns all recent', () async {
      await StorageService.saveSignal(makeSignal(
        id: 's-1',
        at: DateTime.now(),
        sport: Sport.soccer,
      ));
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(p.signalsForSport(null), hasLength(1));
    });
  });

  group('testConnection', () {
    test('bubbles bot name on success', () async {
      final client = MockClient((_) async => http.Response(
            '{"ok":true,"result":{"username":"mybot"}}',
            200,
            headers: {'content-type': 'application/json'},
          ));
      final p = buildProvider(client: client);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.setBotToken('t');
      final name = await p.testConnection();
      expect(name, '@mybot');
    });

    test('rethrows on failure and sets error', () async {
      final client = MockClient((_) async => http.Response(
            '{"ok":false,"description":"invalid"}',
            200,
            headers: {'content-type': 'application/json'},
          ));
      final p = buildProvider(client: client);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.setBotToken('t');
      await expectLater(
        p.testConnection(),
        throwsA(isA<TelegramException>()),
      );
      expect(p.error, contains('invalid'));
    });
  });

  group('clearOldSignals / clearError', () {
    test('clearOldSignals refreshes signals list', () async {
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await p.clearOldSignals();
      expect(p.signals, isEmpty);
    });
    test('clearError is no-op when no error', () async {
      final p = buildProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      var notified = 0;
      p.addListener(() => notified++);
      p.clearError();
      expect(notified, 0);
    });
  });
}
