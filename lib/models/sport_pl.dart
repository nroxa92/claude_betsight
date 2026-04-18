import 'sport.dart';

class SportPl {
  final Sport sport;
  final int bets;
  final int won;
  final int lost;
  final double totalStake;
  final double totalProfit;
  final double roiPercent;

  const SportPl({
    required this.sport,
    required this.bets,
    required this.won,
    required this.lost,
    required this.totalStake,
    required this.totalProfit,
    required this.roiPercent,
  });

  double get winRate => bets > 0 ? (won / bets) * 100 : 0;
}
