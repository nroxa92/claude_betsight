import 'package:betsight/models/odds.dart';
import 'package:betsight/widgets/odds_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required H2HOdds? odds,
    required bool hasDraw,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OddsWidget(odds: odds, hasDraw: hasDraw),
        ),
      ),
    );
  }

  H2HOdds makeOdds({double home = 2.0, double? draw, double away = 2.0}) =>
      H2HOdds(
        home: home,
        draw: draw,
        away: away,
        lastUpdate: DateTime(2026, 4, 18),
        bookmaker: 'Test',
      );

  group('OddsWidget', () {
    testWidgets('shows "Odds unavailable" when odds is null', (tester) async {
      await pump(tester, odds: null, hasDraw: true);
      expect(find.text('Odds unavailable'), findsOneWidget);
    });

    testWidgets('renders Home + Away chips for 2-way market', (tester) async {
      await pump(
        tester,
        odds: makeOdds(home: 1.80, away: 2.10),
        hasDraw: false,
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Away'), findsOneWidget);
      expect(find.text('Draw'), findsNothing);
      expect(find.text('1.80'), findsOneWidget);
      expect(find.text('2.10'), findsOneWidget);
    });

    testWidgets('renders Home/Draw/Away for 3-way market with draw', (tester) async {
      await pump(
        tester,
        odds: makeOdds(home: 2.50, draw: 3.40, away: 3.00),
        hasDraw: true,
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Draw'), findsOneWidget);
      expect(find.text('Away'), findsOneWidget);
      expect(find.text('3.40'), findsOneWidget);
    });

    testWidgets('omits Draw chip when hasDraw=false even with draw value', (tester) async {
      await pump(
        tester,
        odds: makeOdds(home: 1.90, draw: 20.0, away: 1.90),
        hasDraw: false,
      );
      expect(find.text('Draw'), findsNothing);
    });

    testWidgets('omits Draw chip when draw is null even if hasDraw=true', (tester) async {
      await pump(
        tester,
        odds: makeOdds(home: 2.0, away: 2.0),
        hasDraw: true,
      );
      expect(find.text('Draw'), findsNothing);
    });

    testWidgets('odds displayed with 2 decimal places', (tester) async {
      await pump(
        tester,
        odds: makeOdds(home: 1.5, away: 2.67),
        hasDraw: false,
      );
      expect(find.text('1.50'), findsOneWidget);
      expect(find.text('2.67'), findsOneWidget);
    });
  });
}
