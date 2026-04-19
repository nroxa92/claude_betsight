import 'dart:convert';

import 'package:betsight/models/match.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/services/reddit_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Match buildMatch({
    Sport sport = Sport.soccer,
    String home = 'Arsenal',
    String away = 'Liverpool',
    String sportKey = 'soccer_epl',
  }) =>
      Match(
        id: 'm-1',
        sport: sport,
        league: 'EPL',
        sportKey: sportKey,
        home: home,
        away: away,
        commenceTime: DateTime(2026, 5, 1),
        h2h: null,
      );

  http.Response redditPosts(List<Map<String, dynamic>> posts) {
    return http.Response(
      json.encode({
        'data': {
          'children': posts.map((p) => {'data': p}).toList(),
        },
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  group('RedditMonitor.getSignalForMatch', () {
    test('aggregates mentions across 2 subreddits', () async {
      var callCount = 0;
      final svc = RedditMonitor(
        client: MockClient((req) async {
          callCount++;
          return redditPosts([
            {
              'title': 'Arsenal looks strong',
              'selftext': '',
              'ups': 100,
            },
            {
              'title': 'Liverpool injury update',
              'selftext': '',
              'ups': 50,
            },
          ]);
        }),
      );
      final signal = await svc.getSignalForMatch(buildMatch());
      expect(callCount, 2);
      expect(signal.mentionCount, 4);
      expect(signal.teamMentions['Arsenal'], 2);
      expect(signal.teamMentions['Liverpool'], 2);
    });

    test('tracks top upvotes post', () async {
      final svc = RedditMonitor(
        client: MockClient((req) async {
          return redditPosts([
            {'title': 'Arsenal buzz', 'selftext': '', 'ups': 50},
            {'title': 'Big Arsenal post', 'selftext': '', 'ups': 1500},
          ]);
        }),
      );
      final signal = await svc.getSignalForMatch(buildMatch());
      expect(signal.topUpvotes, 1500);
      expect(signal.topPostTitle, 'Big Arsenal post');
    });

    test('posts not mentioning either team not counted', () async {
      final svc = RedditMonitor(
        client: MockClient((req) async {
          return redditPosts([
            {
              'title': 'Chelsea vs City',
              'selftext': 'unrelated',
              'ups': 999
            },
          ]);
        }),
      );
      final signal = await svc.getSignalForMatch(buildMatch());
      expect(signal.mentionCount, 0);
      expect(signal.topUpvotes, 0);
      expect(signal.topPostTitle, isNull);
    });

    test('post mentioning both teams counts both', () async {
      final svc = RedditMonitor(
        client: MockClient((req) async {
          return redditPosts([
            {
              'title': 'Arsenal vs Liverpool preview',
              'selftext': '',
              'ups': 200,
            },
          ]);
        }),
      );
      final signal = await svc.getSignalForMatch(buildMatch());
      expect(signal.teamMentions['Arsenal'], 2);
      expect(signal.teamMentions['Liverpool'], 2);
      expect(signal.mentionCount, 2);
    });

    test('failed subreddit fetch skipped silently', () async {
      var callCount = 0;
      final svc = RedditMonitor(
        client: MockClient((req) async {
          callCount++;
          if (callCount == 1) return http.Response('', 500);
          return redditPosts([
            {'title': 'Arsenal rumour', 'selftext': '', 'ups': 10},
          ]);
        }),
      );
      final signal = await svc.getSignalForMatch(buildMatch());
      expect(signal.mentionCount, 1);
    });

    test('matches are case-insensitive', () async {
      final svc = RedditMonitor(
        client: MockClient((req) async {
          return redditPosts([
            {'title': 'arsenal vs liverpool', 'selftext': '', 'ups': 10},
          ]);
        }),
      );
      final signal = await svc.getSignalForMatch(buildMatch());
      expect(signal.mentionCount, greaterThan(0));
    });
  });

  group('RedditException', () {
    test('toString includes message', () {
      expect(RedditException('test').toString(), contains('test'));
    });
  });
}
