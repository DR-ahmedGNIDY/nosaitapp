import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/delete_subscription_usecase.dart';
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
        academyId: academyId,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        ref.invalidateSelf();
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
    FutureProvider.family<String, String>((ref, playerId) async {
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

/// Fetches ALL subscriptions for the academy in one request (limit=500) and
/// returns a map of playerId → 'نشط' | 'منتهي' | 'جديد'.
/// Players not in the map default to 'جديد' at the call site.
final academyPlayerStatusMapProvider =
    FutureProvider.family<Map<String, String>, String>((ref, academyId) async {
  final usecase = sl<GetSubscriptionsByAcademyUsecase>();
  final result = await usecase(
    GetSubscriptionsByAcademyParams(academyId: academyId, limit: 500, page: 1),
  );
  return result.fold(
    (f) => throw Exception(f.message),
    (data) {
      final now = DateTime.now();
      final map = <String, String>{};
      for (final sub in data.subscriptions) {
        final pid = sub.playerId;
        if (!map.containsKey(pid)) {
          map[pid] = sub.endDate.isAfter(now) ? 'نشط' : 'منتهي';
        } else {
          // Keep 'نشط' over 'منتهي' — the player has at least one active sub
          final existing = map[pid]!;
          if (existing == 'منتهي' && sub.endDate.isAfter(now)) {
            map[pid] = 'نشط';
          }
        }
      }
      return map;
    },
  );
});

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
