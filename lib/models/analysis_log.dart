import 'dart:math';

import 'recommendation.dart';

class AnalysisLog {
  final String id;
  final DateTime timestamp;
  final String userMessage;
  final String assistantResponse;
  final List<String> contextMatchIds;
  final RecommendationType recommendationType;

  const AnalysisLog({
    required this.id,
    required this.timestamp,
    required this.userMessage,
    required this.assistantResponse,
    required this.contextMatchIds,
    required this.recommendationType,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'userMessage': userMessage,
        'assistantResponse': assistantResponse,
        'contextMatchIds': contextMatchIds,
        'recommendationType': recommendationType.name,
      };

  factory AnalysisLog.fromMap(Map<dynamic, dynamic> map) => AnalysisLog(
        id: map['id'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        userMessage: map['userMessage'] as String,
        assistantResponse: map['assistantResponse'] as String,
        contextMatchIds: (map['contextMatchIds'] as List).cast<String>(),
        recommendationType: RecommendationType.values.firstWhere(
          (t) => t.name == map['recommendationType'],
          orElse: () => RecommendationType.none,
        ),
      );
}

String generateUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;

  String hex(int i, int len) => bytes
      .sublist(i, i + len)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex(0, 4)}-${hex(4, 2)}-${hex(6, 2)}-${hex(8, 2)}-${hex(10, 6)}';
}
