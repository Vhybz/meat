import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/supabase_config.dart';

class SupabaseUserService {
  final _client = SupabaseConfig.client;

  Future<List<UserAccount>> getUsers() async {
    final response = await _client
        .from('users')
        .select()
        .eq('is_deleted', false);
    
    return (response as List).map((json) => UserAccount.fromJson(json)).toList();
  }

  Future<void> addUser(UserAccount account) async {
    await _client.from('users').insert(account.toJson());
  }

  Future<void> updateUser(UserAccount account) async {
    await _client
        .from('users')
        .update(account.toJson())
        .eq('id', account.id);
  }

  Future<void> deleteUser(String id) async {
    await _client
        .from('users')
        .update({'is_deleted': true})
        .eq('id', id);
  }

  Future<UserAccount?> getUserById(String id) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', id)
          .single();
      return UserAccount.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<UserAccount?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();
    
    return UserAccount.fromJson(response);
  }

  Future<bool> checkPhoneExists(String phone) async {
    final response = await _client
        .from('users')
        .select('phone')
        .eq('phone', phone)
        .limit(1)
        .maybeSingle();
    
    return response != null;
  }
}
