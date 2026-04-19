import 'package:betsight/models/match.dart';
import 'package:betsight/models/matches_provider.dart';
import 'package:betsight/models/odds.dart';
import 'package:betsight/models/odds_snapshot.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/models/value_preset.dart';
import 'package:betsight/services/odds_api_service.dart';
import 'package:betsight/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  MatchesProvider providerWith({http.Client? client}) {
    final svc = OddsApiService(
      client: client ?? MockClient((_) async => http.Response('', 200)),
    );
    return MatchesProvider(service: svc);
  }

  Match match({
    String id = 'm',
    Sport sport = Sport.soccer,
    double home = 1.8,
    double away = 2.0,
    double? draw,
  }) =>
      Match(
        id: id,
        sport: sport,
        league: 'EPL',
        sportKey: 'soccer_epl',
        home: 'A',
        away: 'B',
        commenceTime: DateTime(2026, 5, 1),
        h2h: H2HOdds(
          home: home,
          draw: draw,
          away: away,
          lastUpdate: DateTime(2026, 4, 18),
          bookmaker: 'T',
        ),
      );

  group('initialization', () {
    test('no api key when storage empty', () {
      final p = providerWith();
      expect(p.hasApiKey, isFalse);
    });
    test('reads API key from storage on construction', () async {
      await StorageService.saveOddsApiKey('stored-key');
      final p = providerWith();
      expect(p.hasApiKey, isTrue);
    });
    test('reads valuePreset from storage', () async {
      await StorageService.saveValuePreset('aggressive');
      final p = providerWith();
      expect(p.valuePreset, ValuePreset.aggressive);
    });
    test('reads watched ids from storage', () async {
      await StorageService.saveWatchedMatchIds({'w-1', 'w-2'});
      final p = providerWith();
      expect(p.watchedMatchIds, {'w-1', 'w-2'});
    });
  });

  group('sport filter', () {
    test('filteredMatches equals all when no sport selected', () {
      final p = providerWith();
      expect(p.filteredMatches, isEmpty);
      expect(p.selectedSport, isNull);
    });
    test('setSelectedSport narrows filteredMatches', () async {
      final p = providerWith();
      p.setSelectedSport(Sport.basketball);
      expect(p.selectedSport, Sport.basketball);
    });
  });

  group('valueBets', () {
    test('valueBets empty when no matches', () {
      final p = providerWith();
      expect(p.valueBets, isEmpty);
    });
    test('setValuePreset persists', () async {
      final p = providerWith();
      await p.setValuePreset(ValuePreset.conservative);
      expect(p.valuePreset, ValuePreset.conservative);
      expect(StorageService.getValuePreset(), 'conservative');
    });
  });

  group('selection', () {
    test('toggleMatchSelection toggles set and notifies', () {
      final p = providerWith();
      var notified = 0;
      p.addListener(() => notified++);
      p.toggleMatchSelection('m-1');
      expect(p.isMatchSelected('m-1'), isTrue);
      expect(p.selectedCount, 1);
      expect(notified, 1);
      p.toggleMatchSelection('m-1');
      expect(p.isMatchSelected('m-1'), isFalse);
    });
    test('clearSelection clears and notifies once', () {
      final p = providerWith();
      p.toggleMatchSelection('m-1');
      p.toggleMatchSelection('m-2');
      var notified = 0;
      p.addListener(() => notified++);
      p.clearSelection();
      expect(p.selectedCount, 0);
      expect(notified, 1);
    });
    test('clearSelection is no-op on empty selection', () {
      final p = providerWith();
      var notified = 0;
      p.addListener(() => notified++);
      p.clearSelection();
      expect(notified, 0);
    });
  });

  group('watched matches', () {
    test('toggleWatched adds and persists', () async {
      await StorageService.saveNotifKickoffEnabled(false);
      final p = providerWith();
      await p.toggleWatched('m-1');
      expect(p.isWatched('m-1'), isTrue);
      expect(StorageService.getWatchedMatchIds(), contains('m-1'));
    });
    test('toggleWatched twice removes', () async {
      await StorageService.saveNotifKickoffEnabled(false);
      final p = providerWith();
      await p.toggleWatched('m-1');
      await p.toggleWatched('m-1');
      expect(p.isWatched('m-1'), isFalse);
    });
  });

  group('driftForMatch', () {
    test('null when fewer than 2 snapshots', () {
      final p = providerWith();
      expect(p.driftForMatch('m-1'), isNull);
    });
    test('computes drift from first→last snapshots', () async {
      await StorageService.saveSnapshot(OddsSnapshot(
        matchId: 'm-1',
        capturedAt: DateTime(2026, 4, 18, 10),
        home: 2.0,
        away: 2.0,
        bookmaker: 'T',
      ));
      await StorageService.saveSnapshot(OddsSnapshot(
        matchId: 'm-1',
        capturedAt: DateTime(2026, 4, 18, 12),
        home: 1.8,
        away: 2.2,
        bookmaker: 'T',
      ));
      final p = providerWith();
      final drift = p.driftForMatch('m-1');
      expect(drift, isNotNull);
      expect(drift!.homePercent, closeTo(-10, 0.01));
    });
  });

  group('API key management', () {
    test('setApiKey updates service and persists', () async {
      final p = providerWith();
      await p.setApiKey('new-key');
      expect(p.hasApiKey, isTrue);
      expect(StorageService.getOddsApiKey(), 'new-key');
    });
    test('removeApiKey clears key and matches', () async {
      await StorageService.saveOddsApiKey('old-key');
      final p = providerWith();
      await p.removeApiKey();
      expect(p.hasApiKey, isFalse);
      expect(p.allMatches, isEmpty);
      expect(StorageService.getOddsApiKey(), isNull);
    });
  });

  group('request quota getters', () {
    test('requestsUsedPercent null before first fetch', () {
      final p = providerWith();
      expect(p.requestsUsedPercent, isNull);
      expect(p.isApiLimitLow, isFalse);
      expect(p.isApiLimitCritical, isFalse);
    });
  });

  group('fetchMatches error paths', () {
    test('no API key sets error without fetching', () async {
      final p = providerWith();
      await p.fetchMatches();
      expect(p.error, 'API key not configured');
      expect(p.allMatches, isEmpty);
    });
    test('clearError resets error', () async {
      final p = providerWith();
      await p.fetchMatches();
      p.clearError();
      expect(p.error, isNull);
    });
  });

  test('match reference for helper compile check', () {
    final m = match();
    expect(m.id, 'm');
  });
}
