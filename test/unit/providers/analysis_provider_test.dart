import 'dart:convert';

import 'package:betsight/models/analysis_log.dart';
import 'package:betsight/models/analysis_provider.dart';
import 'package:betsight/models/investment_tier.dart';
import 'package:betsight/models/match.dart';
import 'package:betsight/models/odds.dart';
import 'package:betsight/models/recommendation.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/models/tipster_signal.dart';
import 'package:betsight/services/claude_service.dart';
import 'package:betsight/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async {
    await setUpHive();
    await StorageService.saveNotifValueEnabled(false);
  });
  tearDown(() async => tearDownHive());

  http.Response claudeOk(String text) => http.Response(
        json.encode({
          'content': [
            {'type': 'text', 'text': text}
          ]
        }),
        200,
        headers: {'content-type': 'application/json'},
      );

  AnalysisProvider provider({http.Client? client}) {
    final svc = ClaudeService(
      client: client ?? MockClient((_) async => http.Response('', 200)),
    );
    final p = AnalysisProvider(service: svc);
    return p;
  }

  Match buildMatch({String id = 'm-1'}) => Match(
        id: id,
        sport: Sport.soccer,
        league: 'EPL',
        sportKey: 'soccer_epl',
        home: 'Arsenal',
        away: 'Liverpool',
        commenceTime: DateTime(2026, 5, 1),
        h2h: H2HOdds(
          home: 2.0,
          away: 2.0,
          lastUpdate: DateTime(2026, 4, 18),
          bookmaker: 'T',
        ),
      );

  group('initialization', () {
    test('reads API key from storage', () async {
      await StorageService.saveAnthropicApiKey('stored');
      final p = provider();
      expect(p.hasApiKey, isTrue);
    });
    test('messages empty initially', () {
      final p = provider();
      expect(p.messages, isEmpty);
      expect(p.isLoading, isFalse);
      expect(p.error, isNull);
    });
  });

  group('staging matches', () {
    test('stageSelectedMatches notifies and stores copy', () {
      final p = provider();
      var notified = 0;
      p.addListener(() => notified++);
      p.stageSelectedMatches([buildMatch()]);
      expect(p.hasStagedMatches, isTrue);
      expect(p.stagedMatches, hasLength(1));
      expect(notified, 1);
    });
    test('clearStagedMatches is no-op on empty', () {
      final p = provider();
      var notified = 0;
      p.addListener(() => notified++);
      p.clearStagedMatches();
      expect(notified, 0);
    });
    test('clearStagedMatches empties and notifies', () {
      final p = provider();
      p.stageSelectedMatches([buildMatch()]);
      var notified = 0;
      p.addListener(() => notified++);
      p.clearStagedMatches();
      expect(p.stagedMatches, isEmpty);
      expect(notified, 1);
    });
  });

  group('staging signals', () {
    TipsterSignal signal(String id) => TipsterSignal(
          id: id,
          telegramMessageId: 1,
          channelUsername: '@c',
          channelTitle: 'c',
          text: 't',
          receivedAt: DateTime.now(),
          isRelevant: true,
        );

    test('stageSelectedSignals + clear', () {
      final p = provider();
      p.stageSelectedSignals([signal('s-1')]);
      expect(p.hasStagedSignals, isTrue);
      p.clearStagedSignals();
      expect(p.stagedSignals, isEmpty);
    });
  });

  group('input prefill', () {
    test('setInputPrefill notifies, clear only when set', () {
      final p = provider();
      p.setInputPrefill('draft');
      expect(p.inputPrefill, 'draft');

      var notified = 0;
      p.addListener(() => notified++);
      p.clearInputPrefill();
      expect(notified, 1);
      p.clearInputPrefill();
      expect(notified, 1);
    });
  });

  group('API key management', () {
    test('setApiKey persists', () async {
      final p = provider();
      await p.setApiKey('new-key');
      expect(p.hasApiKey, isTrue);
      expect(StorageService.getAnthropicApiKey(), 'new-key');
    });
    test('removeApiKey clears', () async {
      await StorageService.saveAnthropicApiKey('old');
      final p = provider();
      await p.removeApiKey();
      expect(p.hasApiKey, isFalse);
      expect(StorageService.getAnthropicApiKey(), isNull);
    });
  });

  group('sendMessage', () {
    test('empty string ignored', () async {
      final p = provider();
      await p.sendMessage('   ');
      expect(p.messages, isEmpty);
    });

    test('appends user + assistant messages on success', () async {
      final client = MockClient((_) async => claudeOk('Hello **SKIP**'));
      final p = provider(client: client);
      await p.setApiKey('k');
      await p.sendMessage('Hi');
      expect(p.messages, hasLength(2));
      expect(p.messages[0].role, 'user');
      expect(p.messages[1].role, 'assistant');
      expect(p.messages[1].content, contains('SKIP'));
    });

    test('persists analysis log with parsed recommendation', () async {
      final client = MockClient((_) async => claudeOk('Analysis **VALUE**'));
      final p = provider(client: client);
      await p.setApiKey('k');
      await p.sendMessage('Hi', contextMatches: [buildMatch(id: 'log-match')]);
      final logs = StorageService.getAllAnalysisLogs();
      expect(logs, hasLength(1));
      expect(logs.first.recommendationType, RecommendationType.value);
      expect(logs.first.contextMatchIds, ['log-match']);
      expect(p.lastLogId, logs.first.id);
    });

    test('clears staged matches after send (when staged used)', () async {
      final client = MockClient((_) async => claudeOk('**SKIP**'));
      final p = provider(client: client);
      await p.setApiKey('k');
      p.stageSelectedMatches([buildMatch()]);
      await p.sendMessage('analyze');
      expect(p.stagedMatches, isEmpty);
    });

    test('keeps staged when explicit contextMatches passed', () async {
      final client = MockClient((_) async => claudeOk('**SKIP**'));
      final p = provider(client: client);
      await p.setApiKey('k');
      p.stageSelectedMatches([buildMatch(id: 'staged')]);
      await p.sendMessage('x', contextMatches: [buildMatch(id: 'explicit')]);
      expect(p.stagedMatches, hasLength(1));
      expect(p.stagedMatches.first.id, 'staged');
    });

    test('on ClaudeException sets error and removes user message', () async {
      final client = MockClient((_) async => http.Response('', 401));
      final p = provider(client: client);
      await p.setApiKey('bad');
      await p.sendMessage('Hi');
      expect(p.error, contains('Invalid API key'));
      expect(p.messages, isEmpty);
    });
  });

  group('clearChat/clearError', () {
    test('clearChat empties messages', () async {
      final client = MockClient((_) async => claudeOk('**SKIP**'));
      final p = provider(client: client);
      await p.setApiKey('k');
      await p.sendMessage('hi');
      p.clearChat();
      expect(p.messages, isEmpty);
      expect(p.error, isNull);
    });
    test('clearError resets error', () async {
      final client = MockClient((_) async => http.Response('', 401));
      final p = provider(client: client);
      await p.setApiKey('bad');
      await p.sendMessage('hi');
      p.clearError();
      expect(p.error, isNull);
    });
  });

  group('recordFeedback', () {
    test('persists feedback on existing log', () async {
      final log = AnalysisLog(
        id: 'l-1',
        timestamp: DateTime(2026, 4, 18),
        userMessage: 'u',
        assistantResponse: 'a',
        contextMatchIds: const [],
        recommendationType: RecommendationType.value,
      );
      await StorageService.saveAnalysisLog(log);

      final p = provider();
      await p.recordFeedback('l-1', UserFeedback.logged);
      final stored = StorageService.getAllAnalysisLogs().first;
      expect(stored.userFeedback, UserFeedback.logged);
    });
  });

  test('setCurrentTier does not throw', () {
    final p = provider();
    p.setCurrentTier(InvestmentTier.accumulator);
  });
}
