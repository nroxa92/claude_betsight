import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/match.dart';
import '../models/odds_snapshot.dart';

class NotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static const _kickoffChannel = AndroidNotificationDetails(
    'kickoff_channel',
    'Kickoff Alerts',
    channelDescription: 'Notifications for upcoming match kickoff',
    importance: Importance.defaultImportance,
  );

  static const _driftChannel = AndroidNotificationDetails(
    'drift_channel',
    'Odds Drift Alerts',
    channelDescription: 'Significant odds movement on watched matches',
    importance: Importance.high,
  );

  static const _valueChannel = AndroidNotificationDetails(
    'value_channel',
    'Value Signal Alerts',
    channelDescription: 'Claude detected new VALUE recommendation',
    importance: Importance.high,
  );

  /// Schedules 24h / 1h / 15min kickoff reminders for the given match.
  /// Past times are skipped silently. Notification IDs are deterministic
  /// (matchId.hashCode + offset seconds) so they can be cancelled cleanly.
  static Future<void> scheduleKickoffReminders(Match match) async {
    if (!_initialized) await init();
    final id = match.id.hashCode;

    final reminders = <(Duration, String)>[
      (const Duration(hours: 24), 'Match starts in 24 hours'),
      (const Duration(hours: 1), 'Match starts in 1 hour'),
      (const Duration(minutes: 15), 'Match starts in 15 minutes'),
    ];

    for (final (before, msg) in reminders) {
      final scheduledAt = match.commenceTime.subtract(before);
      if (scheduledAt.isBefore(DateTime.now())) continue;

      try {
        await _plugin.zonedSchedule(
          id + before.inSeconds,
          '${match.home} vs ${match.away}',
          msg,
          tz.TZDateTime.from(scheduledAt, tz.local),
          const NotificationDetails(android: _kickoffChannel),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // best-effort scheduling — skip individual failures
      }
    }
  }

  static Future<void> cancelKickoffReminders(String matchId) async {
    final id = matchId.hashCode;
    for (final secs in const [86400, 3600, 900]) {
      try {
        await _plugin.cancel(id + secs);
      } catch (_) {
        // ignore individual cancel failures
      }
    }
  }

  /// Immediate drift alert for a watched match whose odds shifted.
  static Future<void> showDriftAlert(Match match, OddsDrift drift) async {
    if (!_initialized) await init();
    final dom = drift.dominantDrift;
    final sign = dom.percent > 0 ? '+' : '';
    await _plugin.show(
      match.id.hashCode,
      '⚡ Drift on ${match.home} vs ${match.away}',
      '${dom.side} $sign${dom.percent.toStringAsFixed(1)}%',
      const NotificationDetails(android: _driftChannel),
    );
  }

  /// Immediate VALUE alert when Claude returns VALUE in Analysis.
  static Future<void> showValueAlert(Match match) async {
    if (!_initialized) await init();
    await _plugin.show(
      match.id.hashCode + 1,
      '🎯 VALUE detected',
      '${match.home} vs ${match.away} — tap to see Claude analysis',
      const NotificationDetails(android: _valueChannel),
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
