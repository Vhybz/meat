import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale_model.dart';
import 'supabase_sale_service.dart';
import 'user_provider.dart';

class SaleHistoryNotifier extends StateNotifier<List<SaleRecord>> {
  final SupabaseSaleService _service;
  final Ref ref;
  StreamSubscription? _subscription;

  SaleHistoryNotifier(this._service, this.ref) : super([]) {
    _initStream();
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
      // State is updated automatically by stream
    } catch (e) {
      debugPrint('Add Sale Error: $e');
    }
  }

  Future<void> updateSale(SaleRecord updatedSale) async {
    try {
      await _service.updateSale(updatedSale);
      // State is updated automatically by stream
    } catch (e) {
      // Handle error
    }
  }
}

final saleServiceProvider = Provider<SupabaseSaleService>((ref) {
  return SupabaseSaleService();
});

final saleHistoryProvider = StateNotifierProvider<SaleHistoryNotifier, List<SaleRecord>>((ref) {
  return SaleHistoryNotifier(ref.watch(saleServiceProvider), ref);
});
