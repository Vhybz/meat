import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale_model.dart';
import 'supabase_sale_service.dart';

class SaleHistoryNotifier extends StateNotifier<List<SaleRecord>> {
  final SupabaseSaleService _service;

  SaleHistoryNotifier(this._service) : super([]) {
    loadSales();
  }

  Future<void> loadSales() async {
    try {
      final sales = await _service.getSales();
      state = sales;
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addSale(SaleRecord sale) async {
    try {
      await _service.saveSale(sale);
      state = [sale, ...state];
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateSale(SaleRecord updatedSale) async {
    try {
      await _service.updateSale(updatedSale);
      state = [
        for (final sale in state)
          if (sale.id == updatedSale.id) updatedSale else sale
      ];
    } catch (e) {
      // Handle error
    }
  }
}

final saleServiceProvider = Provider<SupabaseSaleService>((ref) {
  return SupabaseSaleService();
});

final saleHistoryProvider = StateNotifierProvider<SaleHistoryNotifier, List<SaleRecord>>((ref) {
  return SaleHistoryNotifier(ref.watch(saleServiceProvider));
});
