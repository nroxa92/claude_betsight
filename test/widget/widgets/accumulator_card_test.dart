import 'package:betsight/models/accumulator.dart';
import 'package:betsight/models/accumulators_provider.dart';
import 'package:betsight/models/bet.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/widgets/accumulator_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  AccumulatorLeg leg({
    String matchId = 'm-1',
    String home = 'A',
    String away = 'B',
    BetSelection selection = BetSelection.home,
    double odds = 2.0,
  }) =>
      AccumulatorLeg(
        matchId: matchId,
        sport: Sport.soccer,
        league: 'EPL',
        home: home,
        away: away,
        selection: selection,
        odds: odds,
        kickoff: DateTime(2026, 5, 1),
      );

  BetAccumulator buildAcc({
    List<AccumulatorLeg>? legs,
    AccumulatorStatus status = AccumulatorStatus.building,
  }) =>
      BetAccumulator(
        id: 'acc-1',
        legs: legs ??
            [
              leg(matchId: 'm-1', home: 'Ars', away: 'Liv'),
              leg(matchId: 'm-2', home: 'Chelsea', away: 'City', odds: 3.0),
            ],
        stake: 10,
        status: status,
        createdAt: DateTime(2026, 4, 18),
      );

  Future<void> pumpCard(WidgetTester tester, BetAccumulator acc) async {
    final provider = AccumulatorsProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: AccumulatorCard(acca: acc, currency: 'EUR'),
          ),
        ),
      ),
    );
  }

  testWidgets('renders leg count header', (tester) async {
    await pumpCard(tester, buildAcc());
    expect(find.text('2 legs'), findsOneWidget);
  });

  testWidgets('renders up to 3 leg lines', (tester) async {
    await pumpCard(tester, buildAcc());
    expect(find.textContaining('Ars vs Liv'), findsOneWidget);
    expect(find.textContaining('Chelsea vs City'), findsOneWidget);
  });

  testWidgets('>3 legs shows "+N more" indicator', (tester) async {
    final acc = buildAcc(legs: [
      leg(matchId: '1', home: 'A', away: 'B'),
      leg(matchId: '2', home: 'C', away: 'D'),
      leg(matchId: '3', home: 'E', away: 'F'),
      leg(matchId: '4', home: 'G', away: 'H'),
      leg(matchId: '5', home: 'I', away: 'J'),
    ]);
    await pumpCard(tester, acc);
    expect(find.text('+2 more'), findsOneWidget);
  });

  testWidgets('status chip reflects status', (tester) async {
    await pumpCard(tester, buildAcc(status: AccumulatorStatus.won));
    expect(find.text('Won'), findsOneWidget);
  });
}
