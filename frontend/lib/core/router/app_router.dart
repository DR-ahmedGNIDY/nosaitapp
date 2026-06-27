import 'package:basketball_academy/features/academy/presentation/screens/academy_detail_screen.dart';
import 'package:basketball_academy/features/reports/presentation/screens/reports_screen.dart';
import 'package:basketball_academy/features/academy/presentation/screens/academy_list_screen.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/auth/presentation/screens/account_settings_screen.dart';
import 'package:basketball_academy/features/auth/presentation/screens/login_screen.dart';
import 'package:basketball_academy/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:basketball_academy/features/evaluation/presentation/screens/evaluation_history_screen.dart';
import 'package:basketball_academy/features/notification/presentation/screens/notifications_screen.dart';
import 'package:basketball_academy/features/player/presentation/screens/player_detail_screen.dart';
import 'package:basketball_academy/features/player/presentation/screens/players_list_screen.dart';
import 'package:basketball_academy/features/splash/presentation/screens/splash_screen.dart';
import 'package:basketball_academy/features/subscription/presentation/screens/player_subscription_history_screen.dart';
import 'package:basketball_academy/features/user/presentation/screens/users_list_screen.dart';
import 'package:basketball_academy/features/staff/presentation/screens/staff_list_screen.dart';
import 'package:basketball_academy/features/payroll/presentation/screens/payroll_list_screen.dart';
import 'package:basketball_academy/features/expenses/presentation/screens/expenses_list_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String academyList = '/academies';
  static const String academyDetail = '/academies/:id';
  static const String academyUsers = '/academies/:id/users';
  static const String playersList = '/academies/:id/players';
  static const String playerDetail = '/academies/:id/players/:playerId';
  static const String playerSubscriptions =
      '/academies/:id/players/:playerId/subscriptions';
  static const String playerEvaluations =
      '/academies/:id/players/:playerId/evaluations';
  static const String dashboard = '/dashboard';
  static const String reports = '/reports';
  static const String staffList = '/academies/:id/staff';
  static const String payrollList = '/academies/:id/payroll';
  static const String expensesList = '/academies/:id/expenses';
  static const String notifications = '/notifications';
  static const String accountSettings = '/account-settings';
}

// RouterNotifier يُبلِّغ GoRouter عند تغيّر حالة المصادقة
// بدلاً من إعادة إنشاء GoRouter كل مرة (كان يُسبب عودة Splash)
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    debugPrint('[ROUTER] _RouterNotifier created — GoRouter instance #${identityHashCode(this)}');
    _ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      debugPrint('[ROUTER] authState changed: ${prev.runtimeType} → ${next.runtimeType} | isLoading=${next.isLoading} | isAuthenticated=${next.valueOrNull?.isAuthenticated}');
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final isLoggedIn = authAsync.valueOrNull?.isAuthenticated ?? false;
    final user = authAsync.valueOrNull?.user;
    final loc = state.matchedLocation;

    debugPrint('[ROUTER] redirect() loc=$loc isLoggedIn=$isLoggedIn isLoading=${authAsync.isLoading}');

    if (loc == AppRoutes.splash) return null;
    if (!isLoggedIn && loc != AppRoutes.login) return AppRoutes.login;
    if (isLoggedIn && loc == AppRoutes.login) {
      if (user?.isAdmin == true && user?.academyId != null) {
        return AppRoutes.playersList.replaceFirst(':id', user!.academyId!);
      }
      return AppRoutes.home;
    }
    if (user?.isAdmin == true) {
      final academyId = user?.academyId;
      final allowedPrefixes = [
        '/academies/${academyId ?? ''}/players',
        AppRoutes.notifications,
        AppRoutes.accountSettings,
      ];
      final isAllowed = academyId != null &&
          allowedPrefixes.any((prefix) => loc.startsWith(prefix));
      if (!isAllowed && academyId != null) {
        return AppRoutes.playersList.replaceFirst(':id', academyId);
      }
    }
    return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  debugPrint('[ROUTER] appRouterProvider.build() — GoRouter being CREATED (should happen once)');
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyList,
        builder: (context, state) => const AcademyListScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AcademyDetailScreen(academyId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.academyUsers,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return UsersListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.playersList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return PlayersListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.playerDetail,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          final playerId = state.pathParameters['playerId']!;
          return PlayerDetailScreen(playerId: playerId, academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.playerSubscriptions,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          final playerId = state.pathParameters['playerId']!;
          final playerName =
              state.uri.queryParameters['playerName'] ?? '';
          return PlayerSubscriptionHistoryScreen(
            playerId: playerId,
            academyId: academyId,
            playerName: playerName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.playerEvaluations,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          final playerId = state.pathParameters['playerId']!;
          final playerName =
              state.uri.queryParameters['playerName'] ?? '';
          return EvaluationHistoryScreen(
            playerId: playerId,
            academyId: academyId,
            playerName: playerName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return StaffListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.payrollList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return PayrollListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.expensesList,
        builder: (context, state) {
          final academyId = state.pathParameters['id']!;
          return ExpensesListScreen(academyId: academyId);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountSettings,
        builder: (context, state) => const AccountSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
