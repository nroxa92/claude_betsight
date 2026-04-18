import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/analysis_log.dart';
import '../models/bet.dart';
import '../models/bets_provider.dart';
import '../models/match.dart';
import '../models/sport.dart';
import '../models/tier_provider.dart';
import '../theme/app_theme.dart';

class BetEntrySheet extends StatefulWidget {
  final Match? prefilledMatch;
  final BetSelection? prefilledSelection;
  final double? prefilledOdds;

  const BetEntrySheet({
    super.key,
    this.prefilledMatch,
    this.prefilledSelection,
    this.prefilledOdds,
  });

  @override
  State<BetEntrySheet> createState() => _BetEntrySheetState();
}

class _BetEntrySheetState extends State<BetEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late Sport _sport;
  late TextEditingController _leagueCtrl;
  late TextEditingController _homeCtrl;
  late TextEditingController _awayCtrl;
  late TextEditingController _oddsCtrl;
  late TextEditingController _stakeCtrl;
  late TextEditingController _bookmakerCtrl;
  late TextEditingController _notesCtrl;
  BetSelection? _selection;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final m = widget.prefilledMatch;
    _sport = m?.sport ?? Sport.soccer;
    _leagueCtrl = TextEditingController(text: m?.league ?? '');
    _homeCtrl = TextEditingController(text: m?.home ?? '');
    _awayCtrl = TextEditingController(text: m?.away ?? '');
    _oddsCtrl = TextEditingController(
      text: widget.prefilledOdds?.toStringAsFixed(2) ?? '',
    );
    final defaultStake =
        context.read<BetsProvider>().bankroll.defaultStakeUnit;
    _stakeCtrl = TextEditingController(text: defaultStake.toStringAsFixed(2));
    _bookmakerCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _selection = widget.prefilledSelection;
  }

  @override
  void dispose() {
    _leagueCtrl.dispose();
    _homeCtrl.dispose();
    _awayCtrl.dispose();
    _oddsCtrl.dispose();
    _stakeCtrl.dispose();
    _bookmakerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _validationError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selection == null) {
      setState(() => _validationError = 'Pick a selection (Home/Draw/Away)');
      return;
    }
    if (_selection == BetSelection.draw && _sport != Sport.soccer) {
      setState(() => _validationError = 'Draw only available for soccer');
      return;
    }

    final odds = double.tryParse(_oddsCtrl.text.replaceAll(',', '.')) ?? 0;
    final stake = double.tryParse(_stakeCtrl.text.replaceAll(',', '.')) ?? 0;
    if (odds <= 1.0) {
      setState(() => _validationError = 'Odds must be greater than 1.0');
      return;
    }
    if (stake <= 0) {
      setState(() => _validationError = 'Stake must be positive');
      return;
    }

    final tier = context.read<TierProvider>().currentTier;
    final now = DateTime.now();
    DateTime? matchStartedAt;
    if (tier == InvestmentTier.live) {
      // LIVE bet — place after kickoff; force `placedAt > matchStartedAt`.
      matchStartedAt = now.subtract(const Duration(minutes: 1));
    } else if (widget.prefilledMatch != null) {
      matchStartedAt = widget.prefilledMatch!.commenceTime;
    }

    final bet = Bet(
      id: generateUuid(),
      sport: _sport,
      league: _leagueCtrl.text.trim(),
      home: _homeCtrl.text.trim(),
      away: _awayCtrl.text.trim(),
      selection: _selection!,
      odds: odds,
      stake: stake,
      bookmaker: _bookmakerCtrl.text.trim().isEmpty
          ? null
          : _bookmakerCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      placedAt: now,
      matchStartedAt: matchStartedAt,
      status: BetStatus.pending,
      linkedMatchId: widget.prefilledMatch?.id,
    );

    await context.read<BetsProvider>().addBet(bet);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bet logged')));
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Log new bet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Sport>(
                  initialValue: _sport,
                  decoration: const InputDecoration(labelText: 'Sport'),
                  items: [
                    for (final s in Sport.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text('${s.icon} ${s.display}'),
                      ),
                  ],
                  onChanged: widget.prefilledMatch != null
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() {
                              _sport = v;
                              if (_selection == BetSelection.draw &&
                                  !_sport.hasDraw) {
                                _selection = null;
                              }
                            });
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _leagueCtrl,
                  decoration: const InputDecoration(labelText: 'League'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _homeCtrl,
                  decoration: const InputDecoration(labelText: 'Home team'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _awayCtrl,
                  decoration: const InputDecoration(labelText: 'Away team'),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                Text(
                  'Selection',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final sel in BetSelection.values)
                      if (sel != BetSelection.draw || _sport.hasDraw)
                        ChoiceChip(
                          label: Text(sel.display),
                          selected: _selection == sel,
                          onSelected: (_) =>
                              setState(() => _selection = sel),
                          selectedColor:
                              AppTheme.primary.withValues(alpha: 0.3),
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _oddsCtrl,
                        decoration: const InputDecoration(labelText: 'Odds'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stakeCtrl,
                        decoration: const InputDecoration(labelText: 'Stake'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bookmakerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bookmaker (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                if (_validationError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _validationError!,
                    style: const TextStyle(color: AppTheme.red),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Save Bet'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
