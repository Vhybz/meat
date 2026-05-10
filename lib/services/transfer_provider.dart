import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_models.dart';
import 'supabase_transfer_service.dart';

class TransferNotifier extends StateNotifier<List<StockTransfer>> {
  final SupabaseTransferService _service;

  TransferNotifier(this._service) : super([]) {
    loadTransfers();
  }

  Future<void> loadTransfers() async {
    try {
      final transfers = await _service.getTransfers();
      state = transfers;
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
      await _service.updateTransferStatus(id, TransferStatus.received);
      state = [
        for (final t in state)
          if (t.id == id)
            t.copyWith(status: TransferStatus.received)
          else
            t
      ];
    } catch (e) {
      // Log error
    }
  }
}

final transferServiceProvider = Provider<SupabaseTransferService>((ref) {
  return SupabaseTransferService();
});

final transferProvider = StateNotifierProvider<TransferNotifier, List<StockTransfer>>((ref) {
  return TransferNotifier(ref.watch(transferServiceProvider));
});
