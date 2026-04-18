import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analysis_provider.dart';
import '../models/bankroll.dart';
import '../models/bets_provider.dart';
import '../models/matches_provider.dart';
import '../models/value_preset.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _anthropicController = TextEditingController();
  final TextEditingController _oddsController = TextEditingController();
  bool _showAnthropic = false;
  bool _showOdds = false;

  @override
  void dispose() {
    _anthropicController.dispose();
    _oddsController.dispose();
    super.dispose();
  }

  String _mask(String key) {
    if (key.length <= 6) return '••••••';
    return '${key.substring(0, 4)}${'•' * 6}${key.substring(key.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAnthropicSection(),
          const SizedBox(height: 24),
          _buildOddsSection(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildValuePresetSection(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const _BankrollSection(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildAnthropicSection() {
    final p = context.watch<AnalysisProvider>();
    if (p.hasApiKey && _anthropicController.text.isEmpty) {
      _anthropicController.text = _mask('anthropic_set_value_______');
    }
    return _ApiKeySection(
      title: 'Anthropic API Key',
      icon: Icons.key,
      hint: 'sk-ant-...',
      isSet: p.hasApiKey,
      controller: _anthropicController,
      obscure: !_showAnthropic,
      onToggle: () => setState(() => _showAnthropic = !_showAnthropic),
      onSave: () async {
        final v = _anthropicController.text.trim();
        if (v.isEmpty) return;
        await context.read<AnalysisProvider>().setApiKey(v);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved')));
        setState(() => _anthropicController.text = _mask(v));
      },
      onRemove: () async {
        final ok = await _confirmRemove('Anthropic API key');
        if (ok != true) return;
        if (!mounted) return;
        await context.read<AnalysisProvider>().removeApiKey();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Removed')));
        setState(() => _anthropicController.clear());
      },
    );
  }

  Widget _buildOddsSection() {
    final p = context.watch<MatchesProvider>();
    if (p.hasApiKey && _oddsController.text.isEmpty) {
      _oddsController.text = _mask('odds_set_value___');
    }
    return _ApiKeySection(
      title: 'The Odds API Key',
      icon: Icons.dataset,
      hint: 'Your the-odds-api.com key',
      isSet: p.hasApiKey,
      controller: _oddsController,
      obscure: !_showOdds,
      onToggle: () => setState(() => _showOdds = !_showOdds),
      onSave: () async {
        final v = _oddsController.text.trim();
        if (v.isEmpty) return;
        await context.read<MatchesProvider>().setApiKey(v);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved')));
        setState(() => _oddsController.text = _mask(v));
      },
      onRemove: () async {
        final ok = await _confirmRemove('The Odds API key');
        if (ok != true) return;
        if (!mounted) return;
        await context.read<MatchesProvider>().removeApiKey();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Removed')));
        setState(() => _oddsController.clear());
      },
    );
  }

  Future<bool?> _confirmRemove(String label) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $label?'),
        content: const Text(
          'You will need to re-enter the key to use the related feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildValuePresetSection() {
    return Consumer<MatchesProvider>(
      builder: (_, p, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.track_changes, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Value Bets Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RadioGroup<ValuePreset>(
              groupValue: p.valuePreset,
              onChanged: (v) {
                if (v != null) p.setValuePreset(v);
              },
              child: Column(
                children: [
                  for (final preset in ValuePreset.values)
                    RadioListTile<ValuePreset>(
                      value: preset,
                      activeColor: AppTheme.primary,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        preset.display,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        preset.description,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _aboutRow(Icons.info_outline, 'Version', '1.0.0+1'),
        _aboutRow(Icons.dataset_outlined, 'Match Data', 'The Odds API'),
        _aboutRow(Icons.auto_awesome_outlined, 'AI Analysis',
            'Claude (Anthropic)'),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        Text(
          'BetSight is not a betting agency. It is an informational tool. '
          'All betting decisions are your own. Gamble responsibly.',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 16),
        SelectableText(
          'Get an Odds API key at the-odds-api.com',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[400])),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ApiKeySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String hint;
  final bool isSet;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final Future<void> Function() onSave;
  final Future<void> Function() onRemove;

  const _ApiKeySection({
    required this.title,
    required this.icon,
    required this.hint,
    required this.isSet,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.onSave,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _StatusBadge(active: isSet),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          obscureText: obscure,
          onTap: () {
            if (controller.text.contains('•')) controller.clear();
          },
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggle,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: onSave,
              child: const Text('Save'),
            ),
            const SizedBox(width: 8),
            if (isSet)
              TextButton(
                onPressed: onRemove,
                child: const Text(
                  'Remove',
                  style: TextStyle(color: AppTheme.red),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BankrollSection extends StatefulWidget {
  const _BankrollSection();

  @override
  State<_BankrollSection> createState() => _BankrollSectionState();
}

class _BankrollSectionState extends State<_BankrollSection> {
  late TextEditingController _bankrollCtrl;
  late TextEditingController _stakeCtrl;
  late String _currency;

  static const _currencies = ['EUR', 'USD', 'GBP', 'HRK', 'CHF', 'BAM', 'RSD'];

  @override
  void initState() {
    super.initState();
    final cfg = context.read<BetsProvider>().bankroll;
    _bankrollCtrl =
        TextEditingController(text: cfg.totalBankroll.toStringAsFixed(2));
    _stakeCtrl = TextEditingController(
      text: cfg.defaultStakeUnit.toStringAsFixed(2),
    );
    _currency = cfg.currency;
  }

  @override
  void dispose() {
    _bankrollCtrl.dispose();
    _stakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bankroll =
        double.tryParse(_bankrollCtrl.text.replaceAll(',', '.')) ?? 0;
    final stake =
        double.tryParse(_stakeCtrl.text.replaceAll(',', '.')) ?? 0;
    if (bankroll <= 0 || stake <= 0 || stake >= bankroll) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bankroll and stake must be positive and stake must be less than bankroll',
          ),
        ),
      );
      return;
    }
    await context.read<BetsProvider>().setBankroll(BankrollConfig(
          totalBankroll: bankroll,
          defaultStakeUnit: stake,
          currency: _currency,
        ));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bankroll saved')));
  }

  @override
  Widget build(BuildContext context) {
    final bankroll =
        double.tryParse(_bankrollCtrl.text.replaceAll(',', '.')) ?? 0;
    final stake = double.tryParse(_stakeCtrl.text.replaceAll(',', '.')) ?? 0;
    final pct = bankroll > 0 ? (stake / bankroll * 100) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.account_balance_wallet, color: AppTheme.primary),
            SizedBox(width: 8),
            Text(
              'Bankroll',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bankrollCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Total bankroll'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _stakeCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Default stake unit'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _currency,
          decoration: const InputDecoration(labelText: 'Currency'),
          items: [
            for (final c in _currencies)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _currency = v);
          },
        ),
        const SizedBox(height: 12),
        if (bankroll > 0)
          Text(
            'Default stake: ${pct.toStringAsFixed(1)}% of bankroll',
            style: TextStyle(
              color: pct > 5 ? Colors.orange : Colors.grey[400],
              fontSize: 12,
            ),
          ),
        if (pct > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Industry recommendation: 1-3% per bet',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.green : Colors.orange;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(active),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          active ? 'Active' : 'Not set',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
