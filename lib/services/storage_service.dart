import 'package:hive_flutter/hive_flutter.dart';

import '../models/analysis_log.dart';
import '../models/bet.dart';
import '../models/odds_snapshot.dart';
import '../models/tipster_signal.dart';

class StorageService {
  static const _settingsBox = 'settings';
  static const _analysisLogsBox = 'analysis_logs';
  static const _betsBox = 'bets';
  static const _tipsterSignalsBox = 'tipster_signals';
  static const _oddsSnapshotsBox = 'odds_snapshots';
  static const _anthropicApiKeyField = 'anthropic_api_key';
  static const _oddsApiKeyField = 'odds_api_key';
  static const _valuePresetField = 'value_preset';
  static const _bankrollField = 'bankroll_config';
  static const _telegramTokenField = 'telegram_bot_token';
  static const _monitoredChannelsField = 'monitored_channels';
  static const _telegramEnabledField = 'telegram_enabled';
  static const _watchedMatchIdsField = 'watched_match_ids';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_analysisLogsBox);
    await Hive.openBox(_betsBox);
    await Hive.openBox(_tipsterSignalsBox);
    await Hive.openBox(_oddsSnapshotsBox);
  }

  static Box get _box => Hive.box(_settingsBox);
  static Box get _logsBox => Hive.box(_analysisLogsBox);
  static Box get _betsBoxRef => Hive.box(_betsBox);
  static Box get _signalsBox => Hive.box(_tipsterSignalsBox);
  static Box get _snapshotsBox => Hive.box(_oddsSnapshotsBox);

  static String? getAnthropicApiKey() =>
      _box.get(_anthropicApiKeyField) as String?;
  static Future<void> saveAnthropicApiKey(String key) =>
      _box.put(_anthropicApiKeyField, key);
  static Future<void> deleteAnthropicApiKey() =>
      _box.delete(_anthropicApiKeyField);

  static String? getOddsApiKey() => _box.get(_oddsApiKeyField) as String?;
  static Future<void> saveOddsApiKey(String key) =>
      _box.put(_oddsApiKeyField, key);
  static Future<void> deleteOddsApiKey() => _box.delete(_oddsApiKeyField);

  static String? getValuePreset() => _box.get(_valuePresetField) as String?;
  static Future<void> saveValuePreset(String preset) =>
      _box.put(_valuePresetField, preset);

  static Future<void> saveAnalysisLog(AnalysisLog log) =>
      _logsBox.put(log.id, log.toMap());

  static List<AnalysisLog> getAllAnalysisLogs() {
    final maps = _logsBox.values.toList();
    final logs = <AnalysisLog>[];
    for (final map in maps) {
      try {
        logs.add(AnalysisLog.fromMap(map as Map<dynamic, dynamic>));
      } catch (_) {
        // skip malformed log
      }
    }
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  static Future<void> deleteAnalysisLog(String id) => _logsBox.delete(id);
  static Future<int> clearAllAnalysisLogs() => _logsBox.clear();

  static List<Bet> getAllBets() {
    final maps = _betsBoxRef.values.toList();
    final bets = <Bet>[];
    for (final map in maps) {
      try {
        bets.add(Bet.fromMap(map as Map<dynamic, dynamic>));
      } catch (_) {
        // skip malformed
      }
    }
    return bets;
  }

  static Future<void> saveBet(Bet bet) =>
      _betsBoxRef.put(bet.id, bet.toMap());
  static Future<void> deleteBet(String id) => _betsBoxRef.delete(id);

  static Map<dynamic, dynamic>? getBankrollConfig() =>
      _box.get(_bankrollField) as Map<dynamic, dynamic>?;
  static Future<void> saveBankrollConfig(Map<String, dynamic> config) =>
      _box.put(_bankrollField, config);

  static Future<void> saveSignal(TipsterSignal signal) =>
      _signalsBox.put(signal.id, signal.toMap());

  static List<TipsterSignal> getAllSignals() {
    final maps = _signalsBox.values.toList();
    final signals = <TipsterSignal>[];
    for (final map in maps) {
      try {
        signals.add(TipsterSignal.fromMap(map as Map<dynamic, dynamic>));
      } catch (_) {
        // skip malformed
      }
    }
    signals.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return signals;
  }

  static Future<int> clearOldSignals(
      {Duration keepFor = const Duration(days: 7)}) async {
    final cutoff = DateTime.now().subtract(keepFor);
    final keys = <dynamic>[];
    for (final key in _signalsBox.keys) {
      try {
        final signal = TipsterSignal.fromMap(
            _signalsBox.get(key) as Map<dynamic, dynamic>);
        if (signal.receivedAt.isBefore(cutoff)) keys.add(key);
      } catch (_) {
        keys.add(key);
      }
    }
    for (final k in keys) {
      await _signalsBox.delete(k);
    }
    return keys.length;
  }

  static String? getTelegramToken() =>
      _box.get(_telegramTokenField) as String?;
  static Future<void> saveTelegramToken(String token) =>
      _box.put(_telegramTokenField, token);
  static Future<void> deleteTelegramToken() =>
      _box.delete(_telegramTokenField);

  static List<String> getMonitoredChannels() =>
      (_box.get(_monitoredChannelsField) as List<dynamic>?)
          ?.cast<String>() ??
      const [];
  static Future<void> saveMonitoredChannels(List<String> channels) =>
      _box.put(_monitoredChannelsField, channels);

  static bool getTelegramEnabled() =>
      (_box.get(_telegramEnabledField) as bool?) ?? false;
  static Future<void> saveTelegramEnabled(bool enabled) =>
      _box.put(_telegramEnabledField, enabled);

  static Future<void> saveSnapshot(OddsSnapshot snapshot) async {
    final key =
        '${snapshot.matchId}_${snapshot.capturedAt.toIso8601String()}';
    await _snapshotsBox.put(key, snapshot.toMap());
  }

  static List<OddsSnapshot> getSnapshotsForMatch(String matchId) {
    final snapshots = <OddsSnapshot>[];
    for (final key in _snapshotsBox.keys) {
      if (key is String && key.startsWith('${matchId}_')) {
        try {
          final map = _snapshotsBox.get(key) as Map<dynamic, dynamic>;
          snapshots.add(OddsSnapshot.fromMap(map));
        } catch (_) {
          // skip malformed
        }
      }
    }
    snapshots.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return snapshots;
  }

  static Future<int> clearOldSnapshots(
      {Duration keepFor = const Duration(days: 7)}) async {
    final cutoff = DateTime.now().subtract(keepFor);
    final keysToDelete = <dynamic>[];
    for (final key in _snapshotsBox.keys) {
      try {
        final map = _snapshotsBox.get(key) as Map<dynamic, dynamic>;
        final snapshot = OddsSnapshot.fromMap(map);
        if (snapshot.capturedAt.isBefore(cutoff)) keysToDelete.add(key);
      } catch (_) {
        keysToDelete.add(key);
      }
    }
    for (final k in keysToDelete) {
      await _snapshotsBox.delete(k);
    }
    return keysToDelete.length;
  }

  static Set<String> getWatchedMatchIds() =>
      (_box.get(_watchedMatchIdsField) as List<dynamic>?)
          ?.cast<String>()
          .toSet() ??
      <String>{};
  static Future<void> saveWatchedMatchIds(Set<String> ids) =>
      _box.put(_watchedMatchIdsField, ids.toList());
}
