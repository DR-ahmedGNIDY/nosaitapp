/// استخراج كود اللاعب من محتوى الـ QR.
///
/// يقبل القيم التالية ويُعيد الكود فقط:
///   "PLAYER:Y-0145"  →  "Y-0145"
///   "player:y-0145"  →  "y-0145"  (البادئة غير حسّاسة لحالة الأحرف)
///   " Y-0145 "        →  "Y-0145"
///   "Y-0145"          →  "Y-0145"
class PlayerQr {
  PlayerQr._();

  static const String prefix = 'PLAYER:';

  static String extractCode(String raw) {
    var value = raw.trim();
    if (value.toUpperCase().startsWith(prefix)) {
      value = value.substring(prefix.length).trim();
    }
    return value;
  }
}
