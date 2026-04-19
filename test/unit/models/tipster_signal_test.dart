import 'package:betsight/models/sport.dart';
import 'package:betsight/models/tipster_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t = DateTime(2026, 4, 18, 10, 0);

  TipsterSignal build({
    String id = 's-1',
    int msgId = 1,
    String channel = '@tipster',
    String title = 'Tipster',
    String text = 'Arsenal vs Liverpool — back home',
    DateTime? receivedAt,
    Sport? sport,
    String? league,
    bool relevant = true,
  }) =>
      TipsterSignal(
        id: id,
        telegramMessageId: msgId,
        channelUsername: channel,
        channelTitle: title,
        text: text,
        receivedAt: receivedAt ?? t,
        detectedSport: sport,
        detectedLeague: league,
        isRelevant: relevant,
      );

  group('TipsterSignal.preview', () {
    test('short text returned as-is (trimmed)', () {
      final s = build(text: '  short tip  ');
      expect(s.preview, 'short tip');
    });
    test('text exactly 150 chars returned as-is', () {
      final text = 'a' * 150;
      expect(build(text: text).preview, text);
    });
    test('text > 150 chars truncated to 147 + "..."', () {
      final text = 'b' * 200;
      final s = build(text: text);
      expect(s.preview.length, 150);
      expect(s.preview, endsWith('...'));
      expect(s.preview.substring(0, 147), 'b' * 147);
    });
  });

  group('TipsterSignal.toClaudeContext', () {
    test('includes channel, sport and preview', () {
      final s = build(
        channel: '@prosports',
        sport: Sport.soccer,
        receivedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        text: 'back home win',
      );
      final ctx = s.toClaudeContext();
      expect(ctx, contains('@prosports'));
      expect(ctx, contains('Soccer'));
      expect(ctx, contains('back home win'));
      expect(ctx, contains('ago'));
    });
    test('falls back to "unknown sport" when no sport detected', () {
      final s = build(sport: null);
      expect(s.toClaudeContext(), contains('unknown sport'));
    });
  });

  group('TipsterSignal.toMap + fromMap roundtrip', () {
    test('minimal signal without sport/league', () {
      final original = build();
      final parsed = TipsterSignal.fromMap(original.toMap());
      expect(parsed.id, original.id);
      expect(parsed.telegramMessageId, original.telegramMessageId);
      expect(parsed.channelUsername, original.channelUsername);
      expect(parsed.channelTitle, original.channelTitle);
      expect(parsed.text, original.text);
      expect(parsed.receivedAt, original.receivedAt);
      expect(parsed.detectedSport, isNull);
      expect(parsed.detectedLeague, isNull);
      expect(parsed.isRelevant, isTrue);
    });
    test('with sport and league', () {
      final original = build(
        sport: Sport.basketball,
        league: 'NBA',
        relevant: false,
      );
      final parsed = TipsterSignal.fromMap(original.toMap());
      expect(parsed.detectedSport, Sport.basketball);
      expect(parsed.detectedLeague, 'NBA');
      expect(parsed.isRelevant, isFalse);
    });
  });
}
