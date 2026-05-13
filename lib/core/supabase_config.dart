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
        debugPrint('.env file loaded.');
      } catch (e) {
        debugPrint('.env file not found or failed to load. Proceeding with environment variables.');
      }
      
      // 2. Priority: --dart-define (Production/Netlify) > .env file
      String? url = const String.fromEnvironment('SUPABASE_URL');
      if (url.isEmpty) {
        url = dotenv.env['SUPABASE_URL'];
      }
          
      String? anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
      if (anonKey.isEmpty) {
        anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      }

      debugPrint('Supabase URL: ${url != null ? "Found (masked)" : "NOT FOUND"}');
      debugPrint('Supabase Anon Key: ${anonKey != null ? "Found (masked)" : "NOT FOUND"}');

      if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
        throw Exception('Configuration Error: SUPABASE_URL and SUPABASE_ANON_KEY must be provided via .env or --dart-define');
      }
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      debugPrint('Supabase.initialize() completed.');
    } catch (e) {
      debugPrint('CRITICAL: Supabase Init Error: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
