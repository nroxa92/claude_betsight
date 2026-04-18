import 'package:flutter/material.dart' hide Accumulator;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/accumulator.dart';
import '../models/accumulators_provider.dart';
import '../models/bet.dart';
import '../models/bets_provider.dart';
import '../models/match.dart';
import '../models/matches_provider.dart';
import '../models/sport.dart';
import '../theme/app_theme.dart';

class AccumulatorBuilderScreen extends StatefulWidget {
  const AccumulatorBuilderScreen({super.key});

  @override
  State<AccumulatorBuilderScreen> createState() =>
      _AccumulatorBuilderScreenState();
}

class _AccumulatorBuilderScreenState
    extends State<AccumulatorBuilderScreen> {
  final TextEditingController _stakeCtrl = TextEditingController();
  bool _stakeBound = false;
  String? _stakeError;

  @override
  void dispose() {
    _stakeCtrl.dispose();
    super.dispose();
  }

  Future<BetSelection?> _pickOutcome(
      BuildContext context, Match match) {
    final h2h = match.h2h;
    return showDialog<BetSelection>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${match.home} vs ${match.away}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: h2h == null
              ? [const Text('Odds unavailable')]
              : [
                  ListTile(
                    title: Text(
                      'Home @ ${h2h.home.toStringAsFixed(2)}',
                    ),
                    onTap: () =>
                        Navigator.pop(ctx, BetSelection.home),
                  ),
                  if (match.sport.hasDraw && h2h.draw != null)
                    ListTile(
                      title: Text(
                        'Draw @ ${h2h.draw!.toStringAsFixed(2)}',
                      ),
                      onTap: () =>
                          Navigator.pop(ctx, BetSelection.draw),
                    ),
                  ListTile(
                    title: Text(
                      'Away @ ${h2h.away.toStringAsFixed(2)}',
                    ),
                    onTap: () =>
                        Navigator.pop(ctx, BetSelection.away),
                  ),
                ],
        ),
      ),
    );
  }

  Future<void> _addLeg(
    BuildContext context,
    Match match,
    AccumulatorsProvider provider,
  ) async {
    if (provider.currentDraft != null &&
        provider.currentDraft!.legs.any((l) => l.matchId == match.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This match is already in draft')),
      );
      return;
    }
    final outcome = await _pickOutcome(context, match);
    if (outcome == null) return;
    final h2h = match.h2h;
    if (h2h == null) return;
    final odds = switch (outcome) {
      BetSelection.home => h2h.home,
      BetSelection.draw => h2h.draw ?? 0,
      BetSelection.away => h2h.away,
    };
    if (odds <= 1.0) return;
    provider.addLegToDraft(
      AccumulatorLeg(
        matchId: match.id,
        sport: match.sport,
        league: match.league,
        home: match.home,
        away: match.away,
        selection: outcome,
        odds: odds,
        kickoff: match.commenceTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Accumulator'),
        actions: [
          Consumer<AccumulatorsProvider>(
            builder: (_, p, child) {
              if (p.currentDraft == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Discard draft',
                onPressed: () {
                  p.discardDraft();
                  setState(() {
                    _stakeCtrl.clear();
                    _stakeBound = false;
                  });
                },
              );
            },
          ),
        ],
      ),
      body: Consumer2<AccumulatorsProvider, MatchesProvider>(
        builder: (context, accas, matches, child) {
          final draft = accas.currentDraft;
          if (draft == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.layers_outlined,
                        size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'No draft accumulator yet',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => accas.startNewDraft(),
                      icon: const Icon(Icons.add),
                      label: const Text('Start new accumulator'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!_stakeBound) {
            _stakeCtrl.text =
                draft.stake > 0 ? draft.stake.toStringAsFixed(2) : '';
            _stakeBound = true;
          }

          final watched = matches.allMatches
              .where((m) => matches.isWatched(m.id))
              .toList();
          final warnings = draft.correlationWarnings;
          final canSave = draft.legs.length >= 2 && draft.stake > 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Legs (${draft.legs.length})',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (draft.legs.isEmpty)
                Text(
                  'No legs yet — pick from watched matches below.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                )
              else
                Column(
                  children: [
                    for (final leg in draft.legs)
                      _LegTile(
                        leg: leg,
                        onRemove: () =>
                            accas.removeLegFromDraft(leg.matchId),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              Text(
                'Pick from watched matches',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (watched.isEmpty)
                Text(
                  'No watched matches — star matches in Matches screen.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                )
              else
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: watched.length,
                    itemBuilder: (_, i) => _PickableMatchCard(
                      match: watched[i],
                      onTap: () => _addLeg(context, watched[i], accas),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _stakeCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Stake',
                  errorText: _stakeError,
                ),
                onChanged: (v) {
                  final value = double.tryParse(v.replaceAll(',', '.'));
                  setState(() {
                    if (v.trim().isEmpty) {
                      _stakeError = null;
                    } else if (value == null || value <= 0) {
                      _stakeError = 'Enter a positive stake';
                    } else {
                      _stakeError = null;
                    }
                  });
                  accas.setDraftStake(value ?? 0);
                },
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                draft: draft,
                currency: context.watch<BetsProvider>().bankroll.currency,
              ),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber,
                              size: 16, color: Colors.orange),
                          SizedBox(width: 6),
                          Text(
                            'Correlation warning',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (final w in warnings)
                        Text(
                          '• $w',
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: canSave
                    ? () async {
                        await accas.saveDraftAsAccumulator();
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Accumulator saved')),
                        );
                      }
                    : null,
                icon: const Icon(Icons.check),
                label: const Text('Save accumulator'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegTile extends StatelessWidget {
  final AccumulatorLeg leg;
  final VoidCallback onRemove;

  const _LegTile({required this.leg, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(leg.sport.icon, style: const TextStyle(fontSize: 18)),
        title: Text(
          '${leg.home} vs ${leg.away}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          '${leg.league} · ${leg.selection.display} @ ${leg.odds.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _PickableMatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;

  const _PickableMatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        margin: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(match.sport.icon),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        match.league,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    '${match.home} vs ${match.away}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
                const Icon(Icons.add_circle_outline,
                    size: 18, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Accumulator draft;
  final String currency;

  const _SummaryCard({required this.draft, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _MetricCol(
                label: 'Legs',
                value: '${draft.legs.length}',
              ),
            ),
            Expanded(
              child: _MetricCol(
                label: 'Combined odds',
                value: draft.combinedOdds.toStringAsFixed(2),
                bold: true,
              ),
            ),
            Expanded(
              child: _MetricCol(
                label: 'Payout',
                value:
                    '${draft.potentialPayout.toStringAsFixed(2)} $currency',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _MetricCol({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
