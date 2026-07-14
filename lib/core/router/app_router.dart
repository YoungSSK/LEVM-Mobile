import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import 'app_routes.dart';
import 'route_names.dart';

/// Bridges a Riverpod auth state change into a [Listenable] so GoRouter can
/// refresh its `redirect` when the user logs in or out.
///
/// Riverpod 3.x's [Listenable] api doesn't fire automatically on state changes,
/// so we provide a tiny pub/sub (RefreshBridge) that's nudged by `main.dart`.
class GoRouterRefreshNotifier extends ChangeNotifier implements Listenable {
  GoRouterRefreshNotifier() {
    RefreshBridge.instance.attach(this);
  }

  /// Test-friendly hook: external listeners can call this to nudge GoRouter.
  void pub() => notifyListeners();
}

class RefreshBridge {
  RefreshBridge._();
  static final RefreshBridge instance = RefreshBridge._();

  GoRouterRefreshNotifier? _target;

  void attach(GoRouterRefreshNotifier target) {
    _target = target;
  }

  void notifyRouter() => _target?.pub();
}

class AppRouter {
  AppRouter._();

  static GoRouter build() {
    return GoRouter(
      initialLocation: AppRoutes.login,
      refreshListenable: GoRouterRefreshNotifier(),
      redirect: (context, state) {
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          name: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: RouteNames.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: RouteNames.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: RouteNames.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          name: RouteNames.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.changePassword,
          name: RouteNames.changePassword,
          builder: (context, state) => const ChangePasswordScreen(),
        ),
      ],
    );
  }
}
