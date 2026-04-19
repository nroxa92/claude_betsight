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

  AccumulatorLeg leg({
    String matchId = 'm-1',
    double odds = 2.0,
    BetSelection selection = BetSelection.home,
  }) =>
      AccumulatorLeg(
        matchId: matchId,
        sport: Sport.soccer,
        league: 'EPL',
        home: 'A',
        away: 'B',
        selection: selection,
        odds: odds,
        kickoff: DateTime(2026, 5, 1),
      );

  BetAccumulator makeAcc(String id,
          {AccumulatorStatus status = AccumulatorStatus.building,
          List<AccumulatorLeg>? legs}) =>
      BetAccumulator(
        id: id,
        legs: legs ?? [leg()],
        stake: 10,
        status: status,
        createdAt: DateTime(2026, 4, 18),
      );

  group('initialization', () {
    test('empty when storage empty', () {
      final p = AccumulatorsProvider();
      expect(p.all, isEmpty);
      expect(p.currentDraft, isNull);
    });

    test('loads from storage', () async {
      await StorageService.saveAccumulator(makeAcc('a-1'));
      final p = AccumulatorsProvider();
      expect(p.all, hasLength(1));
      expect(p.all.first.id, 'a-1');
    });
  });

  group('status partitioning', () {
    test('building/placed/settled separate accumulators', () async {
      await StorageService.saveAccumulator(
          makeAcc('build', status: AccumulatorStatus.building));
      await StorageService.saveAccumulator(
          makeAcc('placed', status: AccumulatorStatus.placed));
      await StorageService.saveAccumulator(
          makeAcc('won', status: AccumulatorStatus.won));
      final p = AccumulatorsProvider();
      expect(p.building.map((a) => a.id), ['build']);
      expect(p.placed.map((a) => a.id), ['placed']);
      expect(p.settled.map((a) => a.id), ['won']);
    });
  });

  group('draft lifecycle', () {
    test('startNewDraft creates empty draft and notifies', () {
      final p = AccumulatorsProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.startNewDraft();
      expect(p.currentDraft, isNotNull);
      expect(p.currentDraft!.legs, isEmpty);
      expect(notified, 1);
    });

    test('addLegToDraft starts draft if null', () {
      final p = AccumulatorsProvider();
      p.addLegToDraft(leg());
      expect(p.currentDraft!.legs, hasLength(1));
    });

    test('addLegToDraft appends legs', () {
      final p = AccumulatorsProvider();
      p.startNewDraft();
      p.addLegToDraft(leg(matchId: 'm-1'));
      p.addLegToDraft(leg(matchId: 'm-2'));
      expect(p.currentDraft!.legs, hasLength(2));
    });

    test('removeLegFromDraft removes by matchId', () {
      final p = AccumulatorsProvider();
      p.addLegToDraft(leg(matchId: 'm-1'));
      p.addLegToDraft(leg(matchId: 'm-2'));
      p.removeLegFromDraft('m-1');
      expect(p.currentDraft!.legs.map((l) => l.matchId), ['m-2']);
    });

    test('removeLegFromDraft no-op when no draft', () {
      final p = AccumulatorsProvider();
      p.removeLegFromDraft('anything');
      expect(p.currentDraft, isNull);
    });

    test('setDraftStake updates stake', () {
      final p = AccumulatorsProvider();
      p.startNewDraft();
      p.setDraftStake(25);
      expect(p.currentDraft!.stake, 25);
    });

    test('setDraftStake no-op when no draft', () {
      final p = AccumulatorsProvider();
      p.setDraftStake(25);
      expect(p.currentDraft, isNull);
    });

    test('discardDraft clears', () {
      final p = AccumulatorsProvider();
      p.startNewDraft();
      p.discardDraft();
      expect(p.currentDraft, isNull);
    });
  });

  group('saveDraftAsAccumulator', () {
    test('requires >= 2 legs and stake > 0', () async {
      final p = AccumulatorsProvider();
      p.startNewDraft();
      await p.saveDraftAsAccumulator();
      expect(p.all, isEmpty);

      p.addLegToDraft(leg(matchId: 'm-1'));
      p.setDraftStake(10);
      await p.saveDraftAsAccumulator();
      // still only 1 leg
      expect(p.all, isEmpty);
    });

    test('saves when 2+ legs and stake > 0, clears draft', () async {
      final p = AccumulatorsProvider();
      p.addLegToDraft(leg(matchId: 'm-1'));
      p.addLegToDraft(leg(matchId: 'm-2'));
      p.setDraftStake(20);
      await p.saveDraftAsAccumulator();
      expect(p.all, hasLength(1));
      expect(p.currentDraft, isNull);
      expect(StorageService.getAllAccumulators(), hasLength(1));
    });
  });

  group('placeAccumulator', () {
    test('transitions building → placed with placedAt', () async {
      final p = AccumulatorsProvider();
      await StorageService.saveAccumulator(makeAcc('a-1'));
      p.startNewDraft();
      p.discardDraft();
      final reloaded = AccumulatorsProvider();
      await reloaded.placeAccumulator('a-1');
      final a = reloaded.all.first;
      expect(a.status, AccumulatorStatus.placed);
      expect(a.placedAt, isNotNull);
    });

    test('missing id no-op', () async {
      final p = AccumulatorsProvider();
      await p.placeAccumulator('ghost');
      expect(p.all, isEmpty);
    });
  });

  group('settleAccumulator', () {
    test('won sets status + settledAt', () async {
      await StorageService.saveAccumulator(
          makeAcc('a-1', status: AccumulatorStatus.placed));
      final p = AccumulatorsProvider();
      await p.settleAccumulator('a-1', AccumulatorStatus.won);
      expect(p.all.first.status, AccumulatorStatus.won);
      expect(p.all.first.settledAt, isNotNull);
    });

    test('lost/partial also valid', () async {
      await StorageService.saveAccumulator(
          makeAcc('a-lost', status: AccumulatorStatus.placed));
      await StorageService.saveAccumulator(
          makeAcc('a-partial', status: AccumulatorStatus.placed));
      final p = AccumulatorsProvider();
      await p.settleAccumulator('a-lost', AccumulatorStatus.lost);
      await p.settleAccumulator('a-partial', AccumulatorStatus.partial);
      final map = {for (final a in p.all) a.id: a.status};
      expect(map['a-lost'], AccumulatorStatus.lost);
      expect(map['a-partial'], AccumulatorStatus.partial);
    });

    test('missing id no-op', () async {
      final p = AccumulatorsProvider();
      await p.settleAccumulator('ghost', AccumulatorStatus.won);
      expect(p.all, isEmpty);
    });
  });

  group('deleteAccumulator', () {
    test('removes and persists', () async {
      await StorageService.saveAccumulator(makeAcc('a-1'));
      final p = AccumulatorsProvider();
      await p.deleteAccumulator('a-1');
      expect(p.all, isEmpty);
      expect(StorageService.getAllAccumulators(), isEmpty);
    });
  });
}
