import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analysis_log.dart';
import '../models/analysis_provider.dart';
import '../models/match.dart';
import '../theme/app_theme.dart';
import 'bet_entry_sheet.dart';

class TradeActionBar extends StatelessWidget {
  final String logId;
  final String assistantResponse;
  final Match? stagedMatch;

  const TradeActionBar({
    super.key,
    required this.logId,
    required this.assistantResponse,
    this.stagedMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.flag, size: 16, color: AppTheme.green),
              SizedBox(width: 6),
              Text(
                'VALUE signal detected',
                style: TextStyle(
                  color: AppTheme.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logBet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('LOG BET'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _skip(context),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('SKIP'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _askMore(context),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('ASK MORE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _logBet(BuildContext context) {
    context.read<AnalysisProvider>().recordFeedback(
          logId,
          UserFeedback.logged,
        );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BetEntrySheet(prefilledMatch: stagedMatch),
    );
  }

  void _skip(BuildContext context) {
    context.read<AnalysisProvider>().recordFeedback(
          logId,
          UserFeedback.skipped,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recommendation skipped — logged for calibration'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _askMore(BuildContext context) {
    final provider = context.read<AnalysisProvider>();
    provider.recordFeedback(logId, UserFeedback.askedMore);
    provider.setInputPrefill(
      "Why do you think this is value? What's the main risk?",
    );
  }
}
