import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import 'bankroll.dart';
import 'bet.dart';
import 'sport.dart';
import 'sport_pl.dart';

class BetsProvider extends ChangeNotifier {
  List<Bet> _bets = [];
  BankrollConfig _bankroll = BankrollConfig.defaultConfig;
  String? _error;
  final Set<Sport> _filterSports = {};
  final Set<BetStatus> _filterStatuses = {};
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  String _searchText = '';

  BetsProvider() {
    _bets = StorageService.getAllBets();
    final bankrollMap = StorageService.getBankrollConfig();
    if (bankrollMap != null) {
      try {
        _bankroll = BankrollConfig.fromMap(bankrollMap);
      } catch (_) {
        _bankroll = BankrollConfig.defaultConfig;
      }
    }
  }

  List<Bet> get allBets => List.unmodifiable(_bets);

  List<Bet> get openBets {
    final list = _bets.where((b) => b.status == BetStatus.pending).toList()
      ..sort((a, b) => (a.matchStartedAt ?? a.placedAt)
          .compareTo(b.matchStartedAt ?? b.placedAt));
    return list;
  }

  List<Bet> get settledBets {
    final list = _bets.where((b) => b.status.isSettled).toList()
      ..sort((a, b) =>
          (b.settledAt ?? b.placedAt).compareTo(a.settledAt ?? a.placedAt));
    return list;
  }

  BankrollConfig get bankroll => _bankroll;
  String? get error => _error;

  int get totalBets => _bets.length;
  int get wonBets => _bets.where((b) => b.status == BetStatus.won).length;
  int get lostBets => _bets.where((b) => b.status == BetStatus.lost).length;
  int get voidBets => _bets.where((b) => b.status == BetStatus.void_).length;
  int get pendingBets =>
      _bets.where((b) => b.status == BetStatus.pending).length;

  double get winRate {
    final decisive = wonBets + lostBets;
    return decisive == 0 ? 0.0 : wonBets / decisive;
  }

  double get totalProfit => _bets
      .map((b) => b.actualProfit)
      .whereType<double>()
      .fold(0.0, (a, b) => a + b);

  double get totalStakedOnSettled => _bets
      .where((b) => b.status == BetStatus.won || b.status == BetStatus.lost)
      .map((b) => b.stake)
      .fold(0.0, (a, b) => a + b);

  double get roi => totalStakedOnSettled == 0
      ? 0
      : (totalProfit / totalStakedOnSettled) * 100;

  /// Breakdown P&L by sport (only sports with at least one settled bet).
  /// Used by PlSummaryWidget for per-sport tabular view.
  Map<Sport, SportPl> get perSportBreakdown {
    final result = <Sport, SportPl>{};
    for (final sport in Sport.values) {
      final sportBets =
          settledBets.where((b) => b.sport == sport).toList();
      if (sportBets.isEmpty) continue;

      final won =
          sportBets.where((b) => b.status == BetStatus.won).length;
      final lost =
          sportBets.where((b) => b.status == BetStatus.lost).length;
      final totalStake =
          sportBets.fold<double>(0, (sum, b) => sum + b.stake);
      final totalProfitSport = sportBets.fold<double>(
          0, (sum, b) => sum + (b.actualProfit ?? 0));
      final roi = totalStake > 0
          ? (totalProfitSport / totalStake) * 100
          : 0.0;

      result[sport] = SportPl(
        sport: sport,
        bets: sportBets.length,
        won: won,
        lost: lost,
        totalStake: totalStake,
        totalProfit: totalProfitSport,
        roiPercent: roi,
      );
    }
    return result;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Set<Sport> get filterSports => Set.unmodifiable(_filterSports);
  Set<BetStatus> get filterStatuses => Set.unmodifiable(_filterStatuses);
  DateTime? get filterFromDate => _filterFromDate;
  DateTime? get filterToDate => _filterToDate;
  String get searchText => _searchText;
  bool get hasActiveFilters =>
      _filterSports.isNotEmpty ||
      _filterStatuses.isNotEmpty ||
      _filterFromDate != null ||
      _filterToDate != null ||
      _searchText.isNotEmpty;

  void toggleSportFilter(Sport s) {
    if (_filterSports.contains(s)) {
      _filterSports.remove(s);
    } else {
      _filterSports.add(s);
    }
    notifyListeners();
  }

  void toggleStatusFilter(BetStatus st) {
    if (_filterStatuses.contains(st)) {
      _filterStatuses.remove(st);
    } else {
      _filterStatuses.add(st);
    }
    notifyListeners();
  }

  void setFilterDateRange(DateTime? from, DateTime? to) {
    _filterFromDate = from;
    _filterToDate = to;
    notifyListeners();
  }

  void setSearchText(String text) {
    _searchText = text.toLowerCase().trim();
    notifyListeners();
  }

  void clearFilters() {
    _filterSports.clear();
    _filterStatuses.clear();
    _filterFromDate = null;
    _filterToDate = null;
    _searchText = '';
    notifyListeners();
  }

  /// Apply active filters to a source list (already tier-filtered).
  List<Bet> applyFilters(List<Bet> source) {
    return source.where((b) {
      if (_filterSports.isNotEmpty && !_filterSports.contains(b.sport)) {
        return false;
      }
      if (_filterStatuses.isNotEmpty &&
          !_filterStatuses.contains(b.status)) {
        return false;
      }
      if (_filterFromDate != null && b.placedAt.isBefore(_filterFromDate!)) {
        return false;
      }
      if (_filterToDate != null &&
          b.placedAt.isAfter(_filterToDate!.add(const Duration(days: 1)))) {
        return false;
      }
      if (_searchText.isNotEmpty) {
        final hay = '${b.home} ${b.away} ${b.league}'.toLowerCase();
        if (!hay.contains(_searchText)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> addBet(Bet bet) async {
    _bets.add(bet);
    try {
      await StorageService.saveBet(bet);
      _error = null;
    } catch (_) {
      _error = 'Failed to save bet';
    }
    notifyListeners();
  }

  Future<void> settleBet(String id, BetStatus status) async {
    assert(status != BetStatus.pending, 'Cannot settle as pending');
    final idx = _bets.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final updated =
        _bets[idx].copyWith(status: status, settledAt: DateTime.now());
    _bets[idx] = updated;
    try {
      await StorageService.saveBet(updated);
      _error = null;
    } catch (_) {
      _error = 'Failed to settle bet';
    }
    notifyListeners();
  }

  Future<void> deleteBet(String id) async {
    _bets.removeWhere((b) => b.id == id);
    try {
      await StorageService.deleteBet(id);
      _error = null;
    } catch (_) {
      _error = 'Failed to delete bet';
    }
    notifyListeners();
  }

  Future<void> setBankroll(BankrollConfig config) async {
    _bankroll = config;
    try {
      await StorageService.saveBankrollConfig(config.toMap());
      _error = null;
    } catch (_) {
      _error = 'Failed to save bankroll';
    }
    notifyListeners();
  }
}
