import 'package:url_launcher/url_launcher.dart';

class WhatsAppUtils {
  WhatsAppUtils._();

  /// Cleans a phone number and builds a wa.me URL with an optional message.
  static String buildUrl(String phone, {String? message}) {
    // Strip everything except digits and leading +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Remove leading + for wa.me (it uses plain digits)
    String digits = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;

    // Normalize Egyptian local format: 01XXXXXXXXX → 201XXXXXXXXX
    if (RegExp(r'^0[0-9]{10}$').hasMatch(digits)) {
      digits = '2$digits'; // 0XXX → 20XXX
    }

    final base = 'https://wa.me/$digits';
    if (message == null || message.isEmpty) return base;
    final encoded = Uri.encodeComponent(message);
    return '$base?text=$encoded';
  }

  /// Builds a direct whatsapp:// scheme URI (most reliable on Android).
  /// Both WhatsApp and WhatsApp Business register this scheme.
  static String buildDirectUrl(String phone, {String? message}) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    String digits = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;
    if (RegExp(r'^0[0-9]{10}$').hasMatch(digits)) {
      digits = '2$digits';
    }
    if (message != null && message.isNotEmpty) {
      return 'whatsapp://send?phone=$digits&text=${Uri.encodeComponent(message)}';
    }
    return 'whatsapp://send?phone=$digits';
  }

  /// Opens WhatsApp. Returns false if it could not be opened.
  ///
  /// Strategy (Android 11+ compatible, no canLaunchUrl gate):
  /// 1. whatsapp:// direct scheme — works on WhatsApp & WhatsApp Business.
  /// 2. https://wa.me/ web URL with externalApplication mode.
  /// 3. https://wa.me/ with platformDefault (browser/chooser fallback).
  static Future<bool> open(String phone, {String? message}) async {
    // 1) Direct whatsapp:// scheme — most reliable on all Android versions.
    try {
      final directUri = Uri.parse(buildDirectUrl(phone, message: message));
      final ok = await launchUrl(directUri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    } catch (_) {}

    // 2) HTTPS wa.me deep link — lets Android resolve via App Links.
    final webUri = Uri.parse(buildUrl(phone, message: message));
    try {
      final ok = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    } catch (_) {}

    // 3) Platform default — opens browser or OS chooser as last resort.
    try {
      return await launchUrl(webUri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Message Templates
  // ──────────────────────────────────────────────────────────

  /// Simple contact greeting.
  static String contactTemplate({
    required String parentName,
    required String playerName,
    required String academyName,
  }) =>
      'السلام عليكم $parentName،\n'
      'أتواصل معك من $academyName بخصوص اللاعب $playerName.\n';

  /// Reminder before subscription expires.
  static String subscriptionReminderTemplate({
    required String parentName,
    required String playerName,
    required String endDate,
    required String academyName,
  }) =>
      'السلام عليكم $parentName،\n'
      'نود تذكيرك بأن اشتراك ابنك/ابنتك $playerName في $academyName سينتهي بتاريخ $endDate.\n'
      'يرجى التواصل معنا لتجديد الاشتراك.\n'
      'مع تحيات $academyName 🏀';

  /// Reminder after subscription has expired.
  static String expiredSubscriptionTemplate({
    required String parentName,
    required String playerName,
    required String academyName,
  }) =>
      'السلام عليكم $parentName،\n'
      'نود إعلامك بأن اشتراك ابنك/ابنتك $playerName في $academyName قد انتهى.\n'
      'يرجى التواصل معنا لتجديد الاشتراك في أقرب وقت ممكن.\n'
      'مع تحيات $academyName 🏀';

  /// Share latest evaluation results with parent.
  static String evaluationFollowUpTemplate({
    required String parentName,
    required String playerName,
    required String average,
    required String grade,
    required String academyName,
  }) =>
      'السلام عليكم $parentName،\n'
      'نود مشاركتك نتائج آخر تقييم لابنك/ابنتك $playerName:\n'
      '📊 المتوسط: $average / 10\n'
      '🏆 التقدير: $grade\n'
      'نحرص دائماً على متابعة تطور اللاعبين لديكم.\n'
      'مع تحيات $academyName 🏀';

  /// تهنئة عيد ميلاد اللاعب — نص ثابت كما طلبت الإدارة.
  static String birthdayTemplate({
    required String academyName,
    required String playerName,
  }) =>
      'السلام عليكم ورحمة الله وبركاته\n\n'
      'تتقدم إدارة $academyName بأصدق التهاني للاعب $playerName بمناسبة عيد ميلاده.\n\n'
      'نتمنى له دوام الصحة والتوفيق والنجاح الرياضي.\n\n'
      'كل عام وأنتم بخير.';

  /// تذكير بانتهاء/قرب انتهاء الاشتراك — نص ثابت كما طلبت الإدارة.
  static String subscriptionExpiryTemplate({
    required String academyName,
    required String playerName,
  }) =>
      'السلام عليكم ورحمة الله وبركاته\n\n'
      'نود تذكيركم بأن اشتراك اللاعب $playerName في $academyName قد انتهى أو أوشك على الانتهاء.\n\n'
      'نرجو التكرم بتجديد الاشتراك لضمان استمرار اللاعب في التدريبات والأنشطة.\n\n'
      'لأي استفسار يمكنكم التواصل مع إدارة الأكاديمية.\n\n'
      'مع خالص الشكر والتقدير.';
}
