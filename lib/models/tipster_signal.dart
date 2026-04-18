import 'sport.dart';

class TipsterSignal {
  final String id;
  final int telegramMessageId;
  final String channelUsername;
  final String channelTitle;
  final String text;
  final DateTime receivedAt;
  final Sport? detectedSport;
  final String? detectedLeague;
  final bool isRelevant;

  const TipsterSignal({
    required this.id,
    required this.telegramMessageId,
    required this.channelUsername,
    required this.channelTitle,
    required this.text,
    required this.receivedAt,
    this.detectedSport,
    this.detectedLeague,
    required this.isRelevant,
  });

  String get preview {
    final trimmed = text.trim();
    if (trimmed.length <= 150) return trimmed;
    return '${trimmed.substring(0, 147)}...';
  }

  String toClaudeContext() {
    final timeAgo = _relativeTime(receivedAt);
    final sport = detectedSport?.display ?? 'unknown sport';
    return '[$timeAgo] $channelUsername ($sport): $preview';
  }

  static String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'telegramMessageId': telegramMessageId,
        'channelUsername': channelUsername,
        'channelTitle': channelTitle,
        'text': text,
        'receivedAt': receivedAt.toIso8601String(),
        'detectedSport': detectedSport?.name,
        'detectedLeague': detectedLeague,
        'isRelevant': isRelevant,
      };

  factory TipsterSignal.fromMap(Map<dynamic, dynamic> map) => TipsterSignal(
        id: map['id'] as String,
        telegramMessageId: map['telegramMessageId'] as int,
        channelUsername: map['channelUsername'] as String,
        channelTitle: map['channelTitle'] as String,
        text: map['text'] as String,
        receivedAt: DateTime.parse(map['receivedAt'] as String),
        detectedSport: map['detectedSport'] == null
            ? null
            : Sport.values
                .firstWhere((s) => s.name == map['detectedSport']),
        detectedLeague: map['detectedLeague'] as String?,
        isRelevant: map['isRelevant'] as bool,
      );
}
