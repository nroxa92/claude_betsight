import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bet.dart';
import '../models/bets_provider.dart';
import '../widgets/bet_card.dart';
import '../widgets/bet_entry_sheet.dart';
import '../widgets/pnl_summary.dart';

class BetsScreen extends StatefulWidget {
  const BetsScreen({super.key});

  @override
  State<BetsScreen> createState() => _BetsScreenState();
}

class _BetsScreenState extends State<BetsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Bets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManualBetEntry(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const PlSummaryWidget(),
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
                _buildOpenTab(),
                _buildSettledTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenTab() {
    return Consumer<BetsProvider>(
      builder: (_, p, child) {
        if (p.openBets.isEmpty) {
          return _buildEmptyState(
            icon: Icons.sentiment_neutral,
            text: 'No open bets — tap + to log one',
          );
        }
        return _buildBetList(p, p.openBets);
      },
    );
  }

  Widget _buildSettledTab() {
    return Consumer<BetsProvider>(
      builder: (_, p, child) {
        if (p.settledBets.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            text: 'No settled bets yet',
          );
        }
        return _buildBetList(p, p.settledBets);
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
