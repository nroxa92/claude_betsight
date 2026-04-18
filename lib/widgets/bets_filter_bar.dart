import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bet.dart';
import '../models/bets_provider.dart';
import '../models/sport.dart';
import '../theme/app_theme.dart';

class BetsFilterBar extends StatefulWidget {
  const BetsFilterBar({super.key});

  @override
  State<BetsFilterBar> createState() => _BetsFilterBarState();
}

class _BetsFilterBarState extends State<BetsFilterBar> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BetsProvider>(
      builder: (context, bets, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom:
                  BorderSide(color: Colors.grey[900]!, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search team, league...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            bets.setSearchText('');
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (text) {
                  bets.setSearchText(text);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildSportFilterChip(context, bets),
                    const SizedBox(width: 6),
                    _buildStatusFilterChip(context, bets),
                    const SizedBox(width: 6),
                    _buildDateFilterChip(context, bets),
                    if (bets.hasActiveFilters) ...[
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('Clear',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _searchCtrl.clear();
                          bets.clearFilters();
                          setState(() {});
                        },
                        backgroundColor:
                            AppTheme.red.withValues(alpha: 0.15),
                        labelStyle:
                            const TextStyle(color: AppTheme.red),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSportFilterChip(BuildContext ctx, BetsProvider bets) {
    final count = bets.filterSports.length;
    return ActionChip(
      avatar: const Icon(Icons.sports, size: 14),
      label: Text(
        count == 0 ? 'Sport' : '$count sport${count == 1 ? "" : "s"}',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: count > 0
          ? AppTheme.primary.withValues(alpha: 0.2)
          : null,
      onPressed: () => _showSportPicker(ctx, bets),
    );
  }

  Future<void> _showSportPicker(
      BuildContext ctx, BetsProvider bets) async {
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in Sport.values)
                CheckboxListTile(
                  dense: true,
                  title: Row(
                    children: [
                      Text(s.icon),
                      const SizedBox(width: 6),
                      Text(s.display,
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  value: bets.filterSports.contains(s),
                  onChanged: (_) {
                    bets.toggleSportFilter(s);
                    setSheetState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(BuildContext ctx, BetsProvider bets) {
    final count = bets.filterStatuses.length;
    return ActionChip(
      avatar: const Icon(Icons.flag, size: 14),
      label: Text(
        count == 0 ? 'Status' : '$count status${count == 1 ? "" : "es"}',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: count > 0
          ? AppTheme.primary.withValues(alpha: 0.2)
          : null,
      onPressed: () => _showStatusPicker(ctx, bets),
    );
  }

  Future<void> _showStatusPicker(
      BuildContext ctx, BetsProvider bets) async {
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final st in BetStatus.values)
                CheckboxListTile(
                  dense: true,
                  title: Text(
                    st.display,
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: bets.filterStatuses.contains(st),
                  onChanged: (_) {
                    bets.toggleStatusFilter(st);
                    setSheetState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(BuildContext ctx, BetsProvider bets) {
    final hasRange =
        bets.filterFromDate != null || bets.filterToDate != null;
    return ActionChip(
      avatar: const Icon(Icons.date_range, size: 14),
      label: Text(
        hasRange ? 'Date set' : 'Date',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: hasRange
          ? AppTheme.primary.withValues(alpha: 0.2)
          : null,
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: ctx,
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: (bets.filterFromDate != null &&
                  bets.filterToDate != null)
              ? DateTimeRange(
                  start: bets.filterFromDate!, end: bets.filterToDate!)
              : null,
        );
        if (picked != null) {
          bets.setFilterDateRange(picked.start, picked.end);
        }
      },
    );
  }
}
