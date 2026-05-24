import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_models.dart';
import 'supabase_transfer_service.dart';
import 'product_service.dart';
import 'notification_service.dart';

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
      
      // Notify System (Local)
      ref.read(notificationProvider.notifier).addNotification(
        'NEW STOCK TRANSFER',
        '${transfer.meatType} (${transfer.weight}kg) sent to branch ${transfer.destination}.',
      );
    } catch (e) {
      debugPrint('Error adding transfer: $e');
    }
  }

  Future<void> addTransfers(List<StockTransfer> transfers) async {
    try {
      for (final t in transfers) {
        await _service.addTransfer(t);
      }
      state = [...transfers, ...state];
      
      // Notify System (Local) - Grouped notification
      if (transfers.isNotEmpty) {
        final totalWeight = transfers.fold(0.0, (sum, t) => sum + t.weight);
        ref.read(notificationProvider.notifier).addNotification(
          'NEW BULK STOCK TRANSFER',
          '${transfers.length} items (${totalWeight.toStringAsFixed(1)}kg) sent to branch ${transfers.first.destination}.',
        );
      }
    } catch (e) {
      debugPrint('Error adding bulk transfers: $e');
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
      
      // Strategy: Extract the cut name (part after first ' - ') and look for it in product names
      String cutToMatch = transfer.meatType;
      String animalType = '';
      if (transfer.meatType.contains(' - ')) {
        final parts = transfer.meatType.split(' - ');
        animalType = parts[0].trim();
        cutToMatch = parts.sublist(1).join(' - ').trim();
      }

      // Robust matching logic
      final product = products.firstWhere(
        (p) {
          final pName = p.name.toLowerCase();
          final mType = transfer.meatType.toLowerCase();
          final cut = cutToMatch.toLowerCase();
          final animal = animalType.toLowerCase();

          return pName == cut || 
                 pName == mType ||
                 pName == '$animal $cut' ||
                 mType.contains(pName) ||
                 pName.contains(cut);
        },
        orElse: () => throw Exception('Product not found in retail catalog for: $cutToMatch'),
      );

      await ref.read(productsFutureProvider.notifier).updateStock(product.id, transfer.weight);

      // Notify System (Local)
      ref.read(notificationProvider.notifier).addNotification(
        'STOCK RECEIVED',
        'Added ${transfer.weight}kg of ${product.name} to inventory.',
      );

      state = [
        for (final t in state)
          if (t.id == id)
            t.copyWith(status: TransferStatus.received)
          else
            t
      ];
    } catch (e) {
      debugPrint('Error marking transfer as received: $e');
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
