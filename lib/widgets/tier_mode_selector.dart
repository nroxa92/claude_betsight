import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tier_provider.dart';

class TierModeSelector extends StatelessWidget {
  const TierModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TierProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Colors.grey[900]!, width: 0.5),
            ),
          ),
          child: Row(
            children: InvestmentTier.values.map((tier) {
              final isActive = provider.currentTier == tier;
              final tierColor = Color(tier.colorValue);
              return Expanded(
                child: GestureDetector(
                  onTap: () => provider.setTier(tier),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? tierColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? tierColor : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tier.icon,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          tier.display,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isActive ? tierColor : Colors.grey[400],
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
