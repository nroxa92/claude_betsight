import 'package:betsight/models/sport.dart';
import 'package:betsight/models/sport_pl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SportPl.winRate', () {
    test('0 bets → 0% (no division by zero)', () {
      const p = SportPl(
        sport: Sport.soccer,
        bets: 0,
        won: 0,
        lost: 0,
        totalStake: 0,
        totalProfit: 0,
        roiPercent: 0,
      );
      expect(p.winRate, 0);
    });
    test('10 bets, 5 won → 50%', () {
      const p = SportPl(
        sport: Sport.soccer,
        bets: 10,
        won: 5,
        lost: 5,
        totalStake: 100,
        totalProfit: 0,
        roiPercent: 0,
      );
      expect(p.winRate, 50);
    });
    test('4 bets, 3 won → 75%', () {
      const p = SportPl(
        sport: Sport.soccer,
        bets: 4,
        won: 3,
        lost: 1,
        totalStake: 40,
        totalProfit: 20,
        roiPercent: 50,
      );
      expect(p.winRate, 75);
    });
  });

  test('stores all fields verbatim', () {
    const p = SportPl(
      sport: Sport.basketball,
      bets: 5,
      won: 3,
      lost: 2,
      totalStake: 50,
      totalProfit: 15.5,
      roiPercent: 31.0,
    );
    expect(p.sport, Sport.basketball);
    expect(p.bets, 5);
    expect(p.won, 3);
    expect(p.lost, 2);
    expect(p.totalStake, 50);
    expect(p.totalProfit, 15.5);
    expect(p.roiPercent, 31.0);
  });
}
