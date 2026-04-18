import 'package:hive_flutter/hive_flutter.dart';

import '../models/analysis_log.dart';

class StorageService {
  static const _settingsBox = 'settings';
  static const _analysisLogsBox = 'analysis_logs';
  static const _anthropicApiKeyField = 'anthropic_api_key';
  static const _oddsApiKeyField = 'odds_api_key';
  static const _valuePresetField = 'value_preset';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_analysisLogsBox);
  }

  static Box get _box => Hive.box(_settingsBox);
  static Box get _logsBox => Hive.box(_analysisLogsBox);

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
}
