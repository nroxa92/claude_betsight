import 'package:flutter/material.dart';

import '../models/odds.dart';
import '../theme/app_theme.dart';

class OddsWidget extends StatelessWidget {
  final H2HOdds? odds;
  final bool hasDraw;

  const OddsWidget({super.key, required this.odds, required this.hasDraw});

  @override
  Widget build(BuildContext context) {
    final o = odds;
    if (o == null) {
      return Text(
        'Odds unavailable',
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
      );
    }

    final chips = <Widget>[
      _OddsChip(label: 'Home', value: o.home),
      if (hasDraw && o.draw != null)
        _OddsChip(label: 'Draw', value: o.draw!),
      _OddsChip(label: 'Away', value: o.away),
    ];

    return Row(
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          Expanded(child: chips[i]),
          if (i < chips.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _OddsChip extends StatelessWidget {
  final String label;
  final double value;

  const _OddsChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
