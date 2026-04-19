import 'package:betsight/models/analysis_log.dart';
import 'package:betsight/models/recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 4, 18, 12);

  AnalysisLog build({
    String id = 'log-1',
    DateTime? ts,
    String userMessage = 'analyze this',
    String assistantResponse = 'here you go **VALUE**',
    List<String>? contextMatchIds,
    RecommendationType rec = RecommendationType.value,
    UserFeedback feedback = UserFeedback.none,
    DateTime? feedbackAt,
  }) =>
      AnalysisLog(
        id: id,
        timestamp: ts ?? now,
        userMessage: userMessage,
        assistantResponse: assistantResponse,
        contextMatchIds: contextMatchIds ?? ['m-1'],
        recommendationType: rec,
        userFeedback: feedback,
        feedbackAt: feedbackAt,
      );

  group('UserFeedback enum', () {
    test('has 4 values', () {
      expect(UserFeedback.values, hasLength(4));
    });
  });

  group('AnalysisLog.copyWith', () {
    test('updates userFeedback and feedbackAt', () {
      final log = build();
      final updated = log.copyWith(
        userFeedback: UserFeedback.logged,
        feedbackAt: DateTime(2026, 4, 18, 13),
      );
      expect(updated.userFeedback, UserFeedback.logged);
      expect(updated.feedbackAt, DateTime(2026, 4, 18, 13));
      expect(updated.id, log.id);
      expect(updated.timestamp, log.timestamp);
    });
    test('no args preserves all values', () {
      final log = build(feedback: UserFeedback.skipped);
      final copy = log.copyWith();
      expect(copy.userFeedback, UserFeedback.skipped);
    });
  });

  group('AnalysisLog.toMap + fromMap roundtrip', () {
    test('roundtrips full log with feedback', () {
      final original = build(
        feedback: UserFeedback.logged,
        feedbackAt: DateTime(2026, 4, 18, 13),
        contextMatchIds: ['m-1', 'm-2'],
      );
      final parsed = AnalysisLog.fromMap(original.toMap());
      expect(parsed.id, original.id);
      expect(parsed.timestamp, original.timestamp);
      expect(parsed.userMessage, original.userMessage);
      expect(parsed.assistantResponse, original.assistantResponse);
      expect(parsed.contextMatchIds, ['m-1', 'm-2']);
      expect(parsed.recommendationType, RecommendationType.value);
      expect(parsed.userFeedback, UserFeedback.logged);
      expect(parsed.feedbackAt, DateTime(2026, 4, 18, 13));
    });
    test('fromMap defaults missing recommendationType to none', () {
      final parsed = AnalysisLog.fromMap({
        'id': 'x',
        'timestamp': '2026-04-18T12:00:00.000',
        'userMessage': 'u',
        'assistantResponse': 'a',
        'contextMatchIds': <String>[],
        'recommendationType': 'garbage',
        'userFeedback': 'garbage',
      });
      expect(parsed.recommendationType, RecommendationType.none);
      expect(parsed.userFeedback, UserFeedback.none);
    });
    test('empty contextMatchIds list roundtrips', () {
      final original = build(contextMatchIds: []);
      final parsed = AnalysisLog.fromMap(original.toMap());
      expect(parsed.contextMatchIds, isEmpty);
    });
  });

  group('generateUuid', () {
    test('produces 36-character UUID string (8-4-4-4-12)', () {
      final uuid = generateUuid();
      expect(uuid, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    });
    test('generates distinct values across calls', () {
      final ids = List.generate(100, (_) => generateUuid()).toSet();
      expect(ids, hasLength(100));
    });
    test('version nibble is 4 (UUID v4)', () {
      final uuid = generateUuid();
      expect(uuid[14], '4');
    });
    test('variant nibble is 8, 9, a, or b', () {
      for (var i = 0; i < 20; i++) {
        final uuid = generateUuid();
        expect('89ab'.contains(uuid[19]), isTrue,
            reason: 'variant nibble at index 19 must be 8/9/a/b');
      }
    });
  });
}
