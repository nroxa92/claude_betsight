import 'package:betsight/models/monitored_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final addedAt = DateTime(2026, 4, 1);

  MonitoredChannel build({
    String username = '@test',
    String? title = 'Test Channel',
    int received = 0,
    int relevant = 0,
    DateTime? lastSignal,
    DateTime? lastRelevant,
  }) =>
      MonitoredChannel(
        username: username,
        title: title,
        signalsReceived: received,
        signalsRelevant: relevant,
        addedAt: addedAt,
        lastSignalAt: lastSignal,
        lastRelevantAt: lastRelevant,
      );

  group('reliabilityScore', () {
    test('< 10 signals → -1 (insufficient data)', () {
      expect(build(received: 9, relevant: 5).reliabilityScore, -1);
      expect(build(received: 0, relevant: 0).reliabilityScore, -1);
    });
    test('10 signals, 5 relevant → 0.5', () {
      expect(build(received: 10, relevant: 5).reliabilityScore, 0.5);
    });
    test('20 signals, 0 relevant → 0.0', () {
      expect(build(received: 20, relevant: 0).reliabilityScore, 0.0);
    });
    test('100 signals, 100 relevant → 1.0', () {
      expect(build(received: 100, relevant: 100).reliabilityScore, 1.0);
    });
  });

  group('reliabilityLabel', () {
    test('< 10 signals → "Novo"', () {
      expect(build(received: 5).reliabilityLabel, 'Novo');
    });
    test('< 0.1 ratio → "Niska"', () {
      expect(build(received: 100, relevant: 5).reliabilityLabel, 'Niska');
    });
    test('0.1 ≤ ratio < 0.3 → "Srednja"', () {
      expect(build(received: 100, relevant: 20).reliabilityLabel, 'Srednja');
      expect(build(received: 100, relevant: 10).reliabilityLabel, 'Srednja');
    });
    test('≥ 0.3 ratio → "Visoka"', () {
      expect(build(received: 100, relevant: 50).reliabilityLabel, 'Visoka');
      expect(build(received: 100, relevant: 30).reliabilityLabel, 'Visoka');
    });
  });

  group('reliabilityColorValue', () {
    test('insufficient → grey 0xFF9E9E9E', () {
      expect(build(received: 5).reliabilityColorValue, 0xFF9E9E9E);
    });
    test('low → red 0xFFEF5350', () {
      expect(build(received: 100, relevant: 3).reliabilityColorValue,
          0xFFEF5350);
    });
    test('medium → orange 0xFFFFA726', () {
      expect(build(received: 100, relevant: 20).reliabilityColorValue,
          0xFFFFA726);
    });
    test('high → green 0xFF4CAF50', () {
      expect(build(received: 100, relevant: 50).reliabilityColorValue,
          0xFF4CAF50);
    });
  });

  group('lastRelevantDisplay', () {
    test('null → "Never"', () {
      expect(build(lastRelevant: null).lastRelevantDisplay, 'Never');
    });
    test('recent minutes → "Nm ago"', () {
      final c = build(
        lastRelevant: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(c.lastRelevantDisplay, endsWith('m ago'));
    });
    test('hours → "Nh ago"', () {
      final c = build(
        lastRelevant: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(c.lastRelevantDisplay, endsWith('h ago'));
    });
    test('days → "Nd ago"', () {
      final c = build(
        lastRelevant: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(c.lastRelevantDisplay, endsWith('d ago'));
    });
  });

  group('copyWith', () {
    test('updates counts', () {
      final c = build(received: 10, relevant: 3);
      final c2 = c.copyWith(signalsReceived: 20, signalsRelevant: 8);
      expect(c2.signalsReceived, 20);
      expect(c2.signalsRelevant, 8);
      expect(c2.username, c.username);
      expect(c2.addedAt, c.addedAt);
    });
    test('preserves username and addedAt (not copyable)', () {
      final c = build();
      final c2 = c.copyWith(title: 'New Title');
      expect(c2.username, c.username);
      expect(c2.addedAt, c.addedAt);
      expect(c2.title, 'New Title');
    });
  });

  group('toMap + fromMap roundtrip', () {
    test('minimal channel', () {
      final original = build();
      final parsed = MonitoredChannel.fromMap(original.toMap());
      expect(parsed.username, original.username);
      expect(parsed.title, original.title);
      expect(parsed.signalsReceived, 0);
      expect(parsed.signalsRelevant, 0);
      expect(parsed.addedAt, addedAt);
      expect(parsed.lastSignalAt, isNull);
      expect(parsed.lastRelevantAt, isNull);
    });
    test('fully populated', () {
      final now = DateTime(2026, 4, 18, 12);
      final original = build(
        received: 50,
        relevant: 15,
        lastSignal: now,
        lastRelevant: now.subtract(const Duration(hours: 2)),
      );
      final parsed = MonitoredChannel.fromMap(original.toMap());
      expect(parsed.signalsReceived, 50);
      expect(parsed.signalsRelevant, 15);
      expect(parsed.lastSignalAt, now);
      expect(parsed.lastRelevantAt, now.subtract(const Duration(hours: 2)));
    });
    test('fromMap defaults missing counts to 0', () {
      final parsed = MonitoredChannel.fromMap({
        'username': '@x',
        'addedAt': '2026-04-01T00:00:00.000',
      });
      expect(parsed.signalsReceived, 0);
      expect(parsed.signalsRelevant, 0);
    });
  });
}
