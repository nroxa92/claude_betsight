import 'package:betsight/models/bankroll.dart';
import 'package:betsight/models/bet.dart';
import 'package:betsight/models/bets_provider.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  Bet makeBet({
    String id = 'b',
    Sport sport = Sport.soccer,
    double stake = 10,
    double odds = 2.0,
    BetStatus status = BetStatus.pending,
    DateTime? placedAt,
    DateTime? settledAt,
    BetSelection selection = BetSelection.home,
    String home = 'A',
    String away = 'B',
    String league = 'EPL',
  }) =>
      Bet(
        id: id,
        sport: sport,
        league: league,
        home: home,
        away: away,
        selection: selection,
        odds: odds,
        stake: stake,
        placedAt: placedAt ?? DateTime(2026, 4, 18),
        settledAt: settledAt,
        status: status,
      );

  group('initialization', () {
    test('empty when storage empty', () {
      final p = BetsProvider();
      expect(p.allBets, isEmpty);
      expect(p.bankroll.currency, 'EUR');
    });
    test('loads bets from storage on construction', () async {
      await StorageService.saveBet(makeBet(id: 'pre-1'));
      final p = BetsProvider();
      expect(p.allBets, hasLength(1));
      expect(p.allBets.first.id, 'pre-1');
    });
    test('loads bankroll from storage', () async {
      await StorageService.saveBankrollConfig({
        'totalBankroll': 500.0,
        'defaultStakeUnit': 25.0,
        'currency': 'USD',
      });
      final p = BetsProvider();
      expect(p.bankroll.totalBankroll, 500);
      expect(p.bankroll.currency, 'USD');
    });
    test('falls back to default bankroll on malformed stored config', () async {
      await StorageService.saveBankrollConfig({'invalid': 'data'});
      final p = BetsProvider();
      expect(p.bankroll.currency, 'EUR');
    });
  });

  group('addBet/settleBet/deleteBet', () {
    test('addBet persists and notifies', () async {
      final p = BetsProvider();
      var notified = 0;
      p.addListener(() => notified++);
      await p.addBet(makeBet(id: 'b-1'));
      expect(p.allBets, hasLength(1));
      expect(notified, 1);
      expect(StorageService.getAllBets(), hasLength(1));
    });
    test('settleBet updates status + settledAt', () async {
      final p = BetsProvider();
      await p.addBet(makeBet(id: 'b-1'));
      await p.settleBet('b-1', BetStatus.won);
      final b = p.allBets.first;
      expect(b.status, BetStatus.won);
      expect(b.settledAt, isNotNull);
    });
    test('settleBet with missing id is no-op', () async {
      final p = BetsProvider();
      await p.settleBet('ghost', BetStatus.won);
      expect(p.allBets, isEmpty);
    });
    test('deleteBet removes and persists', () async {
      final p = BetsProvider();
      await p.addBet(makeBet(id: 'b-1'));
      await p.deleteBet('b-1');
      expect(p.allBets, isEmpty);
      expect(StorageService.getAllBets(), isEmpty);
    });
  });

  group('bet lists and stats', () {
    test('openBets vs settledBets separation', () async {
      final p = BetsProvider();
      await p.addBet(makeBet(id: 'open'));
      await p.addBet(
        makeBet(id: 'won', status: BetStatus.won, settledAt: DateTime(2026, 4, 18, 15)),
      );
      expect(p.openBets.map((b) => b.id), ['open']);
      expect(p.settledBets.map((b) => b.id), ['won']);
    });
    test('stat counts across statuses', () async {
      final p = BetsProvider();
      await p.addBet(makeBet(id: '1', status: BetStatus.won));
      await p.addBet(makeBet(id: '2', status: BetStatus.lost));
      await p.addBet(makeBet(id: '3', status: BetStatus.void_));
      await p.addBet(makeBet(id: '4', status: BetStatus.pending));
      expect(p.totalBets, 4);
      expect(p.wonBets, 1);
      expect(p.lostBets, 1);
      expect(p.voidBets, 1);
      expect(p.pendingBets, 1);
    });
    test('winRate = won / (won+lost)', () async {
      final p = BetsProvider();
      await p.addBet(makeBet(id: '1', status: BetStatus.won));
      await p.addBet(makeBet(id: '2', status: BetStatus.lost));
      await p.addBet(makeBet(id: '3', status: BetStatus.won));
      expect(p.winRate, closeTo(0.667, 0.001));
    });
    test('winRate returns 0 with no decisive bets', () async {
      final p = BetsProvider();
      await p.addBet(makeBet(id: '1', status: BetStatus.pending));
      await p.addBet(makeBet(id: '2', status: BetStatus.void_));
      expect(p.winRate, 0);
    });
    test('totalProfit sums actualProfit, ignoring pending', () async {
      final p = BetsProvider();
      await p.addBet(
          makeBet(id: '1', stake: 10, odds: 2.0, status: BetStatus.won)); // +10
      await p.addBet(
          makeBet(id: '2', stake: 5, odds: 3.0, status: BetStatus.lost)); // -5
      await p.addBet(makeBet(id: '3', status: BetStatus.pending));
      expect(p.totalProfit, 5.0);
    });
    test('roi = profit / totalStakedOnSettled', () async {
      final p = BetsProvider();
      await p.addBet(
          makeBet(id: '1', stake: 10, odds: 2.0, status: BetStatus.won)); // +10
      await p.addBet(
          makeBet(id: '2', stake: 10, odds: 2.0, status: BetStatus.lost)); // -10
      // total profit: 0, staked: 20 → roi 0
      expect(p.roi, 0);
    });
    test('roi returns 0 when nothing settled', () async {
      final p = BetsProvider();
      await p.addBet(makeBet(id: '1', status: BetStatus.pending));
      expect(p.roi, 0);
    });
    test('perSportBreakdown groups correctly', () async {
      final p = BetsProvider();
      await p.addBet(makeBet(
          id: '1', sport: Sport.soccer, stake: 10, odds: 2.0, status: BetStatus.won));
      await p.addBet(makeBet(
          id: '2', sport: Sport.basketball, stake: 10, status: BetStatus.lost));
      final bd = p.perSportBreakdown;
      expect(bd.keys, containsAll([Sport.soccer, Sport.basketball]));
      expect(bd[Sport.soccer]!.won, 1);
      expect(bd[Sport.basketball]!.lost, 1);
    });
  });

  group('filters', () {
    test('hasActiveFilters false by default', () {
      final p = BetsProvider();
      expect(p.hasActiveFilters, isFalse);
    });
    test('toggleSportFilter toggles set', () {
      final p = BetsProvider();
      p.toggleSportFilter(Sport.soccer);
      expect(p.filterSports, contains(Sport.soccer));
      p.toggleSportFilter(Sport.soccer);
      expect(p.filterSports, isEmpty);
    });
    test('toggleStatusFilter toggles set', () {
      final p = BetsProvider();
      p.toggleStatusFilter(BetStatus.won);
      expect(p.filterStatuses, contains(BetStatus.won));
      p.toggleStatusFilter(BetStatus.won);
      expect(p.filterStatuses, isEmpty);
    });
    test('setSearchText lowercases + trims', () {
      final p = BetsProvider();
      p.setSearchText('  Arsenal  ');
      expect(p.searchText, 'arsenal');
    });
    test('clearFilters resets all', () {
      final p = BetsProvider();
      p.toggleSportFilter(Sport.soccer);
      p.toggleStatusFilter(BetStatus.won);
      p.setSearchText('x');
      p.setFilterDateRange(DateTime(2026, 4, 1), DateTime(2026, 4, 30));
      expect(p.hasActiveFilters, isTrue);
      p.clearFilters();
      expect(p.hasActiveFilters, isFalse);
    });
    test('applyFilters — sport filter', () {
      final p = BetsProvider();
      p.toggleSportFilter(Sport.soccer);
      final all = [makeBet(id: '1', sport: Sport.soccer), makeBet(id: '2', sport: Sport.basketball)];
      expect(p.applyFilters(all).map((b) => b.id), ['1']);
    });
    test('applyFilters — status filter', () {
      final p = BetsProvider();
      p.toggleStatusFilter(BetStatus.won);
      final all = [
        makeBet(id: '1', status: BetStatus.won),
        makeBet(id: '2', status: BetStatus.lost),
      ];
      expect(p.applyFilters(all).map((b) => b.id), ['1']);
    });
    test('applyFilters — search matches team/league', () {
      final p = BetsProvider();
      p.setSearchText('arsenal');
      final all = [
        makeBet(id: '1', home: 'Arsenal', away: 'Liverpool'),
        makeBet(id: '2', home: 'City', away: 'United'),
      ];
      expect(p.applyFilters(all).map((b) => b.id), ['1']);
    });
    test('applyFilters — date range (from/to)', () {
      final p = BetsProvider();
      p.setFilterDateRange(DateTime(2026, 4, 17), DateTime(2026, 4, 19));
      final all = [
        makeBet(id: '1', placedAt: DateTime(2026, 4, 18)),
        makeBet(id: '2', placedAt: DateTime(2026, 4, 10)),
      ];
      expect(p.applyFilters(all).map((b) => b.id), ['1']);
    });
  });

  group('bankroll', () {
    test('setBankroll persists + notifies', () async {
      final p = BetsProvider();
      var notified = 0;
      p.addListener(() => notified++);
      await p.setBankroll(const BankrollConfig(
        totalBankroll: 1000,
        defaultStakeUnit: 50,
        currency: 'EUR',
      ));
      expect(p.bankroll.totalBankroll, 1000);
      expect(notified, 1);
      final reloaded = BetsProvider();
      expect(reloaded.bankroll.totalBankroll, 1000);
    });
  });

  group('error', () {
    test('clearError is no-op when no error', () {
      final p = BetsProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.clearError();
      expect(notified, 0);
    });
  });
}
