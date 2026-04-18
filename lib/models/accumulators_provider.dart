import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import 'accumulator.dart';
import 'analysis_log.dart' show generateUuid;

class AccumulatorsProvider extends ChangeNotifier {
  List<BetAccumulator> _accumulators = [];
  BetAccumulator? _currentDraft;

  AccumulatorsProvider() {
    _accumulators = StorageService.getAllAccumulators();
  }

  List<BetAccumulator> get all => List.unmodifiable(_accumulators);
  BetAccumulator? get currentDraft => _currentDraft;

  List<BetAccumulator> get building => _accumulators
      .where((a) => a.status == AccumulatorStatus.building)
      .toList();
  List<BetAccumulator> get placed => _accumulators
      .where((a) => a.status == AccumulatorStatus.placed)
      .toList();
  List<BetAccumulator> get settled =>
      _accumulators.where((a) => a.status.isSettled).toList();

  void startNewDraft() {
    _currentDraft = BetAccumulator(
      id: generateUuid(),
      legs: const [],
      stake: 0,
      status: AccumulatorStatus.building,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void addLegToDraft(AccumulatorLeg leg) {
    _currentDraft ??= BetAccumulator(
      id: generateUuid(),
      legs: const [],
      stake: 0,
      status: AccumulatorStatus.building,
      createdAt: DateTime.now(),
    );
    _currentDraft = _currentDraft!.copyWith(
      legs: [..._currentDraft!.legs, leg],
    );
    notifyListeners();
  }

  void removeLegFromDraft(String matchId) {
    if (_currentDraft == null) return;
    _currentDraft = _currentDraft!.copyWith(
      legs: _currentDraft!.legs
          .where((l) => l.matchId != matchId)
          .toList(),
    );
    notifyListeners();
  }

  void setDraftStake(double stake) {
    if (_currentDraft == null) return;
    _currentDraft = _currentDraft!.copyWith(stake: stake);
    notifyListeners();
  }

  Future<void> saveDraftAsAccumulator() async {
    if (_currentDraft == null ||
        _currentDraft!.legs.length < 2 ||
        _currentDraft!.stake <= 0) {
      return;
    }
    _accumulators.add(_currentDraft!);
    await StorageService.saveAccumulator(_currentDraft!);
    _currentDraft = null;
    notifyListeners();
  }

  void discardDraft() {
    _currentDraft = null;
    notifyListeners();
  }

  Future<void> placeAccumulator(String id) async {
    final idx = _accumulators.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final updated = _accumulators[idx].copyWith(
      status: AccumulatorStatus.placed,
      placedAt: DateTime.now(),
    );
    _accumulators[idx] = updated;
    await StorageService.saveAccumulator(updated);
    notifyListeners();
  }

  Future<void> settleAccumulator(
      String id, AccumulatorStatus status) async {
    assert(status.isSettled, 'Cannot settle as building/placed');
    final idx = _accumulators.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final updated = _accumulators[idx].copyWith(
      status: status,
      settledAt: DateTime.now(),
    );
    _accumulators[idx] = updated;
    await StorageService.saveAccumulator(updated);
    notifyListeners();
  }

  Future<void> deleteAccumulator(String id) async {
    _accumulators.removeWhere((a) => a.id == id);
    await StorageService.deleteAccumulator(id);
    notifyListeners();
  }
}
