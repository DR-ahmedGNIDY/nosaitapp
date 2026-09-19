import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:basketball_academy/core/ads/ad_ids.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// أندرويد فقط. نسخة Windows/الديسكتوب مشروع منفصل ولا إعلانات فيها، لكن
/// dart:io موجود هناك أيضاً — لذلك نحرس بـ Platform.isAndroid صراحةً.
bool get adsPlatformSupported => Platform.isAndroid;

/// شريط تشخيص مرئي على الجهاز — للتشخيص فقط، مطفأ افتراضياً:
/// `flutter build apk --release --dart-define=ADS_DEBUG=true`
const bool kAdsDebugOverlay = bool.fromEnvironment('ADS_DEBUG');

/// آخر حالة معروفة لمحاولة تحميل الإعلان (تُعرض في شريط التشخيص).
String _adStatus = 'init: not started';
String get adStatus => _adStatus;

bool _initStarted = false;
Future<void>? _initFuture;

/// تهيئة كسولة: تُستدعى **فقط** عند أول قرار بإظهار إعلان. المستخدم المشترك
/// لا يُهيَّأ لديه الـ SDK إطلاقاً (توفير موارد + خصوصية + زمن إقلاع أسرع).
Future<void> ensureAdsInitialized() {
  if (!adsPlatformSupported) return Future<void>.value();
  if (_initStarted) return _initFuture!;
  _initStarted = true;

  if (AdIds.isUsingTestAds) {
    debugPrint('[ADS] using GOOGLE TEST ad units (debug build)');
  }

  _adStatus = 'init: started';
  _initFuture = MobileAds.instance.initialize().then((_) {
    _adStatus = 'init: OK';
    debugPrint('[ADS] MobileAds initialized');
  }).catchError((Object e) {
    _adStatus = 'init FAILED: $e';
    debugPrint('[ADS] init failed: $e');
  });
  return _initFuture!;
}

/// بانر متكيّف مثبَّت أسفل الشاشة. يبني نفسه بنفسه ويهدم إعلانه في dispose.
/// لا يحجز أي مساحة قبل نجاح التحميل — فلا قفزات layout ولا فراغ عند الفشل.
Widget buildAdaptiveBanner() => const _AdaptiveBanner();

class _AdaptiveBanner extends StatefulWidget {
  const _AdaptiveBanner();

  @override
  State<_AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<_AdaptiveBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // العرض معروف فقط بعد توفّر MediaQuery، لذلك نطلب هنا لا في initState.
    if (!_requested) {
      _requested = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (!adsPlatformSupported) return;
    try {
      await ensureAdsInitialized();
    } catch (e) {
      _setStatus('init threw: $e');
      return;
    }
    if (!mounted) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    AdSize? size;
    try {
      size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    } catch (e) {
      _setStatus('adaptive size threw: $e');
      return;
    }
    if (!mounted) return;
    if (size == null) {
      // سبب صامت معروف: فشل جلب الحجم المتكيّف. نرجع لحجم بانر ثابت بدل الاستسلام.
      _setStatus('adaptive size NULL (w=$width) → fallback banner');
      size = AdSize.banner;
    }

    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: _buildAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _setStatus('LOADED');
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          // فشل التحميل (شبكة ضعيفة، لا مخزون إعلاني…) — نهدم بصمت ولا نعرض
          // شيئاً للمستخدم ولا نحجز مساحة.
          _setStatus('FAILED code=${error.code} ${error.message}');
          debugPrint('[ADS] banner failed: ${error.code} ${error.message}');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });
        },
      ),
    );

    _ad = ad;
    _setStatus('requesting ${AdIds.banner} (${size.width}x${size.height})');
    try {
      await ad.load();
    } catch (e) {
      _setStatus('load() threw: $e');
    }
  }

  void _setStatus(String s) {
    _adStatus = s;
    debugPrint('[ADS] $s');
    if (kAdsDebugOverlay && mounted) setState(() {});
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) {
      if (!kAdsDebugOverlay) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        color: const Color(0xFFB71C1C),
        padding: const EdgeInsets.all(6),
        child: Text(
          'ADS DEBUG: $_adStatus',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 11),
          textDirection: TextDirection.ltr,
        ),
      );
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

// ─── Interstitial (ملء الشاشة) ───────────────────────────────────────────────
//
// نوع الوحدة المتاحة في حساب AdMob. يُعرض عند نقاط انتقال آمنة فقط (شاشات
// عرض، لا نماذج ولا حفظ)، وبضوابط تردّد تمنع الإزعاج.

/// أقل فاصل زمني بين إعلانين.
const Duration _kInterstitialCooldown = Duration(minutes: 3);

/// أقصى عدد إعلانات في تشغيل واحد للتطبيق.
const int _kMaxInterstitialsPerSession = 5;

/// لا نعرض أي إعلان قبل مرور هذه المدة على فتح التطبيق (حتى لا يُفاجأ
/// المستخدم بإعلان فور الدخول).
const Duration _kInterstitialWarmup = Duration(seconds: 45);

/// هل الجلسة الحالية تحت حماية الأطفال؟ الافتراضي **true** (fail-safe):
/// لا نطلب إعلاناً مخصصاً قبل أن نعرف يقيناً أن المستخدم بالغ.
bool _childDirected = true;

/// يضبط حماية إعلانات الأطفال (COPPA). يجب أن يُستدعى **قبل** طلب أي إعلان.
///
/// عند التفعيل: إعلانات غير مخصّصة + تصنيف محتوى G فقط.
/// تغيّر القيمة يُسقط أي إعلان مُحمَّل مسبقاً لأنه طُلب بإعدادات مختلفة.
Future<void> setChildDirected(bool isChild) async {
  if (!adsPlatformSupported) return;
  if (_childDirected == isChild) return;
  _childDirected = isChild;

  // إعلان جُهّز بإعدادات الجلسة السابقة لا يصلح للجلسة الحالية.
  _interstitial?.dispose();
  _interstitial = null;

  await ensureAdsInitialized();
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      tagForChildDirectedTreatment: isChild
          ? TagForChildDirectedTreatment.yes
          : TagForChildDirectedTreatment.unspecified,
      maxAdContentRating: isChild ? MaxAdContentRating.g : null,
    ),
  );
  debugPrint('[ADS] childDirected=$isChild');
}

/// طلب إعلان يحترم حالة حماية الأطفال الحالية.
AdRequest _buildAdRequest() => AdRequest(nonPersonalizedAds: _childDirected);

InterstitialAd? _interstitial;
bool _interstitialLoading = false;
DateTime? _lastInterstitialShownAt;
int _interstitialsShown = 0;
final DateTime _appStartedAt = DateTime.now();

/// يحمّل إعلاناً مسبقاً ليكون جاهزاً عند نقطة العرض التالية. آمن للاستدعاء
/// المتكرر. لا يفعل شيئاً إذا كان هناك إعلان جاهز أو تحميل جارٍ.
Future<void> preloadInterstitial() async {
  if (!adsPlatformSupported) return;
  if (_interstitial != null || _interstitialLoading) return;
  if (_interstitialsShown >= _kMaxInterstitialsPerSession) return;

  _interstitialLoading = true;
  await ensureAdsInitialized();

  await InterstitialAd.load(
    adUnitId: AdIds.interstitial,
    request: _buildAdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _interstitialLoading = false;
        _interstitial = ad;
        _setGlobalStatus('interstitial LOADED');
      },
      onAdFailedToLoad: (error) {
        _interstitialLoading = false;
        _interstitial = null;
        _setGlobalStatus(
            'interstitial FAILED code=${error.code} ${error.message}');
      },
    ),
  );
}

/// هل يُسمح بعرض إعلان الآن؟ (ضوابط التردّد فقط — قرار الاشتراك منفصل)
bool _interstitialAllowedNow() {
  if (_interstitialsShown >= _kMaxInterstitialsPerSession) return false;
  if (DateTime.now().difference(_appStartedAt) < _kInterstitialWarmup) {
    return false;
  }
  final last = _lastInterstitialShownAt;
  if (last != null &&
      DateTime.now().difference(last) < _kInterstitialCooldown) {
    return false;
  }
  return true;
}

/// يعرض إعلان ملء الشاشة إن كان جاهزاً ومسموحاً. يُرجع true إذا عُرض فعلاً.
/// لا يحجب الانتقال إطلاقاً — إن لم يكن جاهزاً يمرّ المستخدم فوراً.
Future<bool> maybeShowInterstitial({required bool adsAllowed}) async {
  if (!adsPlatformSupported || !adsAllowed) return false;

  if (!_interstitialAllowedNow()) {
    unawaited(preloadInterstitial()); // جهّز التالي على أي حال
    return false;
  }

  final ad = _interstitial;
  if (ad == null) {
    unawaited(preloadInterstitial());
    return false;
  }

  _interstitial = null; // لا يُعاد استخدام نفس الإعلان أبداً
  ad.fullScreenContentCallback = FullScreenContentCallback(
    onAdDismissedFullScreenContent: (ad) {
      ad.dispose();
      unawaited(preloadInterstitial());
    },
    onAdFailedToShowFullScreenContent: (ad, error) {
      _setGlobalStatus('interstitial SHOW failed: ${error.message}');
      ad.dispose();
      unawaited(preloadInterstitial());
    },
  );

  _lastInterstitialShownAt = DateTime.now();
  _interstitialsShown++;
  _setGlobalStatus('interstitial SHOWN ($_interstitialsShown)');
  await ad.show();
  return true;
}

void _setGlobalStatus(String s) {
  _adStatus = s;
  debugPrint('[ADS] $s');
}
