import 'package:flutter/foundation.dart';

import '../services/claude_service.dart';
import '../services/storage_service.dart';
import 'analysis_log.dart';
import 'match.dart';
import 'recommendation.dart';
import 'tipster_signal.dart';

class AnalysisProvider extends ChangeNotifier {
  final ClaudeService _service;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  List<Match> _stagedMatches = [];
  List<TipsterSignal> _stagedSignals = [];

  AnalysisProvider({ClaudeService? service})
      : _service = service ?? ClaudeService() {
    final key = StorageService.getAnthropicApiKey();
    if (key != null && key.isNotEmpty) _service.setApiKey(key);
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasApiKey => _service.hasApiKey;
  List<Match> get stagedMatches => List.unmodifiable(_stagedMatches);
  bool get hasStagedMatches => _stagedMatches.isNotEmpty;

  void stageSelectedMatches(List<Match> matches) {
    _stagedMatches = List.from(matches);
    notifyListeners();
  }

  void clearStagedMatches() {
    if (_stagedMatches.isEmpty) return;
    _stagedMatches = [];
    notifyListeners();
  }

  List<TipsterSignal> get stagedSignals => List.unmodifiable(_stagedSignals);
  bool get hasStagedSignals => _stagedSignals.isNotEmpty;

  void stageSelectedSignals(List<TipsterSignal> signals) {
    _stagedSignals = List.from(signals);
    notifyListeners();
  }

  void clearStagedSignals() {
    if (_stagedSignals.isEmpty) return;
    _stagedSignals = [];
    notifyListeners();
  }

  static const _systemPrompt = '''
You are BetSight AI, a sports betting intelligence assistant.
Your job is to analyze matches, odds, and betting value across soccer, basketball, and tennis.

## Analysis method

When match context is provided, calculate implied probability from decimal odds (probability = 1/odds) for each outcome.
Compare implied probability to your own estimate based on team form, head-to-head history, injuries, and recent news you may know about.
A match has value when your estimate exceeds implied probability by a meaningful margin (at least 3 percentage points).

Always mention bookmaker margin if it exceeds 8 percent (sign of a soft book).
Always mention which specific outcome (home/draw/away) looks like value, not just "the match".

## Output format

Every response MUST end with exactly one of these three markers on its own line:

**VALUE** — clear edge detected on a specific outcome, recommend a bet
**WATCH** — interesting spot but edge is marginal or data is incomplete, monitor only
**SKIP** — no edge, fair odds, or too uncertain

Never combine markers. Never skip the marker. The marker must be on its own line as the last line of your response.

## Constraints

This is informational analysis, not financial advice. Users must do their own research and gamble responsibly.
Never suggest loan-based betting, chasing losses, or increasing stakes after a loss.
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

  String _buildUserMessage(
    String text,
    List<Match>? contextMatches,
    List<TipsterSignal>? contextSignals,
  ) {
    final hasMatches = contextMatches != null && contextMatches.isNotEmpty;
    final hasSignals = contextSignals != null && contextSignals.isNotEmpty;
    if (!hasMatches && !hasSignals) return text;

    final buf = StringBuffer();
    if (hasMatches) {
      buf.writeln('[SELECTED MATCHES]');
      for (final m in contextMatches) {
        final h = m.h2h?.home.toStringAsFixed(2) ?? '-';
        final d = m.h2h?.draw?.toStringAsFixed(2) ?? '-';
        final a = m.h2h?.away.toStringAsFixed(2) ?? '-';
        buf.writeln(
          '${m.league}: ${m.home} vs ${m.away} | odds $h-$d-$a | kickoff ${m.commenceTime.toIso8601String()}',
        );
      }
      buf.writeln();
    }
    if (hasSignals) {
      buf.writeln('[TIPSTER SIGNALS]');
      for (final s in contextSignals) {
        buf.writeln(s.toClaudeContext());
      }
      buf.writeln('[/TIPSTER SIGNALS]');
      buf.writeln();
    }
    buf.write(text);
    return buf.toString();
  }

  Future<void> sendMessage(String text, {List<Match>? contextMatches}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final effectiveContext = contextMatches ??
        (_stagedMatches.isNotEmpty ? _stagedMatches : null);
    final usedStaged = contextMatches == null && _stagedMatches.isNotEmpty;
    final effectiveSignals =
        _stagedSignals.isNotEmpty ? _stagedSignals : null;

    final userContent = _buildUserMessage(
      trimmed,
      effectiveContext,
      effectiveSignals,
    );
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

      try {
        final log = AnalysisLog(
          id: generateUuid(),
          timestamp: DateTime.now(),
          userMessage: trimmed,
          assistantResponse: reply,
          contextMatchIds:
              effectiveContext?.map((m) => m.id).toList() ?? const [],
          recommendationType: parseRecommendationType(reply),
        );
        await StorageService.saveAnalysisLog(log);
      } catch (e) {
        debugPrint('Failed to save analysis log: $e');
      }

      if (usedStaged) {
        _stagedMatches = [];
      }
      if (effectiveSignals != null) {
        _stagedSignals = [];
      }
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
