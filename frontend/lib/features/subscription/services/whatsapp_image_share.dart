import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// إرسال صورة الإيصال مباشرة لمحادثة رقم معيّن على واتساب (أندرويد فقط).
///
/// يستخدم كود أصلي في MainActivity (قناة `nosait/whatsapp_share`): يحفظ الصورة
/// في الـ cache ويفتح واتساب على محادثة الرقم والصورة مرفقة (extra "jid").
/// يرجّع false لو مش أندرويد، أو واتساب مش متثبت، أو الفتح فشل — والمستدعي
/// يرجع لقائمة المشاركة.
class WhatsAppImageShare {
  WhatsAppImageShare._();

  static const _channel = MethodChannel('nosait/whatsapp_share');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// أرقام فقط بصيغة دولية: 010… ⇒ 2010…، 00… ⇒ بدون 00.
  static String normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (RegExp(r'^0[0-9]{10}$').hasMatch(digits)) digits = '2$digits';
    return digits;
  }

  static Future<bool> send({
    required Uint8List png,
    required String phone,
    String text = '',
  }) async {
    if (!isSupported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('shareImage', {
        'bytes': png,
        'phone': normalizePhone(phone),
        'text': text,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
