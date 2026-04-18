import 'match.dart';

class CachedMatchesEntry {
  final List<Match> matches;
  final DateTime fetchedAt;
  final int? remainingRequests;

  const CachedMatchesEntry({
    required this.matches,
    required this.fetchedAt,
    this.remainingRequests,
  });

  Duration get age => DateTime.now().difference(fetchedAt);

  bool isExpired(Duration ttl) => age > ttl;

  String get ageDisplay {
    if (age.inSeconds < 60) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  Map<String, dynamic> toMap() => {
        'matches': matches.map((m) => m.toMap()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
        'remainingRequests': remainingRequests,
      };

  factory CachedMatchesEntry.fromMap(Map<dynamic, dynamic> map) =>
      CachedMatchesEntry(
        matches: (map['matches'] as List<dynamic>)
            .map((m) => Match.fromMap(m as Map<dynamic, dynamic>))
            .toList(),
        fetchedAt: DateTime.parse(map['fetchedAt'] as String),
        remainingRequests: map['remainingRequests'] as int?,
      );
}
