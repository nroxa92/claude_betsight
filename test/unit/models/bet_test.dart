import 'package:betsight/models/bet.dart';
import 'package:betsight/models/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final placedAt = DateTime(2026, 4, 18, 12, 0);
  final kickoff = DateTime(2026, 4, 18, 14, 0);
  final settledAt = DateTime(2026, 4, 18, 16, 0);

  Bet buildBet({
    String id = 'bet-1',
    Sport sport = Sport.soccer,
    String league = 'EPL',
    String home = 'Arsenal',
    String away = 'Liverpool',
    BetSelection selection = BetSelection.home,
    double odds = 2.0,
    double stake = 10.0,
    String? bookmaker,
    String? notes,
    DateTime? placed,
    DateTime? matchStartedAt,
    BetStatus status = BetStatus.pending,
    DateTime? settled,
    String? linkedMatchId,
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
        bookmaker: bookmaker,
        notes: notes,
        placedAt: placed ?? placedAt,
        matchStartedAt: matchStartedAt,
        status: status,
        settledAt: settled,
        linkedMatchId: linkedMatchId,
      );

  group('BetSelection', () {
    test('has 3 values', () {
      expect(BetSelection.values, hasLength(3));
    });
    test('display maps correctly', () {
      expect(BetSelection.home.display, 'Home');
      expect(BetSelection.draw.display, 'Draw');
      expect(BetSelection.away.display, 'Away');
    });
  });

  group('BetStatus', () {
    test('has 4 values', () {
      expect(BetStatus.values, hasLength(4));
    });
    test('display maps correctly', () {
      expect(BetStatus.pending.display, 'Pending');
      expect(BetStatus.won.display, 'Won');
      expect(BetStatus.lost.display, 'Lost');
      expect(BetStatus.void_.display, 'Void');
    });
    test('isSettled false only for pending', () {
      expect(BetStatus.pending.isSettled, isFalse);
      expect(BetStatus.won.isSettled, isTrue);
      expect(BetStatus.lost.isSettled, isTrue);
      expect(BetStatus.void_.isSettled, isTrue);
    });
  });

  group('Bet.potentialPayout / potentialProfit', () {
    test('2.0 odds, 10 stake → payout 20, profit 10', () {
      final b = buildBet(odds: 2.0, stake: 10.0);
      expect(b.potentialPayout, 20.0);
      expect(b.potentialProfit, 10.0);
    });
    test('1.5 odds, 100 stake → payout 150, profit 50', () {
      final b = buildBet(odds: 1.5, stake: 100.0);
      expect(b.potentialPayout, 150.0);
      expect(b.potentialProfit, 50.0);
    });
    test('5.0 odds, 20 stake → payout 100, profit 80', () {
      final b = buildBet(odds: 5.0, stake: 20.0);
      expect(b.potentialPayout, 100.0);
      expect(b.potentialProfit, 80.0);
    });
  });

  group('Bet.actualProfit', () {
    test('pending → null', () {
      expect(buildBet(status: BetStatus.pending).actualProfit, isNull);
    });
    test('won → stake * (odds-1)', () {
      final b = buildBet(status: BetStatus.won, odds: 2.5, stake: 10.0);
      expect(b.actualProfit, 15.0);
    });
    test('lost → -stake', () {
      final b = buildBet(status: BetStatus.lost, stake: 10.0);
      expect(b.actualProfit, -10.0);
    });
    test('void → 0', () {
      expect(buildBet(status: BetStatus.void_).actualProfit, 0.0);
    });
  });

  group('Bet.impliedProbability', () {
    test('2.0 odds → 0.5', () {
      expect(buildBet(odds: 2.0).impliedProbability, 0.5);
    });
    test('4.0 odds → 0.25', () {
      expect(buildBet(odds: 4.0).impliedProbability, 0.25);
    });
  });

  group('Bet.isLiveBet / isPreMatchBet', () {
    test('matchStartedAt null → pre-match (backward-compat)', () {
      final b = buildBet(matchStartedAt: null);
      expect(b.isLiveBet, isFalse);
      expect(b.isPreMatchBet, isTrue);
    });
    test('placedAt before kickoff → pre-match', () {
      final b = buildBet(placed: placedAt, matchStartedAt: kickoff);
      expect(b.isLiveBet, isFalse);
      expect(b.isPreMatchBet, isTrue);
    });
    test('placedAt after kickoff → live', () {
      final b = buildBet(
        placed: kickoff.add(const Duration(minutes: 30)),
        matchStartedAt: kickoff,
      );
      expect(b.isLiveBet, isTrue);
      expect(b.isPreMatchBet, isFalse);
    });
    test('placedAt exactly at kickoff → not live (isAfter strict)', () {
      final b = buildBet(placed: kickoff, matchStartedAt: kickoff);
      expect(b.isLiveBet, isFalse);
    });
  });

  group('Bet.copyWith', () {
    test('status update preserves other fields', () {
      final b = buildBet(notes: 'orig', odds: 2.5, stake: 10);
      final c = b.copyWith(status: BetStatus.won);
      expect(c.status, BetStatus.won);
      expect(c.notes, 'orig');
      expect(c.odds, 2.5);
      expect(c.stake, 10);
      expect(c.id, b.id);
    });
    test('settledAt update', () {
      final b = buildBet();
      final c = b.copyWith(settledAt: settledAt);
      expect(c.settledAt, settledAt);
    });
    test('notes update', () {
      final b = buildBet(notes: 'old');
      final c = b.copyWith(notes: 'new');
      expect(c.notes, 'new');
    });
    test('no args → copy with same values', () {
      final b = buildBet(status: BetStatus.won, notes: 'keep');
      final c = b.copyWith();
      expect(c.status, BetStatus.won);
      expect(c.notes, 'keep');
    });
  });

  group('Bet.toMap + fromMap roundtrip', () {
    test('minimal bet (no optionals)', () {
      final original = buildBet();
      final parsed = Bet.fromMap(original.toMap());
      expect(parsed.id, original.id);
      expect(parsed.sport, original.sport);
      expect(parsed.league, original.league);
      expect(parsed.home, original.home);
      expect(parsed.away, original.away);
      expect(parsed.selection, original.selection);
      expect(parsed.odds, original.odds);
      expect(parsed.stake, original.stake);
      expect(parsed.placedAt, original.placedAt);
      expect(parsed.status, original.status);
      expect(parsed.bookmaker, isNull);
      expect(parsed.notes, isNull);
      expect(parsed.matchStartedAt, isNull);
      expect(parsed.settledAt, isNull);
      expect(parsed.linkedMatchId, isNull);
    });
    test('fully populated bet', () {
      final original = buildBet(
        bookmaker: 'Pinnacle',
        notes: 'Good edge',
        matchStartedAt: kickoff,
        status: BetStatus.won,
        settled: settledAt,
        linkedMatchId: 'match-abc',
      );
      final parsed = Bet.fromMap(original.toMap());
      expect(parsed.bookmaker, 'Pinnacle');
      expect(parsed.notes, 'Good edge');
      expect(parsed.matchStartedAt, kickoff);
      expect(parsed.status, BetStatus.won);
      expect(parsed.settledAt, settledAt);
      expect(parsed.linkedMatchId, 'match-abc');
    });
    test('fromMap handles int odds/stake via num.toDouble', () {
      final map = {
        'id': 'b',
        'sport': 'soccer',
        'league': 'EPL',
        'home': 'X',
        'away': 'Y',
        'selection': 'home',
        'odds': 2, // int
        'stake': 10, // int
        'placedAt': '2026-04-18T12:00:00.000',
        'status': 'pending',
      };
      final bet = Bet.fromMap(map);
      expect(bet.odds, 2.0);
      expect(bet.stake, 10.0);
    });
    test('all BetStatus values roundtrip', () {
      for (final s in BetStatus.values) {
        final b = buildBet(status: s);
        expect(Bet.fromMap(b.toMap()).status, s);
      }
    });
    test('all BetSelection values roundtrip', () {
      for (final sel in BetSelection.values) {
        final b = buildBet(selection: sel);
        expect(Bet.fromMap(b.toMap()).selection, sel);
      }
    });
  });
}
