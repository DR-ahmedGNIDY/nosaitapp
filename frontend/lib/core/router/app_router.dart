import 'package:basketball_academy/features/academy/presentation/screens/academy_detail_screen.dart';
import 'package:basketball_academy/features/academy/presentation/screens/academy_list_screen.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/auth/presentation/screens/login_screen.dart';
import 'package:basketball_academy/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:basketball_academy/features/evaluation/presentation/screens/evaluation_history_screen.dart';
import 'package:basketball_academy/features/player/presentation/screens/player_detail_screen.dart';
import 'package:basketball_academy/features/player/presentation/screens/players_list_screen.dart';
import 'package:basketball_academy/features/splash/presentation/screens/splash_screen.dart';
import 'package:basketball_academy/features/subscription/presentation/screens/player_subscription_history_screen.dart';
import 'package:basketball_academy/features/user/presentation/screens/users_list_screen.dart';
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
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
      final loc = state.matchedLocation;

      if (loc == AppRoutes.splash) return null;
      if (!isLoggedIn && loc != AppRoutes.login) return AppRoutes.login;
      if (isLoggedIn && loc == AppRoutes.login) return AppRoutes.home;
      return null;
    },
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
});
