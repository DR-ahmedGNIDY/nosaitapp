import 'package:basketball_academy/features/ai_assistant/ai_reply_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses headings, bullets, numbered lists and paragraphs', () {
    final lines = parseAiReply(
      'ملخص النهارده:\n\n• حضر 12 لاعب\n- غاب 3\n1. أحمد\n2) محمد\n## الإيرادات\nإجمالي 5000 جنيه\n\n\n',
    );
    expect(lines.map((l) => l.kind).toList(), [
      AiLineKind.heading,
      AiLineKind.blank,
      AiLineKind.bullet,
      AiLineKind.bullet,
      AiLineKind.numbered,
      AiLineKind.numbered,
      AiLineKind.heading,
      AiLineKind.paragraph,
    ]);
    expect(lines[2].text, 'حضر 12 لاعب');
    expect(lines[4].marker, '1');
    expect(lines[5].text, 'محمد');
    expect(lines[6].text, 'الإيرادات');
  });

  test('bold markers become bold spans', () {
    const base = TextStyle(fontSize: 15);
    final spans = aiInlineSpans('المديونية **1200 جنيه** على 3 لاعبين', base);
    expect(spans.length, 3);
    expect(spans[1].text, '1200 جنيه');
    expect(spans[1].style?.fontWeight, FontWeight.w800);
  });

  testWidgets('renders without overflow in RTL', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AiReplyText(text: 'عنوان:\n• بند\n1. أول\nفقرة **مهمة**'),
        ),
      ),
    ));
    expect(find.textContaining('بند'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
