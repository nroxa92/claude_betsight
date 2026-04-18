import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/odds_snapshot.dart';

class OddsMovementChart extends StatelessWidget {
  final List<OddsSnapshot> snapshots;
  final bool showDraw;

  const OddsMovementChart({
    super.key,
    required this.snapshots,
    required this.showDraw,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshots.length < 2) {
      return Center(
        child: Text(
          'Not enough snapshots yet (${snapshots.length}/2)',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    final isSmall = MediaQuery.of(context).size.width < 360;
    final leftReserved = isSmall ? 32.0 : 40.0;
    final labelFontSize = isSmall ? 9.0 : 10.0;

    final baseTime = snapshots.first.capturedAt.millisecondsSinceEpoch;

    final homeSpots = <FlSpot>[];
    final drawSpots = <FlSpot>[];
    final awaySpots = <FlSpot>[];

    for (final s in snapshots) {
      final x = (s.capturedAt.millisecondsSinceEpoch - baseTime) /
          (1000 * 60 * 60);
      homeSpots.add(FlSpot(x, s.home));
      if (showDraw && s.draw != null) drawSpots.add(FlSpot(x, s.draw!));
      awaySpots.add(FlSpot(x, s.away));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: homeSpots,
            color: Colors.blue,
            barWidth: 2,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
          if (showDraw && drawSpots.isNotEmpty)
            LineChartBarData(
              spots: drawSpots,
              color: Colors.orange,
              barWidth: 2,
              isCurved: true,
              dotData: const FlDotData(show: false),
            ),
          LineChartBarData(
            spots: awaySpots,
            color: Colors.red,
            barWidth: 2,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftReserved,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(isSmall ? 1 : 2),
                style: TextStyle(fontSize: labelFontSize),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(0)}h',
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
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.2,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
