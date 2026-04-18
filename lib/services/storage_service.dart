import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const _settingsBox = 'settings';
  static const _anthropicApiKeyField = 'anthropic_api_key';
  static const _oddsApiKeyField = 'odds_api_key';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
  }

  static Box get _box => Hive.box(_settingsBox);

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
}
