import 'package:basketball_academy/features/auth/domain/entities/academy_subscription_status.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';

/// نوع الجلسة الحالية. التطبيق يحمل نظامَي مصادقة منفصلين لا يعملان معاً
/// (TokenManager.sessionType) — لذلك الجلسة إمّا مدير/إداري، أو لاعب، أو لا شيء.
enum AdsSessionKind {
  /// لا جلسة (Splash / Welcome / Login / تسجيل أكاديمية).
  none,

  /// جلسة منصّة (super_admin | academy_admin | admin).
  admin,

  /// جلسة بوابة اللاعب.
  player,
}

/// سياسة إظهار الإعلانات — منطق **نقي** بلا أي I/O ولا Riverpod ولا Flutter،
/// حتى يكون قابلاً للاختبار بالكامل.
///
/// المبدأ الحاكم: الاشتراك في هذا النظام **على مستوى الأكاديمية** لا على مستوى
/// المستخدم. مدير الأكاديمية والإداري يرثان حالة اشتراك أكاديميتهما نفسها
/// (AcademySubscription.academyId فريد لكل أكاديمية).
///
/// المبدأ الثاني: **fail-closed**. لا نُظهر إعلاناً إلا إذا كنا نعرف يقيناً أن
/// المستخدم يستحقه. أي حالة غير معروفة → إخفاء. أسوأ نتيجة ممكنة هي فقدان
/// انطباع إعلاني، لا إزعاج مشترك دافع.
abstract final class AdsPolicy {
  /// القرار الوحيد في النظام. لا يوجد أي مسار آخر يُشغّل الإعلانات.
  static bool shouldShowAds({
    required AdsSessionKind session,
    UserEntity? user,
    DateTime? now,
  }) {
    switch (session) {
      // لا جلسة ⇒ لا إعلانات إطلاقاً (شاشات الدخول والتسجيل).
      case AdsSessionKind.none:
        return false;

      // اللاعب يرى الإعلانات دائماً — بصرف النظر عن حالة اشتراك أكاديميته.
      // لا نحتاج أي بيانات اشتراك لهذا القرار، فلا انتظار ولا حالة unknown.
      case AdsSessionKind.player:
        return true;

      case AdsSessionKind.admin:
        // جلسة مدير بلا مستخدم مُحمَّل بعد ⇒ ما زلنا لا نعرف ⇒ إخفاء.
        if (user == null) return false;

        // super_admin مالك المنصة: لا أكاديمية له ولا اشتراك — لا إعلانات.
        // يجب أن يُفصل قبل فحص الاشتراك، وإلا عُومل خطأً كـ "بلا اشتراك".
        if (user.isSuperAdmin) return false;

        return _shouldShowForAcademyMember(
          _effectiveStatus(user, now ?? DateTime.now()),
        );
    }
  }

  /// سن الرشد الإعلاني وفق COPPA — دونه يُعامَل المستخدم كطفل.
  static const int kChildAgeThreshold = 13;

  /// هل يجب تفعيل حماية إعلانات الأطفال لهذه الجلسة؟
  ///
  /// المدير والإداري بالغان حتماً (يديران أكاديمية) ⇒ لا حماية.
  /// اللاعب: نحسب عمره من [birthDate] الحقيقي القادم من الخادم.
  ///
  /// **fail-safe:** إن غاب تاريخ الميلاد أو تعذّرت قراءته ⇒ نُفعّل الحماية.
  /// الخطأ في اتجاه الحماية لا في اتجاه العائد.
  static bool isChildDirected({
    required AdsSessionKind session,
    DateTime? birthDate,
    DateTime? now,
  }) {
    if (session != AdsSessionKind.player) return false;
    if (birthDate == null) return true;

    final today = now ?? DateTime.now();
    var age = today.year - birthDate.year;
    final hadBirthdayThisYear = today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hadBirthdayThisYear) age--;

    // عمر سالب أو غير منطقي (تاريخ مستقبلي / بيانات تالفة) ⇒ حماية.
    if (age < 0 || age > 120) return true;
    return age < kChildAgeThreshold;
  }

  /// نظير `effectiveStatus()` في الـ backend: اشتراك وصل بحالة فعّالة لكن مرّ
  /// تاريخ نهايته أثناء الجلسة يُعامَل منتهياً فوراً — دون انتظار نداء شبكة.
  static AcademySubscriptionStatus _effectiveStatus(
    UserEntity user,
    DateTime now,
  ) {
    final status = user.academySubscriptionStatus;
    final endDate = user.academySubscriptionEndDate;
    final isLive = status == AcademySubscriptionStatus.active ||
        status == AcademySubscriptionStatus.trial;
    if (isLive && endDate != null && now.isAfter(endDate)) {
      return AcademySubscriptionStatus.expired;
    }
    return status;
  }

  /// قرار academy_admin و admin — كلاهما يتبع اشتراك الأكاديمية نفسه.
  static bool _shouldShowForAcademyMember(AcademySubscriptionStatus status) {
    switch (status) {
      // اشتراك مدفوع فعّال ⇒ إخفاء الإعلانات (هذا ما يدفع المشترك مقابله).
      case AcademySubscriptionStatus.active:
        return false;

      // فترة تجريبية: لم يُدفع بعد ⇒ إظهار (حافز للاشتراك).
      case AcademySubscriptionStatus.trial:
      // انتهى / مُعلَّق / لا وثيقة اشتراك ⇒ إظهار.
      case AcademySubscriptionStatus.expired:
      case AcademySubscriptionStatus.suspended:
      case AcademySubscriptionStatus.none:
        return true;

      // لم تصل الحالة بعد أو فشل جلبها ⇒ إخفاء (fail-closed).
      // هذه هي الحالة التي تمنع وميض إعلان أمام مشترك أثناء التحميل.
      case AcademySubscriptionStatus.unknown:
        return false;
    }
  }
}
