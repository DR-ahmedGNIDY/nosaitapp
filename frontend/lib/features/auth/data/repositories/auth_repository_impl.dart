import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/network/token_manager.dart';
import 'package:basketball_academy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:basketball_academy/features/auth/data/models/user_model.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:basketball_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final TokenManager _tokenManager;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required TokenManager tokenManager,
  })  : _remoteDatasource = remoteDatasource,
        _tokenManager = tokenManager;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDatasource.login(email: email, password: password);
      final token = result['token'] as String?;
      final refreshToken = result['refreshToken'] as String?;
      final userData = result['data'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        return const Left(ServerFailure(message: 'استجابة غير صحيحة من الخادم'));
      }

      await _tokenManager.saveToken(token);
      if (refreshToken != null) {
        await _tokenManager.saveRefreshToken(refreshToken);
      }

      final user = UserModel.fromJson(userData);
      return Right(user.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDatasource.logout();
    } catch (_) {
      // ignore logout API errors
    } finally {
      await _tokenManager.clearToken();
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await _remoteDatasource.getCurrentUser();
      return Right(user.toEntity());
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _tokenManager.hasToken();
  }
}
