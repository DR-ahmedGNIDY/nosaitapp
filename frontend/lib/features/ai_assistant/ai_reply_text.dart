import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// نوع كل سطر في رد المساعد بعد التحليل.
enum AiLineKind { blank, heading, bullet, numbered, paragraph }

class AiLine {
  final AiLineKind kind;
  final String text;
  final String? marker; // رقم البند في القوائم المرقّمة
  const AiLine(this.kind, this.text, {this.marker});
}

final _bulletRe = RegExp(r'^\s*[•\-\*▪●]\s+');
final _numberRe = RegExp(r'^\s*(\d{1,3})[\.\)\-]\s+');
final _headingRe = RegExp(r'^\s*#{1,6}\s*');

/// يحوّل نص الرد (نص عادي بنقاط • أو Markdown بسيط) إلى أسطر منسّقة.
List<AiLine> parseAiReply(String raw) {
  final out = <AiLine>[];
  for (final line in raw.replaceAll('\r', '').split('\n')) {
    final t = line.trim();
    if (t.isEmpty) {
      if (out.isNotEmpty && out.last.kind != AiLineKind.blank) {
        out.add(const AiLine(AiLineKind.blank, ''));
      }
      continue;
    }
    if (_headingRe.hasMatch(t)) {
      out.add(AiLine(AiLineKind.heading, t.replaceFirst(_headingRe, '')));
    } else if (_bulletRe.hasMatch(t)) {
      out.add(AiLine(AiLineKind.bullet, t.replaceFirst(_bulletRe, '')));
    } else if (_numberRe.hasMatch(t)) {
      final m = _numberRe.firstMatch(t)!;
      out.add(AiLine(AiLineKind.numbered, t.substring(m.end), marker: m.group(1)));
    } else if (t.endsWith(':') && t.length <= 60) {
      // سطر قصير ينتهي بنقطتين = عنوان قسم.
      out.add(AiLine(AiLineKind.heading, t));
    } else {
      out.add(AiLine(AiLineKind.paragraph, t));
    }
  }
  while (out.isNotEmpty && out.last.kind == AiLineKind.blank) {
    out.removeLast();
  }
  return out;
}

/// يحوّل **غامق** إلى spans (والنجوم المفردة تُحذف).
List<TextSpan> aiInlineSpans(String text, TextStyle base) {
  final spans = <TextSpan>[];
  final parts = text.split('**');
  for (var i = 0; i < parts.length; i++) {
    final p = parts[i];
    if (p.isEmpty) continue;
    spans.add(TextSpan(
      text: p,
      style: i.isOdd ? base.copyWith(fontWeight: FontWeight.w800) : null,
    ));
  }
  return spans;
}

/// عرض رد المساعد: عناوين، نقاط بعلامة ملوّنة، قوائم مرقّمة، وفقرات مريحة للقراءة.
class AiReplyText extends StatelessWidget {
  final String text;
  final double fontSize;
  const AiReplyText({super.key, required this.text, this.fontSize = 15});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      height: 1.75,
      color: AppColors.grey900,
      fontWeight: FontWeight.w500,
    );
    final lines = parseAiReply(text);
    final children = <Widget>[];
    for (final l in lines) {
      switch (l.kind) {
        case AiLineKind.blank:
          children.add(SizedBox(height: fontSize * 0.5));
        case AiLineKind.heading:
          children.add(Padding(
            padding: EdgeInsets.only(
                top: children.isEmpty ? 0 : fontSize * 0.35, bottom: 2),
            child: Text.rich(
              TextSpan(children: aiInlineSpans(l.text, base)),
              style: base.copyWith(
                fontSize: fontSize + 1,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ));
        case AiLineKind.bullet:
        case AiLineKind.numbered:
          children.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: fontSize * 1.6,
                  child: Padding(
                    padding: EdgeInsets.only(top: fontSize * 0.42),
                    child: l.kind == AiLineKind.bullet
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              width: fontSize * 0.42,
                              height: fontSize * 0.42,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : Container(
                            alignment: Alignment.center,
                            height: fontSize * 1.15,
                            margin: EdgeInsetsDirectional.only(
                                end: fontSize * 0.35),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l.marker ?? '',
                              style: TextStyle(
                                fontSize: fontSize * 0.75,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                height: 1,
                              ),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: aiInlineSpans(l.text, base)),
                    style: base,
                  ),
                ),
              ],
            ),
          ));
        case AiLineKind.paragraph:
          children.add(Text.rich(
            TextSpan(children: aiInlineSpans(l.text, base)),
            style: base,
          ));
      }
    }
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
