import 'package:basketball_academy/core/ads/ad_ids.dart';
import 'package:basketball_academy/core/ads/admob_service.dart';
import 'package:basketball_academy/core/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// المكان الوحيد الذي يظهر فيه إعلان. يوضع في `Scaffold.bottomNavigationBar`
/// حتى لا يغطّي أي محتوى ويُزاح تلقائياً مع لوحة المفاتيح.
///
/// ثلاث طبقات منع للمستخدم المشترك: لا يُبنى الودجت، ولا يُحمَّل الإعلان،
/// ولا يُهيَّأ الـ SDK أصلاً.
class AdBannerSlot extends ConsumerWidget {
  const AdBannerSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // البانر معطّل ما لم تُضبط وحدة Banner حقيقية في [AdIds] — الوحدة الحالية
    // في حساب AdMob نوعها Interstitial ولا تصلح للبانر.
    if (!adsPlatformSupported || !AdIds.bannerEnabled) {
      return const SizedBox.shrink();
    }

    // تغيّر القرار (تجديد اشتراك / انتهاؤه / logout) يعيد البناء هنا؛ الخروج
    // بـ shrink يُخرج البانر من الشجرة فيُستدعى dispose ويُهدم الإعلان فوراً.
    final visible = ref.watch(adsVisibilityProvider);
    if (!visible) {
      if (!kAdsDebugOverlay) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        color: const Color(0xFF0D47A1),
        padding: const EdgeInsets.all(6),
        child: const Text(
          'ADS DEBUG: policy said OFF (adsVisibilityProvider=false)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 11),
          textDirection: TextDirection.ltr,
        ),
      );
    }

    // إخفاء أثناء إدخال البيانات: لا إعلان بينما لوحة المفاتيح مفتوحة.
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: buildAdaptiveBanner(),
      ),
    );
  }
}
