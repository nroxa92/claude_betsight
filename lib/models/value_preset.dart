import 'match.dart';

enum ValuePreset {
  conservative(
    display: 'Conservative',
    description: 'Sharp books only, tight odds range',
    marginMax: 0.05,
    oddsMin: 1.50,
    oddsMax: 3.00,
    spreadMax: 2.5,
  ),
  standard(
    display: 'Standard',
    description: 'Balanced edge and match volume',
    marginMax: 0.08,
    oddsMin: 1.40,
    oddsMax: 5.00,
    spreadMax: 4.0,
  ),
  aggressive(
    display: 'Aggressive',
    description: 'Wider range, more candidates',
    marginMax: 0.12,
    oddsMin: 1.20,
    oddsMax: 10.00,
    spreadMax: 10.0,
  );

  final String display;
  final String description;
  final double marginMax;
  final double oddsMin;
  final double oddsMax;
  final double spreadMax;

  const ValuePreset({
    required this.display,
    required this.description,
    required this.marginMax,
    required this.oddsMin,
    required this.oddsMax,
    required this.spreadMax,
  });

  bool matches(Match match) {
    final h2h = match.h2h;
    if (h2h == null) return false;
    if (h2h.bookmakerMargin > marginMax) return false;

    final minOdd = [h2h.home, h2h.away].reduce((a, b) => a < b ? a : b);
    final maxOdd = [h2h.home, h2h.away].reduce((a, b) => a > b ? a : b);

    if (minOdd < oddsMin) return false;
    if (maxOdd > oddsMax) return false;
    if ((maxOdd / minOdd) > spreadMax) return false;

    return true;
  }

  double edgeScore(Match match) {
    final h2h = match.h2h;
    if (h2h == null) return 0.0;
    return 1.0 / (h2h.bookmakerMargin + 0.001);
  }

  static ValuePreset fromString(String? value) {
    return ValuePreset.values.firstWhere(
      (p) => p.name == value,
      orElse: () => ValuePreset.standard,
    );
  }
}
