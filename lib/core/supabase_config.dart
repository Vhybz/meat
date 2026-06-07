import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      debugPrint('Starting Supabase initialization...');
      
      // Credentials with multiple fallback layers
      String url = const String.fromEnvironment('SUPABASE_URL');
      if (url.isEmpty || url == 'your_url') {
        url = dotenv.env['SUPABASE_URL'] ?? '';
      }
      if (url.isEmpty || url == 'your_url') {
        url = 'https://jdvtktjdyduxpsjrilkp.supabase.co';
      }
          
      String anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
      if (anonKey.isEmpty || anonKey == 'your_key') {
        anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      }
      if (anonKey.isEmpty || anonKey == 'your_key') {
        anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkdnRrdGpkeWR1eHBzanJpbGtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNDQwOTgsImV4cCI6MjA5MzkyMDA5OH0.t74kyocVAXs5oF-3_EEH-E3vUXVkz82NbIVgN6t2jpw';
      }

      debugPrint('Initializing Supabase client...');

      await Supabase.initialize(
        url: url.trim(),
        anonKey: anonKey.trim(),
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          // Disable localStorage on web if it might cause issues in some restricted environments
          // but usually it's required for persistence.
        ),
      );
      
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      if (e.toString().contains('already been initialized')) {
        return;
      }
      debugPrint('Supabase Initialization Error: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
