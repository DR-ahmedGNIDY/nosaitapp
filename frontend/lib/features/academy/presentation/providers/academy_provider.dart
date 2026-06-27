import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/academy/domain/entities/academy_entity.dart';
import 'package:basketball_academy/features/academy/domain/usecases/create_academy_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/delete_academy_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/get_academies_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/get_academy_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/update_academy_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AcademiesNotifier extends AsyncNotifier<List<AcademyEntity>> {
  late final GetAcademiesUsecase _getAcademiesUsecase;
  late final CreateAcademyUsecase _createAcademyUsecase;
  late final UpdateAcademyUsecase _updateAcademyUsecase;
  late final DeleteAcademyUsecase _deleteAcademyUsecase;

  @override
  Future<List<AcademyEntity>> build() async {
    _getAcademiesUsecase = sl<GetAcademiesUsecase>();
    _createAcademyUsecase = sl<CreateAcademyUsecase>();
    _updateAcademyUsecase = sl<UpdateAcademyUsecase>();
    _deleteAcademyUsecase = sl<DeleteAcademyUsecase>();
    return _fetchAcademies();
  }

  Future<List<AcademyEntity>> _fetchAcademies() async {
    final result = await _getAcademiesUsecase();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (academies) => academies,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchAcademies);
  }

  Future<String?> createAcademy({
    required String name,
    required String phone,
    required String address,
    String currency = 'EGP',
    List<String> sports = const [],
    String? logoUrl,
  }) async {
    final result = await _createAcademyUsecase(
      CreateAcademyParams(
        name: name,
        phone: phone,
        address: address,
        currency: currency,
        sports: sports,
        logoUrl: logoUrl,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> updateAcademy({
    required String id,
    required String name,
    required String phone,
    required String address,
    String currency = 'EGP',
    List<String> sports = const [],
    String? logoUrl,
  }) async {
    final result = await _updateAcademyUsecase(
      UpdateAcademyParams(
        id: id,
        name: name,
        phone: phone,
        address: address,
        currency: currency,
        sports: sports,
        logoUrl: logoUrl,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> deleteAcademy(String id) async {
    final result = await _deleteAcademyUsecase(
      DeleteAcademyParams(id: id),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }
}

final academiesProvider =
    AsyncNotifierProvider<AcademiesNotifier, List<AcademyEntity>>(
  AcademiesNotifier.new,
);

/// Fetches a single academy by id — used to read the academy's sports list
/// when adding/editing a player or building the dashboard sport section.
final academyByIdProvider =
    FutureProvider.family<AcademyEntity, String>((ref, id) async {
  final usecase = sl<GetAcademyUsecase>();
  final result = await usecase(GetAcademyParams(id: id));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (academy) => academy,
  );
});
