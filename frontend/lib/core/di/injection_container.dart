import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:basketball_academy/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:basketball_academy/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:basketball_academy/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:basketball_academy/features/dashboard/domain/usecases/get_evaluation_distribution_usecase.dart';
import 'package:basketball_academy/features/dashboard/domain/usecases/get_players_by_birth_year_usecase.dart';
import 'package:basketball_academy/features/dashboard/domain/usecases/get_recent_activities_usecase.dart';
import 'package:basketball_academy/features/dashboard/domain/usecases/get_revenue_by_month_usecase.dart';
import 'package:basketball_academy/features/dashboard/domain/usecases/get_subscriptions_by_type_usecase.dart';
import 'package:basketball_academy/core/network/token_manager.dart';
import 'package:basketball_academy/features/evaluation/data/datasources/evaluation_remote_datasource.dart';
import 'package:basketball_academy/features/evaluation/data/repositories/evaluation_repository_impl.dart';
import 'package:basketball_academy/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:basketball_academy/features/evaluation/domain/usecases/create_evaluation_usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/usecases/delete_evaluation_usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/usecases/get_evaluation_usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/usecases/get_evaluations_by_academy_usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/usecases/get_evaluations_by_player_usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/usecases/get_latest_evaluation_usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/usecases/update_evaluation_usecase.dart';
import 'package:basketball_academy/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:basketball_academy/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:basketball_academy/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_revenue_summary_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_subscriptions_by_academy_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_subscriptions_by_player_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/update_subscription_notes_usecase.dart';
import 'package:basketball_academy/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:basketball_academy/features/academy/data/repositories/academy_repository_impl.dart';
import 'package:basketball_academy/features/academy/domain/repositories/academy_repository.dart';
import 'package:basketball_academy/features/academy/domain/usecases/create_academy_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/delete_academy_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/get_academies_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/get_academy_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/update_academy_usecase.dart';
import 'package:basketball_academy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:basketball_academy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:basketball_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:basketball_academy/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:basketball_academy/features/auth/domain/usecases/login_usecase.dart';
import 'package:basketball_academy/features/auth/domain/usecases/logout_usecase.dart';
import 'package:basketball_academy/features/player/data/datasources/player_remote_datasource.dart';
import 'package:basketball_academy/features/player/data/repositories/player_repository_impl.dart';
import 'package:basketball_academy/features/player/domain/repositories/player_repository.dart';
import 'package:basketball_academy/features/player/domain/usecases/create_player_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/delete_player_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/get_player_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/get_players_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/search_players_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/update_player_usecase.dart';
import 'package:basketball_academy/features/user/data/datasources/user_remote_datasource.dart';
import 'package:basketball_academy/features/user/data/repositories/user_repository_impl.dart';
import 'package:basketball_academy/features/user/domain/repositories/user_repository.dart';
import 'package:basketball_academy/features/user/domain/usecases/activate_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/create_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/deactivate_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/delete_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/reset_password_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/get_users_by_academy_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/update_user_usecase.dart';
import 'package:basketball_academy/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:basketball_academy/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:basketball_academy/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:basketball_academy/features/attendance/domain/usecases/get_attendance_log_usecase.dart';
import 'package:basketball_academy/features/attendance/domain/usecases/get_attendance_report_usecase.dart';
import 'package:basketball_academy/features/attendance/domain/usecases/record_attendance_usecase.dart';
import 'package:basketball_academy/features/staff/data/datasources/staff_remote_datasource.dart';
import 'package:basketball_academy/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:basketball_academy/features/staff/domain/repositories/staff_repository.dart';
import 'package:basketball_academy/features/payroll/data/datasources/payroll_remote_datasource.dart';
import 'package:basketball_academy/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:basketball_academy/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:basketball_academy/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:basketball_academy/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:basketball_academy/features/expenses/domain/repositories/expense_repository.dart';
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
  sl.registerLazySingleton<GetAcademyUsecase>(
    () => GetAcademyUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<CreateAcademyUsecase>(
    () => CreateAcademyUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<UpdateAcademyUsecase>(
    () => UpdateAcademyUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<DeleteAcademyUsecase>(
    () => DeleteAcademyUsecase(sl<AcademyRepository>()),
  );

  // User Management
  sl.registerLazySingleton<UserRemoteDatasource>(
    () => UserRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDatasource: sl<UserRemoteDatasource>(),
    ),
  );
  sl.registerLazySingleton<GetUsersByAcademyUsecase>(
    () => GetUsersByAcademyUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<CreateUserUsecase>(
    () => CreateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<UpdateUserUsecase>(
    () => UpdateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<DeleteUserUsecase>(
    () => DeleteUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<ActivateUserUsecase>(
    () => ActivateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<DeactivateUserUsecase>(
    () => DeactivateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<ResetPasswordUsecase>(
    () => ResetPasswordUsecase(sl<UserRepository>()),
  );

  // Player
  sl.registerLazySingleton<PlayerRemoteDatasource>(
    () => PlayerRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(remoteDatasource: sl<PlayerRemoteDatasource>()),
  );
  sl.registerLazySingleton<GetPlayersUsecase>(
    () => GetPlayersUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<SearchPlayersUsecase>(
    () => SearchPlayersUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<GetPlayerUsecase>(
    () => GetPlayerUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<CreatePlayerUsecase>(
    () => CreatePlayerUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<UpdatePlayerUsecase>(
    () => UpdatePlayerUsecase(sl<PlayerRepository>()),
  );
  sl.registerLazySingleton<DeletePlayerUsecase>(
    () => DeletePlayerUsecase(sl<PlayerRepository>()),
  );

  // Subscription
  sl.registerLazySingleton<SubscriptionRemoteDatasource>(
    () => SubscriptionRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(
        remoteDatasource: sl<SubscriptionRemoteDatasource>()),
  );
  sl.registerLazySingleton<GetSubscriptionsByPlayerUsecase>(
    () => GetSubscriptionsByPlayerUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<GetSubscriptionsByAcademyUsecase>(
    () => GetSubscriptionsByAcademyUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<GetSubscriptionUsecase>(
    () => GetSubscriptionUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<CreateSubscriptionUsecase>(
    () => CreateSubscriptionUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<UpdateSubscriptionNotesUsecase>(
    () => UpdateSubscriptionNotesUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<DeleteSubscriptionUsecase>(
    () => DeleteSubscriptionUsecase(sl<SubscriptionRepository>()),
  );
  sl.registerLazySingleton<GetRevenueSummaryUsecase>(
    () => GetRevenueSummaryUsecase(sl<SubscriptionRepository>()),
  );

  // Evaluation
  sl.registerLazySingleton<EvaluationRemoteDatasource>(
    () => EvaluationRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<EvaluationRepository>(
    () => EvaluationRepositoryImpl(
        remoteDatasource: sl<EvaluationRemoteDatasource>()),
  );
  sl.registerLazySingleton<GetEvaluationsByPlayerUsecase>(
    () => GetEvaluationsByPlayerUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<GetLatestEvaluationUsecase>(
    () => GetLatestEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<GetEvaluationUsecase>(
    () => GetEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<CreateEvaluationUsecase>(
    () => CreateEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<UpdateEvaluationUsecase>(
    () => UpdateEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<DeleteEvaluationUsecase>(
    () => DeleteEvaluationUsecase(sl<EvaluationRepository>()),
  );
  sl.registerLazySingleton<GetEvaluationsByAcademyUsecase>(
    () => GetEvaluationsByAcademyUsecase(sl<EvaluationRepository>()),
  );

  // Dashboard
  sl.registerLazySingleton<DashboardRemoteDatasource>(
    () => DashboardRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDatasource: sl<DashboardRemoteDatasource>()),
  );
  sl.registerLazySingleton<GetDashboardStatsUsecase>(
    () => GetDashboardStatsUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetRevenueByMonthUsecase>(
    () => GetRevenueByMonthUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetSubscriptionsByTypeUsecase>(
    () => GetSubscriptionsByTypeUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetPlayersByBirthYearUsecase>(
    () => GetPlayersByBirthYearUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetEvaluationDistributionUsecase>(
    () => GetEvaluationDistributionUsecase(sl<DashboardRepository>()),
  );
  sl.registerLazySingleton<GetRecentActivitiesUsecase>(
    () => GetRecentActivitiesUsecase(sl<DashboardRepository>()),
  );

  // Attendance
  sl.registerLazySingleton<AttendanceRemoteDatasource>(
    () => AttendanceRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
        remoteDatasource: sl<AttendanceRemoteDatasource>()),
  );
  sl.registerLazySingleton<RecordAttendanceUsecase>(
    () => RecordAttendanceUsecase(sl<AttendanceRepository>()),
  );
  sl.registerLazySingleton<GetAttendanceLogUsecase>(
    () => GetAttendanceLogUsecase(sl<AttendanceRepository>()),
  );
  sl.registerLazySingleton<GetAttendanceReportUsecase>(
    () => GetAttendanceReportUsecase(sl<AttendanceRepository>()),
  );

  // Staff
  sl.registerLazySingleton<StaffRemoteDatasource>(
    () => StaffRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(remoteDatasource: sl<StaffRemoteDatasource>()),
  );

  // Payroll
  sl.registerLazySingleton<PayrollRemoteDatasource>(
    () => PayrollRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<PayrollRepository>(
    () => PayrollRepositoryImpl(remoteDatasource: sl<PayrollRemoteDatasource>()),
  );

  // Expenses
  sl.registerLazySingleton<ExpenseRemoteDatasource>(
    () => ExpenseRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(remoteDatasource: sl<ExpenseRemoteDatasource>()),
  );
}
