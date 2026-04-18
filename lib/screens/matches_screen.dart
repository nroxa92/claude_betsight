import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/matches_provider.dart';
import '../widgets/match_card.dart';
import '../widgets/sport_selector.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<MatchesProvider>();
      if (p.hasApiKey) p.fetchMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BetSight')),
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
          Expanded(
            child: Consumer<MatchesProvider>(
              builder: (_, p, child) {
                if (!p.hasApiKey) return _buildNoApiKeyState();
                if (p.isLoading && p.allMatches.isEmpty) {
                  return _buildSkeletonList();
                }
                if (p.error != null && p.allMatches.isEmpty) {
                  return _buildErrorState(p);
                }
                if (p.filteredMatches.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: p.fetchMatches,
                  child: ListView.builder(
                    itemCount: p.filteredMatches.length,
                    itemBuilder: (_, i) =>
                        MatchCard(match: p.filteredMatches[i]),
                  ),
                );
              },
            ),
          ),
        ],
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

  Widget _buildEmptyState() {
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
