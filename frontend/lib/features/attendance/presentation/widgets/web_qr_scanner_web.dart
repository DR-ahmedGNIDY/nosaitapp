// Web-only QR scanner. Uses the browser's getUserMedia + the native Shape
// Detection API (window.BarcodeDetector, supported in Chrome/Edge) via JS
// interop, so it adds zero native build cost — no new pub dependency, no
// platform code compiled into the Android/Windows builds.
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Future<String?> showWebQrScanner(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const _WebQrScannerPage()),
  );
}

class _WebQrScannerPage extends StatefulWidget {
  const _WebQrScannerPage();

  @override
  State<_WebQrScannerPage> createState() => _WebQrScannerPageState();
}

class _WebQrScannerPageState extends State<_WebQrScannerPage> {
  static int _viewCounter = 0;
  late final String _viewType =
      'web-qr-video-${_viewCounter++}-${DateTime.now().microsecondsSinceEpoch}';

  html.VideoElement? _video;
  html.MediaStream? _stream;
  Timer? _pollTimer;
  Object? _detector;
  String? _error;
  bool _supported = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!js_util.hasProperty(html.window, 'BarcodeDetector')) {
      setState(() {
        _supported = false;
        _error = 'هذا المتصفح لا يدعم مسح QR بالكاميرا — استخدم الإدخال اليدوي';
      });
      return;
    }

    try {
      _detector = js_util.callConstructor(
        js_util.getProperty(html.window, 'BarcodeDetector'),
        [
          js_util.jsify({'formats': ['qr_code']})
        ],
      );

      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => video,
      );

      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'environment'},
      });

      video.srcObject = stream;
      _video = video;
      _stream = stream;

      _pollTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
        _detect();
      });

      if (mounted) setState(() {});
    } catch (e) {
      setState(() {
        _error = 'تعذّر فتح الكاميرا — تأكد من السماح بالوصول للكاميرا';
      });
    }
  }

  Future<void> _detect() async {
    if (_detector == null || _video == null) return;
    try {
      final result =
          await js_util.promiseToFuture(js_util.callMethod(_detector!, 'detect', [_video]));
      final list = result as List;
      if (list.isNotEmpty) {
        final raw = js_util.getProperty(list.first, 'rawValue') as String?;
        if (raw != null && raw.trim().isNotEmpty && mounted) {
          _pollTimer?.cancel();
          Navigator.of(context).pop(raw);
        }
      }
    } catch (_) {
      // Ignore transient detect errors (e.g. frame not ready yet).
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _stream?.getTracks().forEach((t) => t.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مسح QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _supported
          ? (_video == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : HtmlElementView(viewType: _viewType))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
