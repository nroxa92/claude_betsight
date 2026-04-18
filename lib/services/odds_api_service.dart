import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cached_matches_entry.dart';
import '../models/match.dart';
import 'storage_service.dart';

typedef CachedMatchesResult = ({
  List<Match> matches,
  bool fromCache,
  int? remaining,
  DateTime? cachedAt,
});

class OddsApiService {
  final http.Client _client;
  String _apiKey = '';
  int? _remainingRequests;

  static const _baseUrl = 'https://api.the-odds-api.com/v4';
  static const _timeout = Duration(seconds: 15);

  OddsApiService({http.Client? client}) : _client = client ?? http.Client();

  bool get hasApiKey => _apiKey.isNotEmpty;
  int? get remainingRequests => _remainingRequests;

  void setApiKey(String key) => _apiKey = key;

  /// Fetch matches across one or more sport keys. Per-sport failures
  /// (timeout, 4xx other than 401/429, malformed JSON) are silently
  /// skipped and remaining sports still get tried — partial results are
  /// preferable to all-or-nothing. 401/429 still throw OddsApiException
  /// because they apply to the whole request, not a single sport.
  Future<List<Match>> getMatches({
    required List<String> sportKeys,
    String regions = 'eu',
    List<String> markets = const ['h2h'],
  }) async {
    if (!hasApiKey) {
      throw OddsApiException('API key not configured');
    }

    final allMatches = <Match>[];
    for (final sportKey in sportKeys) {
      try {
        final uri = Uri.parse('$_baseUrl/sports/$sportKey/odds').replace(
          queryParameters: {
            'apiKey': _apiKey,
            'regions': regions,
            'markets': markets.join(','),
            'oddsFormat': 'decimal',
          },
        );

        final response = await _client.get(uri).timeout(_timeout);

        final remaining = response.headers['x-requests-remaining'];
        if (remaining != null) {
          _remainingRequests = int.tryParse(remaining);
        }

        if (response.statusCode == 401) {
          throw OddsApiException('Invalid API key');
        } else if (response.statusCode == 429) {
          throw OddsApiException('Rate limit exceeded');
        } else if (response.statusCode == 422) {
          continue;
        } else if (response.statusCode != 200) {
          continue;
        }

        try {
          final data = json.decode(response.body) as List<dynamic>;
          for (final item in data) {
            try {
              allMatches.add(
                Match.fromJson(item as Map<String, dynamic>, sportKey),
              );
            } on FormatException {
              continue;
            }
          }
        } on FormatException {
          continue;
        }
      } on TimeoutException {
        continue;
      }
    }

    allMatches.sort((a, b) => a.commenceTime.compareTo(b.commenceTime));
    return allMatches;
  }

  /// Cached fetch — returns cache hit if entry exists and isn't expired,
  /// otherwise hits the API and saves a fresh entry. `forceRefresh` always
  /// bypasses the cache (used by pull-to-refresh).
  Future<CachedMatchesResult> getMatchesCached({
    required List<String> sportKeys,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = StorageService.getCachedMatches();
      if (cached != null) {
        final ttlMinutes = StorageService.getCacheTtlMinutes();
        if (!cached.isExpired(Duration(minutes: ttlMinutes))) {
          if (cached.remainingRequests != null) {
            _remainingRequests = cached.remainingRequests;
          }
          return (
            matches: cached.matches,
            fromCache: true,
            remaining: cached.remainingRequests,
            cachedAt: cached.fetchedAt,
          );
        }
      }
    }

    final matches = await getMatches(sportKeys: sportKeys);
    final entry = CachedMatchesEntry(
      matches: matches,
      fetchedAt: DateTime.now(),
      remainingRequests: _remainingRequests,
    );
    await StorageService.saveCachedMatches(entry);
    return (
      matches: matches,
      fromCache: false,
      remaining: _remainingRequests,
      cachedAt: null,
    );
  }

  void dispose() => _client.close();
}

class OddsApiException implements Exception {
  final String message;
  OddsApiException(this.message);
  @override
  String toString() => 'OddsApiException: $message';
}
