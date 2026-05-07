import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_models.dart';

class TransferNotifier extends StateNotifier<List<StockTransfer>> {
  TransferNotifier() : super([]);

  void addTransfer(StockTransfer transfer) {
    state = [...state, transfer];
  }

  void markAsReceived(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(status: TransferStatus.received)
        else
          t
    ];
  }
}

final transferProvider = StateNotifierProvider<TransferNotifier, List<StockTransfer>>((ref) {
  return TransferNotifier();
});
