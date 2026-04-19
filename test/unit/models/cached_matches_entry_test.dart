import 'package:betsight/models/cached_matches_entry.dart';
import 'package:betsight/models/match.dart';
import 'package:betsight/models/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Match buildMatch({String id = 'm-1'}) => Match(
        id: id,
        sport: Sport.soccer,
        league: 'EPL',
        sportKey: 'soccer_epl',
        home: 'A',
        away: 'B',
        commenceTime: DateTime(2026, 5, 1),
        h2h: null,
      );

  group('CachedMatchesEntry.age', () {
    test('age increases with fetchedAt in the past', () {
      final e = CachedMatchesEntry(
        matches: [],
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(e.age.inMinutes, greaterThanOrEqualTo(5));
    });
  });

  group('CachedMatchesEntry.isExpired', () {
    test('age < ttl → not expired', () {
      final e = CachedMatchesEntry(
        matches: [],
        fetchedAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(e.isExpired(const Duration(minutes: 10)), isFalse);
    });
    test('age > ttl → expired', () {
      final e = CachedMatchesEntry(
        matches: [],
        fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(e.isExpired(const Duration(hours: 1)), isTrue);
    });
  });

  group('CachedMatchesEntry.ageDisplay', () {
    test('< 1 min → "just now"', () {
      final e = CachedMatchesEntry(
        matches: [],
        fetchedAt: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(e.ageDisplay, 'just now');
    });
    test('minutes → "Nm ago"', () {
      final e = CachedMatchesEntry(
        matches: [],
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(e.ageDisplay, endsWith('m ago'));
    });
    test('hours → "Nh ago"', () {
      final e = CachedMatchesEntry(
        matches: [],
        fetchedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(e.ageDisplay, endsWith('h ago'));
    });
    test('days → "Nd ago"', () {
      final e = CachedMatchesEntry(
        matches: [],
        fetchedAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(e.ageDisplay, endsWith('d ago'));
    });
  });

  group('CachedMatchesEntry.toMap + fromMap roundtrip', () {
    test('empty matches list', () {
      final original = CachedMatchesEntry(
        matches: [],
        fetchedAt: DateTime(2026, 4, 18, 10),
        remainingRequests: 495,
      );
      final parsed = CachedMatchesEntry.fromMap(original.toMap());
      expect(parsed.matches, isEmpty);
      expect(parsed.fetchedAt, DateTime(2026, 4, 18, 10));
      expect(parsed.remainingRequests, 495);
    });
    test('with matches', () {
      final original = CachedMatchesEntry(
        matches: [buildMatch(id: 'a'), buildMatch(id: 'b')],
        fetchedAt: DateTime(2026, 4, 18, 10),
      );
      final parsed = CachedMatchesEntry.fromMap(original.toMap());
      expect(parsed.matches, hasLength(2));
      expect(parsed.matches[0].id, 'a');
      expect(parsed.matches[1].id, 'b');
      expect(parsed.remainingRequests, isNull);
    });
  });
}
