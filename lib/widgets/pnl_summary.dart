import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bets_provider.dart';
import '../models/sport.dart';
import '../models/sport_pl.dart';
import '../theme/app_theme.dart';
import 'charts/equity_curve_chart.dart';

class PlSummaryWidget extends StatelessWidget {
  const PlSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BetsProvider>(
      builder: (_, p, child) {
        if (p.totalBets == 0) return const SizedBox.shrink();

        final currency = p.bankroll.currency;
        final winRatePct = p.winRate * 100;
        final winRateColor =
            winRatePct > 50 ? AppTheme.green : Colors.grey[300]!;
        final roiColor = p.roi > 0
            ? AppTheme.green
            : p.roi < 0
                ? AppTheme.red
                : Colors.grey[300]!;
        final profitColor = p.totalProfit > 0
            ? AppTheme.green
            : p.totalProfit < 0
                ? AppTheme.red
                : Colors.grey[300]!;

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _Metric(
                      label: 'Total',
                      value: '${p.totalBets}',
                      unit: 'bets',
                    ),
                    _Metric(
                      label: 'Win rate',
                      value: '${winRatePct.toStringAsFixed(1)}%',
                      unit: '${p.wonBets}W ${p.lostBets}L',
                      color: winRateColor,
                    ),
                    _Metric(
                      label: 'ROI',
                      value: '${p.roi.toStringAsFixed(1)}%',
                      unit: 'on $currency',
                      color: roiColor,
                    ),
                    _Metric(
                      label: 'Total P/L',
                      value:
                          '${p.totalProfit >= 0 ? '+' : ''}${p.totalProfit.toStringAsFixed(2)}',
                      unit: currency,
                      color: profitColor,
                    ),
                  ],
                ),
              ),
            ),
            if (p.settledBets.length >= 2)
              Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equity Curve',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: EquityCurveChart(
                          settledBets: p.settledBets,
                          currency: currency,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (p.perSportBreakdown.isNotEmpty)
              _PerSportCard(breakdown: p.perSportBreakdown),
          ],
        );
      },
    );
  }
}

class _PerSportCard extends StatelessWidget {
  final Map<Sport, SportPl> breakdown;
  const _PerSportCard({required this.breakdown});

  static const _headerStyle = TextStyle(
    fontSize: 10,
    color: Colors.grey,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Per-sport breakdown',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                SizedBox(
                  width: 90,
                  child: Text('Sport', style: _headerStyle),
                ),
                Expanded(
                  child: Text('Bets',
                      style: _headerStyle, textAlign: TextAlign.right),
                ),
                Expanded(
                  child: Text('Win%',
                      style: _headerStyle, textAlign: TextAlign.right),
                ),
                Expanded(
                  child: Text('ROI',
                      style: _headerStyle, textAlign: TextAlign.right),
                ),
                SizedBox(
                  width: 70,
                  child: Text('P/L',
                      style: _headerStyle, textAlign: TextAlign.right),
                ),
              ],
            ),
            const Divider(height: 12),
            ...breakdown.entries.map((entry) {
              final pl = entry.value;
              final color = pl.roiPercent > 0
                  ? AppTheme.green
                  : pl.roiPercent < 0
                      ? AppTheme.red
                      : Colors.grey;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Row(
                        children: [
                          Text(pl.sport.icon),
                          const SizedBox(width: 4),
                          Text(
                            pl.sport.display,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text('${pl.bets}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text('${pl.winRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text(
                        '${pl.roiPercent > 0 ? "+" : ""}${pl.roiPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${pl.totalProfit > 0 ? "+" : ""}${pl.totalProfit.toStringAsFixed(2)}',
                        style: TextStyle(color: color, fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;

  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
