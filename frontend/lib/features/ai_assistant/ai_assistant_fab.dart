import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/ai_assistant/ai_assistant_screen.dart';
import 'package:flutter/material.dart';

/// زر المساعد الذكي العائم (أسفل يسار لوحة التحكم) مع شارة "قريباً" فوقه.
/// الأيقونة مصغّرة لـ 192px (~60KB) حتى لا تؤثر على سرعة تحميل الويب.
class AiAssistantFab extends StatelessWidget {
  const AiAssistantFab({super.key});

  static const double _size = 62;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white, width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: const Text(
            'قريباً',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Tooltip(
          message: 'المساعد الذكي',
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
              ),
              child: Image.asset(
                'assets/images/ai_assistant.png',
                width: _size,
                height: _size,
                filterQuality: FilterQuality.medium,
                semanticLabel: 'المساعد الذكي',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
