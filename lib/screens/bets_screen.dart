import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/accumulators_provider.dart';
import '../models/bet.dart';
import '../models/bets_provider.dart';
import '../models/tier_provider.dart';
import '../widgets/accumulator_card.dart';
import '../widgets/bet_card.dart';
import '../widgets/bet_entry_sheet.dart';
import '../widgets/bets_filter_bar.dart';
import '../widgets/pnl_summary.dart';
import 'accumulator_builder_screen.dart';

class BetsScreen extends StatefulWidget {
  const BetsScreen({super.key});

  @override
  State<BetsScreen> createState() => _BetsScreenState();
}

class _BetsScreenState extends State<BetsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _maybeShowError(BetsProvider p) {
    final err = p.error;
    if (err == null || err == _lastShownError) return;
    _lastShownError = err;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: p.clearError,
          ),
        ),
      );
    });
  }

  void _showManualBetEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const BetEntrySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TierProvider>(
      builder: (context, tierProv, child) {
        final isAcca =
            tierProv.currentTier == InvestmentTier.accumulator;
        return Scaffold(
          appBar: AppBar(
            title: Text(isAcca ? 'Accumulators' : 'Bets'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (isAcca) {
                final accas = context.read<AccumulatorsProvider>();
                if (accas.currentDraft == null) accas.startNewDraft();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccumulatorBuilderScreen(),
                  ),
                );
              } else {
                _showManualBetEntry(context);
              }
            },
            child: const Icon(Icons.add),
          ),
          body: isAcca ? _buildAccumulatorView() : _buildRegularView(),
        );
      },
    );
  }

  Widget _buildRegularView() {
    return Consumer<TierProvider>(
      builder: (_, tierProv, child) {
        final tier = tierProv.currentTier;
        return Column(
          children: [
            const PlSummaryWidget(),
            const BetsFilterBar(),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Open'),
                Tab(text: 'Settled'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOpenTab(tier),
                  _buildSettledTab(tier),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Bet> _filterBetsForTier(List<Bet> bets, InvestmentTier tier) =>
      switch (tier) {
        InvestmentTier.preMatch =>
          bets.where((b) => b.isPreMatchBet).toList(),
        InvestmentTier.live => bets.where((b) => b.isLiveBet).toList(),
        InvestmentTier.accumulator => const [],
      };

  Widget _buildAccumulatorView() {
    return Consumer2<AccumulatorsProvider, BetsProvider>(
      builder: (_, accas, bets, child) {
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Building'),
                  Tab(text: 'Placed'),
                  Tab(text: 'Settled'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAccaList(accas.building, bets.bankroll.currency,
                        emptyText: 'No drafts — tap + to start one'),
                    _buildAccaList(accas.placed, bets.bankroll.currency,
                        emptyText: 'No placed accumulators yet'),
                    _buildAccaList(accas.settled, bets.bankroll.currency,
                        emptyText: 'No settled accumulators yet'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccaList(List list, String currency,
      {required String emptyText}) {
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.layers_outlined,
        text: emptyText,
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) =>
          AccumulatorCard(acca: list[i], currency: currency),
    );
  }

  Widget _buildOpenTab(InvestmentTier tier) {
    return Consumer<BetsProvider>(
      builder: (_, p, child) {
        _maybeShowError(p);
        final tierFiltered = _filterBetsForTier(p.openBets, tier);
        final filtered = p.applyFilters(tierFiltered);
        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.sentiment_neutral,
            text: p.hasActiveFilters
                ? 'No open bets match your filters'
                : tier == InvestmentTier.live
                    ? 'No live bets — place one during a match'
                    : 'No open bets — tap + to log one',
          );
        }
        return _buildBetList(p, filtered);
      },
    );
  }

  Widget _buildSettledTab(InvestmentTier tier) {
    return Consumer<BetsProvider>(
      builder: (_, p, child) {
        _maybeShowError(p);
        final tierFiltered = _filterBetsForTier(p.settledBets, tier);
        final filtered = p.applyFilters(tierFiltered);
        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            text: p.hasActiveFilters
                ? 'No settled bets match your filters'
                : 'No settled bets yet',
          );
        }
        return _buildBetList(p, filtered);
      },
    );
  }

  Widget _buildBetList(BetsProvider p, List<Bet> bets) {
    return ListView.builder(
      itemCount: bets.length,
      itemBuilder: (_, i) =>
          BetCard(bet: bets[i], currency: p.bankroll.currency),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
