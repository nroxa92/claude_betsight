import 'package:betsight/models/bets_provider.dart';
import 'package:betsight/models/sport.dart';
import 'package:betsight/widgets/bets_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  Future<BetsProvider> pump(WidgetTester tester) async {
    final provider = BetsProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: BetsFilterBar()),
        ),
      ),
    );
    return provider;
  }

  testWidgets('renders search field with hint', (tester) async {
    await pump(tester);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search team, league...'), findsOneWidget);
  });

  testWidgets('typing in search updates provider searchText', (tester) async {
    final provider = await pump(tester);
    await tester.enterText(find.byType(TextField), 'Arsenal');
    await tester.pump();
    expect(provider.searchText, 'arsenal');
  });

  testWidgets('Sport/Status/Date filter chips render', (tester) async {
    await pump(tester);
    expect(find.text('Sport'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
  });

  testWidgets('Clear chip not shown when no active filters', (tester) async {
    await pump(tester);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('Clear chip appears when filters active, and clears them',
      (tester) async {
    final provider = await pump(tester);
    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    expect(find.text('Clear'), findsOneWidget);
    expect(provider.hasActiveFilters, isTrue);
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(provider.hasActiveFilters, isFalse);
  });

  testWidgets('Sport chip label updates to "1 sport" when one selected',
      (tester) async {
    final provider = await pump(tester);
    provider.toggleSportFilter(Sport.soccer);
    await tester.pump();
    expect(find.text('1 sport'), findsOneWidget);
  });
}
