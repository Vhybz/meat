import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sale_model.dart';
import 'supabase_sale_service.dart';
import 'user_provider.dart';
import 'product_service.dart';
import 'offline_sync_service.dart';
import 'audit_service.dart';

class SaleHistoryNotifier extends StateNotifier<List<SaleRecord>> {
  final SupabaseSaleService _service;
  final Ref ref;
  StreamSubscription? _subscription;

  SaleHistoryNotifier(this._service, this.ref) : super([]) {
    _init();
    
    // Background Heartbeat: Auto-refresh data and check for updates every 3 seconds
    ref.listen(liveHeartbeatProvider, (_, _) {
      // Force a list refresh to ensure all financial calculations are re-computed
      state = [...state];
    });
  }

  void _init() {
    _loadFromCache();
    _initStream();
  }

  void _loadFromCache() {
    try {
      final box = Hive.box(OfflineSyncService.salesBoxName);
      if (box.isNotEmpty) {
        final List<SaleRecord> cached = box.values
            .map((json) => SaleRecord.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        state = cached;
        debugPrint('Sale Engine: ${cached.length} records loaded from local cache.');
      }
    } catch (e) {
      debugPrint('Sale Engine Cache Error: $e');
    }
  }

  void _saveToCache(List<SaleRecord> sales) {
    try {
      final box = Hive.box(OfflineSyncService.salesBoxName);
      box.clear();
      // Keep only last 100 sales offline to save space
      final toCache = sales.take(100).toList();
      for (var s in toCache) {
        box.put(s.id, s.toJson());
      }
    } catch (e) {
      debugPrint('Sale Engine Save Error: $e');
    }
  }

  void _initStream() {
    final user = ref.read(currentUserProvider);
    if (user?.branchCode == null) return;

    _subscription?.cancel();
    _subscription = _service.getSalesStream(user!.branchCode!).listen((sales) {
      state = sales;
      _saveToCache(sales);
    }, onError: (e) {
      debugPrint('Sale Stream Error (Offline?): Using cached data.');
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
      
      // 1. Add to Offline Queue (Hive) - This ensures data is safe even if network drops
      await OfflineSyncService.addToQueue(
        actionType: 'SALE', 
        data: saleWithBranch.toJson(),
      );

      // 1b. Audit Log
      await AuditService.log(
        ref: ref,
        action: 'SALE_CREATED',
        entityType: 'SALE',
        entityId: saleWithBranch.id,
        newData: saleWithBranch.toJson(),
      );

      // 2. Optimistic UI update: Add to local state immediately
      state = [saleWithBranch, ...state];
      
      // 3. NO LONGER SUBTRACTING STOCK HERE
      // Stock will be subtracted when the sale is VERIFIED.
    } catch (e) {
      debugPrint('Add Sale (Queue) Error: $e');
    }
  }

  Future<void> verifySale(String saleId, {String? bankReceiptUrl, String? bankReceiptId}) async {
    try {
      final sale = state.firstWhere((s) => s.id == saleId);
      if (sale.isVerified) return; // Already verified

      final updatedSale = sale.copyWith(
        isVerified: true, 
        status: SaleStatus.completed,
        bankReceiptUrl: bankReceiptUrl ?? sale.bankReceiptUrl,
        bankReceiptId: bankReceiptId ?? sale.bankReceiptId,
      );
      
      // 1. Update DB
      await _service.updateSale(updatedSale);

      // 1b. Audit Log
      await AuditService.log(
        ref: ref,
        action: 'SALE_VERIFIED',
        entityType: 'SALE',
        entityId: sale.id,
        newData: updatedSale.toJson(),
      );

      // 2. Subtract items from total stock (The user wants this after verification)
      for (final item in sale.items) {
        await ref.read(productsFutureProvider.notifier).updateStock(
          item.product.id, 
          -item.quantity, 
          reason: 'SALE', 
          referenceId: sale.id,
        );
      }
      
      // Notify session listeners
      state = [
        for (final s in state)
          if (s.id == saleId) updatedSale else s
      ];
    } catch (e) {
      debugPrint('Verify Sale Error: $e');
    }
  }

  Future<void> updateSale(SaleRecord updatedSale) async {
    try {
      await _service.updateSale(updatedSale);
      // NOTE: Stock is NOT automatically returned on cancellation or rectification 
      // to ensure stock only increases via verified transfers or manual admin overrides.
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

  Future<void> purgeAllRecords() async {
    try {
      final ids = state.map((s) => s.id).toList();
      await _service.deleteSales(ids);
      state = [];
    } catch (e) {
      debugPrint('Purge Sales Error: $e');
    }
  }
}

final saleServiceProvider = Provider<SupabaseSaleService>((ref) {
  return SupabaseSaleService();
});

final saleHistoryProvider = StateNotifierProvider<SaleHistoryNotifier, List<SaleRecord>>((ref) {
  return SaleHistoryNotifier(ref.watch(saleServiceProvider), ref);
});
