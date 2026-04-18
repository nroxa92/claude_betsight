import 'dart:async';

import '../models/football_data_signal.dart';
import '../models/intelligence_report.dart';
import '../models/match.dart';
import '../models/monitored_channel.dart';
import '../models/nba_stats_signal.dart';
import '../models/odds_snapshot.dart';
import '../models/reddit_signal.dart';
import '../models/source_score.dart';
import '../models/sport.dart';
import '../models/telegram_provider.dart';
import 'ball_dont_lie_service.dart';
import 'football_data_service.dart';
import 'reddit_monitor.dart';
import 'storage_service.dart';

class IntelligenceAggregator {
  final FootballDataService? footballService;
  final BallDontLieService? nbaService;
  final RedditMonitor? redditMonitor;
  final TelegramProvider telegramProvider;

  static const _signalCacheTtl = Duration(hours: 3);

  IntelligenceAggregator({
    required this.footballService,
    required this.nbaService,
    required this.redditMonitor,
    required this.telegramProvider,
  });

  /// Builds a confluence report by scoring each source in parallel.
  /// Each source error gets converted to an inactive SourceScore; we never
  /// throw out of buildReport — the report itself reflects partial coverage.
  Future<IntelligenceReport> buildReport(Match match) async {
    final futures = await Future.wait([
      _scoreOdds(match),
      _scoreFootballData(match),
      _scoreNbaStats(match),
      _scoreReddit(match),
      _scoreTelegram(match),
    ]);

    return IntelligenceReport(
      matchId: match.id,
      sources: futures,
      generatedAt: DateTime.now(),
    );
  }

  /// SOURCE 1: Odds (max 2.0)
  /// - Base 0.5 for having h2h data
  /// - +0.5 if margin < 5% (sharp book)
  /// - +0.5 if drift has significant move
  /// - +0.5 extra if drift direction is non-Home (less obvious)
  Future<SourceScore> _scoreOdds(Match match) async {
    try {
      final h2h = match.h2h;
      if (h2h == null) {
        return SourceScore.inactive(SourceType.odds, 'No odds data');
      }

      var score = 0.5;
      final reasoning = <String>[
        'margin ${(h2h.bookmakerMargin * 100).toStringAsFixed(1)}%'
      ];

      if (h2h.bookmakerMargin < 0.05) {
        score += 0.5;
        reasoning.add('sharp book');
      }

      final snapshots = StorageService.getSnapshotsForMatch(match.id);
      if (snapshots.length >= 2) {
        final drift = OddsDrift.compute(snapshots.first, snapshots.last);
        if (drift.hasSignificantMove) {
          score += 0.5;
          final dom = drift.dominantDrift;
          final sign = dom.percent > 0 ? '+' : '';
          reasoning.add('drift ${dom.side} $sign${dom.percent.toStringAsFixed(1)}%');

          if (dom.side != 'Home') {
            score += 0.5;
            reasoning.add('non-favourite direction');
          }
        }
      }

      score = score.clamp(0.0, SourceType.odds.maxScore);
      return SourceScore(
        source: SourceType.odds,
        score: score,
        reasoning: reasoning.join(', '),
        isActive: true,
      );
    } catch (e) {
      return SourceScore.inactive(SourceType.odds, 'Error: $e');
    }
  }

  /// SOURCE 2: Football-Data (max 1.5)
  /// - 0.3 active baseline
  /// - +0.4 if either side has strong form (>= 4 wins in last 5)
  /// - +0.4 if H2H clearly favours one side (>= 3 wins in last 5)
  /// - +0.4 if standings gap >= 8 positions
  Future<SourceScore> _scoreFootballData(Match match) async {
    if (footballService == null || !footballService!.hasApiKey) {
      return SourceScore.inactive(SourceType.footballData, 'No API key');
    }
    if (match.sport != Sport.soccer) {
      return SourceScore.inactive(
          SourceType.footballData, 'Not a soccer match');
    }

    FootballDataSignal? signal = StorageService.getFootballSignal(match.id);
    if (signal == null ||
        DateTime.now().difference(signal.fetchedAt) > _signalCacheTtl) {
      try {
        signal = await footballService!.getSignalForMatch(match);
        await StorageService.saveFootballSignal(signal);
      } catch (e) {
        return SourceScore.inactive(
            SourceType.footballData, 'Fetch failed: $e');
      }
    }

    var score = 0.3;
    final reasoning = <String>[];

    final homeWins = signal.homeWinsForm;
    final awayWins = signal.awayWinsForm;
    if (homeWins >= 4 || awayWins >= 4) {
      score += 0.4;
      reasoning.add(homeWins >= 4 ? 'home strong form' : 'away strong form');
    }

    final h2hTotal =
        signal.h2hHomeWins + signal.h2hDraws + signal.h2hAwayWins;
    if (h2hTotal >= 5) {
      if (signal.h2hHomeWins >= 3 || signal.h2hAwayWins >= 3) {
        score += 0.4;
        reasoning.add(signal.h2hHomeWins >= 3
            ? 'home H2H dominant'
            : 'away H2H dominant');
      }
    }

    if (signal.homePosition != null && signal.awayPosition != null) {
      final gap = (signal.homePosition! - signal.awayPosition!).abs();
      if (gap >= 8) {
        score += 0.4;
        reasoning.add('standings gap $gap');
      }
    }

    reasoning.add(
        'form H${signal.homeFormLast5.join()} A${signal.awayFormLast5.join()}');

    score = score.clamp(0.0, SourceType.footballData.maxScore);
    return SourceScore(
      source: SourceType.footballData,
      score: score,
      reasoning: reasoning.join(', '),
      isActive: true,
    );
  }

  /// SOURCE 3: NBA Stats (max 1.0)
  /// - 0.3 active baseline
  /// - +0.35 if either side has >= 7/10 recent wins
  /// - +0.35 if rest days difference >= 3
  Future<SourceScore> _scoreNbaStats(Match match) async {
    if (nbaService == null) {
      return SourceScore.inactive(SourceType.nbaStats, 'Service unavailable');
    }
    if (match.sport != Sport.basketball) {
      return SourceScore.inactive(SourceType.nbaStats, 'Not an NBA match');
    }

    NbaStatsSignal? signal = StorageService.getNbaSignal(match.id);
    if (signal == null ||
        DateTime.now().difference(signal.fetchedAt) > _signalCacheTtl) {
      try {
        signal = await nbaService!.getSignalForMatch(match);
        await StorageService.saveNbaSignal(signal);
      } catch (e) {
        return SourceScore.inactive(
            SourceType.nbaStats, 'Fetch failed: $e');
      }
    }

    var score = 0.3;
    final reasoning = <String>[];

    if (signal.homeWinsLast10 >= 7 || signal.awayWinsLast10 >= 7) {
      score += 0.35;
      reasoning.add(
          signal.homeWinsLast10 >= 7 ? 'home hot streak' : 'away hot streak');
    }

    if (signal.homeRestDays != null && signal.awayRestDays != null) {
      final diff = (signal.homeRestDays! - signal.awayRestDays!).abs();
      if (diff >= 3) {
        score += 0.35;
        reasoning.add('rest diff $diff days');
      }
    }

    reasoning.add(
        'last10 H${signal.homeWinsLast10} A${signal.awayWinsLast10}');

    score = score.clamp(0.0, SourceType.nbaStats.maxScore);
    return SourceScore(
      source: SourceType.nbaStats,
      score: score,
      reasoning: reasoning.join(', '),
      isActive: true,
    );
  }

  /// SOURCE 4: Reddit (max 1.0)
  /// - inactive if mention count < 3
  /// - 0.2 baseline
  /// - +0.3 if mention count >= 10 (high buzz)
  /// - +0.3 if sentiment bias |x| > 0.3 (clear tilt)
  /// - +0.2 if top post upvotes >= 500 (viral)
  Future<SourceScore> _scoreReddit(Match match) async {
    if (redditMonitor == null) {
      return SourceScore.inactive(SourceType.reddit, 'Service unavailable');
    }

    RedditSignal? signal = StorageService.getRedditSignal(match.id);
    if (signal == null ||
        DateTime.now().difference(signal.fetchedAt) > _signalCacheTtl) {
      try {
        signal = await redditMonitor!.getSignalForMatch(match);
        await StorageService.saveRedditSignal(signal);
      } catch (e) {
        return SourceScore.inactive(
            SourceType.reddit, 'Fetch failed: $e');
      }
    }

    if (signal.mentionCount < 3) {
      return SourceScore.inactive(
        SourceType.reddit,
        'Low mention count (${signal.mentionCount})',
      );
    }

    var score = 0.2;
    final reasoning = <String>['${signal.mentionCount} mentions'];

    if (signal.mentionCount >= 10) {
      score += 0.3;
      reasoning.add('high buzz');
    }

    final bias = signal.getSentimentBias(match.home, match.away);
    if (bias.abs() > 0.3) {
      score += 0.3;
      reasoning.add(bias > 0 ? 'away tilt' : 'home tilt');
    }

    if (signal.topUpvotes >= 500) {
      score += 0.2;
      reasoning.add('viral post');
    }

    score = score.clamp(0.0, SourceType.reddit.maxScore);
    return SourceScore(
      source: SourceType.reddit,
      score: score,
      reasoning: reasoning.join(', '),
      isActive: true,
    );
  }

  /// SOURCE 5: Telegram (max 0.5, weighted by channel reliability)
  /// - inactive if no recent signals matching either team
  /// - score = clamp(sum(weights) * 0.25, 0, 0.5)
  /// - weights: Visoka=1.0, Srednja=0.7, Niska=0.3, Novo=0.5
  Future<SourceScore> _scoreTelegram(Match match) async {
    final recent = telegramProvider.recentSignals;
    if (recent.isEmpty) {
      return SourceScore.inactive(SourceType.telegram, 'No signals');
    }

    final homeL = match.home.toLowerCase();
    final awayL = match.away.toLowerCase();
    final relevant = recent.where((s) {
      final text = s.text.toLowerCase();
      return text.contains(homeL) || text.contains(awayL);
    }).toList();

    if (relevant.isEmpty) {
      return SourceScore.inactive(
          SourceType.telegram, 'No matching signals');
    }

    final channels = telegramProvider.channels;
    double weightedSum = 0;
    final reasoning = <String>[];
    for (final signal in relevant) {
      final channel = channels.firstWhere(
        (c) => c.username == signal.channelUsername,
        orElse: () => MonitoredChannel(
          username: signal.channelUsername,
          addedAt: DateTime.now(),
        ),
      );
      final weight = switch (channel.reliabilityLabel) {
        'Visoka' => 1.0,
        'Srednja' => 0.7,
        'Niska' => 0.3,
        _ => 0.5,
      };
      weightedSum += weight;
      reasoning.add('${signal.channelUsername} (${channel.reliabilityLabel})');
    }

    final score = (weightedSum * 0.25).clamp(0.0, SourceType.telegram.maxScore);
    final reasoningStr = reasoning.length > 3
        ? '${reasoning.take(3).join(', ')}...'
        : reasoning.join(', ');

    return SourceScore(
      source: SourceType.telegram,
      score: score,
      reasoning: reasoningStr,
      isActive: true,
    );
  }
}
