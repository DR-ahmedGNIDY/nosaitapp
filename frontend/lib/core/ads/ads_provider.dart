import 'package:basketball_academy/core/ads/ads_policy.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_session_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// القرار الوحيد لإظهار الإعلانات في التطبيق كله.
///
/// يجمع مصدرَي الجلسة (المدير واللاعب) ويمرّرهما إلى [AdsPolicy]. حالة
/// الاشتراك تصل بالفعل داخل [UserEntity] من ردّ /auth/login و /auth/me، فلا
/// يوجد نداء شبكة منفصل ولا فجوة زمنية بين معرفة الدور ومعرفة الاشتراك.
final adsVisibilityProvider = Provider<bool>((ref) {
  final playerSession = ref.watch(playerSessionProvider).valueOrNull;
  if (playerSession?.isAuthenticated == true) {
    return AdsPolicy.shouldShowAds(session: AdsSessionKind.player);
  }

  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState?.isAuthenticated != true) {
    // يشمل حالتَي التحميل (valueOrNull == null) وعدم تسجيل الدخول.
    return AdsPolicy.shouldShowAds(session: AdsSessionKind.none);
  }

  final show = AdsPolicy.shouldShowAds(
    session: AdsSessionKind.admin,
    user: authState!.user,
  );
  if (kDebugMode) {
    debugPrint(
      '[ADS] policy → show=$show role=${authState.user?.role} '
      'sub=${authState.user?.academySubscriptionStatus}',
    );
  }
  return show;
});

/// هل تُفعَّل حماية إعلانات الأطفال (COPPA) للجلسة الحالية؟
///
/// المصدر الوحيد لعمر اللاعب هو `birthDate` القادم من الخادم — لا يُسأل عنه
/// المستخدم ولا يُخمَّن. المدير والإداري بالغان حتماً.
final adsChildDirectedProvider = Provider<bool>((ref) {
  final playerSession = ref.watch(playerSessionProvider).valueOrNull;
  if (playerSession?.isAuthenticated != true) {
    return AdsPolicy.isChildDirected(session: AdsSessionKind.admin);
  }

  final raw = playerSession!.player?['birthDate'] as String?;
  final birthDate = raw == null ? null : DateTime.tryParse(raw);
  final isChild = AdsPolicy.isChildDirected(
    session: AdsSessionKind.player,
    birthDate: birthDate,
  );
  if (kDebugMode) {
    debugPrint('[ADS] childDirected=$isChild birthDate=$raw');
  }
  return isChild;
});
