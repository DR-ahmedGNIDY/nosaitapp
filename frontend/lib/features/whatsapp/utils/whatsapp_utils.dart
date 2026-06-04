import 'package:url_launcher/url_launcher.dart';

class WhatsAppUtils {
  WhatsAppUtils._();

  /// Cleans a phone number and builds a wa.me URL with an optional message.
  static String buildUrl(String phone, {String? message}) {
    // Strip everything except digits and leading +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Remove leading + for wa.me (it uses plain digits)
    final digits = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;

    final base = 'https://wa.me/$digits';
    if (message == null || message.isEmpty) return base;
    final encoded = Uri.encodeComponent(message);
    return '$base?text=$encoded';
  }

  /// Opens WhatsApp. Returns false if WhatsApp is not installed.
  static Future<bool> open(String phone, {String? message}) async {
    final url = Uri.parse(buildUrl(phone, message: message));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // ──────────────────────────────────────────────────────────
  // Message Templates
  // ──────────────────────────────────────────────────────────

  /// Simple contact greeting.
  static String contactTemplate({
    required String parentName,
    required String playerName,
  }) =>
      'السلام عليكم $parentName،\n'
      'أتواصل معك من أكاديمية كرة السلة بخصوص اللاعب $playerName.\n';

  /// Reminder before subscription expires.
  static String subscriptionReminderTemplate({
    required String parentName,
    required String playerName,
    required String endDate,
  }) =>
      'السلام عليكم $parentName،\n'
      'نود تذكيرك بأن اشتراك ابنك/ابنتك $playerName في الأكاديمية سينتهي بتاريخ $endDate.\n'
      'يرجى التواصل معنا لتجديد الاشتراك.\n'
      'شكراً لكم 🏀';

  /// Reminder after subscription has expired.
  static String expiredSubscriptionTemplate({
    required String parentName,
    required String playerName,
  }) =>
      'السلام عليكم $parentName،\n'
      'نود إعلامك بأن اشتراك ابنك/ابنتك $playerName في الأكاديمية قد انتهى.\n'
      'يرجى التواصل معنا لتجديد الاشتراك في أقرب وقت ممكن.\n'
      'شكراً لكم 🏀';

  /// Share latest evaluation results with parent.
  static String evaluationFollowUpTemplate({
    required String parentName,
    required String playerName,
    required String average,
    required String grade,
  }) =>
      'السلام عليكم $parentName،\n'
      'نود مشاركتك نتائج آخر تقييم لابنك/ابنتك $playerName:\n'
      '📊 المتوسط: $average / 10\n'
      '🏆 التقدير: $grade\n'
      'نحرص دائماً على متابعة تطور اللاعبين لديكم.\n'
      'شكراً لكم 🏀';
}
