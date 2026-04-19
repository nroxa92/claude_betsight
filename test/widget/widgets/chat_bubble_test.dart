import 'package:betsight/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBubble(WidgetTester tester, {
    required String text,
    required bool isUser,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBubble(text: text, isUser: isUser),
        ),
      ),
    );
  }

  group('ChatBubble', () {
    testWidgets('renders user message text', (tester) async {
      await pumpBubble(tester, text: 'Hello Claude', isUser: true);
      expect(find.text('Hello Claude'), findsOneWidget);
    });

    testWidgets('renders assistant message text', (tester) async {
      await pumpBubble(tester, text: 'Here is analysis', isUser: false);
      expect(find.text('Here is analysis'), findsOneWidget);
    });

    testWidgets('user bubble aligned right', (tester) async {
      await pumpBubble(tester, text: 't', isUser: true);
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('assistant bubble aligned left', (tester) async {
      await pumpBubble(tester, text: 't', isUser: false);
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('text is selectable', (tester) async {
      await pumpBubble(tester, text: 'copy me', isUser: false);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('multiline text renders verbatim', (tester) async {
      await pumpBubble(tester, text: 'line1\nline2', isUser: false);
      expect(find.text('line1\nline2'), findsOneWidget);
    });
  });
}
