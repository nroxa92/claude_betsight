import 'package:betsight/models/sport.dart';
import 'package:betsight/models/tipster_signal.dart';
import 'package:betsight/widgets/signal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TipsterSignal buildSignal({
    String title = 'Pro Tipster',
    String username = '@pro',
    String text = 'EPL: Arsenal value at 2.10',
    Sport? sport,
    String? league,
    DateTime? receivedAt,
  }) =>
      TipsterSignal(
        id: 's-1',
        telegramMessageId: 1,
        channelUsername: username,
        channelTitle: title,
        text: text,
        receivedAt: receivedAt ?? DateTime.now(),
        detectedSport: sport,
        detectedLeague: league,
        isRelevant: true,
      );

  Future<void> pumpCard(
    WidgetTester tester, {
    required TipsterSignal signal,
    required bool selected,
    ValueChanged<bool>? onChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SignalCard(
              signal: signal,
              selected: selected,
              onSelectedChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  group('SignalCard', () {
    testWidgets('shows channel title and username', (tester) async {
      await pumpCard(
        tester,
        signal: buildSignal(title: 'Tipster A', username: '@tipa'),
        selected: false,
      );
      expect(find.text('Tipster A'), findsOneWidget);
      expect(find.text('@tipa'), findsOneWidget);
    });

    testWidgets('shows preview text', (tester) async {
      await pumpCard(
        tester,
        signal: buildSignal(text: 'my preview'),
        selected: false,
      );
      expect(find.text('my preview'), findsOneWidget);
    });

    testWidgets('sport icon defaults to 📨 when no sport detected', (tester) async {
      await pumpCard(
        tester,
        signal: buildSignal(),
        selected: false,
      );
      expect(find.text('📨'), findsOneWidget);
    });

    testWidgets('shows sport icon when sport detected', (tester) async {
      await pumpCard(
        tester,
        signal: buildSignal(sport: Sport.soccer),
        selected: false,
      );
      expect(find.text('⚽'), findsOneWidget);
    });

    testWidgets('league badge shown when detectedLeague set', (tester) async {
      await pumpCard(
        tester,
        signal: buildSignal(league: 'EPL'),
        selected: false,
      );
      expect(find.text('EPL'), findsOneWidget);
    });

    testWidgets('no checkbox when onSelectedChanged is null', (tester) async {
      await pumpCard(
        tester,
        signal: buildSignal(),
        selected: false,
        onChanged: null,
      );
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('checkbox shown when onSelectedChanged set', (tester) async {
      await pumpCard(
        tester,
        signal: buildSignal(),
        selected: false,
        onChanged: (_) {},
      );
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('tapping card toggles selection', (tester) async {
      var received = false;
      await pumpCard(
        tester,
        signal: buildSignal(),
        selected: false,
        onChanged: (v) => received = v,
      );
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(received, isTrue);
    });

    testWidgets('time ago shows "5m" for 5 min old signal', (tester) async {
      await pumpCard(
        tester,
        signal: buildSignal(
          receivedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        selected: false,
      );
      expect(find.text('5m'), findsOneWidget);
    });

    testWidgets('time ago shows "2h" for 2 hr old signal', (tester) async {
      await pumpCard(
        tester,
        signal: buildSignal(
          receivedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        selected: false,
      );
      expect(find.text('2h'), findsOneWidget);
    });
  });
}
