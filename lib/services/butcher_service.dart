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

  Future<void> loadLogs() async {
    try {
      state = const AsyncValue.loading();
      final user = ref.read(currentUserProvider);
      if (user == null || user.branchCode == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final logs = await _service.getSlaughterLogs(user.branchCode!);
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLog(SlaughterLog log) async {
    try {
      final user = ref.read(currentUserProvider);
      final logWithBranch = log.copyWith(branchCode: user?.branchCode);
      await _service.addSlaughterLog(logWithBranch);
      state.whenData((logs) {
        state = AsyncValue.data([logWithBranch, ...logs]);
      });
    } catch (e) {
      debugPrint('Error adding slaughter log: $e');
    }
  }

  Future<void> updateStatus(String id, SlaughterStatus status) async {
    try {
      final time = status == SlaughterStatus.completed ? DateTime.now() : null;
      await _service.updateSlaughterStatus(id, status, time: time);
      
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

  Future<void> loadBatches() async {
    try {
      state = const AsyncValue.loading();
      final user = ref.read(currentUserProvider);
      if (user == null || user.branchCode == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final batches = await _service.getActiveBatches(user.branchCode!);
      state = AsyncValue.data(batches);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBatch(MeatBatch batch) async {
    try {
      final user = ref.read(currentUserProvider);
      final batchWithBranch = batch.copyWith(branchCode: user?.branchCode);
      await _service.addMeatBatch(batchWithBranch);
      state.whenData((batches) {
        state = AsyncValue.data([batchWithBranch, ...batches]);
      });
    } catch (e) {
      debugPrint('Error adding meat batch: $e');
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

  Future<void> loadCuts() async {
    try {
      state = const AsyncValue.loading();
      final user = ref.read(currentUserProvider);
      if (user == null || user.branchCode == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final cuts = await _service.getRecentCuts(user.branchCode!);
      state = AsyncValue.data(cuts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCut(MeatCut cut) async {
    try {
      final user = ref.read(currentUserProvider);
      final cutWithBranch = cut.copyWith(branchCode: user?.branchCode);
      await _service.addMeatCut(cutWithBranch);
      state.whenData((cuts) {
        state = AsyncValue.data([cutWithBranch, ...cuts]);
      });
    } catch (e) {
      debugPrint('Error adding meat cut: $e');
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

  Future<void> loadWaste() async {
    try {
      state = const AsyncValue.loading();
      final user = ref.read(currentUserProvider);
      if (user == null || user.branchCode == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final waste = await _service.getWaste(user.branchCode!);
      state = AsyncValue.data(waste);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWaste(String batchId, String reason, double weight) async {
    try {
      final user = ref.read(currentUserProvider);
      await _service.addWaste(user?.branchCode ?? 'GLOBAL', batchId, reason, weight);
      loadWaste(); // Refresh
    } catch (e) {
      debugPrint('Error adding waste: $e');
    }
  }
}

final butcherWasteProvider = StateNotifierProvider<ButcherWasteNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ButcherWasteNotifier(ref.watch(butcherServiceProvider), ref);
});
