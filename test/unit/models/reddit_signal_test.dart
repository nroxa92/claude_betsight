import 'package:betsight/models/reddit_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RedditSignal build({
    int mentions = 10,
    int topUp = 100,
    Map<String, int>? teamMentions,
    String? postTitle,
    String? subreddit,
  }) =>
      RedditSignal(
        matchId: 'm-1',
        mentionCount: mentions,
        topUpvotes: topUp,
        teamMentions: teamMentions ?? {'Arsenal': 5, 'Liverpool': 5},
        topPostTitle: postTitle,
        topPostSubreddit: subreddit,
        fetchedAt: DateTime(2026, 4, 18),
      );

  group('getSentimentBias', () {
    test('balanced 5/5 → 0', () {
      expect(build().getSentimentBias('Arsenal', 'Liverpool'), 0);
    });
    test('home tilt (home 8, away 2) → -0.6', () {
      final s = build(teamMentions: {'Arsenal': 8, 'Liverpool': 2});
      expect(s.getSentimentBias('Arsenal', 'Liverpool'), closeTo(-0.6, 0.001));
    });
    test('away tilt (home 2, away 8) → +0.6', () {
      final s = build(teamMentions: {'Arsenal': 2, 'Liverpool': 8});
      expect(s.getSentimentBias('Arsenal', 'Liverpool'), closeTo(0.6, 0.001));
    });
    test('team not in map → treated as 0', () {
      final s = build(teamMentions: {'SomeTeam': 5});
      expect(s.getSentimentBias('Arsenal', 'Liverpool'), 0);
    });
    test('both teams absent → 0 (no division by zero)', () {
      final s = build(teamMentions: {});
      expect(s.getSentimentBias('Arsenal', 'Liverpool'), 0);
    });
  });

  group('toClaudeContext', () {
    test('balanced sentiment shown when |bias| < 0.2', () {
      final s = build(teamMentions: {'Arsenal': 5, 'Liverpool': 6});
      final ctx = s.toClaudeContext('Arsenal', 'Liverpool');
      expect(ctx, contains('balanced'));
    });
    test('skewed toward home team', () {
      final s = build(teamMentions: {'Arsenal': 8, 'Liverpool': 1});
      final ctx = s.toClaudeContext('Arsenal', 'Liverpool');
      expect(ctx, contains('Arsenal'));
      expect(ctx, contains('skewed'));
    });
    test('skewed toward away team', () {
      final s = build(teamMentions: {'Arsenal': 1, 'Liverpool': 8});
      final ctx = s.toClaudeContext('Arsenal', 'Liverpool');
      expect(ctx, contains('Liverpool'));
    });
    test('includes mention count', () {
      final ctx = build(mentions: 42).toClaudeContext('A', 'B');
      expect(ctx, contains('42 mentions'));
    });
    test('top post only included when title present', () {
      final withPost = build(
        postTitle: 'Big news',
        subreddit: 'soccer',
        topUp: 500,
      ).toClaudeContext('A', 'B');
      expect(withPost, contains('r/soccer'));
      expect(withPost, contains('500'));
      expect(withPost, contains('Big news'));

      final noPost = build().toClaudeContext('A', 'B');
      expect(noPost, isNot(contains('Top post')));
    });
  });

  group('toMap + fromMap roundtrip', () {
    test('roundtrips teamMentions map', () {
      final original = build(
        teamMentions: {'Arsenal': 8, 'Liverpool': 2, 'Neutral': 1},
        postTitle: 'Injuries',
        subreddit: 'soccer',
      );
      final parsed = RedditSignal.fromMap(original.toMap());
      expect(parsed.teamMentions['Arsenal'], 8);
      expect(parsed.teamMentions['Liverpool'], 2);
      expect(parsed.teamMentions['Neutral'], 1);
      expect(parsed.topPostTitle, 'Injuries');
      expect(parsed.topPostSubreddit, 'soccer');
    });
    test('empty teamMentions map', () {
      final original = build(teamMentions: {});
      final parsed = RedditSignal.fromMap(original.toMap());
      expect(parsed.teamMentions, isEmpty);
    });
  });
}
