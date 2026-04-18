class MonitoredChannel {
  final String username;
  final String? title;
  final int signalsReceived;
  final int signalsRelevant;
  final DateTime addedAt;
  final DateTime? lastSignalAt;
  final DateTime? lastRelevantAt;

  const MonitoredChannel({
    required this.username,
    this.title,
    this.signalsReceived = 0,
    this.signalsRelevant = 0,
    required this.addedAt,
    this.lastSignalAt,
    this.lastRelevantAt,
  });

  /// -1 = insufficient data (< 10 signals), else relevant/received ratio.
  double get reliabilityScore {
    if (signalsReceived < 10) return -1;
    return signalsRelevant / signalsReceived;
  }

  String get reliabilityLabel {
    final score = reliabilityScore;
    if (score < 0) return 'Novo';
    if (score < 0.1) return 'Niska';
    if (score < 0.3) return 'Srednja';
    return 'Visoka';
  }

  /// Color value as ARGB int — caller wraps in Color(value).
  int get reliabilityColorValue {
    final score = reliabilityScore;
    if (score < 0) return 0xFF9E9E9E;
    if (score < 0.1) return 0xFFEF5350;
    if (score < 0.3) return 0xFFFFA726;
    return 0xFF4CAF50;
  }

  String get lastRelevantDisplay {
    if (lastRelevantAt == null) return 'Never';
    final diff = DateTime.now().difference(lastRelevantAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  MonitoredChannel copyWith({
    String? title,
    int? signalsReceived,
    int? signalsRelevant,
    DateTime? lastSignalAt,
    DateTime? lastRelevantAt,
  }) {
    return MonitoredChannel(
      username: username,
      title: title ?? this.title,
      signalsReceived: signalsReceived ?? this.signalsReceived,
      signalsRelevant: signalsRelevant ?? this.signalsRelevant,
      addedAt: addedAt,
      lastSignalAt: lastSignalAt ?? this.lastSignalAt,
      lastRelevantAt: lastRelevantAt ?? this.lastRelevantAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'username': username,
        'title': title,
        'signalsReceived': signalsReceived,
        'signalsRelevant': signalsRelevant,
        'addedAt': addedAt.toIso8601String(),
        'lastSignalAt': lastSignalAt?.toIso8601String(),
        'lastRelevantAt': lastRelevantAt?.toIso8601String(),
      };

  factory MonitoredChannel.fromMap(Map<dynamic, dynamic> map) =>
      MonitoredChannel(
        username: map['username'] as String,
        title: map['title'] as String?,
        signalsReceived: (map['signalsReceived'] as int?) ?? 0,
        signalsRelevant: (map['signalsRelevant'] as int?) ?? 0,
        addedAt: DateTime.parse(map['addedAt'] as String),
        lastSignalAt: map['lastSignalAt'] == null
            ? null
            : DateTime.parse(map['lastSignalAt'] as String),
        lastRelevantAt: map['lastRelevantAt'] == null
            ? null
            : DateTime.parse(map['lastRelevantAt'] as String),
      );
}
