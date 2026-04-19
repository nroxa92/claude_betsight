import 'package:betsight/models/tier_provider.dart';
import 'package:betsight/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  test('initial tier is preMatch when no saved state', () {
    final p = TierProvider();
    expect(p.currentTier, InvestmentTier.preMatch);
  });

  test('constructor reads persisted tier from storage', () async {
    await StorageService.saveCurrentTier('live');
    final p = TierProvider();
    expect(p.currentTier, InvestmentTier.live);
  });

  test('setTier updates state, persists, notifies', () async {
    final p = TierProvider();
    var notified = 0;
    p.addListener(() => notified++);

    await p.setTier(InvestmentTier.accumulator);
    expect(p.currentTier, InvestmentTier.accumulator);
    expect(notified, 1);
    expect(StorageService.getCurrentTier(), 'accumulator');
  });

  test('setTier to current tier is no-op (no notify)', () async {
    final p = TierProvider();
    var notified = 0;
    p.addListener(() => notified++);
    await p.setTier(InvestmentTier.preMatch);
    expect(notified, 0);
  });

  test('suggestionChips differ per tier', () async {
    final p = TierProvider();
    final preChips = p.suggestionChips;
    await p.setTier(InvestmentTier.live);
    final liveChips = p.suggestionChips;
    await p.setTier(InvestmentTier.accumulator);
    final accChips = p.suggestionChips;
    expect(preChips, isNot(equals(liveChips)));
    expect(liveChips, isNot(equals(accChips)));
    expect(preChips, hasLength(3));
  });

  test('claudeContextAppendix matches current tier', () async {
    final p = TierProvider();
    expect(p.claudeContextAppendix, InvestmentTier.preMatch.claudeContextAppendix);
    await p.setTier(InvestmentTier.live);
    expect(p.claudeContextAppendix, InvestmentTier.live.claudeContextAppendix);
  });
}
