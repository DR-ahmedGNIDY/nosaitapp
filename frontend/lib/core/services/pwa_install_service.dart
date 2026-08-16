// جسر بين Flutter وواجهة تثبيت الـ PWA في المتصفح (beforeinstallprompt).
// على غير الويب (Android/Windows) تُستخدم نسخة وهمية بلا تأثير.
export 'pwa_install_service_stub.dart'
    if (dart.library.js_interop) 'pwa_install_service_web.dart';
