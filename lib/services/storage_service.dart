import 'package:hive_flutter/hive_flutter.dart';

import '../models/analysis_log.dart';
import '../models/bet.dart';
import '../models/cached_matches_entry.dart';
import '../models/football_data_signal.dart';
import '../models/intelligence_report.dart';
import '../models/monitored_channel.dart';
import '../models/nba_stats_signal.dart';
import '../models/odds_snapshot.dart';
import '../models/recommendation.dart';
import '../models/reddit_signal.dart';
import '../models/tipster_signal.dart';

class StorageService {
  static const _settingsBox = 'settings';
  static const _analysisLogsBox = 'analysis_logs';
  static const _betsBox = 'bets';
  static const _tipsterSignalsBox = 'tipster_signals';
  static const _oddsSnapshotsBox = 'odds_snapshots';
  static const _oddsCacheBox = 'odds_cache';
  static const _channelsDetailBox = 'monitored_channels_detail';
  static const _intelligenceReportsBox = 'intelligence_reports';
  static const _footballSignalsBox = 'football_signals_cache';
  static const _nbaSignalsBox = 'nba_signals_cache';
  static const _redditSignalsBox = 'reddit_signals_cache';
  static const _footballDataApiKeyField = 'football_data_api_key';
  static const _cacheEntryKey = 'all_matches';
  static const _cacheTtlMinutesField = 'cache_ttl_minutes';
  static const _lastCleanupField = 'last_cleanup_at';
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
    await Hive.openBox(_oddsCacheBox);
    await Hive.openBox(_channelsDetailBox);
    await Hive.openBox(_intelligenceReportsBox);
    await Hive.openBox(_footballSignalsBox);
    await Hive.openBox(_nbaSignalsBox);
    await Hive.openBox(_redditSignalsBox);
  }

  static Box get _box => Hive.box(_settingsBox);
  static Box get _logsBox => Hive.box(_analysisLogsBox);
  static Box get _betsBoxRef => Hive.box(_betsBox);
  static Box get _signalsBox => Hive.box(_tipsterSignalsBox);
  static Box get _snapshotsBox => Hive.box(_oddsSnapshotsBox);
  static Box get _cacheBox => Hive.box(_oddsCacheBox);
  static Box get _channelsBox => Hive.box(_channelsDetailBox);
  static Box get _reportsBox => Hive.box(_intelligenceReportsBox);
  static Box get _footballBox => Hive.box(_footballSignalsBox);
  static Box get _nbaBox => Hive.box(_nbaSignalsBox);
  static Box get _redditBox => Hive.box(_redditSignalsBox);

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

  static Future<void> updateAnalysisLogFeedback(
      String logId, UserFeedback feedback) async {
    final map = _logsBox.get(logId) as Map<dynamic, dynamic>?;
    if (map == null) return;
    final log = AnalysisLog.fromMap(map);
    final updated = log.copyWith(
      userFeedback: feedback,
      feedbackAt: DateTime.now(),
    );
    await saveAnalysisLog(updated);
  }

  static List<AnalysisLog> getLogsByRecommendation(RecommendationType type) {
    return getAllAnalysisLogs()
        .where((l) => l.recommendationType == type)
        .toList();
  }

  static Map<RecommendationType, Map<UserFeedback, int>> getFeedbackStats() {
    final stats = <RecommendationType, Map<UserFeedback, int>>{};
    for (final log in getAllAnalysisLogs()) {
      stats.putIfAbsent(log.recommendationType, () => {});
      stats[log.recommendationType]!.update(
        log.userFeedback,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    return stats;
  }

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

  static List<MonitoredChannel> getAllMonitoredChannels() {
    final list = <MonitoredChannel>[];
    for (final map in _channelsBox.values) {
      try {
        list.add(MonitoredChannel.fromMap(map as Map<dynamic, dynamic>));
      } catch (_) {
        // skip malformed
      }
    }
    list.sort((a, b) => a.addedAt.compareTo(b.addedAt));
    return list;
  }

  static Future<void> saveMonitoredChannel(MonitoredChannel channel) =>
      _channelsBox.put(channel.username, channel.toMap());

  static Future<void> deleteMonitoredChannel(String username) =>
      _channelsBox.delete(username);

  static String? getFootballDataApiKey() =>
      _box.get(_footballDataApiKeyField) as String?;
  static Future<void> saveFootballDataApiKey(String key) =>
      _box.put(_footballDataApiKeyField, key);
  static Future<void> deleteFootballDataApiKey() =>
      _box.delete(_footballDataApiKeyField);

  static IntelligenceReport? getReport(String matchId) {
    final map = _reportsBox.get(matchId);
    if (map == null) return null;
    try {
      return IntelligenceReport.fromMap(map as Map<dynamic, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveReport(IntelligenceReport report) =>
      _reportsBox.put(report.matchId, report.toMap());

  static List<IntelligenceReport> getAllReports() {
    final list = <IntelligenceReport>[];
    for (final map in _reportsBox.values) {
      try {
        list.add(IntelligenceReport.fromMap(map as Map<dynamic, dynamic>));
      } catch (_) {
        // skip malformed
      }
    }
    list.sort((a, b) => b.confluenceScore.compareTo(a.confluenceScore));
    return list;
  }

  static Future<void> deleteReport(String matchId) =>
      _reportsBox.delete(matchId);

  static Future<int> clearOldReports(
      {Duration keepFor = const Duration(hours: 6)}) async {
    final cutoff = DateTime.now().subtract(keepFor);
    final keys = <dynamic>[];
    for (final key in _reportsBox.keys) {
      try {
        final report = IntelligenceReport.fromMap(
            _reportsBox.get(key) as Map<dynamic, dynamic>);
        if (report.generatedAt.isBefore(cutoff)) keys.add(key);
      } catch (_) {
        keys.add(key);
      }
    }
    for (final k in keys) {
      await _reportsBox.delete(k);
    }
    return keys.length;
  }

  static FootballDataSignal? getFootballSignal(String matchId) {
    final map = _footballBox.get(matchId);
    if (map == null) return null;
    try {
      return FootballDataSignal.fromMap(map as Map<dynamic, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveFootballSignal(FootballDataSignal signal) =>
      _footballBox.put(signal.matchId, signal.toMap());

  static NbaStatsSignal? getNbaSignal(String matchId) {
    final map = _nbaBox.get(matchId);
    if (map == null) return null;
    try {
      return NbaStatsSignal.fromMap(map as Map<dynamic, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveNbaSignal(NbaStatsSignal signal) =>
      _nbaBox.put(signal.matchId, signal.toMap());

  static RedditSignal? getRedditSignal(String matchId) {
    final map = _redditBox.get(matchId);
    if (map == null) return null;
    try {
      return RedditSignal.fromMap(map as Map<dynamic, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveRedditSignal(RedditSignal signal) =>
      _redditBox.put(signal.matchId, signal.toMap());

  /// Migrates legacy `List<String>` channel list (settings box) into
  /// per-channel MonitoredChannel records. No-op if already migrated
  /// (channels box already populated) or if there is nothing to migrate.
  static Future<void> migrateMonitoredChannels() async {
    if (_channelsBox.isNotEmpty) return;
    final oldList = getMonitoredChannels();
    if (oldList.isEmpty) return;
    final now = DateTime.now();
    for (final username in oldList) {
      final channel = MonitoredChannel(username: username, addedAt: now);
      await saveMonitoredChannel(channel);
    }
  }

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

  /// Returns the most recent snapshot for a match (sorted ascending →
  /// `.last` is newest), or null if there are none.
  static OddsSnapshot? getLatestSnapshotForMatch(String matchId) {
    final snapshots = getSnapshotsForMatch(matchId);
    if (snapshots.isEmpty) return null;
    return snapshots.last;
  }

  /// Saves snapshot only if odds differ from the last saved snapshot for
  /// that match. Returns true if saved, false if skipped (no change).
  static Future<bool> saveSnapshotIfChanged(OddsSnapshot snapshot) async {
    final last = getLatestSnapshotForMatch(snapshot.matchId);
    if (last != null &&
        last.home == snapshot.home &&
        last.draw == snapshot.draw &&
        last.away == snapshot.away) {
      return false;
    }
    await saveSnapshot(snapshot);
    return true;
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

  static CachedMatchesEntry? getCachedMatches() {
    final map = _cacheBox.get(_cacheEntryKey);
    if (map == null) return null;
    try {
      return CachedMatchesEntry.fromMap(map as Map<dynamic, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCachedMatches(CachedMatchesEntry entry) =>
      _cacheBox.put(_cacheEntryKey, entry.toMap());

  static Future<void> clearCachedMatches() =>
      _cacheBox.delete(_cacheEntryKey);

  static int getCacheTtlMinutes() =>
      (_box.get(_cacheTtlMinutesField) as int?) ?? 15;
  static Future<void> saveCacheTtlMinutes(int minutes) =>
      _box.put(_cacheTtlMinutesField, minutes);

  static DateTime? getLastCleanupAt() {
    final iso = _box.get(_lastCleanupField) as String?;
    if (iso == null) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLastCleanupAt(DateTime t) =>
      _box.put(_lastCleanupField, t.toIso8601String());

  /// Runs cleanup of stale signals/snapshots/cache if the previous run was
  /// more than 24h ago (or never ran). Returns counts of cleared items.
  /// No-op (zero counts) when the 24h gate hasn't elapsed.
  static Future<Map<String, int>> runScheduledCleanup() async {
    final lastRun = getLastCleanupAt();
    if (lastRun != null &&
        DateTime.now().difference(lastRun) < const Duration(hours: 24)) {
      return {
        'signals_cleaned': 0,
        'snapshots_cleaned': 0,
        'cache_entries_cleaned': 0,
        'reports_cleaned': 0,
        'football_cleaned': 0,
        'nba_cleaned': 0,
        'reddit_cleaned': 0,
      };
    }

    final signalsCleaned =
        await clearOldSignals(keepFor: const Duration(days: 7));
    final snapshotsCleaned =
        await clearOldSnapshots(keepFor: const Duration(days: 7));

    var cacheEntriesCleaned = 0;
    final cached = getCachedMatches();
    if (cached != null && cached.age > const Duration(hours: 24)) {
      await clearCachedMatches();
      cacheEntriesCleaned = 1;
    }

    final reportsCleaned =
        await clearOldReports(keepFor: const Duration(hours: 6));
    final footballCleaned = await _purgeOldSignalCache(
      _footballBox,
      (m) => FootballDataSignal.fromMap(m).fetchedAt,
    );
    final nbaCleaned = await _purgeOldSignalCache(
      _nbaBox,
      (m) => NbaStatsSignal.fromMap(m).fetchedAt,
    );
    final redditCleaned = await _purgeOldSignalCache(
      _redditBox,
      (m) => RedditSignal.fromMap(m).fetchedAt,
    );

    await saveLastCleanupAt(DateTime.now());
    return {
      'signals_cleaned': signalsCleaned,
      'snapshots_cleaned': snapshotsCleaned,
      'cache_entries_cleaned': cacheEntriesCleaned,
      'reports_cleaned': reportsCleaned,
      'football_cleaned': footballCleaned,
      'nba_cleaned': nbaCleaned,
      'reddit_cleaned': redditCleaned,
    };
  }

  /// Removes signal cache entries older than 3 days (or unparsable).
  /// Generic helper used by intelligence signal boxes.
  static Future<int> _purgeOldSignalCache(
    Box box,
    DateTime Function(Map<dynamic, dynamic> map) fetchedAtOf,
  ) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 3));
    final keys = <dynamic>[];
    for (final key in box.keys) {
      try {
        final fetched = fetchedAtOf(box.get(key) as Map<dynamic, dynamic>);
        if (fetched.isBefore(cutoff)) keys.add(key);
      } catch (_) {
        keys.add(key);
      }
    }
    for (final k in keys) {
      await box.delete(k);
    }
    return keys.length;
  }
}
