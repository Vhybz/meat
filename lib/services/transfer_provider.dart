import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_models.dart';
import 'supabase_transfer_service.dart';
import 'product_service.dart';

class TransferNotifier extends StateNotifier<List<StockTransfer>> {
  final SupabaseTransferService _service;
  final Ref ref;

  TransferNotifier(this._service, this.ref) : super([]) {
    loadTransfers();
  }

  Future<void> loadTransfers() async {
    try {
      final transfers = await _service.getTransfers();
      if (state.length != transfers.length || state.toString() != transfers.toString()) {
        state = transfers;
      }
    } catch (e) {
      // Log error
    }
  }

  Future<void> addTransfer(StockTransfer transfer) async {
    try {
      await _service.addTransfer(transfer);
      state = [transfer, ...state];
    } catch (e) {
      // Log error
    }
  }

  Future<void> markAsReceived(String id) async {
    try {
      final transfer = state.firstWhere((t) => t.id == id);
      await _service.updateTransferStatus(id, TransferStatus.received);
      
      // Update Retail Stock
      final productsAsync = ref.read(productsFutureProvider);
      final products = productsAsync.value;
      
      if (products == null) throw Exception('Products not loaded yet');
      
      // Strategy: Extract the cut name (part after ' - ') and look for it in product names
      String cutToMatch = transfer.meatType;
      if (transfer.meatType.contains(' - ')) {
        cutToMatch = transfer.meatType.split(' - ')[1].trim();
      }

      final product = products.firstWhere(
        (p) => p.name.toLowerCase() == cutToMatch.toLowerCase() || 
               transfer.meatType.toLowerCase().contains(p.name.toLowerCase()),
        orElse: () => throw Exception('Product not found in retail catalog for: $cutToMatch'),
      );

      await ref.read(productsFutureProvider.notifier).updateStock(product.id, transfer.weight);

      state = [
        for (final t in state)
          if (t.id == id)
            t.copyWith(status: TransferStatus.received)
          else
            t
      ];
    } catch (e) {
      rethrow;
    }
  }
}

final transferServiceProvider = Provider<SupabaseTransferService>((ref) {
  return SupabaseTransferService();
});

final transferProvider = StateNotifierProvider<TransferNotifier, List<StockTransfer>>((ref) {
  return TransferNotifier(ref.watch(transferServiceProvider), ref);
});
