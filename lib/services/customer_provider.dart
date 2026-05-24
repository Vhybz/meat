import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer_model.dart';
import 'supabase_customer_service.dart';
import 'user_provider.dart';
import 'branch_provider.dart';
import 'sms_service.dart';
import 'offline_sync_service.dart';

class CustomerNotifier extends StateNotifier<List<Customer>> {
  final SupabaseCustomerService _service;
  final Ref ref;

  CustomerNotifier(this._service, this.ref) : super([]) {
    _init();
  }

  void _init() {
    _loadFromCache();
    loadCustomers();
  }

  void _loadFromCache() {
    try {
      final box = Hive.box(OfflineSyncService.customersBoxName);
      if (box.isNotEmpty) {
        final List<Customer> cached = box.values
            .map((json) => Customer.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        state = cached;
        debugPrint('Customer Engine: ${cached.length} customers loaded from local cache.');
      }
    } catch (e) {
      debugPrint('Customer Engine Cache Error: $e');
    }
  }

  void _saveToCache(List<Customer> customers) {
    try {
      final box = Hive.box(OfflineSyncService.customersBoxName);
      box.clear();
      for (var c in customers) {
        box.put(c.id, c.toJson());
      }
    } catch (e) {
      debugPrint('Customer Engine Save Error: $e');
    }
  }

  Future<void> loadCustomers() async {
    try {
      final user = ref.read(currentUserProvider);
      final customers = await _service.getCustomers(user?.branchCode ?? '');
      if (state.length != customers.length || state.toString() != customers.toString()) {
        state = customers;
        _saveToCache(customers);
      }
    } catch (e) {
      debugPrint('Error loading customers (Offline?): $e');
    }
  }

  Future<Customer?> addCustomer(Customer customer) async {
    try {
      final user = ref.read(currentUserProvider);
      
      // Check if already in list to avoid duplicates before saving
      final existing = state.where((c) => c.phone == customer.phone).firstOrNull;
      if (existing != null) {
        debugPrint('Customer with phone ${customer.phone} already exists in local state.');
        return existing;
      }

      final customerWithBranch = customer.copyWith(branchCode: user?.branchCode);
      final savedCustomer = await _service.addCustomer(customerWithBranch);
      
      state = [...state, savedCustomer];
      
      // Send Welcome SMS
      final currentBranch = ref.read(currentBranchProvider);
      
      await SmsService.sendCustomerWelcomeSms(
        savedCustomer.name, 
        savedCustomer.phone, 
        currentBranch?.name
      );
      
      return savedCustomer;
    } catch (e) {
      debugPrint('Error adding customer: $e');
      rethrow;
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

  Future<void> awardLoyaltyPoints(String customerId, double amount) async {
    try {
      final customer = state.firstWhere((c) => c.id == customerId);
      // Award 1 point per ₵10 spent (customize as needed)
      final pointsEarned = amount / 10.0;
      final updatedCustomer = customer.copyWith(
        loyaltyPoints: customer.loyaltyPoints + pointsEarned,
        visitCount: customer.visitCount + 1,
      );
      
      await _service.updateCustomer(updatedCustomer);
      state = [
        for (final c in state)
          if (c.id == customerId) updatedCustomer else c
      ];
    } catch (e) {
      debugPrint('Error awarding points: $e');
    }
  }
}

final customerServiceProvider = Provider<SupabaseCustomerService>((ref) {
  return SupabaseCustomerService();
});

final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier(ref.watch(customerServiceProvider), ref);
});
