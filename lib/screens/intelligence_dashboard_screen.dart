import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intelligence_provider.dart';
import '../models/intelligence_report.dart';
import '../models/match.dart';
import '../models/matches_provider.dart';
import '../models/source_score.dart';
import '../models/sport.dart';

class IntelligenceDashboardScreen extends StatelessWidget {
  const IntelligenceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligence Dashboard'),
        actions: [
          Consumer2<MatchesProvider, IntelligenceProvider>(
            builder: (_, matches, intel, child) {
              final watched = matches.allMatches
                  .where((m) => matches.isWatched(m.id))
                  .toList();
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh all',
                onPressed: watched.isEmpty
                    ? null
                    : () =>
                        intel.refreshAllWatched(watched, force: true),
              );
            },
          ),
        ],
      ),
      body: Consumer2<MatchesProvider, IntelligenceProvider>(
        builder: (_, matches, intel, child) {
          final watched = matches.allMatches
              .where((m) => matches.isWatched(m.id))
              .toList();

          if (watched.isEmpty) return _buildEmptyState();

          return RefreshIndicator(
            onRefresh: () =>
                intel.refreshAllWatched(watched, force: true),
            child: ListView.builder(
              itemCount: watched.length,
              itemBuilder: (_, i) => _IntelligenceMatchCard(
                match: watched[i],
                report: intel.reportFor(watched[i].id),
                isGenerating: intel.isGeneratingFor(watched[i].id),
                onGenerate: () =>
                    intel.generateReport(watched[i], force: true),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 56, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text('No watched matches',
              style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 4),
          Text(
            'Star matches in Matches screen to see intelligence',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _IntelligenceMatchCard extends StatelessWidget {
  final Match match;
  final IntelligenceReport? report;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _IntelligenceMatchCard({
    required this.match,
    required this.report,
    required this.isGenerating,
    required this.onGenerate,
  });

  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(match.sport.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.league,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[400]),
                      ),
                      Text(
                        '${match.home} vs ${match.away}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isGenerating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (report == null)
                  OutlinedButton(
                    onPressed: onGenerate,
                    child: const Text('Generate'),
                  )
                else
                  _ConfluenceBadge(report: report!),
              ],
            ),
            if (report != null) ...[
              const SizedBox(height: 12),
              ..._buildSourceRows(report!),
              const SizedBox(height: 8),
              Text(
                'Generated ${_relativeTime(report!.generatedAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSourceRows(IntelligenceReport report) {
    return report.sources.map((s) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(s.source.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Text(
                s.source.display,
                style: TextStyle(
                  fontSize: 12,
                  color: s.isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: s.isActive
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: s.score / s.source.maxScore,
                        minHeight: 6,
                        backgroundColor: Colors.grey[800],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: Text(
                s.isActive
                    ? '${s.score.toStringAsFixed(1)}/${s.source.maxScore}'
                    : 'inactive',
                style: TextStyle(
                  fontSize: 11,
                  color: s.isActive ? Colors.white : Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _ConfluenceBadge extends StatelessWidget {
  final IntelligenceReport report;
  const _ConfluenceBadge({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = Color(report.category.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${report.confluenceScore.toStringAsFixed(1)} — ${report.category.display.replaceAll('_', ' ')}',
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

