import 'dart:typed_data';

import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/subscription/domain/entities/academy_debts_entity.dart';
import 'package:basketball_academy/features/subscription/domain/entities/receipt_entity.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:dartz/dartz.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, List<SubscriptionEntity>>> getSubscriptionsByPlayer({
    required String playerId,
    String? status,
  });

  Future<
      Either<
          Failure,
          ({
            List<SubscriptionEntity> subscriptions,
            int total,
            int page,
            int totalPages,
          })>> getSubscriptionsByAcademy({
    required String academyId,
    String? type,
    String? status,
    String? playerId,
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, SubscriptionEntity>> getSubscriptionById(String id);

  Future<Either<Failure, SubscriptionEntity>> createSubscription({
    required String playerId,
    required String type,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    int? sessionsLimit,
    String? academyId,
    double? paidAmount,
    String? paymentMethod,
  });

  Future<Either<Failure, SubscriptionEntity>> addPayment({
    required String subscriptionId,
    required double amount,
    String method = 'cash',
    DateTime? date,
    String? note,
  });

  Future<Either<Failure, SubscriptionEntity>> deletePayment({
    required String subscriptionId,
    required String paymentId,
  });

  Future<Either<Failure, AcademyDebtsEntity>> getAcademyDebts(String academyId);

  Future<Either<Failure, ReceiptEntity>> getReceipt({
    required String subscriptionId,
    required String paymentId,
  });

  Future<Either<Failure, SubscriptionEntity>> freezeSubscription({
    required String subscriptionId,
    required int days,
    String? startDate,
    String reason = 'other',
    String? note,
  });

  /// يرجّع رسالة السيرفر (عدد الأيام المحتسبة).
  Future<Either<Failure, String>> resumeSubscription(String subscriptionId);

  Future<Either<Failure, String>> shareReceiptImage({
    required String subscriptionId,
    required String paymentId,
    required Uint8List png,
  });

  Future<Either<Failure, SubscriptionEntity>> updateNotes({
    required String id,
    required String notes,
  });

  Future<Either<Failure, void>> deleteSubscription(String id);

  Future<Either<Failure, Map<String, dynamic>>> getRevenueSummary(
      String academyId);

  /// خريطة playerId → 'active' | 'expired' لكل لاعبي الأكاديمية.
  Future<Either<Failure, Map<String, String>>> getAcademyPlayerStatusMap(
      String academyId);
}
