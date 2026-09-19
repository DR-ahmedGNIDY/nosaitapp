// نقطة الدخول الوحيدة لـ AdMob. حزمة google_mobile_ads لا تدعم Flutter Web،
// والمشروع يبني نسخة ويب منشورة — لذلك نستخدم نفس نمط الاستيراد الشرطي
// المتّبع في المشروع (انظر web_download_service.dart): الويب يحصل على نسخة
// فارغة لا تستورد الحزمة إطلاقاً، فلا ينكسر بناء الويب.
export 'admob_service_stub.dart' if (dart.library.io) 'admob_service_io.dart';
