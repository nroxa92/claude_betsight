import 'package:flutter/foundation.dart';

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
  int? get remainingRequests => _service.remainingRequests;
  bool get hasApiKey => _service.hasApiKey;
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
    if (_watchedMatchIds.contains(matchId)) {
      _watchedMatchIds.remove(matchId);
    } else {
      _watchedMatchIds.add(matchId);
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
      await StorageService.saveSnapshot(snapshot);
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

  Future<void> fetchMatches() async {
    if (!hasApiKey) {
      _error = 'API key not configured';
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
      _allMatches = await _service.getMatches(sportKeys: allKeys);
      await _captureSnapshotsForWatched();
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
