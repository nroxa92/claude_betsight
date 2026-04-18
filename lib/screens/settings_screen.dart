import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analysis_provider.dart';
import '../models/bankroll.dart';
import '../models/bets_provider.dart';
import '../models/matches_provider.dart';
import '../models/telegram_provider.dart';
import '../models/value_preset.dart';
import '../services/storage_service.dart';
import '../services/telegram_monitor.dart';
import '../theme/app_theme.dart';
import 'bot_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _anthropicController = TextEditingController();
  final TextEditingController _oddsController = TextEditingController();
  final TextEditingController _footballController = TextEditingController();
  bool _showAnthropic = false;
  bool _showOdds = false;
  bool _showFootball = false;
  bool _footballHasKey = false;
  bool _footballInited = false;

  @override
  void dispose() {
    _anthropicController.dispose();
    _oddsController.dispose();
    _footballController.dispose();
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
          _buildFootballDataSection(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildValuePresetSection(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const _CacheLimitsSection(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const _BankrollSection(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const _TelegramSection(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anthropic API key saved')),
        );
        setState(() => _anthropicController.text = _mask(v));
      },
      onRemove: () async {
        final ok = await _confirmRemove('Anthropic API key');
        if (ok != true) return;
        if (!mounted) return;
        await context.read<AnalysisProvider>().removeApiKey();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anthropic API key removed')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Odds API key saved')),
        );
        setState(() => _oddsController.text = _mask(v));
      },
      onRemove: () async {
        final ok = await _confirmRemove('The Odds API key');
        if (ok != true) return;
        if (!mounted) return;
        await context.read<MatchesProvider>().removeApiKey();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Odds API key removed')),
        );
        setState(() => _oddsController.clear());
      },
    );
  }

  Widget _buildFootballDataSection() {
    if (!_footballInited) {
      _footballInited = true;
      final stored = StorageService.getFootballDataApiKey();
      if (stored != null && stored.isNotEmpty) {
        _footballHasKey = true;
        _footballController.text = _mask(stored);
      }
    }
    return _ApiKeySection(
      title: 'Football-Data.org API',
      icon: Icons.sports_soccer,
      hint: 'Your football-data.org token',
      isSet: _footballHasKey,
      controller: _footballController,
      obscure: !_showFootball,
      onToggle: () => setState(() => _showFootball = !_showFootball),
      onSave: () async {
        final v = _footballController.text.trim();
        if (v.isEmpty) return;
        await StorageService.saveFootballDataApiKey(v);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Football-Data API key saved (restart app to apply)',
            ),
          ),
        );
        setState(() {
          _footballHasKey = true;
          _footballController.text = _mask(v);
        });
      },
      onRemove: () async {
        final ok = await _confirmRemove('Football-Data API key');
        if (ok != true || !mounted) return;
        await StorageService.deleteFootballDataApiKey();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Football-Data API key removed')),
        );
        setState(() {
          _footballHasKey = false;
          _footballController.clear();
        });
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

class _CacheLimitsSection extends StatefulWidget {
  const _CacheLimitsSection();

  @override
  State<_CacheLimitsSection> createState() => _CacheLimitsSectionState();
}

class _CacheLimitsSectionState extends State<_CacheLimitsSection> {
  static const _ttlOptions = [5, 15, 30, 60];
  late int _ttl;

  @override
  void initState() {
    super.initState();
    _ttl = StorageService.getCacheTtlMinutes();
  }

  Future<void> _setTtl(int v) async {
    await StorageService.saveCacheTtlMinutes(v);
    if (!mounted) return;
    setState(() => _ttl = v);
  }

  Color _progressColor(MatchesProvider p) {
    final left = p.remainingRequests ?? 0;
    if (left < 1) return AppTheme.red;
    if (left < 20) return Colors.orange;
    if (left < 100) return Colors.yellow;
    return AppTheme.green;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MatchesProvider>();
    final pct = p.requestsUsedPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.speed, color: AppTheme.primary),
            SizedBox(width: 8),
            Text(
              'Cache & Limits',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (pct == null)
          Text(
            'API usage will appear after the first refresh.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          )
        else ...[
          Text(
            'API Usage this month',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.card,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_progressColor(p)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${MatchesProvider.apiMonthlyCap - (p.remainingRequests ?? 0)} / ${MatchesProvider.apiMonthlyCap}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              Text(
                '${p.remainingRequests} left',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          Text(
            'Resets on 1st of month',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Cache TTL',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final m in _ttlOptions)
              ChoiceChip(
                label: Text(m < 60 ? '$m min' : '1 h'),
                selected: _ttl == m,
                onSelected: (_) => _setTtl(m),
                selectedColor: AppTheme.primary.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Lower TTL = fresher data but more API calls.',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
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

class _TelegramSection extends StatefulWidget {
  const _TelegramSection();

  @override
  State<_TelegramSection> createState() => _TelegramSectionState();
}

class _TelegramSectionState extends State<_TelegramSection> {
  final TextEditingController _tokenCtrl = TextEditingController();
  bool _showToken = false;
  bool _initialized = false;
  bool _testing = false;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  String _mask() => 'tg_•••••set';

  Future<void> _save() async {
    final v = _tokenCtrl.text.trim();
    if (v.isEmpty) return;
    await context.read<TelegramProvider>().setBotToken(v);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Token saved')));
    setState(() => _tokenCtrl.text = _mask());
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Telegram bot token?'),
        content: const Text(
          'Monitoring will stop and the token will be deleted from local storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<TelegramProvider>().removeBotToken();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Token removed')));
    setState(() => _tokenCtrl.clear());
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final name =
          await context.read<TelegramProvider>().testConnection();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Connected as $name')),
      );
    } on TelegramException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Test failed: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Test failed')),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TelegramProvider>();
    if (!_initialized) {
      _initialized = true;
      if (p.hasToken) _tokenCtrl.text = _mask();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.send, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Telegram Monitor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _StatusBadge(active: p.isMonitoring),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tokenCtrl,
          obscureText: !_showToken,
          onTap: () {
            if (_tokenCtrl.text.contains('•')) _tokenCtrl.clear();
          },
          decoration: InputDecoration(
            hintText: 'Bot token (BotFather)',
            suffixIcon: IconButton(
              icon: Icon(
                _showToken ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _showToken = !_showToken),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
            OutlinedButton(
              onPressed: p.hasToken && !_testing ? _test : null,
              child: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test'),
            ),
            if (p.hasToken)
              TextButton(
                onPressed: _remove,
                child: const Text(
                  'Remove',
                  style: TextStyle(color: AppTheme.red),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BotManagerScreen(),
              ),
            );
          },
          icon: const Icon(Icons.tune),
          label: Text('Manage Channels (${p.channels.length})'),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppTheme.primary,
          title: const Text(
            'Monitoring enabled',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            p.hasToken ? 'Polls Telegram every 10s' : 'Save a token first',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          value: p.enabled,
          onChanged: p.hasToken ? (v) => p.setEnabled(v) : null,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Bot must be added as member to channels you want to monitor. '
                'Create one via @BotFather.',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(
          'Create bot: https://t.me/BotFather',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
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
