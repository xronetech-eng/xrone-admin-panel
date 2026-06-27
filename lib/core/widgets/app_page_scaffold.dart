import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/routing/app_routes.dart';

import '../constants/app_spacing.dart';
import '../navigation/navigation_logger.dart';
import '../responsive/responsive_helper.dart';

import 'sidebar_foundation.dart';

typedef RouteWidgetBuilder = Widget Function(String route);

class AppPageScaffold extends StatefulWidget {
  const AppPageScaffold({
    required this.initialRoute,
    required this.routeBuilder,
    super.key,
  });

  final String initialRoute;
  final RouteWidgetBuilder routeBuilder;

  @override
  State<AppPageScaffold> createState() => _AppPageScaffoldState();
}

class _AppPageScaffoldState extends State<AppPageScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _contentNavigatorKey = GlobalKey<NavigatorState>();
  late final ValueNotifier<String> _selectedRoute;
  late final Widget _desktopSidebar;
  late final Widget _tabletSidebar;

  @override
  void initState() {
    super.initState();
    _selectedRoute = ValueNotifier<String>(widget.initialRoute);
    _desktopSidebar = SidebarFoundation(
      selectedRouteListenable: _selectedRoute,
      onRouteSelected: _selectRoute,
    );
    _tabletSidebar = SidebarFoundation(
      selectedRouteListenable: _selectedRoute,
      onRouteSelected: _selectRoute,
      isCollapsed: true,
    );
  }

  @override
  void dispose() {
    _selectedRoute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showDesktopSidebar = ResponsiveHelper.isDesktop(context);
    final showTabletSidebar = ResponsiveHelper.isTablet(context);
    final showMobileDrawer = ResponsiveHelper.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: showMobileDrawer
          ? Drawer(
              width: 304.w,
              child: SidebarFoundation(
                selectedRouteListenable: _selectedRoute,
                onRouteSelected: (route) {
                  NavigationLogger.source(
                    'AppPageScaffold.mobileDrawer',
                    action: 'pop-drawer',
                    to: route,
                  );
                  Navigator.of(context).pop();
                  _selectRoute(route);
                },
              ),
            )
          : null,

      body: Row(
        children: [
          if (showDesktopSidebar) _desktopSidebar,
          if (showTabletSidebar) _tabletSidebar,
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveHelper.value<double>(
                  context,
                  mobile: AppSpacing.md,
                  tablet: AppSpacing.lg,
                  desktop: AppSpacing.xl,
                ),
              ),
              child: Navigator(
                key: _contentNavigatorKey,
                initialRoute: widget.initialRoute,
                onGenerateRoute: _onGenerateContentRoute,
                observers: [LoggingNavigatorObserver('content')],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Route<void> _onGenerateContentRoute(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.dashboard;
    final resolvedRoute = AppRoutes.values.contains(routeName)
        ? routeName
        : AppRoutes.dashboard;
    NavigationLogger.source(
      'AppPageScaffold.contentRoute',
      action: routeName == resolvedRoute ? 'resolve' : 'fallback-dashboard',
      from: routeName,
      to: resolvedRoute,
    );

    return PageRouteBuilder<void>(
      settings: RouteSettings(name: resolvedRoute),
      pageBuilder: (context, animation, secondaryAnimation) {
        return widget.routeBuilder(resolvedRoute);
      },
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  void _selectRoute(String route) {
    if (_selectedRoute.value == route) {
      NavigationLogger.source(
        'AppPageScaffold._selectRoute',
        action: 'ignore-selected',
        to: route,
      );
      return;
    }

    NavigationLogger.source(
      'AppPageScaffold._selectRoute',
      action: 'pushReplacementNamed',
      from: _selectedRoute.value,
      to: route,
    );
    _selectedRoute.value = route;
    _contentNavigatorKey.currentState?.pushReplacementNamed(route);
  }
}
