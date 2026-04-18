import 'package:flutter/material.dart' hide Accumulator;
import 'package:provider/provider.dart';

import '../models/accumulator.dart';
import '../models/accumulators_provider.dart';
import '../models/bet.dart';
import '../theme/app_theme.dart';

class AccumulatorCard extends StatelessWidget {
  final Accumulator acca;
  final String currency;

  const AccumulatorCard({
    super.key,
    required this.acca,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final profit = acca.actualProfit;
    return Dismissible(
      key: ValueKey('acca_${acca.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await context.read<AccumulatorsProvider>().deleteAccumulator(acca.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Accumulator deleted')),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.red.withValues(alpha: 0.4),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${acca.legs.length} legs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _OddsBadge(odds: acca.combinedOdds),
                  const SizedBox(width: 6),
                  _StatusChip(status: acca.status),
                ],
              ),
              const SizedBox(height: 8),
              for (final leg in acca.legs.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    '${leg.home} vs ${leg.away} — ${leg.selection.display} @ ${leg.odds.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (acca.legs.length > 3)
                Text(
                  '+${acca.legs.length - 3} more',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _MetaChip(
                    label: 'Stake ${acca.stake.toStringAsFixed(2)} $currency',
                  ),
                  _MetaChip(
                    label:
                        'Payout ${acca.potentialPayout.toStringAsFixed(2)} $currency',
                  ),
                ],
              ),
              if (profit != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${profit >= 0 ? '+' : ''}${profit.toStringAsFixed(2)} $currency',
                  style: TextStyle(
                    color: profit > 0
                        ? AppTheme.green
                        : profit < 0
                            ? AppTheme.red
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final provider = context.read<AccumulatorsProvider>();
    switch (acca.status) {
      case AccumulatorStatus.building:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => provider.placeAccumulator(acca.id),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Place'),
              ),
            ),
          ],
        );
      case AccumulatorStatus.placed:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showSettleSheet(context),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Settle'),
              ),
            ),
          ],
        );
      case AccumulatorStatus.won:
      case AccumulatorStatus.lost:
      case AccumulatorStatus.partial:
        return const SizedBox.shrink();
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete accumulator?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }

  void _showSettleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Settle accumulator',
                style: Theme.of(sheetCtx).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
              '${acca.legs.length} legs · combined ${acca.combinedOdds.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            _settleButton(sheetCtx, AccumulatorStatus.won, '✓ Won',
                AppTheme.green),
            const SizedBox(height: 8),
            _settleButton(sheetCtx, AccumulatorStatus.lost, '✗ Lost',
                AppTheme.red),
            const SizedBox(height: 8),
            _settleButton(sheetCtx, AccumulatorStatus.partial,
                '— Partial / Cash out', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _settleButton(
    BuildContext ctx,
    AccumulatorStatus status,
    String label,
    Color color,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () async {
        await ctx
            .read<AccumulatorsProvider>()
            .settleAccumulator(acca.id, status);
        if (ctx.mounted) {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
                content: Text('Accumulator settled as ${status.display}')),
          );
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _OddsBadge extends StatelessWidget {
  final double odds;
  const _OddsBadge({required this.odds});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        odds.toStringAsFixed(2),
        style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AccumulatorStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      AccumulatorStatus.building => (Colors.grey, Icons.edit),
      AccumulatorStatus.placed => (Colors.blue, Icons.hourglass_empty),
      AccumulatorStatus.won => (AppTheme.green, Icons.check),
      AccumulatorStatus.lost => (AppTheme.red, Icons.close),
      AccumulatorStatus.partial => (Colors.orange, Icons.remove),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.display,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: Colors.grey[300]),
      ),
    );
  }
}
