// يُنزّل ملف بايتات مباشرة عبر متصفح الويب (عنصر <a download>) — لا تطبيق له
// خارج الويب لأن كل استدعاء له محاط بفحص kIsWeb عند نقطة الاستخدام.
export 'web_download_service_io.dart'
    if (dart.library.html) 'web_download_service_web.dart';
