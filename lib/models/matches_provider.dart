import 'package:flutter/foundation.dart';

import '../services/odds_api_service.dart';
import '../services/storage_service.dart';
import 'match.dart';
import 'sport.dart';

class MatchesProvider extends ChangeNotifier {
  final OddsApiService _service;
  List<Match> _allMatches = [];
  Sport? _selectedSport;
  bool _isLoading = false;
  String? _error;

  MatchesProvider({OddsApiService? service})
      : _service = service ?? OddsApiService() {
    final key = StorageService.getOddsApiKey();
    if (key != null && key.isNotEmpty) _service.setApiKey(key);
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
