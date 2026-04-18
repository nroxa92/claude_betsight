import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ClaudeService {
  final http.Client _client;
  String _apiKey = '';

  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  static const _apiVersion = '2023-06-01';
  static const _timeout = Duration(seconds: 30);
  static const _maxTokens = 1024;

  ClaudeService({http.Client? client}) : _client = client ?? http.Client();

  bool get hasApiKey => _apiKey.isNotEmpty;
  void setApiKey(String key) => _apiKey = key;

  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
    String? systemPrompt,
  }) async {
    if (!hasApiKey) throw ClaudeException('API key not configured');

    final messages = <Map<String, dynamic>>[
      for (final msg in history) {'role': msg.role, 'content': msg.content},
      {'role': 'user', 'content': userMessage},
    ];

    final body = {
      'model': _model,
      'max_tokens': _maxTokens,
      'messages': messages,
      'system': ?systemPrompt,
    };

    try {
      final response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': _apiVersion,
            },
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 401) throw ClaudeException('Invalid API key');
      if (response.statusCode == 429) {
        throw ClaudeException('Rate limit exceeded');
      }

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw ClaudeException('Malformed response from Claude');
      }

      if (response.statusCode != 200) {
        final errorMsg = data['error']?['message'] ?? 'Unknown error';
        throw ClaudeException(errorMsg.toString());
      }

      final content = data['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) {
        throw ClaudeException('Empty response from Claude');
      }

      final textBlocks = content
          .where((b) => b is Map && b['type'] == 'text')
          .map((b) => (b as Map)['text'] as String);

      return textBlocks.join('\n').trim();
    } on TimeoutException {
      throw ClaudeException('Request timed out');
    }
  }

  void dispose() => _client.close();
}

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ClaudeException implements Exception {
  final String message;
  ClaudeException(this.message);
  @override
  String toString() => 'ClaudeException: $message';
}
