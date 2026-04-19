import 'package:betsight/models/match_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatchNote.toMap + fromMap roundtrip', () {
    test('roundtrips all fields', () {
      final original = MatchNote(
        matchId: 'm-1',
        text: 'Injury to key striker',
        updatedAt: DateTime(2026, 4, 18, 10),
      );
      final parsed = MatchNote.fromMap(original.toMap());
      expect(parsed.matchId, 'm-1');
      expect(parsed.text, 'Injury to key striker');
      expect(parsed.updatedAt, DateTime(2026, 4, 18, 10));
    });
    test('empty text roundtrips', () {
      final original = MatchNote(
        matchId: 'm-1',
        text: '',
        updatedAt: DateTime(2026, 4, 18),
      );
      expect(MatchNote.fromMap(original.toMap()).text, '');
    });
    test('long multiline text roundtrips', () {
      final text = 'Line 1\nLine 2\nLine 3';
      final original = MatchNote(
        matchId: 'm-1',
        text: text,
        updatedAt: DateTime(2026, 4, 18),
      );
      expect(MatchNote.fromMap(original.toMap()).text, text);
    });
  });
}
