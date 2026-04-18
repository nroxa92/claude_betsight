import 'package:flutter/material.dart';

import '../models/sport.dart';
import '../theme/app_theme.dart';

class SportSelector extends StatelessWidget {
  final Sport? selectedSport;
  final ValueChanged<Sport?> onSportSelected;

  const SportSelector({
    super.key,
    required this.selectedSport,
    required this.onSportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(label: 'All', sport: null),
          const SizedBox(width: 8),
          _chip(label: '${Sport.soccer.icon} Soccer', sport: Sport.soccer),
          const SizedBox(width: 8),
          _chip(
            label: '${Sport.basketball.icon} Basketball',
            sport: Sport.basketball,
          ),
          const SizedBox(width: 8),
          _chip(label: '${Sport.tennis.icon} Tennis', sport: Sport.tennis),
        ],
      ),
    );
  }

  Widget _chip({required String label, required Sport? sport}) {
    final selected = selectedSport == sport;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSportSelected(sport),
      selectedColor: AppTheme.primary.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
