import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale_model.dart';

class SaleHistoryNotifier extends StateNotifier<List<SaleRecord>> {
  SaleHistoryNotifier() : super([]);

  void addSale(SaleRecord sale) {
    state = [sale, ...state];
  }

  void updateSale(SaleRecord updatedSale) {
    state = [
      for (final sale in state)
        if (sale.id == updatedSale.id) updatedSale else sale
    ];
  }
}

final saleHistoryProvider = StateNotifierProvider<SaleHistoryNotifier, List<SaleRecord>>((ref) {
  return SaleHistoryNotifier();
});
