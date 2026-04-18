class MatchNote {
  final String matchId;
  final String text;
  final DateTime updatedAt;

  const MatchNote({
    required this.matchId,
    required this.text,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'text': text,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MatchNote.fromMap(Map<dynamic, dynamic> map) => MatchNote(
        matchId: map['matchId'] as String,
        text: map['text'] as String,
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
