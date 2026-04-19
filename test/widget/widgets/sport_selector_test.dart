import 'package:betsight/models/sport.dart';
import 'package:betsight/widgets/sport_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSelector(
    WidgetTester tester, {
    Sport? selected,
    required ValueChanged<Sport?> onChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SportSelector(
            selectedSport: selected,
            onSportSelected: onChanged,
          ),
        ),
      ),
    );
  }

  group('SportSelector', () {
    testWidgets('renders All + 3 sport chips', (tester) async {
      await pumpSelector(tester, selected: null, onChanged: (_) {});
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('sport labels include icons', (tester) async {
      await pumpSelector(tester, selected: null, onChanged: (_) {});
      expect(find.textContaining('Soccer'), findsOneWidget);
      expect(find.textContaining('Basketball'), findsOneWidget);
      expect(find.textContaining('Tennis'), findsOneWidget);
    });

    testWidgets('tapping All chip calls onChanged with null', (tester) async {
      Sport? received = Sport.soccer;
      var called = false;
      await pumpSelector(
        tester,
        selected: Sport.soccer,
        onChanged: (s) {
          received = s;
          called = true;
        },
      );
      await tester.tap(find.text('All'));
      await tester.pump();
      expect(called, isTrue);
      expect(received, isNull);
    });

    testWidgets('tapping Soccer chip calls onChanged(Sport.soccer)', (tester) async {
      Sport? received;
      await pumpSelector(
        tester,
        selected: null,
        onChanged: (s) => received = s,
      );
      await tester.tap(find.textContaining('Soccer'));
      await tester.pump();
      expect(received, Sport.soccer);
    });

    testWidgets('selected sport chip shows selected=true', (tester) async {
      await pumpSelector(
        tester,
        selected: Sport.basketball,
        onChanged: (_) {},
      );
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final selected = chips.where((c) => c.selected).toList();
      expect(selected, hasLength(1));
    });
  });
}
