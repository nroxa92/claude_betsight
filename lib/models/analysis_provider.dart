import 'package:flutter/foundation.dart';

import '../services/claude_service.dart';
import '../services/storage_service.dart';
import 'match.dart';

class AnalysisProvider extends ChangeNotifier {
  final ClaudeService _service;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  AnalysisProvider({ClaudeService? service})
      : _service = service ?? ClaudeService() {
    final key = StorageService.getAnthropicApiKey();
    if (key != null && key.isNotEmpty) _service.setApiKey(key);
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasApiKey => _service.hasApiKey;

  static const _systemPrompt = '''
You are BetSight AI, a sports betting intelligence assistant.
Your job is to help users analyze matches, odds, and betting value
across soccer, basketball, and tennis.

Guidelines:
- When match context is provided, use it directly in your analysis.
- Calculate implied probability from decimal odds (1/odds) and compare to your own estimate.
- Flag value bets where your estimate exceeds implied probability by a meaningful margin.
- Use structured recommendation labels: **VALUE**, **WATCH**, **SKIP**.
- Always mention bookmaker margin if it's unusually high (>8%).
- This is not financial advice. Users must DYOR and gamble responsibly.
''';

  Future<void> setApiKey(String key) async {
    _service.setApiKey(key);
    await StorageService.saveAnthropicApiKey(key);
    notifyListeners();
  }

  Future<void> removeApiKey() async {
    _service.setApiKey('');
    await StorageService.deleteAnthropicApiKey();
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _buildUserMessage(String text, List<Match>? contextMatches) {
    if (contextMatches == null || contextMatches.isEmpty) return text;

    final buf = StringBuffer('[SELECTED MATCHES]\n');
    for (final m in contextMatches) {
      final h = m.h2h?.home.toStringAsFixed(2) ?? '-';
      final d = m.h2h?.draw?.toStringAsFixed(2) ?? '-';
      final a = m.h2h?.away.toStringAsFixed(2) ?? '-';
      buf.writeln(
        '${m.league}: ${m.home} vs ${m.away} | odds $h-$d-$a | kickoff ${m.commenceTime.toIso8601String()}',
      );
    }
    buf.writeln();
    buf.write(text);
    return buf.toString();
  }

  Future<void> sendMessage(String text, {List<Match>? contextMatches}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userContent = _buildUserMessage(trimmed, contextMatches);
    final userMessage = ChatMessage(role: 'user', content: userContent);
    _messages.add(userMessage);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final history = _messages.sublist(0, _messages.length - 1);
      final reply = await _service.sendMessage(
        userMessage: userContent,
        history: history,
        systemPrompt: _systemPrompt,
      );
      _messages.add(ChatMessage(role: 'assistant', content: reply));
    } on ClaudeException catch (e) {
      _messages.removeLast();
      _error = e.message;
    } catch (_) {
      _messages.removeLast();
      _error = 'Failed to send message';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
