/// استخراج كود اللاعب من محتوى الـ QR أو الإدخال اليدوي.
///
/// يقبل القيم التالية ويُعيد الكود فقط:
///   "PLAYER:Y-0145"  →  "Y-0145"
///   "player:y-0145"  →  "Y-0145"  (البادئة غير حسّاسة لحالة الأحرف)
///   " Y-0145 "        →  "Y-0145"
///   "Y-0145"          →  "Y-0145"
///   "145" / "0145"    →  "Y-0145"  (إدخال يدوي بالرقم فقط)
class PlayerQr {
  PlayerQr._();

  static const String prefix = 'PLAYER:';

  static final RegExp _digitsOnly = RegExp(r'^\d+$');
  static final RegExp _lowerY = RegExp(r'^y-\d+$', caseSensitive: false);

  static String extractCode(String raw) {
    var value = raw.trim();
    if (value.toUpperCase().startsWith(prefix)) {
      value = value.substring(prefix.length).trim();
    }
    if (_digitsOnly.hasMatch(value)) return 'Y-${value.padLeft(4, '0')}';
    if (_lowerY.hasMatch(value)) return value.toUpperCase();
    return value;
  }
}
