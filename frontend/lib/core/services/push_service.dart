import 'dart:async';

import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/navigation/app_navigator.dart';
import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// نوع الجلسة التي يُسجَّل لها الجهاز.
enum PushAudience { admin, player }

/// إشعارات Push عبر Firebase Cloud Messaging — Android فقط حالياً.
///
/// - [init] مرة واحدة عند تشغيل التطبيق (يفشل بهدوء لو Firebase غير مُعدّ،
///   مثلاً قبل إضافة google-services.json).
/// - [register] بعد تسجيل الدخول: يطلب الإذن ويرسل توكن الجهاز للسيرفر.
/// - [unregister] قبل تسجيل الخروج: يحذف التوكن من السيرفر (يحتاج التوكن الحالي).
/// - الضغط على الإشعار يفتح صفحة الإشعارات المناسبة للجلسة.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// يُستدعى عند وصول إشعار والتطبيق مفتوح (لتحديث مركز الإشعارات فوراً).
  VoidCallback? onMessage;

  bool _ready = false;
  PushAudience? _audience;
  StreamSubscription<String>? _refreshSub;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      // لا google-services.json أو إعداد ناقص — التطبيق يعمل بدون Push.
      if (kDebugMode) debugPrint('[PUSH] Firebase not configured: $e');
      return;
    }

    // إشعار وصل والتطبيق مفتوح: النظام لا يعرضه، فنعرض شريطاً داخل التطبيق.
    FirebaseMessaging.onMessage.listen(_showInApp);
    // الضغط على إشعار والتطبيق في الخلفية.
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());
    // الضغط على إشعار والتطبيق مغلق تماماً.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // ننتظر حتى يُبنى الـ router وتُستعاد الجلسة.
      Future.delayed(const Duration(milliseconds: 1500), _openNotifications);
    }
  }

  String _path(PushAudience a) => a == PushAudience.player
      ? '/player/device-token'
      : '/notifications/device-token';

  Future<void> register(PushAudience audience) async {
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      _audience = audience;
      await _send(audience, token);
      await _refreshSub?.cancel();
      _refreshSub = messaging.onTokenRefresh.listen((t) {
        final a = _audience;
        if (a != null) _send(a, t);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[PUSH] register failed: $e');
    }
  }

  Future<void> _send(PushAudience audience, String token) => sl<ApiClient>()
      .post(_path(audience), data: {'token': token, 'platform': 'android'});

  /// يُستدعى قبل مسح توكن الجلسة، حتى لا تصل إشعارات الحساب لهذا الجهاز بعد الخروج.
  Future<void> unregister(PushAudience audience) async {
    if (!_ready) return;
    try {
      await _refreshSub?.cancel();
      _refreshSub = null;
      _audience = null;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await sl<ApiClient>().delete(_path(audience), data: {'token': token});
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PUSH] unregister failed: $e');
    }
  }

  void _openNotifications() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final route = _audience == PushAudience.player
        ? AppRoutes.playerNotifications
        : AppRoutes.notifications;
    GoRouter.of(ctx).push(route);
  }

  void _showInApp(RemoteMessage message) {
    onMessage?.call();
    final ctx = rootNavigatorKey.currentContext;
    final n = message.notification;
    if (ctx == null || n == null) return;
    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
      SnackBar(
        content: Text([n.title, n.body]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join('\n')),
        action: SnackBarAction(label: 'عرض', onPressed: _openNotifications),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
