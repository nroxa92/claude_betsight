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

  group('Bet flow end-to-end', () {
    test('place → settle won → stats reflect profit', () async {
      final p = BetsProvider();
      await p.setBankroll(const BankrollConfig(
        totalBankroll: 1000,
        defaultStakeUnit: 10,
        currency: 'EUR',
      ));

      final bet = Bet(
        id: 'flow-1',
        sport: Sport.soccer,
        league: 'EPL',
        home: 'Arsenal',
        away: 'Liverpool',
        selection: BetSelection.home,
        odds: 2.5,
        stake: 20,
        placedAt: DateTime(2026, 4, 18),
        status: BetStatus.pending,
      );
      await p.addBet(bet);
      expect(p.pendingBets, 1);
      expect(p.totalProfit, 0);

      await p.settleBet('flow-1', BetStatus.won);
      expect(p.wonBets, 1);
      expect(p.totalProfit, 30); // stake 20 * (odds 2.5 - 1)
      expect(p.roi, closeTo(150, 0.001));

      // Delete and verify totals reset
      await p.deleteBet('flow-1');
      expect(p.totalBets, 0);
      expect(p.totalProfit, 0);
    });

    test('multiple bets across sports build perSportBreakdown', () async {
      final p = BetsProvider();

      Future<void> placeAndSettle(String id, Sport sport, BetStatus status,
          {double stake = 10, double odds = 2.0}) async {
        await p.addBet(Bet(
          id: id,
          sport: sport,
          league: 'X',
          home: 'a',
          away: 'b',
          selection: BetSelection.home,
          odds: odds,
          stake: stake,
          placedAt: DateTime(2026, 4, 18),
          status: BetStatus.pending,
        ));
        await p.settleBet(id, status);
      }

      await placeAndSettle('b-s1', Sport.soccer, BetStatus.won);
      await placeAndSettle('b-s2', Sport.soccer, BetStatus.lost);
      await placeAndSettle('b-nba', Sport.basketball, BetStatus.won);
      await placeAndSettle('b-atp', Sport.tennis, BetStatus.void_);

      final bd = p.perSportBreakdown;
      expect(bd.keys.toSet(), {Sport.soccer, Sport.basketball, Sport.tennis});
      expect(bd[Sport.soccer]!.bets, 2);
      expect(bd[Sport.soccer]!.won, 1);
      expect(bd[Sport.basketball]!.won, 1);
    });

    test('persistence across provider instances', () async {
      {
        final p = BetsProvider();
        await p.addBet(Bet(
          id: 'persist',
          sport: Sport.soccer,
          league: 'EPL',
          home: 'A',
          away: 'B',
          selection: BetSelection.home,
          odds: 2.0,
          stake: 10,
          placedAt: DateTime(2026, 4, 18),
          status: BetStatus.pending,
        ));
      }
      // Fresh provider instance, same hive state
      final p2 = BetsProvider();
      expect(p2.allBets, hasLength(1));
      expect(p2.allBets.first.id, 'persist');
    });

    test('filters isolate bet list correctly', () async {
      final p = BetsProvider();
      await p.addBet(Bet(
        id: 'a',
        sport: Sport.soccer,
        league: 'EPL',
        home: 'Arsenal',
        away: 'Liverpool',
        selection: BetSelection.home,
        odds: 2.0,
        stake: 10,
        placedAt: DateTime(2026, 4, 18),
        status: BetStatus.pending,
      ));
      await p.addBet(Bet(
        id: 'b',
        sport: Sport.basketball,
        league: 'NBA',
        home: 'Lakers',
        away: 'Warriors',
        selection: BetSelection.home,
        odds: 1.9,
        stake: 10,
        placedAt: DateTime(2026, 4, 18),
        status: BetStatus.pending,
      ));

      p.toggleSportFilter(Sport.soccer);
      expect(p.applyFilters(p.allBets).map((b) => b.id).toList(), ['a']);

      p.setSearchText('lakers');
      // search combined with sport filter: must match both → 0
      expect(p.applyFilters(p.allBets), isEmpty);

      p.clearFilters();
      expect(p.applyFilters(p.allBets), hasLength(2));
    });

    test('settled storage persists across reloads (won, void, lost)', () async {
      final p = BetsProvider();
      final bets = [
        Bet(
          id: 'w',
          sport: Sport.soccer,
          league: 'x',
          home: 'a',
          away: 'b',
          selection: BetSelection.home,
          odds: 2.0,
          stake: 10,
          placedAt: DateTime(2026, 4, 18),
          status: BetStatus.pending,
        ),
        Bet(
          id: 'l',
          sport: Sport.soccer,
          league: 'x',
          home: 'a',
          away: 'b',
          selection: BetSelection.home,
          odds: 2.0,
          stake: 10,
          placedAt: DateTime(2026, 4, 18),
          status: BetStatus.pending,
        ),
        Bet(
          id: 'v',
          sport: Sport.soccer,
          league: 'x',
          home: 'a',
          away: 'b',
          selection: BetSelection.home,
          odds: 2.0,
          stake: 10,
          placedAt: DateTime(2026, 4, 18),
          status: BetStatus.pending,
        ),
      ];
      for (final b in bets) {
        await p.addBet(b);
      }
      await p.settleBet('w', BetStatus.won);
      await p.settleBet('l', BetStatus.lost);
      await p.settleBet('v', BetStatus.void_);

      // new instance reads from storage
      final p2 = BetsProvider();
      expect(p2.wonBets, 1);
      expect(p2.lostBets, 1);
      expect(p2.voidBets, 1);
      expect(p2.totalProfit, 0);
      expect(StorageService.getAllBets(), hasLength(3));
    });
  });
}
