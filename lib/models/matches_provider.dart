import 'package:flutter/foundation.dart';

import '../services/notifications_service.dart';
import '../services/odds_api_service.dart';
import '../services/storage_service.dart';
import 'match.dart';
import 'odds_snapshot.dart';
import 'sport.dart';
import 'value_preset.dart';

class MatchesProvider extends ChangeNotifier {
  final OddsApiService _service;
  List<Match> _allMatches = [];
  Sport? _selectedSport;
  bool _isLoading = false;
  String? _error;
  ValuePreset _valuePreset = ValuePreset.standard;
  final Set<String> _selectedMatchIds = {};
  Set<String> _watchedMatchIds = {};
  bool _fromCache = false;
  DateTime? _cachedAt;
  int? _remainingRequests;

  MatchesProvider({OddsApiService? service})
      : _service = service ?? OddsApiService() {
    final key = StorageService.getOddsApiKey();
    if (key != null && key.isNotEmpty) _service.setApiKey(key);
    _valuePreset = ValuePreset.fromString(StorageService.getValuePreset());
    _watchedMatchIds = StorageService.getWatchedMatchIds();
  }

  List<Match> get allMatches => List.unmodifiable(_allMatches);

  List<Match> get filteredMatches => _selectedSport == null
      ? List.unmodifiable(_allMatches)
      : List.unmodifiable(
          _allMatches.where((m) => m.sport == _selectedSport),
        );

  Sport? get selectedSport => _selectedSport;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get remainingRequests =>
      _remainingRequests ?? _service.remainingRequests;
  bool get hasApiKey => _service.hasApiKey;
  bool get fromCache => _fromCache;
  DateTime? get cachedAt => _cachedAt;

  /// Free tier monthly cap for The Odds API. Used to compute progress / %.
  static const apiMonthlyCap = 500;

  /// null until first API call lands.
  double? get requestsUsedPercent {
    if (remainingRequests == null) return null;
    final used = apiMonthlyCap - remainingRequests!;
    return (used / apiMonthlyCap) * 100;
  }

  bool get isApiLimitLow =>
      remainingRequests != null && remainingRequests! < 20;
  bool get isApiLimitCritical =>
      remainingRequests != null && remainingRequests! < 1;
  ValuePreset get valuePreset => _valuePreset;

  List<Match> get valueBets {
    final matches =
        filteredMatches.where((m) => _valuePreset.matches(m)).toList();
    matches.sort(
      (a, b) => _valuePreset.edgeScore(b).compareTo(_valuePreset.edgeScore(a)),
    );
    return matches;
  }

  Future<void> setValuePreset(ValuePreset preset) async {
    _valuePreset = preset;
    await StorageService.saveValuePreset(preset.name);
    notifyListeners();
  }

  Set<String> get selectedMatchIds => Set.unmodifiable(_selectedMatchIds);
  int get selectedCount => _selectedMatchIds.length;
  bool isMatchSelected(String matchId) =>
      _selectedMatchIds.contains(matchId);
  List<Match> get selectedMatches =>
      _allMatches.where((m) => _selectedMatchIds.contains(m.id)).toList();

  void toggleMatchSelection(String matchId) {
    if (_selectedMatchIds.contains(matchId)) {
      _selectedMatchIds.remove(matchId);
    } else {
      _selectedMatchIds.add(matchId);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedMatchIds.isEmpty) return;
    _selectedMatchIds.clear();
    notifyListeners();
  }

  Set<String> get watchedMatchIds => Set.unmodifiable(_watchedMatchIds);
  bool isWatched(String matchId) => _watchedMatchIds.contains(matchId);

  Future<void> toggleWatched(String matchId) async {
    final wasWatched = _watchedMatchIds.contains(matchId);
    if (wasWatched) {
      _watchedMatchIds.remove(matchId);
      await NotificationsService.cancelKickoffReminders(matchId);
    } else {
      _watchedMatchIds.add(matchId);
      try {
        final match = _allMatches.firstWhere((m) => m.id == matchId);
        await NotificationsService.scheduleKickoffReminders(match);
      } catch (_) {
        // match not in current list — schedule deferred (no-op for now)
      }
    }
    await StorageService.saveWatchedMatchIds(_watchedMatchIds);
    notifyListeners();
  }

  OddsDrift? driftForMatch(String matchId) {
    final snapshots = StorageService.getSnapshotsForMatch(matchId);
    if (snapshots.length < 2) return null;
    return OddsDrift.compute(snapshots.first, snapshots.last);
  }

  Future<void> _captureSnapshotsForWatched() async {
    var saved = 0;
    var skipped = 0;
    for (final match in _allMatches) {
      if (!_watchedMatchIds.contains(match.id)) continue;
      final h2h = match.h2h;
      if (h2h == null) continue;

      final snapshot = OddsSnapshot(
        matchId: match.id,
        capturedAt: DateTime.now(),
        home: h2h.home,
        draw: h2h.draw,
        away: h2h.away,
        bookmaker: h2h.bookmaker,
      );
      final didSave =
          await StorageService.saveSnapshotIfChanged(snapshot);
      if (didSave) {
        saved++;
        final drift = driftForMatch(match.id);
        if (drift != null && drift.hasSignificantMove) {
          final dominantAbs = drift.dominantDrift.percent.abs();
          if (dominantAbs >= 5) {
            try {
              await NotificationsService.showDriftAlert(match, drift);
            } catch (_) {
              // notification failure must not break capture loop
            }
          }
        }
      } else {
        skipped++;
      }
    }
    if (saved > 0 || skipped > 0) {
      debugPrint('Snapshots: saved $saved, skipped (unchanged) $skipped');
    }
  }

  void setSelectedSport(Sport? sport) {
    _selectedSport = sport;
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _service.setApiKey(key);
    await StorageService.saveOddsApiKey(key);
    notifyListeners();
  }

  Future<void> removeApiKey() async {
    _service.setApiKey('');
    await StorageService.deleteOddsApiKey();
    _allMatches = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchMatches({bool forceRefresh = false}) async {
    if (!hasApiKey) {
      _error = 'API key not configured';
      notifyListeners();
      return;
    }

    if (isApiLimitCritical && !forceRefresh) {
      final cached = StorageService.getCachedMatches();
      if (cached != null) {
        _allMatches = cached.matches;
        _fromCache = true;
        _cachedAt = cached.fetchedAt;
        _error = null;
        notifyListeners();
        return;
      }
      _error = 'Monthly API quota exhausted. Resets on 1st of month.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final allKeys = <String>[
      ...Sport.soccer.defaultSportKeys,
      ...Sport.basketball.defaultSportKeys,
      ...Sport.tennis.defaultSportKeys,
    ];

    try {
      final result = await _service.getMatchesCached(
        sportKeys: allKeys,
        forceRefresh: forceRefresh,
      );
      _allMatches = result.matches;
      _fromCache = result.fromCache;
      _cachedAt = result.cachedAt;
      _remainingRequests = result.remaining;

      if (!_fromCache) {
        await _captureSnapshotsForWatched();
      }
    } on OddsApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load matches';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
