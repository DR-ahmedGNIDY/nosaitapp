import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/core/network/token_manager.dart';
import 'package:basketball_academy/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:basketball_academy/features/academy/data/repositories/academy_repository_impl.dart';
import 'package:basketball_academy/features/academy/domain/repositories/academy_repository.dart';
import 'package:basketball_academy/features/academy/domain/usecases/get_academies_usecase.dart';
import 'package:basketball_academy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:basketball_academy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:basketball_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:basketball_academy/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:basketball_academy/features/auth/domain/usecases/login_usecase.dart';
import 'package:basketball_academy/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  // Core
  sl.registerLazySingleton<TokenManager>(
    () => TokenManager(sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl<TokenManager>()),
  );

  // Auth
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: sl<AuthRemoteDatasource>(),
      tokenManager: sl<TokenManager>(),
    ),
  );
  sl.registerLazySingleton<LoginUsecase>(
    () => LoginUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUsecase>(
    () => LogoutUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentUserUsecase>(
    () => GetCurrentUserUsecase(sl<AuthRepository>()),
  );

  // Academy
  sl.registerLazySingleton<AcademyRemoteDatasource>(
    () => AcademyRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AcademyRepository>(
    () => AcademyRepositoryImpl(
      remoteDatasource: sl<AcademyRemoteDatasource>(),
    ),
  );
  sl.registerLazySingleton<GetAcademiesUsecase>(
    () => GetAcademiesUsecase(sl<AcademyRepository>()),
  );
}
