import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import 'bankroll.dart';
import 'bet.dart';

class BetsProvider extends ChangeNotifier {
  List<Bet> _bets = [];
  BankrollConfig _bankroll = BankrollConfig.defaultConfig;
  String? _error;

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

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
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
