import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseConfig {
  static const url = 'https://fcitzuumiszlsrxfomlr.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZjaXR6dXVtaXN6bHNyeGZvbWxyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ1Mzg4MjQsImV4cCI6MjA1MDExNDgyNH0.'
      'rc4ronwa8kNqgBe9QFD7z9OtPvURJY1LZYJsqTckEa0';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static bool verifyConnection() {
    try {
      final projectUri = Uri.parse(url);

      return Supabase.instance.isInitialized &&
          projectUri.scheme == 'https' &&
          projectUri.host == 'fcitzuumiszlsrxfomlr.supabase.co';
    } on Object {
      return false;
    }
  }
}
