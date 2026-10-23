import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class GetAcademyPlayerStatusMapParams {
  final String academyId;

  const GetAcademyPlayerStatusMapParams({required this.academyId});
}

/// حالة اشتراك كل لاعب في الأكاديمية — playerId → 'active' | 'expired'.
///
/// تُحسب على السيرفر (أحدث endDate لكل لاعب) بدل ما الفرونت يجيب سجلات
/// الاشتراكات المُقسّمة على صفحات ويستنتج منها، لأن كل تجديد بينشئ سجل جديد
/// فعدد السجلات بيتخطى أي حد ثابت مع الوقت.
class GetAcademyPlayerStatusMapUsecase
    extends UseCase<Map<String, String>, GetAcademyPlayerStatusMapParams> {
  final SubscriptionRepository _repository;

  GetAcademyPlayerStatusMapUsecase(this._repository);

  @override
  Future<Either<Failure, Map<String, String>>> call(
      GetAcademyPlayerStatusMapParams params) {
    return _repository.getAcademyPlayerStatusMap(params.academyId);
  }
}
