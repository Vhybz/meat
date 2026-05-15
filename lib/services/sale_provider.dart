import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale_model.dart';
import 'supabase_sale_service.dart';
import 'user_provider.dart';
import 'product_service.dart';

class SaleHistoryNotifier extends StateNotifier<List<SaleRecord>> {
  final SupabaseSaleService _service;
  final Ref ref;
  StreamSubscription? _subscription;

  SaleHistoryNotifier(this._service, this.ref) : super([]) {
    _initStream();
    
    // Background Heartbeat: Auto-refresh data and check for updates every 3 seconds
    ref.listen(liveHeartbeatProvider, (_, __) {
      // Force a list refresh to ensure all financial calculations are re-computed
      state = [...state];
    });
  }

  void _initStream() {
    final user = ref.read(currentUserProvider);
    if (user?.branchCode == null) return;

    _subscription?.cancel();
    _subscription = _service.getSalesStream(user!.branchCode!).listen((sales) {
      state = sales;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadSales() async {
    _initStream();
  }

  Future<void> addSale(SaleRecord sale) async {
    try {
      final user = ref.read(currentUserProvider);
      final saleWithBranch = sale.copyWith(branchCode: user?.branchCode);
      await _service.saveSale(saleWithBranch);
      
      // Subtract items from total stock
      for (final item in sale.items) {
        await ref.read(productsFutureProvider.notifier).updateStock(item.product.id, -item.quantity);
      }

      // State is updated automatically by stream
    } catch (e) {
      debugPrint('Add Sale Error: $e');
    }
  }

  Future<void> updateSale(SaleRecord updatedSale) async {
    try {
      final oldSale = state.firstWhere((s) => s.id == updatedSale.id);
      
      await _service.updateSale(updatedSale);

      // If sale is being cancelled, return items to stock
      if (updatedSale.status == SaleStatus.cancelled && oldSale.status != SaleStatus.cancelled) {
        for (final item in updatedSale.items) {
          await ref.read(productsFutureProvider.notifier).updateStock(item.product.id, item.quantity);
        }
      }
      
      // If sale is being rectified, adjust stock
      if (updatedSale.status == SaleStatus.rectified && oldSale.status != SaleStatus.cancelled) {
        // Return old items
        for (final item in oldSale.items) {
          await ref.read(productsFutureProvider.notifier).updateStock(item.product.id, item.quantity);
        }
        // Subtract new items
        for (final item in updatedSale.items) {
          await ref.read(productsFutureProvider.notifier).updateStock(item.product.id, -item.quantity);
        }
      }
      
      // State is updated automatically by stream
    } catch (e) {
      debugPrint('Update Sale Error: $e');
    }
  }

  Future<void> deleteSales(List<String> ids) async {
    try {
      await _service.deleteSales(ids);
    } catch (e) {
      debugPrint('Delete Sales Error: $e');
      rethrow;
    }
  }
}

final saleServiceProvider = Provider<SupabaseSaleService>((ref) {
  return SupabaseSaleService();
});

final saleHistoryProvider = StateNotifierProvider<SaleHistoryNotifier, List<SaleRecord>>((ref) {
  return SaleHistoryNotifier(ref.watch(saleServiceProvider), ref);
});
