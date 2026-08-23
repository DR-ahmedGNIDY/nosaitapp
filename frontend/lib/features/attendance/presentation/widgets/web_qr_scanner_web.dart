// Web-only QR scanner. Two decode paths, picked at runtime:
//   1. window.BarcodeDetector (native Shape Detection API — Chrome/Edge on
//      Android & desktop). Fastest, nothing to download.
//   2. jsQR (web/js/jsQR.min.js, lazy-loaded only when path 1 is missing).
//      This is the iOS/Safari path: every browser on iPhone runs WebKit, which
//      has no BarcodeDetector, but getUserMedia works fine — so we pull frames
//      onto a canvas and decode them in JS.
// Either way it adds zero native build cost — no new pub dependency, no
// platform code compiled into the Android/Windows builds.
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Path of the lazy-loaded fallback decoder, relative to the app's base href.
const String _kJsQrScriptPath = 'js/jsQR.min.js';

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

  /// BarcodeDetector instance, or null when we fall back to jsQR.
  Object? _detector;

  /// Reused canvas for the jsQR path (a new one per frame is wasteful).
  html.CanvasElement? _canvas;

  String? _error;
  bool _supported = true;
  bool _detecting = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // A camera is only reachable over https:// (or localhost). On plain http
    // the browser hides mediaDevices entirely, which is worth naming clearly.
    if (html.window.navigator.mediaDevices == null) {
      setState(() {
        _supported = false;
        _error =
            'الكاميرا غير متاحة في هذا المتصفح — تأكد من فتح الموقع عبر https';
      });
      return;
    }

    if (!await _prepareDecoder()) {
      if (!mounted) return;
      setState(() {
        _supported = false;
        _error = 'هذا المتصفح لا يدعم مسح QR بالكاميرا — استخدم الإدخال اليدوي';
      });
      return;
    }

    try {
      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        // Without playsinline, iOS Safari takes the video fullscreen and the
        // element stops being a usable frame source.
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => video,
      );

      final stream = await _openCamera();

      video.srcObject = stream;
      // iOS ignores the autoplay attribute for srcObject streams.
      try {
        await video.play();
      } catch (_) {
        // Some browsers reject the promise but still start playback.
      }

      _video = video;
      _stream = stream;

      _pollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        _detect();
      });

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر فتح الكاميرا — تأكد من السماح بالوصول للكاميرا';
      });
    }
  }

  Future<html.MediaStream> _openCamera() async {
    final mediaDevices = html.window.navigator.mediaDevices!;
    try {
      return await mediaDevices.getUserMedia({
        'video': {'facingMode': 'environment'},
      });
    } catch (_) {
      // Laptops (and a few mobile browsers) have no rear camera; retry with
      // whatever camera exists rather than failing outright.
      return await mediaDevices.getUserMedia({'video': true});
    }
  }

  /// Sets up [_detector] (native path) or loads jsQR (fallback path).
  /// Returns false when neither decoder is available.
  Future<bool> _prepareDecoder() async {
    if (js_util.hasProperty(html.window, 'BarcodeDetector')) {
      try {
        _detector = js_util.callConstructor(
          js_util.getProperty(html.window, 'BarcodeDetector'),
          [
            js_util.jsify({
              'formats': ['qr_code']
            })
          ],
        );
        return true;
      } catch (_) {
        // Present but unusable (e.g. qr_code format unsupported) — fall back.
        _detector = null;
      }
    }
    return _ensureJsQr();
  }

  Future<bool> _ensureJsQr() async {
    if (js_util.hasProperty(html.window, 'jsQR')) return true;

    final completer = Completer<bool>();
    void finish(bool ok) {
      if (!completer.isCompleted) completer.complete(ok);
    }

    final script = html.ScriptElement()..src = _kJsQrScriptPath;
    script.onLoad.listen((_) {
      finish(js_util.hasProperty(html.window, 'jsQR'));
    });
    script.onError.listen((_) => finish(false));
    html.document.head!.append(script);

    return completer.future
        .timeout(const Duration(seconds: 15), onTimeout: () => false);
  }

  Future<void> _detect() async {
    final video = _video;
    if (video == null || _detecting) return;
    _detecting = true;
    try {
      final raw = _detector != null
          ? await _detectNative(video)
          : _detectWithJsQr(video);
      if (raw != null && raw.trim().isNotEmpty && mounted) {
        _pollTimer?.cancel();
        Navigator.of(context).pop(raw);
      }
    } catch (_) {
      // Ignore transient detect errors (e.g. frame not ready yet).
    } finally {
      _detecting = false;
    }
  }

  Future<String?> _detectNative(html.VideoElement video) async {
    final result = await js_util
        .promiseToFuture(js_util.callMethod(_detector!, 'detect', [video]));
    final list = result as List;
    if (list.isEmpty) return null;
    return js_util.getProperty(list.first, 'rawValue') as String?;
  }

  String? _detectWithJsQr(html.VideoElement video) {
    final vw = video.videoWidth;
    final vh = video.videoHeight;
    if (vw == 0 || vh == 0) return null; // first frame not decoded yet

    // Downscale wide frames: decoding a full 1920px frame every 300ms drains
    // an iPhone battery fast, and QR codes survive 640px easily.
    const maxWidth = 640;
    final scale = vw > maxWidth ? maxWidth / vw : 1.0;
    final w = (vw * scale).round();
    final h = (vh * scale).round();

    final canvas = (_canvas ??= html.CanvasElement());
    if (canvas.width != w || canvas.height != h) {
      canvas.width = w;
      canvas.height = h;
    }

    final ctx = canvas.context2D;
    ctx.drawImageScaled(video, 0, 0, w, h);
    final imageData = ctx.getImageData(0, 0, w, h);

    final result = js_util.callMethod(html.window, 'jsQR', [
      imageData.data,
      w,
      h,
      js_util.jsify({'inversionAttempts': 'dontInvert'}),
    ]);
    if (result == null) return null;
    return js_util.getProperty(result, 'data') as String?;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _stream?.getTracks().forEach((t) => t.stop());
    _video?.srcObject = null;
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
              ? Center(
                  child: _error == null
                      ? const CircularProgressIndicator(color: Colors.white)
                      : _message(_error!),
                )
              : HtmlElementView(viewType: _viewType))
          : Center(child: _message(_error ?? '')),
    );
  }

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
}
