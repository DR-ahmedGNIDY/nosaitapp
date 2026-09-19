/// حالة اشتراك المنصة (Nosait) على مستوى **الأكاديمية** — لا يوجد اشتراك شخصي
/// للمدير أو الإداري. تُقابل قيم `effectiveStatus()` في موديل الـ backend
/// `AcademySubscription` (backend/src/models/academySubscription.model.js).
///
/// `unknown` ليست قيمة من الخادم — هي الحالة قبل وصول الرد أو عند فشله، وهي
/// حالة fail-closed مقصودة في سياسة الإعلانات (لا نعرض إعلاناً ونحن لا نعرف).
enum AcademySubscriptionStatus {
  /// فترة تجريبية فعّالة.
  trial,

  /// اشتراك مدفوع فعّال.
  active,

  /// انتهى (تجريبي أو مدفوع).
  expired,

  /// مُعلَّق يدوياً من إدارة المنصة.
  suspended,

  /// لا توجد وثيقة اشتراك للأكاديمية (أكاديمية قديمة قبل الهجرة)، أو المستخدم
  /// super_admin بلا أكاديمية أصلاً.
  none,

  /// لم تصل بيانات الاشتراك بعد، أو فشل جلبها.
  unknown;

  /// يقرأ الحالة من نص الخادم. أي قيمة غير معروفة → [unknown] وليس تخميناً.
  static AcademySubscriptionStatus fromApi(String? raw) {
    switch (raw) {
      case 'trial':
        return AcademySubscriptionStatus.trial;
      case 'active':
        return AcademySubscriptionStatus.active;
      case 'expired':
        return AcademySubscriptionStatus.expired;
      case 'suspended':
        return AcademySubscriptionStatus.suspended;
      default:
        return AcademySubscriptionStatus.unknown;
    }
  }

  /// اشتراك مدفوع فعّال — وحده الذي يُخفي الإعلانات عن مدير/إداري الأكاديمية.
  /// ملاحظة: `trial` ليست منه عمداً (انظر [AdsPolicy]).
  bool get isPaidActive => this == AcademySubscriptionStatus.active;
}
