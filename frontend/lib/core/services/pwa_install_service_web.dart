import 'dart:js' as js;

class PwaInstallService {
  static bool isInstallable() => _callBool('isPwaInstallable');
  static bool isInstalled() => _callBool('isPwaInstalled');
  static bool isIos() => _callBool('isIosDevice');

  static void triggerInstall() {
    try {
      js.context.callMethod('triggerPwaInstall', []);
    } catch (_) {}
  }

  static bool _callBool(String fnName) {
    try {
      return js.context.callMethod(fnName, []) == true;
    } catch (_) {
      return false;
    }
  }
}
