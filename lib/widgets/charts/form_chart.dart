import 'package:flutter/material.dart';

class FormChart extends StatelessWidget {
  final String teamName;
  final List<String> form;

  const FormChart({super.key, required this.teamName, required this.form});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          children: form.map((result) {
            final color = switch (result) {
              'W' => Colors.green,
              'D' => Colors.grey,
              'L' => Colors.red,
              _ => Colors.transparent,
            };
            return Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                result,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
