import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/bet.dart';

class EquityCurveChart extends StatelessWidget {
  final List<Bet> settledBets;
  final String currency;

  const EquityCurveChart({
    super.key,
    required this.settledBets,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (settledBets.length < 2) {
      return Center(
        child: Text(
          'Not enough settled bets',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    final sorted = [...settledBets]..sort(
        (a, b) =>
            (a.settledAt ?? a.placedAt).compareTo(b.settledAt ?? b.placedAt),
      );

    var running = 0.0;
    final spots = <FlSpot>[const FlSpot(0, 0)];
    for (var i = 0; i < sorted.length; i++) {
      running += sorted[i].actualProfit ?? 0;
      spots.add(FlSpot((i + 1).toDouble(), running));
    }

    final positive = running >= 0;
    final lineColor = positive ? Colors.green : Colors.red;

    final isSmall = MediaQuery.of(context).size.width < 360;
    final leftReserved = isSmall ? 40.0 : 50.0;
    final labelFontSize = isSmall ? 8.0 : 9.0;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: lineColor,
            barWidth: 2,
            isCurved: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftReserved,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(0)}$currency',
                style: TextStyle(fontSize: labelFontSize),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) => Text(
                '#${value.toInt()}',
                style: TextStyle(fontSize: labelFontSize),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
