import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import 'app.dart';

Future<void> bootstrap() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SupabaseConfig.initialize();
      assert(SupabaseConfig.verifyConnection());

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
        return true;
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return const Material(
          color: Colors.white,
          child: Center(
            child: Text('Something went wrong. Please refresh the page.'),
          ),
        );
      };

      runApp(const XroneAdminPanelApp());
    },
    (Object error, StackTrace stack) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }
    },
  );
}
