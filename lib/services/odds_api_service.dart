import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/match.dart';

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

  void dispose() => _client.close();
}

class OddsApiException implements Exception {
  final String message;
  OddsApiException(this.message);
  @override
  String toString() => 'OddsApiException: $message';
}
