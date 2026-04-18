import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bet.dart';
import '../models/bets_provider.dart';
import '../models/sport.dart';
import '../theme/app_theme.dart';

class BetCard extends StatelessWidget {
  final Bet bet;
  final String currency;

  const BetCard({super.key, required this.bet, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isPending = bet.status == BetStatus.pending;
    final profit = bet.actualProfit;

    return Dismissible(
      key: ValueKey('bet_${bet.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await context.read<BetsProvider>().deleteBet(bet.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bet deleted')),
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
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isPending ? () => _showSettleDialog(context, bet) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(bet.sport.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bet.league,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _StatusChip(status: bet.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${bet.home} vs ${bet.away}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick: ${bet.selection.display}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _MetaChip(label: 'Odds ${bet.odds.toStringAsFixed(2)}'),
                    _MetaChip(
                      label:
                          'Stake ${bet.stake.toStringAsFixed(2)} $currency',
                    ),
                    if (bet.bookmaker != null && bet.bookmaker!.isNotEmpty)
                      _MetaChip(label: bet.bookmaker!),
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
                      fontSize: 16,
                    ),
                  ),
                ],
                if (isPending) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showSettleDialog(context, bet),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Settle'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bet?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettleDialog(BuildContext context, Bet bet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Settle bet',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '${bet.home} vs ${bet.away}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            Text(
              'Pick: ${bet.selection.display} @ ${bet.odds.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            _settleButton(
                sheetContext, bet, BetStatus.won, '✓ Won', AppTheme.green),
            const SizedBox(height: 8),
            _settleButton(
                sheetContext, bet, BetStatus.lost, '✗ Lost', AppTheme.red),
            const SizedBox(height: 8),
            _settleButton(
                sheetContext, bet, BetStatus.void_, '— Void', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _settleButton(
    BuildContext ctx,
    Bet bet,
    BetStatus status,
    String label,
    Color color,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () async {
        await ctx.read<BetsProvider>().settleBet(bet.id, status);
        if (ctx.mounted) {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Bet settled as ${status.display}')),
          );
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BetStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      BetStatus.pending => (Colors.blue, Icons.hourglass_empty),
      BetStatus.won => (AppTheme.green, Icons.check),
      BetStatus.lost => (AppTheme.red, Icons.close),
      BetStatus.void_ => (Colors.grey, Icons.remove),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.display,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.grey[300], fontSize: 12),
      ),
    );
  }
}
