import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
        throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY is missing from .env file');
      }
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
    } catch (e) {
      debugPrint('Supabase Init Error: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
