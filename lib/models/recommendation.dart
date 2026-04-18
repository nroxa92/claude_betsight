enum RecommendationType { value, watch, skip, none }

extension RecommendationTypeMeta on RecommendationType {
  String get display => switch (this) {
        RecommendationType.value => 'VALUE',
        RecommendationType.watch => 'WATCH',
        RecommendationType.skip => 'SKIP',
        RecommendationType.none => 'NONE',
      };
}

RecommendationType parseRecommendationType(String response) {
  final lines = response.split('\n').map((l) => l.trim()).toList();

  for (final line in lines) {
    if (line == '**VALUE**') return RecommendationType.value;
  }
  for (final line in lines) {
    if (line == '**WATCH**') return RecommendationType.watch;
  }
  for (final line in lines) {
    if (line == '**SKIP**') return RecommendationType.skip;
  }

  if (response.contains('**VALUE**')) return RecommendationType.value;
  if (response.contains('**WATCH**')) return RecommendationType.watch;
  if (response.contains('**SKIP**')) return RecommendationType.skip;

  return RecommendationType.none;
}
