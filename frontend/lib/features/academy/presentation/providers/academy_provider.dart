import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/academy/domain/entities/academy_entity.dart';
import 'package:basketball_academy/features/academy/domain/usecases/get_academies_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AcademiesNotifier extends AsyncNotifier<List<AcademyEntity>> {
  late final GetAcademiesUsecase _getAcademiesUsecase;

  @override
  Future<List<AcademyEntity>> build() async {
    _getAcademiesUsecase = sl<GetAcademiesUsecase>();
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
}

final academiesProvider =
    AsyncNotifierProvider<AcademiesNotifier, List<AcademyEntity>>(
  AcademiesNotifier.new,
);
