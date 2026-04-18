import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import '../services/telegram_monitor.dart';
import 'sport.dart';
import 'tipster_signal.dart';

class TelegramProvider extends ChangeNotifier {
  final TelegramMonitor _monitor;
  List<TipsterSignal> _signals = [];
  List<String> _monitoredChannels = [];
  bool _enabled = false;
  String? _error;

  TelegramProvider({TelegramMonitor? monitor})
      : _monitor = monitor ?? TelegramMonitor() {
    _monitor.onSignalReceived = _handleNewSignal;

    _signals = StorageService.getAllSignals();
    _monitoredChannels = StorageService.getMonitoredChannels();
    _enabled = StorageService.getTelegramEnabled();

    final token = StorageService.getTelegramToken();
    if (token != null && token.isNotEmpty) {
      _monitor.setBotToken(token);
      if (_enabled) _monitor.startMonitoring();
    }
  }

  List<TipsterSignal> get signals => List.unmodifiable(_signals);

  List<TipsterSignal> get recentSignals {
    final sixHoursAgo = DateTime.now().subtract(const Duration(hours: 6));
    return _signals.where((s) => s.receivedAt.isAfter(sixHoursAgo)).toList();
  }

  List<TipsterSignal> signalsForSport(Sport? sport) {
    if (sport == null) return recentSignals;
    return recentSignals.where((s) => s.detectedSport == sport).toList();
  }

  List<String> get monitoredChannels => List.unmodifiable(_monitoredChannels);
  bool get enabled => _enabled;
  bool get hasToken => _monitor.hasToken;
  bool get isMonitoring => _monitor.isMonitoring;
  String? get error => _error;
  int get recentCount => recentSignals.length;

  Future<void> setBotToken(String token) async {
    _monitor.setBotToken(token);
    await StorageService.saveTelegramToken(token);
    notifyListeners();
  }

  Future<void> removeBotToken() async {
    _monitor.stopMonitoring();
    _monitor.setBotToken('');
    await StorageService.deleteTelegramToken();
    await setEnabled(false);
    notifyListeners();
  }

  Future<void> addChannel(String channel) async {
    final clean = channel.trim();
    if (clean.isEmpty || _monitoredChannels.contains(clean)) return;
    _monitoredChannels = [..._monitoredChannels, clean];
    await StorageService.saveMonitoredChannels(_monitoredChannels);
    notifyListeners();
  }

  Future<void> removeChannel(String channel) async {
    _monitoredChannels =
        _monitoredChannels.where((c) => c != channel).toList();
    await StorageService.saveMonitoredChannels(_monitoredChannels);
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await StorageService.saveTelegramEnabled(enabled);
    if (enabled && hasToken) {
      _monitor.startMonitoring();
    } else {
      _monitor.stopMonitoring();
    }
    notifyListeners();
  }

  Future<String> testConnection() async {
    try {
      final info = await _monitor.testConnection();
      final botName = info['username'] ?? info['first_name'] ?? 'Bot';
      _error = null;
      notifyListeners();
      return '@$botName';
    } catch (e) {
      _error = e is TelegramException ? e.message : 'Connection failed';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearOldSignals() async {
    await StorageService.clearOldSignals();
    _signals = StorageService.getAllSignals();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _handleNewSignal(TipsterSignal signal) {
    final exists = _signals.any((s) =>
        s.telegramMessageId == signal.telegramMessageId &&
        s.channelUsername == signal.channelUsername);
    if (exists) return;

    if (_monitoredChannels.isNotEmpty &&
        !_monitoredChannels.contains(signal.channelUsername)) {
      return;
    }

    _signals = [signal, ..._signals];
    StorageService.saveSignal(signal);
    notifyListeners();
  }

  @override
  void dispose() {
    _monitor.dispose();
    super.dispose();
  }
}
