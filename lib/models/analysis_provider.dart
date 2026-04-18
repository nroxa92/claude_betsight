import 'package:flutter/foundation.dart';

import '../services/claude_service.dart';
import '../services/notifications_service.dart';
import '../services/storage_service.dart';
import 'analysis_log.dart';
import 'bet.dart';
import 'intelligence_report.dart';
import 'investment_tier.dart';
import 'match.dart';
import 'odds_snapshot.dart';
import 'recommendation.dart';
import 'sport.dart';
import 'tipster_signal.dart';

class AnalysisProvider extends ChangeNotifier {
  final ClaudeService _service;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  List<Match> _stagedMatches = [];
  List<TipsterSignal> _stagedSignals = [];
  String? _lastLogId;
  String? _inputPrefill;
  InvestmentTier _currentTier = InvestmentTier.preMatch;

  void setCurrentTier(InvestmentTier tier) {
    _currentTier = tier;
  }

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

  String? get lastLogId => _lastLogId;
  String? get inputPrefill => _inputPrefill;

  void setInputPrefill(String text) {
    _inputPrefill = text;
    notifyListeners();
  }

  void clearInputPrefill() {
    if (_inputPrefill == null) return;
    _inputPrefill = null;
    notifyListeners();
  }

  Future<void> recordFeedback(String logId, UserFeedback feedback) async {
    await StorageService.updateAnalysisLogFeedback(logId, feedback);
  }

  static const _systemPrompt = '''
You are BetSight AI, a specialized sports betting intelligence assistant.
You help the user find value bets across soccer, basketball, and tennis by combining match context, real odds, tipster signals, and the user's betting history.

## User profile

The user is an experienced bettor and technical analyst. Do not explain basic concepts (implied probability, bookmaker margin, Asian handicap, spread, over/under) — use them directly. The user pastes match data, odds, and sometimes tipster signals in structured context blocks. Read them carefully before answering.

## Objective 1 — Odds analysis

For every match you analyze:
1. Calculate implied probability for each outcome: `p = 1 / decimal_odds`
2. Sum them — if total > 1.0, the excess is the bookmaker margin (e.g., 1.07 total = 7% margin)
3. Flag if margin > 8% (soft book, worse value across the board)
4. Identify which outcome is most mispriced — this is the candidate for value

If the user provides odds drift data in `[ODDS DRIFT]` block, interpret significant moves (>3%) as smart money signal toward the outcome with falling odds.

## Objective 2 — Match context

Use the user-provided `[SELECTED MATCHES]` block as primary context. If recent form, head-to-head, injuries, or weather data is available (either in the block or from your training knowledge on well-known leagues/teams), incorporate it. For tennis, consider surface and recent rankings. For basketball, consider pace and rest days.

If the user provides `[TIPSTER SIGNALS]` block, treat these as third-party opinions — not facts. Note which channels flagged this match and which outcomes they favored, but do not auto-trust.

If the user provides `[BETTING HISTORY]` block, notice patterns: is this the fifth time the user bets Arsenal this week? Flag potential confirmation bias politely.

## Objective 3 — Recommendation

Every response MUST end with exactly one of these three markers on its own line:

**VALUE** — clear edge detected. You MUST specify:
  - WHICH outcome (Home / Draw / Away / specific player / Over X.X / etc.)
  - At WHICH odds (the current odds from context)
  - Your estimated probability vs implied probability (at least 3 percentage points edge)
  - A concrete next step (e.g., "stake 2% of bankroll", "wait for odds to rise above 2.10")

**WATCH** — interesting spot but edge is marginal, data incomplete, or close to kickoff without confirmation. The user should monitor, not bet yet.

**SKIP** — no edge, fair odds, or too uncertain.

Never combine markers. Never skip the marker. The marker goes on its own line as the last line.

## Constraints

- This is pattern analysis and informational research, not financial advice.
- Never suggest loan-based betting, chasing losses, or increasing stakes after a loss.
- Respect the user's bankroll if provided — suggest stakes as percentage, not absolute amounts.
- If data is genuinely insufficient to form a view, say SKIP with reason — do not fabricate analysis.

## Language

Respond in the language the user uses (English, Croatian, or other). Internal reasoning is always in English for consistency. Sport terminology stays in English even in Croatian responses (e.g., "Asian handicap", "over/under", "moneyline").
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
    String text, {
    List<Match>? contextMatches,
    List<TipsterSignal>? contextSignals,
    List<Bet>? bettingHistory,
    Map<String, OddsDrift>? driftByMatchId,
    Map<String, IntelligenceReport>? intelligenceReports,
  }) {
    final hasMatches = contextMatches != null && contextMatches.isNotEmpty;
    final hasSignals = contextSignals != null && contextSignals.isNotEmpty;
    final hasHistory = bettingHistory != null && bettingHistory.isNotEmpty;
    final hasIntel =
        intelligenceReports != null && intelligenceReports.isNotEmpty;
    // Tier appendix is always emitted, so the early-return that used to
    // skip the buffer when no other context was available is gone.
    final _ = hasMatches || hasSignals || hasHistory || hasIntel;

    final buf = StringBuffer();
    if (hasMatches) {
      buf.writeln('[SELECTED MATCHES]');
      for (final m in contextMatches) {
        final h2h = m.h2h;
        final oddsStr = h2h == null
            ? 'odds unavailable'
            : h2h.draw == null
                ? 'odds H/A: ${h2h.home.toStringAsFixed(2)}/${h2h.away.toStringAsFixed(2)}'
                : 'odds H/D/A: ${h2h.home.toStringAsFixed(2)}/${h2h.draw!.toStringAsFixed(2)}/${h2h.away.toStringAsFixed(2)}';
        final bookmaker = h2h?.bookmaker ?? 'unknown';
        buf.writeln(
          '${m.league}: ${m.home} vs ${m.away} | '
          'kickoff ${m.commenceTime.toIso8601String()} | '
          '$oddsStr | bookmaker $bookmaker',
        );
        final drift = driftByMatchId?[m.id];
        if (drift != null && drift.hasSignificantMove) {
          final dom = drift.dominantDrift;
          final sign = dom.percent > 0 ? '+' : '';
          buf.writeln(
            '  [drift] ${dom.side} $sign${dom.percent.toStringAsFixed(1)}% since last snapshot',
          );
        }
      }
      buf.writeln('[/SELECTED MATCHES]');
      buf.writeln();
    }
    if (hasIntel) {
      for (final report in intelligenceReports.values) {
        buf.writeln(report.toClaudeContext());
        buf.writeln();
      }
    }
    if (hasSignals) {
      buf.writeln('[TIPSTER SIGNALS]');
      for (final s in contextSignals) {
        buf.writeln(s.toClaudeContext());
      }
      buf.writeln('[/TIPSTER SIGNALS]');
      buf.writeln();
    }
    if (hasHistory) {
      buf.writeln('[BETTING HISTORY — last ${bettingHistory.length} bets]');
      for (final bet in bettingHistory) {
        final outcome = bet.actualProfit;
        final outcomeStr = outcome == null
            ? 'pending'
            : outcome > 0
                ? 'won +${outcome.toStringAsFixed(2)}'
                : outcome < 0
                    ? 'lost ${outcome.toStringAsFixed(2)}'
                    : 'void';
        buf.writeln(
          '${bet.placedAt.toIso8601String().substring(0, 10)} | '
          '${bet.sport.display} | ${bet.home} vs ${bet.away} | '
          '${bet.selection.display} @ ${bet.odds.toStringAsFixed(2)} | '
          'stake ${bet.stake.toStringAsFixed(2)} | $outcomeStr',
        );
      }
      buf.writeln('[/BETTING HISTORY]');
      buf.writeln();
    }
    buf.writeln(_currentTier.claudeContextAppendix);
    buf.writeln();
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

    List<Bet>? history;
    try {
      final all = StorageService.getAllBets()
        ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
      if (all.isNotEmpty) history = all.take(5).toList();
    } catch (_) {
      history = null;
    }

    Map<String, OddsDrift>? drifts;
    Map<String, IntelligenceReport>? intelReports;
    if (effectiveContext != null) {
      final m = <String, OddsDrift>{};
      final reports = <String, IntelligenceReport>{};
      for (final match in effectiveContext) {
        final snapshots =
            StorageService.getSnapshotsForMatch(match.id);
        if (snapshots.length >= 2) {
          m[match.id] =
              OddsDrift.compute(snapshots.first, snapshots.last);
        }
        final report = StorageService.getReport(match.id);
        if (report != null) reports[match.id] = report;
      }
      if (m.isNotEmpty) drifts = m;
      if (reports.isNotEmpty) intelReports = reports;
    }

    final userContent = _buildUserMessage(
      trimmed,
      contextMatches: effectiveContext,
      contextSignals: effectiveSignals,
      bettingHistory: history,
      driftByMatchId: drifts,
      intelligenceReports: intelReports,
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
        final recType = parseRecommendationType(reply);
        final log = AnalysisLog(
          id: generateUuid(),
          timestamp: DateTime.now(),
          userMessage: trimmed,
          assistantResponse: reply,
          contextMatchIds:
              effectiveContext?.map((m) => m.id).toList() ?? const [],
          recommendationType: recType,
        );
        _lastLogId = log.id;
        await StorageService.saveAnalysisLog(log);

        if (recType == RecommendationType.value &&
            effectiveContext != null &&
            effectiveContext.isNotEmpty) {
          try {
            await NotificationsService.showValueAlert(
                effectiveContext.first);
          } catch (_) {
            // notification failure must not block UX
          }
        }
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
