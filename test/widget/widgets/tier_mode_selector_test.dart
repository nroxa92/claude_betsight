import 'package:betsight/models/tier_provider.dart';
import 'package:betsight/widgets/tier_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/hive_test_setup.dart';

void main() {
  setUp(() async => setUpHive());
  tearDown(() async => tearDownHive());

  Future<void> pump(WidgetTester tester, TierProvider tier) {
    return tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: tier,
        child: const MaterialApp(
          home: Scaffold(body: TierModeSelector()),
        ),
      ),
    );
  }

  testWidgets('renders all 3 tier pills', (tester) async {
    final tier = TierProvider();
    await pump(tester, tier);
    expect(find.text('Pre-Match'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Accumulator'), findsOneWidget);
  });

  testWidgets('tier icons rendered', (tester) async {
    final tier = TierProvider();
    await pump(tester, tier);
    expect(find.text('⚽'), findsOneWidget);
    expect(find.text('🔴'), findsOneWidget);
    expect(find.text('🏆'), findsOneWidget);
  });

  testWidgets('all 3 GestureDetector pills present', (tester) async {
    final tier = TierProvider();
    await pump(tester, tier);
    expect(find.byType(GestureDetector), findsNWidgets(3));
  });
}
