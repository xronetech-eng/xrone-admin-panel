import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class NavigationLogger {
  static void source(
    String source, {
    required String action,
    String? from,
    String? to,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      '[Navigation] source=$source action=$action'
      '${from == null ? '' : ' from=$from'}'
      '${to == null ? '' : ' to=$to'}',
    );
  }

  static String routeName(Route<dynamic>? route) {
    return route?.settings.name ?? '<unnamed>';
  }
}

class LoggingNavigatorObserver extends NavigatorObserver {
  LoggingNavigatorObserver(this.scope);

  final String scope;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationLogger.source(
      '$scope NavigatorObserver',
      action: 'push',
      from: NavigationLogger.routeName(previousRoute),
      to: NavigationLogger.routeName(route),
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    NavigationLogger.source(
      '$scope NavigatorObserver',
      action: 'replace',
      from: NavigationLogger.routeName(oldRoute),
      to: NavigationLogger.routeName(newRoute),
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationLogger.source(
      '$scope NavigatorObserver',
      action: 'pop',
      from: NavigationLogger.routeName(route),
      to: NavigationLogger.routeName(previousRoute),
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationLogger.source(
      '$scope NavigatorObserver',
      action: 'remove',
      from: NavigationLogger.routeName(route),
      to: NavigationLogger.routeName(previousRoute),
    );
  }
}
