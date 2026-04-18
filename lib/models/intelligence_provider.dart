import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/intelligence_aggregator.dart';
import '../services/storage_service.dart';
import 'intelligence_report.dart';
import 'match.dart';

class IntelligenceProvider extends ChangeNotifier {
  final Map<String, IntelligenceReport> _reports = {};
  final Set<String> _generatingFor = {};
  String? _error;
  Timer? _autoRefreshTimer;
  IntelligenceAggregator? _aggregator;

  IntelligenceProvider() {
    for (final report in StorageService.getAllReports()) {
      _reports[report.matchId] = report;
    }
  }

  /// Inject aggregator after construction (called from main.dart provider).
  /// Until called, generateReport will surface a configuration error.
  void wireAggregator(IntelligenceAggregator aggregator) {
    _aggregator = aggregator;
  }

  IntelligenceReport? reportFor(String matchId) => _reports[matchId];
  bool isGeneratingFor(String matchId) => _generatingFor.contains(matchId);

  List<IntelligenceReport> get allReports {
    final list = _reports.values.toList()
      ..sort((a, b) => b.confluenceScore.compareTo(a.confluenceScore));
    return list;
  }

  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> generateReport(Match match, {bool force = false}) async {
    if (_generatingFor.contains(match.id)) return;

    if (!force) {
      final existing = _reports[match.id];
      if (existing != null && !existing.isExpired(const Duration(hours: 1))) {
        return;
      }
    }

    final aggregator = _aggregator;
    if (aggregator == null) {
      _error = 'Intelligence aggregator not configured';
      notifyListeners();
      return;
    }

    _generatingFor.add(match.id);
    notifyListeners();

    try {
      final report = await aggregator.buildReport(match);
      _reports[match.id] = report;
      await StorageService.saveReport(report);
      _error = null;
    } catch (e) {
      _error = 'Intelligence report failed: $e';
    } finally {
      _generatingFor.remove(match.id);
      notifyListeners();
    }
  }

  Future<void> refreshAllWatched(List<Match> watchedMatches,
      {bool force = false}) async {
    final futures = watchedMatches.map((m) => generateReport(m, force: force));
    await Future.wait(futures);
  }

  void startAutoRefresh(List<Match> Function() watchedProvider) {
    stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      final watched = watchedProvider();
      if (watched.isNotEmpty) {
        await refreshAllWatched(watched, force: true);
      }
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> removeReportFor(String matchId) async {
    _reports.remove(matchId);
    await StorageService.deleteReport(matchId);
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
