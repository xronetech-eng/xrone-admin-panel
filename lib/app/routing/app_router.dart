import 'package:flutter/material.dart';

import '../../core/navigation/navigation_logger.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../features/auth/pages/forgot_password_screen.dart';
import '../../features/auth/pages/login_screen.dart';
import '../../features/auth/widgets/admin_guard.dart';
import '../../features/dashboard/pages/dashboard_screen.dart';
import '../../features/payments/pages/payments_screen.dart';
import '../../features/pilot_management/pages/pilot_management_screen.dart';
import '../../features/pilots/pages/pilots_screen.dart';
import '../../features/settings/pages/settings_screen.dart';
import '../../features/store/pages/store_screen.dart';
import '../../features/tracking/pages/tracking_screen.dart';
import '../../features/users/pages/users_screen.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.dashboard;
    NavigationLogger.source(
      'AppRouter.onGenerateRoute',
      action: 'resolve',
      to: routeName,
    );

    if (routeName == AppRoutes.authLogin) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginScreen(),
      );
    }

    if (routeName == AppRoutes.authForgotPassword) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const ForgotPasswordScreen(),
      );
    }

    if (!AppRoutes.values.contains(routeName)) {
      NavigationLogger.source(
        'AppRouter.onGenerateRoute',
        action: 'unknown-route',
        to: routeName,
      );
      return onUnknownRoute(settings);
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => AdminGuard(
        child: AppPageScaffold(
          initialRoute: routeName,
          routeBuilder: screenForRoute,
        ),
      ),
    );
  }

  static Route<void> onUnknownRoute(RouteSettings settings) {
    NavigationLogger.source(
      'AppRouter.onUnknownRoute',
      action: 'fallback-page-not-found',
      to: settings.name ?? '<null>',
    );

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => AdminGuard(
        child: AppPageScaffold(
          initialRoute: AppRoutes.dashboard,
          routeBuilder: (_) => const EmptyState(
            title: 'Page not found',
            message: 'The requested route is not available.',
          ),
        ),
      ),
    );
  }

  static String titleForRoute(String route) {
    return switch (route) {
      AppRoutes.dashboard => 'Dashboard',
      AppRoutes.users => 'Users',
      AppRoutes.pilots => 'Pilots',
      AppRoutes.pilotManagement => 'Pilot Management',
      AppRoutes.store => 'Store',
      AppRoutes.payments => 'Payments',
      AppRoutes.tracking => 'Tracking',
      AppRoutes.settings => 'Settings',
      _ => 'Xrone Admin',
    };
  }

  static Widget screenForRoute(String route) {
    return switch (route) {
      AppRoutes.dashboard => const DashboardScreen(),
      AppRoutes.users => const UsersScreen(),
      AppRoutes.pilots => const PilotsScreen(),
      AppRoutes.pilotManagement => const PilotManagementScreen(),
      AppRoutes.store => const StoreScreen(),
      AppRoutes.payments => const PaymentsScreen(),
      AppRoutes.tracking => const TrackingScreen(),
      AppRoutes.settings => const SettingsScreen(),
      _ => const EmptyState(
        title: 'Page not found',
        message: 'The requested route is not available.',
      ),
    };
  }
}
