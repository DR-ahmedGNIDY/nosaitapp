import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:basketball_academy/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:basketball_academy/features/auth/domain/usecases/login_usecase.dart';
import 'package:basketball_academy/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isAuthenticated;
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final LoginUsecase _loginUsecase;
  late final LogoutUsecase _logoutUsecase;
  late final GetCurrentUserUsecase _getCurrentUserUsecase;

  @override
  Future<AuthState> build() async {
    _loginUsecase = sl<LoginUsecase>();
    _logoutUsecase = sl<LogoutUsecase>();
    _getCurrentUserUsecase = sl<GetCurrentUserUsecase>();
    return _checkAuthState();
  }

  Future<AuthState> _checkAuthState() async {
    final result = await _getCurrentUserUsecase();
    return result.fold(
      (_) => const AuthState(isAuthenticated: false),
      (user) => AuthState(isAuthenticated: true, user: user),
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final result = await _loginUsecase(LoginParams(email: email, password: password));
    state = result.fold(
      (failure) => AsyncValue.data(
        AuthState(isAuthenticated: false, errorMessage: failure.message),
      ),
      (user) => AsyncValue.data(
        AuthState(isAuthenticated: true, user: user),
      ),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _logoutUsecase();
    state = const AsyncValue.data(AuthState(isAuthenticated: false));
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(clearError: true));
    }
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
