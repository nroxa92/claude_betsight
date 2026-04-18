import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/intelligence_provider.dart';
import '../models/intelligence_report.dart';
import '../models/match.dart';
import '../models/match_note.dart';
import '../models/matches_provider.dart';
import '../models/navigation_controller.dart';
import '../models/source_score.dart';
import '../models/sport.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/form_chart.dart';
import '../widgets/charts/odds_movement_chart.dart';
import '../widgets/charts/tennis_info_panel.dart';

class MatchDetailScreen extends StatefulWidget {
  final Match match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late final TextEditingController _noteCtrl;
  DateTime? _noteSavedAt;

  @override
  void initState() {
    super.initState();
    final existing = StorageService.getMatchNote(widget.match.id);
    _noteCtrl = TextEditingController(text: existing?.text ?? '');
    _noteSavedAt = existing?.updatedAt;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final note = MatchNote(
      matchId: widget.match.id,
      text: _noteCtrl.text,
      updatedAt: DateTime.now(),
    );
    await StorageService.saveMatchNote(note);
    if (!mounted) return;
    setState(() => _noteSavedAt = note.updatedAt);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${m.home} vs ${m.away}',
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Consumer<MatchesProvider>(
              builder: (_, p, child) {
                final watched = p.isWatched(m.id);
                return IconButton(
                  icon: Icon(watched ? Icons.star : Icons.star_border,
                      color: watched ? AppTheme.secondary : null),
                  onPressed: () => p.toggleWatched(m.id),
                );
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Intelligence'),
              Tab(text: 'Charts'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(match: m),
            _IntelligenceTab(match: m),
            _ChartsTab(match: m),
            _buildNotesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pre-bet notes',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _noteCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText:
                    'Discipline trigger — what is your thesis? key risks?',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _noteSavedAt == null
                      ? 'Not saved yet'
                      : 'Last saved: ${DateFormat('MMM d, HH:mm').format(_noteSavedAt!)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _saveNote,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Match match;
  const _OverviewTab({required this.match});

  String _kickoff(Match m) {
    if (m.isLive) return 'LIVE';
    final d = m.timeToKickoff;
    if (d.inHours < 24) {
      final h = d.inHours;
      final mm = d.inMinutes % 60;
      return h > 0 ? 'in ${h}h ${mm}m' : 'in ${d.inMinutes}m';
    }
    return DateFormat('MMM d, HH:mm').format(m.commenceTime);
  }

  @override
  Widget build(BuildContext context) {
    final h2h = match.h2h;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${match.sport.icon} ${match.league}',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(_kickoff(match),
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(height: 24),
        if (h2h == null)
          Text('Odds unavailable',
              style: TextStyle(color: Colors.grey[500]))
        else ...[
          Row(
            children: [
              Expanded(
                child: _OddsTile(
                    label: 'Home', odds: h2h.home, team: match.home),
              ),
              if (match.sport.hasDraw && h2h.draw != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _OddsTile(
                      label: 'Draw', odds: h2h.draw!, team: 'Draw'),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _OddsTile(
                    label: 'Away', odds: h2h.away, team: match.away),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bookmaker: ${h2h.bookmaker} · Margin: ${(h2h.bookmakerMargin * 100).toStringAsFixed(1)}%',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            context.read<NavigationController>().setTab(1);
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Analyze in AI'),
        ),
      ],
    );
  }
}

class _OddsTile extends StatelessWidget {
  final String label;
  final double odds;
  final String team;
  const _OddsTile({
    required this.label,
    required this.odds,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            odds.toStringAsFixed(2),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            team,
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _IntelligenceTab extends StatelessWidget {
  final Match match;
  const _IntelligenceTab({required this.match});

  @override
  Widget build(BuildContext context) {
    return Consumer<IntelligenceProvider>(
      builder: (_, intel, child) {
        final report = intel.reportFor(match.id);
        final loading = intel.isGeneratingFor(match.id);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (report == null && !loading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.radar,
                          size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('No report yet',
                          style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () =>
                            intel.generateReport(match, force: true),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Generate'),
                      ),
                    ],
                  ),
                ),
              )
            else if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _ReportView(
                report: report!,
                onRefresh: () => intel.generateReport(match, force: true),
              ),
          ],
        );
      },
    );
  }
}

class _ReportView extends StatelessWidget {
  final IntelligenceReport report;
  final VoidCallback onRefresh;
  const _ReportView({required this.report, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final color = Color(report.category.colorValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Text(
                '${report.confluenceScore.toStringAsFixed(1)} / 6.0',
                style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                report.category.display.replaceAll('_', ' '),
                style: TextStyle(color: color, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                report.category.interpretation,
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final s in report.sources)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.source.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.isActive
                            ? '${s.source.display} — ${s.score.toStringAsFixed(1)}/${s.source.maxScore}'
                            : '${s.source.display} (inactive)',
                        style: TextStyle(
                          color:
                              s.isActive ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        s.reasoning,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh report'),
        ),
      ],
    );
  }
}

class _ChartsTab extends StatelessWidget {
  final Match match;
  const _ChartsTab({required this.match});

  @override
  Widget build(BuildContext context) {
    final snapshots = StorageService.getSnapshotsForMatch(match.id);
    final fdSignal = StorageService.getFootballSignal(match.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Odds movement',
            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: OddsMovementChart(
            snapshots: snapshots,
            showDraw: match.sport.hasDraw,
          ),
        ),
        const SizedBox(height: 24),
        if (match.sport == Sport.soccer) ...[
          if (fdSignal != null) ...[
            Text(
              'Form (last 5)',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 8),
            FormChart(
              teamName: fdSignal.homeTeam,
              form: fdSignal.homeFormLast5,
            ),
            const SizedBox(height: 12),
            FormChart(
              teamName: fdSignal.awayTeam,
              form: fdSignal.awayFormLast5,
            ),
          ] else
            Text(
              'Form data not yet fetched. Generate intelligence report first.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
        ] else if (match.sport == Sport.tennis) ...[
          TennisInfoPanel(match: match),
        ] else if (match.sport == Sport.basketball) ...[
          Text(
            'NBA form data not yet visualized in Charts tab. '
            'Generate intelligence report to see last10 stats in the Intelligence tab.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ],
    );
  }
}
