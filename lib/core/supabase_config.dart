import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      debugPrint('Starting Supabase initialization...');
      
      // 1. Try to load from .env file (Local development)
      try {
        await dotenv.load(fileName: ".env");
        debugPrint('.env file loaded successfully.');
      } catch (e) {
        debugPrint('.env file not found or failed to load: $e');
      }
      
      // 2. Resolve credentials using priority: 
      //    --dart-define > .env file > Hardcoded Defaults (for seamless PC build)
      
      String? url = const String.fromEnvironment('SUPABASE_URL');
      if (url.isEmpty) {
        url = dotenv.env['SUPABASE_URL'] ?? 'https://jdvtktjdyduxpsjrilkp.supabase.co';
      }
          
      String? anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
      if (anonKey.isEmpty) {
        anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkdnRrdGpkeWR1eHBzanJpbGtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNDQwOTgsImV4cCI6MjA5MzkyMDA5OH0.t74kyocVAXs5oF-3_EEH-E3vUXVkz82NbIVgN6t2jpw';
      }

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
      );
      debugPrint('Supabase.initialize() completed for $url');
    } catch (e) {
      debugPrint('CRITICAL: Supabase Init Error: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
