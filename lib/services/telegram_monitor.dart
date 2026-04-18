import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analysis_log.dart' show generateUuid;
import '../models/sport.dart';
import '../models/tipster_signal.dart';

class TelegramMonitor {
  final http.Client _client;
  String _botToken = '';
  int _lastUpdateId = 0;
  Timer? _pollTimer;
  void Function(TipsterSignal)? onSignalReceived;

  static const _baseUrl = 'https://api.telegram.org';
  static const _timeout = Duration(seconds: 15);
  static const _pollInterval = Duration(seconds: 10);

  static const _relevanceKeywords = [
    'tip', 'bet', 'value', 'lock', 'odds', 'pick', 'stake',
    'vs', 'home', 'away', 'draw', 'over', 'under', 'handicap',
    'epl', 'nba', 'atp', 'wta', 'champions',
  ];

  TelegramMonitor({http.Client? client}) : _client = client ?? http.Client();

  bool get hasToken => _botToken.isNotEmpty;
  bool get isMonitoring => _pollTimer?.isActive ?? false;

  void setBotToken(String token) {
    final wasMonitoring = isMonitoring;
    stopMonitoring();
    _botToken = token;
    if (wasMonitoring) startMonitoring();
  }

  void startMonitoring() {
    if (!hasToken || isMonitoring) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    _poll();
  }

  void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<Map<String, dynamic>> testConnection() async {
    if (!hasToken) throw TelegramException('Bot token not configured');
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/bot$_botToken/getMe'))
          .timeout(_timeout);
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['ok'] != true) {
        throw TelegramException(
            data['description']?.toString() ?? 'Unknown error');
      }
      return data['result'] as Map<String, dynamic>;
    } on TimeoutException {
      throw TelegramException('Request timed out');
    } on FormatException {
      throw TelegramException('Malformed response');
    }
  }

  /// One pass of long-poll-style getUpdates. Errors are swallowed because
  /// the next interval tick will retry; we don't surface transient
  /// network failures to the user.
  Future<void> _poll() async {
    if (!hasToken) return;
    try {
      final uri =
          Uri.parse('$_baseUrl/bot$_botToken/getUpdates').replace(
        queryParameters: {
          'offset': (_lastUpdateId + 1).toString(),
          'timeout': '0',
          'allowed_updates': '["channel_post","message"]',
        },
      );

      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['ok'] != true) return;

      final updates = (data['result'] as List<dynamic>?) ?? [];
      for (final update in updates) {
        final map = update as Map<String, dynamic>;
        final updateId = map['update_id'] as int;
        if (updateId > _lastUpdateId) _lastUpdateId = updateId;

        final post = map['channel_post'] ?? map['message'];
        if (post == null) continue;

        final signal = _parseUpdate(post as Map<String, dynamic>);
        if (signal != null) onSignalReceived?.call(signal);
      }
    } catch (_) {
      // Silent fail — poll will retry.
    }
  }

  TipsterSignal? _parseUpdate(Map<String, dynamic> post) {
    final text = post['text'] as String? ?? post['caption'] as String?;
    if (text == null || text.trim().isEmpty) return null;

    final messageId = post['message_id'] as int;
    final chat = post['chat'] as Map<String, dynamic>?;
    if (chat == null) return null;

    final username = chat['username'] as String?;
    final title = chat['title'] as String? ?? 'Unknown';
    if (username == null) return null;

    final lowerText = text.toLowerCase();
    final isRelevant =
        _relevanceKeywords.any((kw) => lowerText.contains(kw));
    if (!isRelevant) return null;

    Sport? detectedSport;
    String? detectedLeague;
    if (lowerText.contains('epl') || lowerText.contains('premier league')) {
      detectedSport = Sport.soccer;
      detectedLeague = 'EPL';
    } else if (lowerText.contains('champions league') ||
        lowerText.contains('ucl')) {
      detectedSport = Sport.soccer;
      detectedLeague = 'Champions League';
    } else if (lowerText.contains('nba')) {
      detectedSport = Sport.basketball;
      detectedLeague = 'NBA';
    } else if (lowerText.contains('atp') || lowerText.contains('wta')) {
      detectedSport = Sport.tennis;
    }

    return TipsterSignal(
      id: generateUuid(),
      telegramMessageId: messageId,
      channelUsername: '@$username',
      channelTitle: title,
      text: text.trim(),
      receivedAt: DateTime.now(),
      detectedSport: detectedSport,
      detectedLeague: detectedLeague,
      isRelevant: true,
    );
  }

  void dispose() {
    stopMonitoring();
    _client.close();
  }
}

class TelegramException implements Exception {
  final String message;
  TelegramException(this.message);
  @override
  String toString() => 'TelegramException: $message';
}
