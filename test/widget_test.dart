import 'dart:io';

import 'package:betsight/main.dart';
import 'package:betsight/models/analysis_provider.dart';
import 'package:betsight/models/matches_provider.dart';
import 'package:betsight/models/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

Widget _wrap() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => NavigationController()),
      ChangeNotifierProvider(create: (_) => MatchesProvider()),
      ChangeNotifierProvider(create: (_) => AnalysisProvider()),
    ],
    child: const BetSightApp(),
  );
}

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('betsight_test');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  testWidgets('BetSightApp renders with bottom navigation', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Matches'), findsWidgets);
    expect(find.text('Analysis'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('Bottom navigation switches tabs', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('The Odds API key required'), findsOneWidget);

    await tester.tap(find.text('Analysis').last);
    await tester.pumpAndSettle();
    expect(find.text('Anthropic API key required'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Anthropic API Key'), findsOneWidget);
    expect(find.text('The Odds API Key'), findsOneWidget);
  });
}
