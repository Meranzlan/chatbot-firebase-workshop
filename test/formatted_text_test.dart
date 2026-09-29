import 'package:chatbot_firebase/config/app_colors.dart';
import 'package:chatbot_firebase/views/widgets/formatted_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Draws FormattedText and returns what it shows, split into styled pieces.
  Future<TextSpan> format(WidgetTester tester, String markdown) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormattedText(markdown, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
    return tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!;
  }

  TextStyle styleOf(TextSpan text, String piece) => text.children!
      .cast<TextSpan>()
      .firstWhere(
        (span) => span.text == piece,
        orElse: () => fail('"$piece" is not shown as its own styled piece'),
      )
      .style!;

  testWidgets('shows Gemini\'s Markdown as formatting, not symbols', (
    tester,
  ) async {
    final text = await format(
      tester,
      '## Tips\n* **Bold** and *italic*\n- A dash item',
    );

    expect(text.toPlainText(), 'Tips\n• Bold and italic\n• A dash item');
    expect(styleOf(text, 'Tips').fontWeight, FontWeight.bold);
    expect(styleOf(text, 'Bold').fontWeight, FontWeight.bold);
    expect(styleOf(text, 'italic').fontStyle, FontStyle.italic);
  });

  testWidgets('shows source numbers like [1] as citation markers', (
    tester,
  ) async {
    final text = await format(tester, 'It came out in September. [1][2]');

    expect(text.toPlainText(), 'It came out in September. [1][2]');
    expect(styleOf(text, '[1]').color, AppColors.webCitation);
    expect(styleOf(text, '[2]').color, AppColors.webCitation);
  });

  testWidgets('shows `inline code` in a code font, without the backticks', (
    tester,
  ) async {
    final text = await format(
      tester,
      'Mark widgets `const`, and keep `a * b * c` as typed.',
    );

    // The asterisks inside code stay as typed instead of becoming italics.
    expect(
      text.toPlainText(),
      'Mark widgets const, and keep a * b * c as typed.',
    );
    expect(styleOf(text, 'const').fontFamily, 'monospace');
    expect(styleOf(text, 'a * b * c').fontFamily, 'monospace');
  });
}
