import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/monitored_channel.dart';
import '../models/telegram_provider.dart';
import '../theme/app_theme.dart';

class BotManagerScreen extends StatefulWidget {
  const BotManagerScreen({super.key});

  @override
  State<BotManagerScreen> createState() => _BotManagerScreenState();
}

class _BotManagerScreenState extends State<BotManagerScreen> {
  final _newChannelController = TextEditingController();

  @override
  void dispose() {
    _newChannelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bot Manager')),
      body: Consumer<TelegramProvider>(
        builder: (context, provider, child) {
          final channels = provider.channels;
          final totalReceived = channels.fold<int>(
            0,
            (sum, c) => sum + c.signalsReceived,
          );
          final totalRelevant = channels.fold<int>(
            0,
            (sum, c) => sum + c.signalsRelevant,
          );

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statTile('Channels', '${channels.length}'),
                    _statTile('Total signals', '$totalReceived'),
                    _statTile('Relevant', '$totalRelevant'),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newChannelController,
                        decoration: const InputDecoration(
                          labelText: 'Add channel (e.g., @tipsmaster)',
                          prefixIcon: Icon(Icons.add_circle_outline),
                        ),
                        onSubmitted: (_) => _addChannel(provider),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _addChannel(provider),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: channels.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: channels.length,
                        itemBuilder: (_, i) => _ChannelCard(
                          channel: channels[i],
                          onDelete: () => _confirmDelete(
                            provider,
                            channels[i].username,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.podcasts, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(
            'No channels yet',
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            'Add a channel to start monitoring',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _addChannel(TelegramProvider provider) async {
    var text = _newChannelController.text.trim();
    if (text.isEmpty) return;
    if (!text.startsWith('@')) text = '@$text';
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel handle too short')),
      );
      return;
    }
    await provider.addChannel(text);
    if (!mounted) return;
    _newChannelController.clear();
  }

  Future<void> _confirmDelete(
      TelegramProvider provider, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove channel?'),
        content: Text(
          'Remove $username? Stats for this channel will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.removeChannel(username);
    }
  }
}

class _ChannelCard extends StatelessWidget {
  final MonitoredChannel channel;
  final VoidCallback onDelete;

  const _ChannelCard({required this.channel, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.title ?? channel.username,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (channel.title != null)
                        Text(
                          channel.username,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                _ReliabilityBadge(channel: channel),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _metaChip('${channel.signalsReceived} received'),
                _metaChip('${channel.signalsRelevant} relevant'),
                _metaChip('Last: ${channel.lastRelevantDisplay}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: Colors.grey[300]),
      ),
    );
  }
}

class _ReliabilityBadge extends StatelessWidget {
  final MonitoredChannel channel;
  const _ReliabilityBadge({required this.channel});

  @override
  Widget build(BuildContext context) {
    final color = Color(channel.reliabilityColorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        channel.reliabilityLabel,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
