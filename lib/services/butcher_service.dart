import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/butcher_models.dart';
import 'supabase_butcher_service.dart';

import 'user_provider.dart';

class SlaughterLogNotifier extends StateNotifier<AsyncValue<List<SlaughterLog>>> {
  final SupabaseButcherService _service;
  final Ref ref;

  SlaughterLogNotifier(this._service, this.ref) : super(const AsyncValue.loading()) {
    loadLogs();
  }

  Future<void> loadLogs({bool silent = false}) async {
    final branchCode = ref.read(currentUserProvider)?.branchCode;
    if (branchCode == null) {
      if (!silent) state = const AsyncValue.data([]);
      return;
    }
    try {
      if (!silent) state = const AsyncValue.loading();
      final logs = await _service.getSlaughterLogs(branchCode);
      state = AsyncValue.data(logs);
    } catch (e, st) {
      if (!silent) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLog(SlaughterLog log) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned to user');
      final logWithBranch = log.copyWith(branchCode: branchCode);
      await _service.addSlaughterLog(logWithBranch);
      state.whenData((logs) {
        state = AsyncValue.data([logWithBranch, ...logs]);
      });
    } catch (e) {
      debugPrint('Error adding slaughter log: $e');
      rethrow;
    }
  }

  Future<void> updateSlaughterRecord(SlaughterLog log) async {
    try {
      await _service.updateSlaughterLog(log);
      
      // If completed, ensure batch status is updated too
      if (log.status == SlaughterStatus.completed) {
        await _service.updateBatchStatus(log.id, 'processing');
        ref.read(meatBatchesProvider.notifier).loadBatches(silent: true);
      }

      state.whenData((logs) {
        state = AsyncValue.data([
          for (final l in logs)
            if (l.id == log.id) log else l
        ]);
      });
    } catch (e) {
      debugPrint('Error updating slaughter record: $e');
    }
  }

  Future<void> updateStatus(String id, SlaughterStatus status) async {
    try {
      final time = status == SlaughterStatus.completed ? DateTime.now() : null;
      await _service.updateSlaughterStatus(id, status, time: time);
      
      // Real Workflow Logic: If slaughter is completed, make the batch available for processing
      if (status == SlaughterStatus.completed) {
        await _service.updateBatchStatus(id, 'processing');
        // Refresh meat batches list so it appears in the processing screen
        ref.read(meatBatchesProvider.notifier).loadBatches(silent: true);
      }

      state.whenData((logs) {
        state = AsyncValue.data([
          for (final log in logs)
            if (log.id == id) 
              log.copyWith(status: status, slaughterTime: time ?? log.slaughterTime)
            else 
              log
        ]);
      });
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }
}

final butcherServiceProvider = Provider<SupabaseButcherService>((ref) => SupabaseButcherService());

final slaughterLogsProvider = StateNotifierProvider<SlaughterLogNotifier, AsyncValue<List<SlaughterLog>>>((ref) {
  return SlaughterLogNotifier(ref.watch(butcherServiceProvider), ref);
});

class MeatBatchNotifier extends StateNotifier<AsyncValue<List<MeatBatch>>> {
  final SupabaseButcherService _service;
  final Ref ref;

  MeatBatchNotifier(this._service, this.ref) : super(const AsyncValue.loading()) {
    loadBatches();
  }

  Future<void> loadBatches({bool silent = false}) async {
    final branchCode = ref.read(currentUserProvider)?.branchCode;
    if (branchCode == null) {
      if (!silent) state = const AsyncValue.data([]);
      return;
    }
    try {
      if (!silent) state = const AsyncValue.loading();
      final batches = await _service.getActiveBatches(branchCode);
      state = AsyncValue.data(batches);
    } catch (e, st) {
      if (!silent) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBatch(MeatBatch batch) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned to user');
      final batchWithBranch = batch.copyWith(branchCode: branchCode);
      await _service.addMeatBatch(batchWithBranch);
      state.whenData((batches) {
        state = AsyncValue.data([batchWithBranch, ...batches]);
      });
    } catch (e) {
      debugPrint('Error adding meat batch: $e');
      rethrow;
    }
  }

  Future<void> closeBatch(String id) async {
    try {
      await _service.updateBatchStatus(id, 'completed');
      state.whenData((batches) {
        state = AsyncValue.data(batches.where((b) => b.id != id).toList());
      });
    } catch (e) {
      debugPrint('Error closing batch: $e');
    }
  }
}

final activeBatchesProvider = StateNotifierProvider<MeatBatchNotifier, AsyncValue<List<MeatBatch>>>((ref) {
  return MeatBatchNotifier(ref.watch(butcherServiceProvider), ref);
});

final meatBatchesProvider = activeBatchesProvider;

class MeatCutNotifier extends StateNotifier<AsyncValue<List<MeatCut>>> {
  final SupabaseButcherService _service;
  final Ref ref;

  MeatCutNotifier(this._service, this.ref) : super(const AsyncValue.loading()) {
    loadCuts();
  }

  Future<void> loadCuts({bool silent = false}) async {
    final branchCode = ref.read(currentUserProvider)?.branchCode;
    if (branchCode == null) {
      if (!silent) state = const AsyncValue.data([]);
      return;
    }
    try {
      if (!silent) state = const AsyncValue.loading();
      final cuts = await _service.getRecentCuts(branchCode);
      state = AsyncValue.data(cuts);
    } catch (e, st) {
      if (!silent) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCut(MeatCut cut) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned to user');
      final cutWithBranch = cut.copyWith(branchCode: branchCode);
      await _service.addMeatCut(cutWithBranch);
      state.whenData((cuts) {
        state = AsyncValue.data([cutWithBranch, ...cuts]);
      });
    } catch (e) {
      debugPrint('Error adding meat cut: $e');
      rethrow;
    }
  }

  Future<void> addCuts(List<MeatCut> cuts) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned to user');
      
      final cutsWithBranch = cuts.map((c) => c.copyWith(branchCode: branchCode)).toList();
      for (var cut in cutsWithBranch) {
        await _service.addMeatCut(cut);
      }
      
      state.whenData((currentCuts) {
        state = AsyncValue.data([...cutsWithBranch, ...currentCuts]);
      });
    } catch (e) {
      debugPrint('Error adding multiple cuts: $e');
      rethrow;
    }
  }
}

final recentCutsProvider = StateNotifierProvider<MeatCutNotifier, AsyncValue<List<MeatCut>>>((ref) {
  return MeatCutNotifier(ref.watch(butcherServiceProvider), ref);
});

class ButcherWasteNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final SupabaseButcherService _service;
  final Ref ref;

  ButcherWasteNotifier(this._service, this.ref) : super(const AsyncValue.loading()) {
    loadWaste();
  }

  Future<void> loadWaste({bool silent = false}) async {
    final branchCode = ref.read(currentUserProvider)?.branchCode;
    if (branchCode == null) {
      if (!silent) state = const AsyncValue.data([]);
      return;
    }
    try {
      if (!silent) state = const AsyncValue.loading();
      final waste = await _service.getWaste(branchCode);
      state = AsyncValue.data(waste);
    } catch (e, st) {
      if (!silent) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWaste(String batchId, String reason, double weight) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      final code = branchCode ?? 'GLOBAL';
      await _service.addWaste(code, batchId, reason, weight);
      loadWaste(silent: true); // Refresh silently
    } catch (e) {
      debugPrint('Error adding waste: $e');
    }
  }
}

final butcherWasteProvider = StateNotifierProvider<ButcherWasteNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ButcherWasteNotifier(ref.watch(butcherServiceProvider), ref);
});

class ButcherOrderNotifier extends StateNotifier<AsyncValue<List<ButcherOrder>>> {
  final SupabaseButcherService _service;
  final Ref ref;

  ButcherOrderNotifier(this._service, this.ref) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders({bool silent = false}) async {
    final branchCode = ref.read(currentUserProvider)?.branchCode;
    if (branchCode == null) {
      if (!silent) state = const AsyncValue.data([]);
      return;
    }
    try {
      if (!silent) state = const AsyncValue.loading();
      final orders = await _service.getButcherOrders(branchCode);
      state = AsyncValue.data(orders);
    } catch (e, st) {
      // For demo/offline, let's provide some mock data if it fails
      if (!silent) state = AsyncValue.data(_getMockOrders());
    }
  }

  List<ButcherOrder> _getMockOrders() {
    return [
      ButcherOrder(
        id: 'MS-ORD-101',
        customerName: 'Prime Steakhouse Inc.',
        items: ['Beef Sirloin (10kg)', 'Pork Ribs (5kg)'],
        totalWeight: 15.0,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: ButcherOrderStatus.preparing,
      ),
      ButcherOrder(
        id: 'MS-ORD-102',
        customerName: 'City Grill',
        items: ['Chicken Wings (20kg)', 'Whole Chicken (10)'],
        totalWeight: 32.5,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        status: ButcherOrderStatus.pending,
      ),
    ];
  }

  Future<void> updateStatus(String id, ButcherOrderStatus status) async {
    try {
      await _service.updateButcherOrderStatus(id, status);
      state.whenData((orders) {
        state = AsyncValue.data([
          for (final order in orders)
            if (order.id == id) order.copyWith(status: status) else order
        ]);
      });
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }
}

final butcherOrdersProvider = StateNotifierProvider<ButcherOrderNotifier, AsyncValue<List<ButcherOrder>>>((ref) {
  return ButcherOrderNotifier(ref.watch(butcherServiceProvider), ref);
});
