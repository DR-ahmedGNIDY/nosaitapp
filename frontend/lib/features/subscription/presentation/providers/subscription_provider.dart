import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_academy_player_status_map_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_revenue_summary_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_subscriptions_by_academy_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_subscriptions_by_player_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/update_subscription_notes_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// PlayerSubscriptionsNotifier — family (one instance per playerId)
// ---------------------------------------------------------------------------

class PlayerSubscriptionsNotifier
    extends FamilyAsyncNotifier<List<SubscriptionEntity>, String> {
  String? _statusFilter;

  late final GetSubscriptionsByPlayerUsecase _getSubscriptionsUsecase;
  late final CreateSubscriptionUsecase _createSubscriptionUsecase;
  late final UpdateSubscriptionNotesUsecase _updateNotesUsecase;
  late final DeleteSubscriptionUsecase _deleteSubscriptionUsecase;

  @override
  Future<List<SubscriptionEntity>> build(String playerId) async {
    _getSubscriptionsUsecase = sl<GetSubscriptionsByPlayerUsecase>();
    _createSubscriptionUsecase = sl<CreateSubscriptionUsecase>();
    _updateNotesUsecase = sl<UpdateSubscriptionNotesUsecase>();
    _deleteSubscriptionUsecase = sl<DeleteSubscriptionUsecase>();
    _statusFilter = null;
    return _fetch(playerId);
  }

  Future<List<SubscriptionEntity>> _fetch(String playerId) async {
    final result = await _getSubscriptionsUsecase(
      GetSubscriptionsByPlayerParams(
        playerId: playerId,
        status: _statusFilter,
      ),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (subscriptions) => subscriptions,
    );
  }

  Future<void> filterByStatus(String? status) async {
    _statusFilter = status;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> refresh() async {
    _statusFilter = null;
    ref.invalidateSelf();
  }

  Future<String?> createSubscription({
    required String playerId,
    required String type,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    int? sessionsLimit,
    String? academyId,
  }) async {
    final result = await _createSubscriptionUsecase(
      CreateSubscriptionParams(
        playerId: playerId,
        type: type,
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        sessionsLimit: sessionsLimit,
        academyId: academyId,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        ref.invalidateSelf();
        _invalidateSubscriptionViews(ref);
        return null;
      },
    );
  }

  Future<String?> updateNotes({
    required String id,
    required String notes,
  }) async {
    final result = await _updateNotesUsecase(
      UpdateSubscriptionNotesParams(id: id, notes: notes),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        ref.invalidateSelf();
        _invalidateSubscriptionViews(ref);
        return null;
      },
    );
  }

  Future<String?> deleteSubscription(String id) async {
    final result = await _deleteSubscriptionUsecase(
      DeleteSubscriptionParams(id: id),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        ref.invalidateSelf();
        _invalidateSubscriptionViews(ref);
        return null;
      },
    );
  }
}

final playerSubscriptionsProvider = AsyncNotifierProvider.family<
    PlayerSubscriptionsNotifier,
    List<SubscriptionEntity>,
    String>(
  PlayerSubscriptionsNotifier.new,
);

// ---------------------------------------------------------------------------
// Player Status Provider — derives جديد/نشط/منتهي from subscriptions
// ---------------------------------------------------------------------------

/// Returns one of: 'جديد' | 'نشط' | 'منتهي'
final playerStatusProvider =
    FutureProvider.autoDispose.family<String, String>((ref, playerId) async {
  final subsAsync =
      await ref.watch(playerSubscriptionsProvider(playerId).future);
  if (subsAsync.isEmpty) return 'جديد';
  // Pick the subscription with the latest endDate
  final latest = subsAsync.reduce(
      (a, b) => a.endDate.isAfter(b.endDate) ? a : b);
  return latest.endDate.isAfter(DateTime.now()) ? 'نشط' : 'منتهي';
});

// ---------------------------------------------------------------------------
// Academy-wide player status map — single request, no per-player loops
// ---------------------------------------------------------------------------

/// Fetches the academy-wide player subscription status in ONE request and
/// returns a map of playerId → 'نشط' | 'منتهي'.
/// Players not in the map default to 'جديد' at the call site.
///
/// The server computes this from the latest endDate per player, so a renewal
/// never leaves a player looking expired because of an older record. It used
/// to page through the raw subscription records instead, which silently
/// dropped every player whose records fell past the first page.
final academyPlayerStatusMapProvider =
    FutureProvider.family<Map<String, String>, String>((ref, academyId) async {
  final usecase = sl<GetAcademyPlayerStatusMapUsecase>();
  final result = await usecase(
    GetAcademyPlayerStatusMapParams(academyId: academyId),
  );
  return result.fold(
    (f) => throw Exception(f.message),
    (data) => data.map(
      (playerId, status) =>
          MapEntry(playerId, status == 'active' ? 'نشط' : 'منتهي'),
    ),
  );
});

// ---------------------------------------------------------------------------
// Academy Subscriptions List — full list for the "Subscriptions" screen
// ---------------------------------------------------------------------------

/// Fetches ALL subscriptions for the academy (single request, limit=500) for
/// use in the academy-wide subscriptions list screen. Search/status filters
/// are applied client-side in the screen against this cached list.
class AcademySubscriptionsNotifier
    extends FamilyAsyncNotifier<List<SubscriptionEntity>, String> {
  @override
  Future<List<SubscriptionEntity>> build(String academyId) async {
    return _fetch(academyId);
  }

  Future<List<SubscriptionEntity>> _fetch(String academyId) async {
    final usecase = sl<GetSubscriptionsByAcademyUsecase>();
    final result = await usecase(
      GetSubscriptionsByAcademyParams(academyId: academyId, limit: 500, page: 1),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => data.subscriptions,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<String?> deleteSubscription(String id) async {
    final usecase = sl<DeleteSubscriptionUsecase>();
    final result = await usecase(DeleteSubscriptionParams(id: id));
    return result.fold(
      (failure) => failure.message,
      (_) {
        ref.invalidateSelf();
        _invalidateSubscriptionViews(ref);
        return null;
      },
    );
  }
}

final academySubscriptionsProvider = AsyncNotifierProvider.family<
    AcademySubscriptionsNotifier, List<SubscriptionEntity>, String>(
  AcademySubscriptionsNotifier.new,
);

// ---------------------------------------------------------------------------
// Revenue Summary Provider
// ---------------------------------------------------------------------------

final revenueSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
        (ref, academyId) async {
  final usecase = sl<GetRevenueSummaryUsecase>();
  final result =
      await usecase(GetRevenueSummaryParams(academyId: academyId));
  return result.fold(
    (f) => throw Exception(f.message),
    (data) => data,
  );
});

// ---------------------------------------------------------------------------
// Cross-screen refresh after a subscription is created / edited / deleted
// ---------------------------------------------------------------------------

/// Marks every subscription-derived view as stale so the next screen that
/// shows it fetches fresh data. Lazy: a provider nobody is watching is only
/// re-fetched when its screen is opened, so this adds no requests by itself.
void _invalidateSubscriptionViews(Ref ref) {
  ref.invalidate(playerSubscriptionsProvider);
  ref.invalidate(academySubscriptionsProvider);
  ref.invalidate(academyPlayerStatusMapProvider);
  ref.invalidate(revenueSummaryProvider);
}
