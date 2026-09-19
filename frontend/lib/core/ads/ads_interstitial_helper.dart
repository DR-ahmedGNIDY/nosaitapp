import 'package:basketball_academy/core/ads/admob_service.dart';
import 'package:basketball_academy/core/ads/ads_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// نقطة الاستدعاء الوحيدة لإعلان ملء الشاشة.
///
/// تُستدعى عند انتقالات **آمنة** فقط: الانتقال إلى شاشة عرض (ألبوم، متجر،
/// إشعارات، تقارير). لا تُستدعى أبداً قبل نموذج إدخال، ولا قبل حفظ، ولا في
/// شاشات الدخول، ولا في المحادثة.
///
/// لا تحجب الانتقال: إن لم يكن هناك إعلان جاهز أو منعته ضوابط التردّد،
/// تعود فوراً ويكمل المستخدم طريقه بلا تأخير.
abstract final class AdsInterstitial {
  /// يعرض إعلاناً إن سمحت السياسة وضوابط التردّد. يُرجع true إذا عُرض.
  static Future<bool> maybeShow(WidgetRef ref) async {
    final allowed = ref.read(adsVisibilityProvider);
    if (!allowed) return false;
    // حماية الأطفال تُضبط دائماً قبل عرض/طلب أي إعلان.
    await setChildDirected(ref.read(adsChildDirectedProvider));
    return maybeShowInterstitial(adsAllowed: allowed);
  }

  /// يجهّز إعلاناً مسبقاً ليكون العرض التالي فورياً. تُستدعى عند فتح الشاشات
  /// الرئيسية. لا تفعل شيئاً إذا كانت السياسة تمنع الإعلانات.
  static void preload(WidgetRef ref) {
    if (!ref.read(adsVisibilityProvider)) return;
    // نضبط الحماية أولاً ثم نجهّز الإعلان، حتى لا يُطلب إعلان مخصّص لطفل.
    setChildDirected(ref.read(adsChildDirectedProvider))
        .then((_) => preloadInterstitial());
  }
}
