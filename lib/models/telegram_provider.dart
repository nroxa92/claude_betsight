import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import '../services/telegram_monitor.dart';
import 'monitored_channel.dart';
import 'sport.dart';
import 'tipster_signal.dart';

class TelegramProvider extends ChangeNotifier {
  final TelegramMonitor _monitor;
  List<TipsterSignal> _signals = [];
  List<MonitoredChannel> _channels = [];
  bool _enabled = false;
  String? _error;

  TelegramProvider({TelegramMonitor? monitor})
      : _monitor = monitor ?? TelegramMonitor() {
    _monitor.onSignalReceived = _handleNewSignal;

    _signals = StorageService.getAllSignals();
    _enabled = StorageService.getTelegramEnabled();
    _bootstrapChannels();

    final token = StorageService.getTelegramToken();
    if (token != null && token.isNotEmpty) {
      _monitor.setBotToken(token);
      if (_enabled) _monitor.startMonitoring();
    }
  }

  Future<void> _bootstrapChannels() async {
    try {
      await StorageService.migrateMonitoredChannels();
    } catch (_) {
      // best-effort migration
    }
    _channels = StorageService.getAllMonitoredChannels();
    notifyListeners();
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

  List<MonitoredChannel> get channels => List.unmodifiable(_channels);
  List<String> get channelUsernames =>
      _channels.map((c) => c.username).toList();
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

  Future<void> addChannel(String username) async {
    final clean = username.trim();
    if (clean.isEmpty || _channels.any((c) => c.username == clean)) return;
    final channel =
        MonitoredChannel(username: clean, addedAt: DateTime.now());
    _channels = [..._channels, channel];
    await StorageService.saveMonitoredChannel(channel);
    notifyListeners();
  }

  Future<void> removeChannel(String username) async {
    _channels = _channels.where((c) => c.username != username).toList();
    await StorageService.deleteMonitoredChannel(username);
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

    final now = DateTime.now();
    final idx =
        _channels.indexWhere((c) => c.username == signal.channelUsername);
    if (idx != -1) {
      final old = _channels[idx];
      final updated = old.copyWith(
        title: old.title ?? signal.channelTitle,
        signalsReceived: old.signalsReceived + 1,
        signalsRelevant:
            old.signalsRelevant + (signal.isRelevant ? 1 : 0),
        lastSignalAt: now,
        lastRelevantAt: signal.isRelevant ? now : old.lastRelevantAt,
      );
      _channels[idx] = updated;
      StorageService.saveMonitoredChannel(updated);
    }

    if (_channels.isNotEmpty && idx == -1) return;
    if (!signal.isRelevant) {
      if (idx != -1) notifyListeners();
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
