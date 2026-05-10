import '../models/customer_model.dart';
import '../core/supabase_config.dart';

class SupabaseCustomerService {
  final _client = SupabaseConfig.client;

  Future<List<Customer>> getCustomers() async {
    final response = await _client
        .from('customers')
        .select()
        .order('name', ascending: true);
    
    return (response as List).map((json) => Customer.fromJson(json)).toList();
  }

  Future<void> addCustomer(Customer customer) async {
    await _client.from('customers').insert(customer.toJson());
  }

  Future<void> updateCustomer(Customer customer) async {
    await _client
        .from('customers')
        .update(customer.toJson())
        .eq('id', customer.id);
  }

  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }
}
