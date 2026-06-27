import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: avoid_print
  print('[Firebase] initialize:start');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ignore: avoid_print
    print('[Firebase] initialize:success');
  } catch (e) {
    // ignore: avoid_print
    print('[Firebase] initialize:error $e');
    rethrow;
  }

  await bootstrap();
}
