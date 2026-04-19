import 'package:betsight/models/accumulator.dart';
import 'package:betsight/models/accumulators_provider.dart';
import 'package:betsight/models/bet.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  AccumulatorLeg leg(String id, {double odds = 2.0}) => AccumulatorLeg(
        matchId: id,
        sport: Sport.soccer,
        league: 'EPL',
        home: 'A',
        away: 'B',
        selection: BetSelection.home,
        odds: odds,
        kickoff: DateTime(2026, 5, 1),
      );

  test('build → save → place → settle flow', () async {
    final p = AccumulatorsProvider();

    p.startNewDraft();
    p.addLegToDraft(leg('m-1', odds: 2.0));
    p.addLegToDraft(leg('m-2', odds: 2.5));
    p.setDraftStake(20);

    await p.saveDraftAsAccumulator();
    expect(p.all, hasLength(1));
    final id = p.all.first.id;

    await p.placeAccumulator(id);
    expect(p.placed.first.placedAt, isNotNull);

    await p.settleAccumulator(id, AccumulatorStatus.won);
    final a = p.all.first;
    expect(a.status, AccumulatorStatus.won);
    expect(a.combinedOdds, closeTo(5.0, 0.001));
    expect(a.actualProfit, 80);

    // Persists across provider reload
    final p2 = AccumulatorsProvider();
    expect(p2.all, hasLength(1));
    expect(p2.all.first.status, AccumulatorStatus.won);
  });

  test('correlation warning flows through to saved accumulator', () async {
    final p = AccumulatorsProvider();
    p.startNewDraft();
    p.addLegToDraft(AccumulatorLeg(
      matchId: 'm-1',
      sport: Sport.soccer,
      league: 'EPL',
      home: 'A',
      away: 'B',
      selection: BetSelection.home,
      odds: 2.0,
      kickoff: DateTime(2026, 5, 1, 14),
    ));
    p.addLegToDraft(AccumulatorLeg(
      matchId: 'm-2',
      sport: Sport.soccer,
      league: 'EPL',
      home: 'C',
      away: 'D',
      selection: BetSelection.home,
      odds: 1.9,
      kickoff: DateTime(2026, 5, 1, 16),
    ));
    p.setDraftStake(10);
    await p.saveDraftAsAccumulator();

    final saved = p.all.first;
    expect(saved.correlationWarnings, isNotEmpty);
    expect(
      saved.correlationWarnings.any((w) => w.contains('EPL')),
      isTrue,
    );
  });

  test('removeLegFromDraft leaves valid 2-leg draft savable', () async {
    final p = AccumulatorsProvider();
    p.startNewDraft();
    p.addLegToDraft(leg('m-1'));
    p.addLegToDraft(leg('m-2'));
    p.addLegToDraft(leg('m-3'));
    p.removeLegFromDraft('m-2');
    p.setDraftStake(5);
    await p.saveDraftAsAccumulator();
    expect(p.all.first.legs.map((l) => l.matchId), ['m-1', 'm-3']);
  });

  test('delete removes from memory and storage', () async {
    final p = AccumulatorsProvider();
    p.addLegToDraft(leg('m-1'));
    p.addLegToDraft(leg('m-2'));
    p.setDraftStake(10);
    await p.saveDraftAsAccumulator();
    final id = p.all.first.id;
    await p.deleteAccumulator(id);
    expect(p.all, isEmpty);
    expect(StorageService.getAllAccumulators(), isEmpty);
  });
}
