import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import 'investment_tier.dart';

export 'investment_tier.dart';

class TierProvider extends ChangeNotifier {
  InvestmentTier _currentTier = InvestmentTier.preMatch;

  TierProvider() {
    _currentTier = InvestmentTierMeta.fromString(
      StorageService.getCurrentTier(),
    );
  }

  InvestmentTier get currentTier => _currentTier;

  Future<void> setTier(InvestmentTier tier) async {
    if (_currentTier == tier) return;
    _currentTier = tier;
    await StorageService.saveCurrentTier(tier.name);
    notifyListeners();
  }

  List<String> get suggestionChips => switch (_currentTier) {
        InvestmentTier.preMatch => const [
            "Analyze tomorrow's EPL",
            'Best value bets this weekend',
            'Underdog picks under 4.0 odds',
          ],
        InvestmentTier.live => const [
            'Live odds movement on watched',
            'In-play value — which matches look mispriced now?',
            'Momentum shift detection',
          ],
        InvestmentTier.accumulator => const [
            'Build a 3-leg accumulator from my watched matches',
            'Check correlation in my current selections',
            'Conservative acca — all favorites under 2.0',
          ],
      };

  String get claudeContextAppendix => _currentTier.claudeContextAppendix;
}
