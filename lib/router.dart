import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'main.dart';
import 'pages/auth/login_page.dart';
import 'pages/daily_control_pages.dart';

GoRouter buildAppRouter({required AuthController auth}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.isInitialized) {
        return null;
      }
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!auth.isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }
      return isAuthRoute ? '/' : null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeMindShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: HomeOverviewPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scenes',
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: ScenesPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/devices',
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: DevicesPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                pageBuilder: (_, _) => NoTransitionPage(child: ProfilePage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
