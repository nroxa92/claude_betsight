import 'package:flutter/material.dart';

import '../../models/match.dart';
import '../../theme/app_theme.dart';

class TennisInfoPanel extends StatelessWidget {
  final Match match;

  const TennisInfoPanel({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final h2h = match.h2h;
    if (h2h == null) return _buildNoData();

    final homeImplied = (1.0 / h2h.home) * 100;
    final awayImplied = (1.0 / h2h.away) * 100;
    final margin = (homeImplied + awayImplied) - 100;
    final homeIsFav = h2h.home < h2h.away;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sports_tennis, size: 18),
                SizedBox(width: 8),
                Text(
                  'Tennis Match Info',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star,
                      color: AppTheme.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bookmaker favourite: ${homeIsFav ? match.home : match.away}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProbTile(
                    label: match.home,
                    odds: h2h.home,
                    probability: homeImplied,
                    isFav: homeIsFav,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProbTile(
                    label: match.away,
                    odds: h2h.away,
                    probability: awayImplied,
                    isFav: !homeIsFav,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Bookmaker margin: ',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
                Text(
                  '${margin.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: margin < 5
                        ? AppTheme.green
                        : margin < 8
                            ? Colors.orange
                            : AppTheme.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  margin < 5
                      ? '(sharp)'
                      : margin < 8
                          ? '(normal)'
                          : '(soft)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Detailed player form (recent matches, H2H, surface stats) not available — '
                    'BetSight does not integrate a dedicated tennis data source. '
                    'For deep analysis, reference ATP/WTA official sites or a tennis-specific tool.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoData() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No odds data for this tennis match',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbTile extends StatelessWidget {
  final String label;
  final double odds;
  final double probability;
  final bool isFav;

  const _ProbTile({
    required this.label,
    required this.odds,
    required this.probability,
    required this.isFav,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFav
              ? AppTheme.green.withValues(alpha: 0.5)
              : Colors.grey[800]!,
          width: isFav ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                odds.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${probability.toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
