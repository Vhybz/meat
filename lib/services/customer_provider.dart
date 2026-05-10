import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import 'supabase_customer_service.dart';

class CustomerNotifier extends StateNotifier<List<Customer>> {
  final SupabaseCustomerService _service;

  CustomerNotifier(this._service) : super([]) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      final customers = await _service.getCustomers();
      state = customers;
    } catch (e) {}
  }

  Future<void> addCustomer(Customer customer) async {
    if (!state.any((c) => c.phone == customer.phone)) {
      try {
        await _service.addCustomer(customer);
        state = [...state, customer];
      } catch (e) {}
    }
  }

  Future<void> toggleFavorite(String id) async {
    final customer = state.firstWhere((c) => c.id == id);
    final updatedCustomer = customer.copyWith(isFavorite: !customer.isFavorite);
    try {
      await _service.updateCustomer(updatedCustomer);
      state = [
        for (final c in state)
          if (c.id == id) updatedCustomer else c
      ];
    } catch (e) {}
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _service.deleteCustomer(id);
      state = state.where((c) => c.id != id).toList();
    } catch (e) {}
  }
}

final customerServiceProvider = Provider<SupabaseCustomerService>((ref) {
  return SupabaseCustomerService();
});

final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier(ref.watch(customerServiceProvider));
});
