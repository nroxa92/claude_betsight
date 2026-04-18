import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analysis_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final p = context.read<AnalysisProvider>();
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
                          return ChatBubble(
                            text: m.content,
                            isUser: m.role == 'user',
                          );
                        },
                      ),
              ),
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
            Icon(Icons.auto_awesome, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'Start your betting analysis',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in const [
                  "Analyze today's EPL",
                  "NBA value picks",
                  "ATP upsets",
                ])
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
        ),
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
