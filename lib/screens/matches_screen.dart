import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analysis_provider.dart';
import '../models/match.dart';
import '../models/matches_provider.dart';
import '../models/navigation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/match_card.dart';
import '../widgets/sport_selector.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<MatchesProvider>();
      if (p.hasApiKey) p.fetchMatches();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToAnalysisWithSelection(
      BuildContext context, MatchesProvider matches) {
    final selected = matches.selectedMatches;
    if (selected.isEmpty) return;
    context.read<AnalysisProvider>().stageSelectedMatches(selected);
    context.read<NavigationController>().setTab(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BetSight')),
      floatingActionButton: Consumer<MatchesProvider>(
        builder: (_, p, child) {
          if (p.selectedCount == 0) return const SizedBox.shrink();
          final n = p.selectedCount;
          return FloatingActionButton.extended(
            onPressed: () => _goToAnalysisWithSelection(context, p),
            icon: const Icon(Icons.auto_awesome),
            label: Text('Analyze $n match${n == 1 ? "" : "es"}'),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<MatchesProvider>(
              builder: (_, p, child) => SportSelector(
                selectedSport: p.selectedSport,
                onSportSelected: p.setSelectedSport,
              ),
            ),
          ),
          const _ApiLimitBanner(),
          const _CachedBadge(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Value Bets'),
              Tab(text: 'All Matches'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildValueBetsTab(),
                _buildAllMatchesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueBetsTab() {
    return Consumer<MatchesProvider>(
      builder: (_, p, child) {
        if (!p.hasApiKey) return _buildNoApiKeyState();
        if (p.isLoading && p.allMatches.isEmpty) {
          return _buildSkeletonList();
        }
        if (p.error != null && p.allMatches.isEmpty) {
          return _buildErrorState(p);
        }
        final list = p.valueBets;
        if (list.isEmpty) return _buildEmptyValueState(p);
        return _buildMatchList(p, list);
      },
    );
  }

  Widget _buildAllMatchesTab() {
    return Consumer<MatchesProvider>(
      builder: (_, p, child) {
        if (!p.hasApiKey) return _buildNoApiKeyState();
        if (p.isLoading && p.allMatches.isEmpty) {
          return _buildSkeletonList();
        }
        if (p.error != null && p.allMatches.isEmpty) {
          return _buildErrorState(p);
        }
        if (p.filteredMatches.isEmpty) return _buildEmptyAllState();
        return _buildMatchList(p, p.filteredMatches);
      },
    );
  }

  Widget _buildMatchList(MatchesProvider p, List<Match> list) {
    return RefreshIndicator(
      onRefresh: () => p.fetchMatches(forceRefresh: true),
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final m = list[i];
          return MatchCard(
            match: m,
            selectable: true,
            isSelected: p.isMatchSelected(m.id),
            onSelectionToggle: () => p.toggleMatchSelection(m.id),
          );
        },
      ),
    );
  }

  Widget _buildNoApiKeyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'The Odds API key required',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Settings to add your key',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, i) => const MatchCardSkeleton(),
    );
  }

  Widget _buildErrorState(MatchesProvider p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              p.error ?? 'Unknown error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: p.fetchMatches,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyValueState(MatchesProvider p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No value bets match current preset (${p.valuePreset.display}). '
              'Try a different preset in Settings.',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAllState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_neutral, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No matches found for this sport today',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiLimitBanner extends StatelessWidget {
  const _ApiLimitBanner();

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchesProvider>(
      builder: (_, p, child) {
        if (p.remainingRequests == null) return const SizedBox.shrink();
        if (p.isApiLimitCritical) {
          return _banner(
            color: AppTheme.red,
            icon: Icons.error_outline,
            text:
                'API quota exhausted — showing cached data only. Resets 1st of month.',
          );
        }
        if (p.isApiLimitLow) {
          return _banner(
            color: Colors.orange,
            icon: Icons.warning_amber_outlined,
            text:
                'Only ${p.remainingRequests} API requests left this month.',
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _banner({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CachedBadge extends StatelessWidget {
  const _CachedBadge();

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchesProvider>(
      builder: (_, p, child) {
        if (!p.fromCache || p.cachedAt == null || p.allMatches.isEmpty) {
          return const SizedBox.shrink();
        }
        final age = DateTime.now().difference(p.cachedAt!);
        String ageStr;
        if (age.inSeconds < 60) {
          ageStr = 'just now';
        } else if (age.inMinutes < 60) {
          ageStr = '${age.inMinutes}m ago';
        } else if (age.inHours < 24) {
          ageStr = '${age.inHours}h ago';
        } else {
          ageStr = '${age.inDays}d ago';
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.cached, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Cached ($ageStr) — pull to refresh',
                  style:
                      TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
