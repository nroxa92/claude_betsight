import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/match.dart';
import '../models/reddit_signal.dart';
import '../models/sport.dart';

class RedditMonitor {
  final http.Client _client;

  static const _baseUrl = 'https://www.reddit.com';
  // Reddit refuses requests without a unique User-Agent.
  static const _userAgent = 'BetSight/1.0';
  static const _timeout = Duration(seconds: 15);

  static const _subredditsForSport = {
    Sport.soccer: ['soccer', 'sportsbook'],
    Sport.basketball: ['nba', 'sportsbook'],
    Sport.tennis: ['tennis', 'sportsbook'],
  };

  RedditMonitor({http.Client? client}) : _client = client ?? http.Client();

  Future<RedditSignal> getSignalForMatch(Match match) async {
    final subreddits = _subredditsForSport[match.sport] ?? const <String>[];
    if (subreddits.isEmpty) {
      throw RedditException('Sport not supported');
    }

    var mentionCount = 0;
    var topUpvotes = 0;
    String? topTitle;
    String? topSub;
    final teamMentions = <String, int>{
      match.home: 0,
      match.away: 0,
    };

    for (final sub in subreddits) {
      try {
        final uri = Uri.parse('$_baseUrl/r/$sub/hot.json?limit=50');
        final resp = await _client
            .get(uri, headers: {'User-Agent': _userAgent})
            .timeout(_timeout);
        if (resp.statusCode != 200) continue;

        final data = json.decode(resp.body) as Map<String, dynamic>;
        final posts = ((data['data'] as Map<String, dynamic>)['children']
            as List<dynamic>);

        for (final p in posts) {
          final post = (p as Map<String, dynamic>)['data']
              as Map<String, dynamic>;
          final title = (post['title'] as String?) ?? '';
          final text = (post['selftext'] as String?) ?? '';
          final fullText = '$title\n$text'.toLowerCase();
          final upvotes = (post['ups'] as int?) ?? 0;

          final homeL = match.home.toLowerCase();
          final awayL = match.away.toLowerCase();

          var mentioned = false;
          if (fullText.contains(homeL)) {
            teamMentions[match.home] = (teamMentions[match.home] ?? 0) + 1;
            mentioned = true;
          }
          if (fullText.contains(awayL)) {
            teamMentions[match.away] = (teamMentions[match.away] ?? 0) + 1;
            mentioned = true;
          }

          if (mentioned) {
            mentionCount++;
            if (upvotes > topUpvotes) {
              topUpvotes = upvotes;
              topTitle = title;
              topSub = sub;
            }
          }
        }
      } catch (_) {
        // skip failed subreddit, keep trying others
        continue;
      }
    }

    return RedditSignal(
      matchId: match.id,
      mentionCount: mentionCount,
      topUpvotes: topUpvotes,
      teamMentions: teamMentions,
      topPostTitle: topTitle,
      topPostSubreddit: topSub,
      fetchedAt: DateTime.now(),
    );
  }

  void dispose() => _client.close();
}

class RedditException implements Exception {
  final String message;
  RedditException(this.message);
  @override
  String toString() => 'RedditException: $message';
}
