import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class CreateSubscriptionParams {
  final String playerId;
  final String type;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final int? sessionsLimit;
  final String? academyId;

  const CreateSubscriptionParams({
    required this.playerId,
    required this.type,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.notes,
    this.sessionsLimit,
    this.academyId,
  });
}

class CreateSubscriptionUsecase
    extends UseCase<SubscriptionEntity, CreateSubscriptionParams> {
  final SubscriptionRepository _repository;

  CreateSubscriptionUsecase(this._repository);

  @override
  Future<Either<Failure, SubscriptionEntity>> call(
      CreateSubscriptionParams params) {
    return _repository.createSubscription(
      playerId: params.playerId,
      type: params.type,
      amount: params.amount,
      startDate: params.startDate,
      endDate: params.endDate,
      notes: params.notes,
      sessionsLimit: params.sessionsLimit,
      academyId: params.academyId,
    );
  }
}
