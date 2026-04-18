import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analysis_provider.dart';
import '../models/recommendation.dart';
import '../models/sport.dart';
import '../models/telegram_provider.dart';
import '../models/tier_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/signal_card.dart';
import '../widgets/trade_action_bar.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  bool _disposed = false;
  AnalysisProvider? _listenedProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AnalysisProvider>();
    if (!identical(provider, _listenedProvider)) {
      _listenedProvider?.removeListener(_handlePrefill);
      provider.addListener(_handlePrefill);
      _listenedProvider = provider;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _listenedProvider?.removeListener(_handlePrefill);
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _handlePrefill() {
    if (_disposed) return;
    final provider = _listenedProvider;
    if (provider == null) return;
    final prefill = provider.inputPrefill;
    if (prefill == null) return;
    if (_textController.text.isEmpty) {
      _textController.text = prefill;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: prefill.length),
      );
      _inputFocus.requestFocus();
    }
    provider.clearInputPrefill();
  }

  void _scrollToBottom() {
    if (_disposed || !_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_disposed || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final tier = context.read<TierProvider>().currentTier;
    final p = context.read<AnalysisProvider>();
    p.setCurrentTier(tier);
    p.sendMessage(text).then((_) => _scrollToBottom());
  }

  Future<bool?> _confirmClearChat() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will delete the entire conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: Consumer<AnalysisProvider>(
        builder: (_, p, child) {
          if (!p.hasApiKey) return _buildNoApiKeyState();
          return Column(
            children: [
              _SignalBanner(onView: () => _showSignalSheet(context)),
              Expanded(
                child: p.messages.isEmpty && !p.isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: p.messages.length + (p.isLoading ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == p.messages.length && p.isLoading) {
                            return const _TypingIndicator();
                          }
                          final m = p.messages[i];
                          final isUser = m.role == 'user';
                          final isValueResponse = !isUser &&
                              parseRecommendationType(m.content) ==
                                  RecommendationType.value;
                          final isLastMessage =
                              i == p.messages.length - 1;
                          final showActionBar = isValueResponse &&
                              isLastMessage &&
                              p.lastLogId != null;
                          return Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              ChatBubble(text: m.content, isUser: isUser),
                              if (showActionBar)
                                TradeActionBar(
                                  logId: p.lastLogId!,
                                  assistantResponse: m.content,
                                  stagedMatch: p.stagedMatches.isNotEmpty
                                      ? p.stagedMatches.first
                                      : null,
                                ),
                            ],
                          );
                        },
                      ),
              ),
              if (p.hasStagedMatches) _buildStagedBar(p),
              if (p.hasStagedSignals) _buildStagedSignalsBar(p),
              if (p.error != null) _buildErrorBar(p),
              _buildInputBar(p),
            ],
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
              'Anthropic API key required',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your key in Settings',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
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
            Consumer<TierProvider>(
              builder: (_, tierProv, child) {
                final tier = tierProv.currentTier;
                return Column(
                  children: [
                    Text(tier.icon, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      '${tier.display} analysis',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.philosophy,
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final s in tierProv.suggestionChips)
                          ActionChip(
                            label: Text(s),
                            onPressed: () {
                              _textController.text = s;
                              _sendMessage();
                            },
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSignalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _SignalSheet(),
    );
  }

  Widget _buildStagedSignalsBar(AnalysisProvider p) {
    final n = p.stagedSignals.length;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.send, size: 16, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$n tipster signal${n == 1 ? "" : "s"} staged for next question',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: p.clearStagedSignals,
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStagedBar(AnalysisProvider p) {
    final n = p.stagedMatches.length;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$n match${n == 1 ? "" : "es"} staged for next question',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: p.clearStagedMatches,
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBar(AnalysisProvider p) {
    return Dismissible(
      key: const ValueKey('error_bar'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => p.clearError(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppTheme.red.withValues(alpha: 0.2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                p.error ?? '',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: p.clearError,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(AnalysisProvider p) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await _confirmClearChat();
                if (ok == true) p.clearChat();
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocus,
                maxLines: 4,
                minLines: 1,
                enabled: !p.isLoading,
                decoration: InputDecoration(
                  hintText: p.isLoading
                      ? 'Waiting for response...'
                      : 'Ask about matches...',
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              color: AppTheme.primary,
              onPressed: p.isLoading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalBanner extends StatelessWidget {
  final VoidCallback onView;
  const _SignalBanner({required this.onView});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelegramProvider>(
      builder: (_, p, child) {
        if (p.recentCount == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.send, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${p.recentCount} recent tipster signal${p.recentCount == 1 ? "" : "s"}',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: onView,
                child: const Text(
                  'View →',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SignalSheet extends StatefulWidget {
  const _SignalSheet();

  @override
  State<_SignalSheet> createState() => _SignalSheetState();
}

class _SignalSheetState extends State<_SignalSheet> {
  Sport? _filter;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TelegramProvider>();
    final list = provider.signalsForSport(_filter);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Signals',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(label: 'All', sport: null),
                  const SizedBox(width: 8),
                  _filterChip(
                      label: '${Sport.soccer.icon} Soccer',
                      sport: Sport.soccer),
                  const SizedBox(width: 8),
                  _filterChip(
                      label: '${Sport.basketball.icon} Basketball',
                      sport: Sport.basketball),
                  const SizedBox(width: 8),
                  _filterChip(
                      label: '${Sport.tennis.icon} Tennis',
                      sport: Sport.tennis),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        'No signals in the last 6 hours',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final s = list[i];
                        return SignalCard(
                          signal: s,
                          selected: _selectedIds.contains(s.id),
                          onSelectedChanged: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedIds.add(s.id);
                              } else {
                                _selectedIds.remove(s.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            if (_selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Text(
                      '${_selectedIds.length} selected',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        final selected = list
                            .where((s) => _selectedIds.contains(s.id))
                            .toList();
                        context
                            .read<AnalysisProvider>()
                            .stageSelectedSignals(selected);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Staged ${selected.length} signal${selected.length == 1 ? "" : "s"}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Use as context'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required Sport? sport}) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == sport,
      onSelected: (_) => setState(() => _filter = sport),
      selectedColor: AppTheme.primary.withValues(alpha: 0.3),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Thinking...', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}
