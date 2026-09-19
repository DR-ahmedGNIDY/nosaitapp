import 'package:flutter/foundation.dart';

/// معرّفات AdMob. المعرّفات الحقيقية تُستخدم في بناء release **فقط**؛ أثناء
/// التطوير تُستخدم وحدات الاختبار الرسمية من Google.
///
/// ⚠️ النقر على إعلان حقيقي من جهاز تطوير قد يؤدي إلى تعليق حساب AdMob، لذلك
/// التبديل تلقائي عبر [kDebugMode] ولا يعتمد على تذكّر المطوّر.
abstract final class AdIds {
  /// App ID — يُستخدم أيضاً في AndroidManifest كـ meta-data.
  /// (هنا للتوثيق والمرجع فقط؛ الـ SDK يقرؤه من الماني فيست.)
  static const String androidAppId = 'ca-app-pub-6344883554405987~3739372322';

  // ── Interstitial (ملء الشاشة) — هذا هو نوع الوحدة الموجودة في حساب AdMob ──

  /// وحدة الـ Interstitial الحقيقية (release فقط).
  static const String _releaseInterstitial =
      'ca-app-pub-6344883554405987/3400581114';

  /// وحدة Interstitial الاختبار الرسمية من Google لأندرويد.
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  // ── Banner ────────────────────────────────────────────────────────────────
  // لا توجد وحدة Banner في حساب AdMob حتى الآن — الوحدة المتاحة نوعها
  // Interstitial، وطلبها كبانر يفشل حتماً. نترك المعرّف فارغاً فيُعطَّل البانر
  // بالكامل. لتفعيله لاحقاً: أنشئ وحدة Banner في AdMob وضع معرّفها هنا فقط.
  static const String _releaseBanner = '';

  /// وحدة بانر الاختبار الرسمية من Google لأندرويد.
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';

  /// إجبار وحدات الاختبار في بناء release — للتشخيص فقط:
  /// `flutter build apk --release --dart-define=USE_TEST_ADS=true`
  /// القيمة الافتراضية false، فبناء release العادي يبقى على الوحدة الحقيقية
  /// بلا أي تغيير في سلوكه.
  static const bool _forceTestAds = bool.fromEnvironment('USE_TEST_ADS');

  /// هل نحن على وحدات الاختبار؟ (يُطبع تحذير في السجل عند التهيئة)
  static bool get isUsingTestAds => kDebugMode || _forceTestAds;

  /// معرّف البانر المستخدم فعلياً الآن ('' يعني معطّل).
  static String get banner => isUsingTestAds ? _testBanner : _releaseBanner;

  /// هل البانر مفعّل؟ (يحتاج وحدة Banner حقيقية في AdMob)
  static bool get bannerEnabled => banner.isNotEmpty;

  /// معرّف الـ Interstitial المستخدم فعلياً الآن.
  static String get interstitial =>
      isUsingTestAds ? _testInterstitial : _releaseInterstitial;
}
