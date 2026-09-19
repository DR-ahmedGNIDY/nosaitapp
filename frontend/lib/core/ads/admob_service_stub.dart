import 'package:flutter/widgets.dart';

/// نسخة الويب: الإعلانات غير مدعومة إطلاقاً — كل شيء no-op.
bool get adsPlatformSupported => false;

const bool kAdsDebugOverlay = false;
String get adStatus => 'unsupported platform';

Future<void> ensureAdsInitialized() async {}

Widget buildAdaptiveBanner() => const SizedBox.shrink();

// Interstitial — لا شيء على الويب.
Future<void> preloadInterstitial() async {}

Future<bool> maybeShowInterstitial({required bool adsAllowed}) async => false;

Future<void> setChildDirected(bool isChild) async {}
