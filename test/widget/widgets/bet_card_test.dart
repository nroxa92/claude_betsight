import 'package:betsight/models/bet.dart';
import 'package:betsight/models/bets_provider.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/widgets/bet_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  Bet makeBet({
    String id = 'b-1',
    BetStatus status = BetStatus.pending,
    double odds = 2.0,
    double stake = 10,
    String? bookmaker,
  }) =>
      Bet(
        id: id,
        sport: Sport.soccer,
        league: 'EPL',
        home: 'Arsenal',
        away: 'Liverpool',
        selection: BetSelection.home,
        odds: odds,
        stake: stake,
        bookmaker: bookmaker,
        placedAt: DateTime(2026, 4, 18),
        status: status,
      );

  Future<void> pumpCard(WidgetTester tester, Bet bet) async {
    final provider = BetsProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: BetCard(bet: bet, currency: 'EUR'),
          ),
        ),
      ),
    );
  }

  testWidgets('renders league, teams, pick, odds, stake', (tester) async {
    await pumpCard(tester, makeBet(bookmaker: 'Pinnacle'));
    expect(find.text('EPL'), findsOneWidget);
    expect(find.text('Arsenal vs Liverpool'), findsOneWidget);
    expect(find.text('Pick: Home'), findsOneWidget);
    expect(find.text('Odds 2.00'), findsOneWidget);
    expect(find.text('Stake 10.00 EUR'), findsOneWidget);
    expect(find.text('Pinnacle'), findsOneWidget);
  });

  testWidgets('pending bet shows Settle button', (tester) async {
    await pumpCard(tester, makeBet(status: BetStatus.pending));
    expect(find.text('Settle'), findsOneWidget);
  });

  testWidgets('won bet shows +profit in green', (tester) async {
    await pumpCard(tester,
        makeBet(status: BetStatus.won, odds: 2.0, stake: 10));
    expect(find.text('+10.00 EUR'), findsOneWidget);
    expect(find.text('Settle'), findsNothing);
  });

  testWidgets('lost bet shows -stake', (tester) async {
    await pumpCard(tester, makeBet(status: BetStatus.lost, stake: 20));
    expect(find.text('-20.00 EUR'), findsOneWidget);
  });

  testWidgets('void bet shows 0.00 profit', (tester) async {
    await pumpCard(tester, makeBet(status: BetStatus.void_));
    expect(find.text('+0.00 EUR'), findsOneWidget);
  });

  testWidgets('status chip shows correct label', (tester) async {
    await pumpCard(tester, makeBet(status: BetStatus.won));
    expect(find.text('Won'), findsOneWidget);
  });

  testWidgets('no bookmaker chip when null', (tester) async {
    await pumpCard(tester, makeBet());
    expect(find.text('Pinnacle'), findsNothing);
  });
}
