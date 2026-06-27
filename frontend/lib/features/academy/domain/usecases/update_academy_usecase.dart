import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/academy/domain/entities/academy_entity.dart';
import 'package:basketball_academy/features/academy/domain/repositories/academy_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateAcademyParams {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String currency;
  final List<String> sports;
  final String? logoUrl;

  const UpdateAcademyParams({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.currency = 'EGP',
    this.sports = const [],
    this.logoUrl,
  });
}

class UpdateAcademyUsecase extends UseCase<AcademyEntity, UpdateAcademyParams> {
  final AcademyRepository _repository;
  UpdateAcademyUsecase(this._repository);

  @override
  Future<Either<Failure, AcademyEntity>> call(UpdateAcademyParams params) {
    return _repository.updateAcademy(
      id: params.id,
      name: params.name,
      phone: params.phone,
      address: params.address,
      currency: params.currency,
      sports: params.sports,
      logoUrl: params.logoUrl,
    );
  }
}
