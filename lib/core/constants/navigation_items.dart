import 'package:flutter/material.dart';

import '../../app/routing/app_routes.dart';

class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

abstract final class NavigationItems {
  static const values = <NavigationItem>[
    NavigationItem(
      label: 'Dashboard',
      route: AppRoutes.dashboard,
      icon: Icons.dashboard_outlined,
    ),
    NavigationItem(
      label: 'Users',
      route: AppRoutes.users,
      icon: Icons.people_outline,
    ),
    NavigationItem(
      label: 'Pilots',
      route: AppRoutes.pilots,
      icon: Icons.badge_outlined,
    ),
    NavigationItem(
      label: 'Pilot Management',
      route: AppRoutes.pilotManagement,
      icon: Icons.manage_accounts_outlined,
    ),
    NavigationItem(
      label: 'Store',
      route: AppRoutes.store,
      icon: Icons.storefront_outlined,
    ),
    NavigationItem(
      label: 'Payments',
      route: AppRoutes.payments,
      icon: Icons.payments_outlined,
    ),
    NavigationItem(
      label: 'Tracking',
      route: AppRoutes.tracking,
      icon: Icons.location_searching_outlined,
    ),
    NavigationItem(
      label: 'Settings',
      route: AppRoutes.settings,
      icon: Icons.settings_outlined,
    ),
  ];
}
