import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_system_service.dart';
import 'user_provider.dart';
import '../models/system_models.dart';

final systemServiceProvider = Provider<SupabaseSystemService>((ref) {
  return SupabaseSystemService();
});

final auditLogProvider = FutureProvider<List<AuditLog>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(systemServiceProvider).getAuditLogs(user.branchCode ?? '');
});

final notificationsFutureProvider = FutureProvider<List<SystemNotification>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(systemServiceProvider).getNotifications(user.branchCode ?? '', user.id);
});

final customerPaymentsProvider = FutureProvider.family<List<CustomerPayment>, String>((ref, customerId) async {
  return ref.watch(systemServiceProvider).getCustomerPayments(customerId);
});

final stockHistoryProvider = FutureProvider.family<List<StockHistory>, String>((ref, productId) async {
  return ref.watch(systemServiceProvider).getStockHistory(productId);
});
