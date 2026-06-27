import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/repository/auth_repository.dart';
import '../core/navigation/navigation_logger.dart';
import 'routing/app_router.dart';
import 'routing/app_routes.dart';
import 'theme/app_theme.dart';

class XroneAdminPanelApp extends StatelessWidget {
  const XroneAdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return BlocProvider(
          create: (_) => AuthBloc(repository: AuthRepository()),
          child: MaterialApp(
            title: 'Xrone Admin Panel',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            initialRoute: AppRoutes.authLogin,
            onGenerateInitialRoutes: (initialRouteName) {
              NavigationLogger.source(
                'MaterialApp.onGenerateInitialRoutes',
                action: 'exact-initial-route',
                to: initialRouteName,
              );
              return [
                AppRouter.onGenerateRoute(
                  RouteSettings(name: initialRouteName),
                ),
              ];
            },
            onGenerateRoute: AppRouter.onGenerateRoute,
            onUnknownRoute: AppRouter.onUnknownRoute,
            navigatorObservers: [LoggingNavigatorObserver('root')],
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.noScaling),
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }
}
