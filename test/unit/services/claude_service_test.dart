import 'dart:convert';

import 'package:betsight/services/claude_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  http.Response jsonResponse(dynamic data, {int status = 200}) =>
      http.Response(json.encode(data), status,
          headers: {'content-type': 'application/json'});

  group('ClaudeService — setup', () {
    test('hasApiKey false by default', () {
      final svc = ClaudeService(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(svc.hasApiKey, isFalse);
    });
    test('setApiKey flips hasApiKey', () {
      final svc = ClaudeService(
        client: MockClient((_) async => http.Response('', 200)),
      );
      svc.setApiKey('x');
      expect(svc.hasApiKey, isTrue);
    });
  });

  group('ClaudeService.sendMessage', () {
    test('throws if no API key', () {
      final svc = ClaudeService(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(
        () => svc.sendMessage(userMessage: 'hi', history: []),
        throwsA(isA<ClaudeException>()),
      );
    });

    test('returns concatenated text blocks', () async {
      final svc = ClaudeService(
        client: MockClient((_) async => jsonResponse({
              'content': [
                {'type': 'text', 'text': 'Hello'},
                {'type': 'text', 'text': 'World'},
              ],
            })),
      );
      svc.setApiKey('k');
      final result = await svc.sendMessage(userMessage: 'hi', history: []);
      expect(result, 'Hello\nWorld');
    });

    test('ignores non-text blocks', () async {
      final svc = ClaudeService(
        client: MockClient((_) async => jsonResponse({
              'content': [
                {'type': 'text', 'text': 'OK'},
                {'type': 'tool_use', 'input': {}},
              ],
            })),
      );
      svc.setApiKey('k');
      final result = await svc.sendMessage(userMessage: 'hi', history: []);
      expect(result, 'OK');
    });

    test('trims whitespace from response', () async {
      final svc = ClaudeService(
        client: MockClient((_) async => jsonResponse({
              'content': [
                {'type': 'text', 'text': '  padded  '},
              ],
            })),
      );
      svc.setApiKey('k');
      final result = await svc.sendMessage(userMessage: 'hi', history: []);
      expect(result, 'padded');
    });

    test('throws ClaudeException on 401', () async {
      final svc = ClaudeService(
        client: MockClient((_) async => http.Response('denied', 401)),
      );
      svc.setApiKey('bad');
      expect(
        () => svc.sendMessage(userMessage: 'hi', history: []),
        throwsA(
          isA<ClaudeException>()
              .having((e) => e.message, 'message', contains('Invalid API key')),
        ),
      );
    });

    test('throws ClaudeException on 429', () async {
      final svc = ClaudeService(
        client: MockClient((_) async => http.Response('', 429)),
      );
      svc.setApiKey('k');
      expect(
        () => svc.sendMessage(userMessage: 'hi', history: []),
        throwsA(isA<ClaudeException>()),
      );
    });

    test('throws on malformed JSON', () async {
      final svc = ClaudeService(
        client: MockClient(
          (_) async => http.Response('not json', 200,
              headers: {'content-type': 'application/json'}),
        ),
      );
      svc.setApiKey('k');
      expect(
        () => svc.sendMessage(userMessage: 'hi', history: []),
        throwsA(isA<ClaudeException>()),
      );
    });

    test('throws with API error message on non-200 with error body', () async {
      final svc = ClaudeService(
        client: MockClient((_) async => jsonResponse({
              'error': {'message': 'bad request'}
            }, status: 400)),
      );
      svc.setApiKey('k');
      expect(
        () => svc.sendMessage(userMessage: 'hi', history: []),
        throwsA(isA<ClaudeException>()
            .having((e) => e.message, 'message', contains('bad request'))),
      );
    });

    test('throws on empty content array', () async {
      final svc = ClaudeService(
        client: MockClient((_) async => jsonResponse({'content': []})),
      );
      svc.setApiKey('k');
      expect(
        () => svc.sendMessage(userMessage: 'hi', history: []),
        throwsA(isA<ClaudeException>()),
      );
    });

    test('sends x-api-key and anthropic-version headers', () async {
      late http.BaseRequest capturedRequest;
      late String capturedBody;
      final svc = ClaudeService(
        client: MockClient((req) async {
          capturedRequest = req;
          capturedBody = req.body;
          return jsonResponse({
            'content': [
              {'type': 'text', 'text': 'ok'}
            ]
          });
        }),
      );
      svc.setApiKey('secret-key');
      await svc.sendMessage(userMessage: 'hi', history: []);
      expect(capturedRequest.headers['x-api-key'], 'secret-key');
      expect(capturedRequest.headers['anthropic-version'], '2023-06-01');
      expect(capturedBody, contains('claude-sonnet-4'));
    });

    test('includes history and user message in payload', () async {
      late String capturedBody;
      final svc = ClaudeService(
        client: MockClient((req) async {
          capturedBody = req.body;
          return jsonResponse({
            'content': [
              {'type': 'text', 'text': 'ok'}
            ]
          });
        }),
      );
      svc.setApiKey('k');
      await svc.sendMessage(
        userMessage: 'Question?',
        history: [
          ChatMessage(role: 'user', content: 'earlier'),
          ChatMessage(role: 'assistant', content: 'answer'),
        ],
        systemPrompt: 'You are helpful',
      );
      final decoded = json.decode(capturedBody) as Map<String, dynamic>;
      expect(decoded['messages'], hasLength(3));
      expect(decoded['messages'][0]['content'], 'earlier');
      expect(decoded['messages'][1]['content'], 'answer');
      expect(decoded['messages'][2]['content'], 'Question?');
      expect(decoded['system'], 'You are helpful');
    });

    test('omits system key when no systemPrompt', () async {
      late String capturedBody;
      final svc = ClaudeService(
        client: MockClient((req) async {
          capturedBody = req.body;
          return jsonResponse({
            'content': [
              {'type': 'text', 'text': 'ok'}
            ]
          });
        }),
      );
      svc.setApiKey('k');
      await svc.sendMessage(userMessage: 'hi', history: []);
      final decoded = json.decode(capturedBody) as Map<String, dynamic>;
      expect(decoded.containsKey('system'), isFalse);
    });
  });

  group('ChatMessage', () {
    test('stores role, content, timestamp', () {
      final now = DateTime(2026, 4, 18);
      final m = ChatMessage(role: 'user', content: 'hi', timestamp: now);
      expect(m.role, 'user');
      expect(m.content, 'hi');
      expect(m.timestamp, now);
    });
    test('defaults timestamp to now', () {
      final m = ChatMessage(role: 'user', content: 'hi');
      expect(m.timestamp, isNotNull);
    });
    test('toJson includes role, content, ISO timestamp', () {
      final m = ChatMessage(
        role: 'assistant',
        content: 'reply',
        timestamp: DateTime(2026, 4, 18),
      );
      final json = m.toJson();
      expect(json['role'], 'assistant');
      expect(json['content'], 'reply');
      expect(json['timestamp'], startsWith('2026-04-18'));
    });
  });

  group('ClaudeException', () {
    test('toString includes message', () {
      expect(ClaudeException('oops').toString(), contains('oops'));
    });
  });
}
