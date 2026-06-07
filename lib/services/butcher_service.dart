import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/butcher_models.dart';
import 'supabase_butcher_service.dart';
import 'user_provider.dart';
import 'offline_sync_service.dart';
import 'audit_service.dart';

class SlaughterLogNotifier extends StateNotifier<AsyncValue<List<SlaughterLog>>> {
  final SupabaseButcherService _service;
  final Ref ref;
  
  // Track IDs of items that were added locally but not yet confirmed by the server
  final Set<String> _pendingSyncIds = {};
  final List<SlaughterLog> _localItems = [];
  
  // NEW: Track local status overrides to prevent "reverting" UI during sync
  final Map<String, SlaughterStatus> _statusOverrides = {};

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
      if (!silent && !state.hasValue) state = const AsyncValue.loading();
      
      final remoteLogs = await _service.getSlaughterLogs(branchCode);
      
      // Cleanup: Remove local items that are now present in the remote list
      final remoteIds = remoteLogs.map((l) => l.id).toSet();
      final remoteTags = remoteLogs.map((l) => l.tagNumber).whereType<String>().toSet();
      
      _pendingSyncIds.removeWhere((id) => remoteIds.contains(id));
      _localItems.removeWhere((l) => remoteIds.contains(l.id) || (l.tagNumber != null && remoteTags.contains(l.tagNumber)));
      
      // Apply status overrides to remote logs to prevent UI flickering/reverting
      // Priority: local override > server status
      final mergedLogs = remoteLogs.map((log) {
        if (_statusOverrides.containsKey(log.id)) {
          final localStatus = _statusOverrides[log.id]!;
          
          // If the server has reached or passed our local status, we can clear the override
          // Logic: processed (4) > completed (3) > cleaned (2) > slaughtering (1) > pending (0)
          if (log.status.index >= localStatus.index) {
            _statusOverrides.remove(log.id);
            return log;
          }
          
          // Otherwise, stay locked to the local status for UI consistency
          return log.copyWith(status: localStatus);
        }
        return log;
      }).toList();

      state = AsyncValue.data([..._localItems, ...mergedLogs]);
    } catch (e) {
      if (!silent) state = AsyncValue.error(e, StackTrace.current);
      debugPrint('Load Logs Error: $e');
    }
  }

  Future<void> addLog(SlaughterLog log) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned to user');
      final logWithBranch = log.copyWith(branchCode: branchCode);
      
      // 1. Add to Offline Queue (Hive)
      await OfflineSyncService.addToQueue(
        actionType: 'INTAKE', 
        data: logWithBranch.toJson(),
      );

      // 1b. Audit Log
      await AuditService.log(
        ref: ref, 
        action: 'INTAKE_CREATED', 
        entityType: 'SLAUGHTER_LOG', 
        entityId: logWithBranch.id,
        newData: logWithBranch.toJson(),
      );

      // 2. Track locally
      _pendingSyncIds.add(logWithBranch.id);
      _localItems.insert(0, logWithBranch);

      // 3. Update state immediately
      final currentData = state.value ?? [];
      state = AsyncValue.data([..._localItems, ...currentData.where((l) => !_pendingSyncIds.contains(l.id))]);
    } catch (e) {
      debugPrint('Error adding slaughter log (Queue): $e');
    }
  }

  Future<void> queueAnimalRecord({
    required String animalUuid,
    required String tagNumber,
    String? manualFarmTag,
    required AnimalType type,
    required double weight,
    double? price,
    double? farmPrice,
    required String sourceFarm,
    required String branchCode,
  }) async {
    final Map<String, dynamic> animalData = {
      'id': animalUuid,
      'tag_number': tagNumber,
      'manual_farm_tag': manualFarmTag,
      'branch_code': branchCode,
      'type': type.name,
      'weight': weight,
      'purchase_price': farmPrice ?? price, // Map to purchase_price in DB
      'source_farm': sourceFarm,
      'status': 'waiting',
      'arrival_time': DateTime.now().toIso8601String(),
    };

    await OfflineSyncService.addToQueue(
      actionType: 'ANIMAL',
      data: animalData,
    );
  }

  Future<void> updateStatus(String id, SlaughterStatus status) async {
    try {
      final logs = state.value ?? [];
      final logIndex = logs.indexWhere((l) => l.id == id);
      if (logIndex == -1) return;
      
      final log = logs[logIndex];
      // Set time for both 'slaughtering' and 'completed' to ensure they sort correctly
      final time = (status == SlaughterStatus.slaughtering || status == SlaughterStatus.completed) 
          ? DateTime.now() 
          : log.slaughterTime;
      
      final updatedLog = log.copyWith(
        status: status,
        slaughterTime: time,
      );

      // 1. Record override to prevent sync reverting the UI
      _statusOverrides[id] = status;
      debugPrint('State Lock: Animal $id status manually set to ${status.name}');

      // 2. Add to Offline Queue (Update)
      await OfflineSyncService.addToQueue(
        actionType: 'UPDATE_SLAUGHTER',
        data: updatedLog.toJson(),
      );

      // 3. Update state immediately (Local state takes precedence)
      state = AsyncValue.data([
        for (final l in (state.value ?? []))
          if (l.id == id) updatedLog else l
      ]);
      
      // 4. Manual refresh after a short delay to confirm with server
      Future.delayed(const Duration(seconds: 2), () => loadLogs(silent: true));

      // 5. Special handling for completion
      if (status == SlaughterStatus.completed) {
        ref.read(meatBatchesProvider.notifier).loadBatches(silent: true);
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  Future<void> updateSlaughterRecord(SlaughterLog log) async {
    try {
      // Record override for this log too
      _statusOverrides[log.id] = log.status;

      // 1. Add to Offline Queue (Update)
      await OfflineSyncService.addToQueue(
        actionType: 'UPDATE_SLAUGHTER', 
        data: log.toJson(),
      );

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
    } catch (e) {
      if (!silent) state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addBatch(MeatBatch batch) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned to user');
      final batchWithBranch = batch.copyWith(branchCode: branchCode);
      
      // 1. Add to Offline Queue
      await OfflineSyncService.addToQueue(
        actionType: 'CREATE_BATCH', 
        data: batchWithBranch.toJson(),
      );

      // 1b. Audit Log
      await AuditService.log(
        ref: ref,
        action: 'BATCH_CREATED',
        entityType: 'MEAT_BATCH',
        entityId: batchWithBranch.id,
        newData: batchWithBranch.toJson(),
      );

      // 2. Optimistic Update
      state.whenData((batches) {
        state = AsyncValue.data([batchWithBranch, ...batches]);
      });
    } catch (e) {
      debugPrint('Error adding meat batch: $e');
    }
  }

  Future<void> receiveCarcass(SlaughterLog log, String receivedBy) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned');

      final currentBatches = state.value ?? [];
      final existingBatch = currentBatches.firstWhere((b) => b.id == log.id, 
        orElse: () => MeatBatch(
          id: log.id,
          branchCode: branchCode,
          animalId: log.animalId,
          meatType: log.type.displayName,
          weight: log.meatWeight,
          costPrice: log.farmPrice ?? 0.0,
          createdAt: DateTime.now(),
          status: 'transporting',
          source: BatchSource(name: 'Direct Slaughter', location: branchCode, owner: 'Mi~Corazon'),
        )
      );

      final updatedBatch = existingBatch.copyWith(
        status: MeatBatchStatus.preparing.name,
        receivedBy: receivedBy,
      );

      // 1. Mark the animal as "Processed" in the slaughter log
      final updatedLog = log.copyWith(status: SlaughterStatus.processed);
      await OfflineSyncService.addToQueue(
        actionType: 'UPDATE_SLAUGHTER', 
        data: updatedLog.toJson(),
      );

      // 2. Update the Meat Batch status to "preparing"
      await OfflineSyncService.addToQueue(
        actionType: 'UPDATE_BATCH', 
        data: updatedBatch.toJson(),
      );

      // 3. Optimistic Update local state
      state = AsyncValue.data([
        for (final b in currentBatches)
          if (b.id == log.id) updatedBatch else b
      ]);
      
      // If it wasn't in the list yet (rare case), add it
      if (!currentBatches.any((b) => b.id == log.id)) {
        state = AsyncValue.data([updatedBatch, ...currentBatches]);
      }

      // Update the slaughter logs state locally
      ref.read(slaughterLogsProvider.notifier).loadLogs(silent: true);
    } catch (e) {
      debugPrint('Error receiving carcass: $e');
    }
  }

  Future<void> updateBatchProcessingStatus(String id, MeatBatchStatus status) async {
    try {
      final batches = state.value ?? [];
      final batch = batches.firstWhere((b) => b.id == id);
      final updatedBatch = batch.copyWith(status: status.name);

      // 1. Add to Offline Queue
      await OfflineSyncService.addToQueue(
        actionType: 'UPDATE_BATCH',
        data: updatedBatch.toJson(),
      );

      // 2. Immediate State Update
      state = AsyncValue.data([
        for (final b in batches)
          if (b.id == id) updatedBatch else b
      ]);
    } catch (e) {
      debugPrint('Error updating batch status: $e');
    }
  }

  Future<void> closeBatch(String id) async {
    try {
      final batches = state.value ?? [];
      final batch = batches.firstWhere((b) => b.id == id);
      final updatedBatch = batch.copyWith(status: 'completed');

      // 1. Add to Offline Queue
      await OfflineSyncService.addToQueue(
        actionType: 'UPDATE_BATCH',
        data: updatedBatch.toJson(),
      );

      // 2. Immediate State Update (Remove from active list)
      state = AsyncValue.data(batches.where((b) => b.id != id).toList());
    } catch (e) {
      debugPrint('Error closing batch: $e');
    }
  }

  Future<void> initiateBatchFromSlaughter({
    required SlaughterLog log,
    required double totalCarcassWeight,
    required List<MeatCut> cuts,
    required double waste,
  }) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned');

      // 1. Create the Meat Batch record first
      final batch = MeatBatch(
        id: log.id,
        branchCode: branchCode,
        animalId: log.animalId,
        meatType: log.type.displayName,
        weight: totalCarcassWeight,
        costPrice: log.farmPrice ?? 0.0,
        createdAt: DateTime.now(),
        status: MeatBatchStatus.preparing.name, // Changed from transporting to preparing
        source: BatchSource(
          name: 'Direct Slaughter',
          location: branchCode,
          owner: 'Mi~Corazon',
        ),
      );

      await OfflineSyncService.addToQueue(
        actionType: 'CREATE_BATCH',
        data: batch.toJson(),
      );

      // 2. Add the cuts referencing the batch
      for (final cut in cuts) {
        await ref.read(recentCutsProvider.notifier).addCut(cut);
      }

      // 3. Add waste record if any
      if (waste > 0) {
        await ref.read(butcherWasteProvider.notifier).addWaste(log.id, 'Slaughter Waste/Bones', waste);
      }

      // 4. Mark Slaughter as fully Processed (removes from pipeline, moves to production floor)
      final updatedLog = log.copyWith(
        status: SlaughterStatus.processed, // Changed from completed to processed
        meatWeight: totalCarcassWeight,
        slaughterTime: DateTime.now(),
      );
      
      await ref.read(slaughterLogsProvider.notifier).updateSlaughterRecord(updatedLog);

      // 5. Update local batches list
      final currentBatches = state.value ?? [];
      state = AsyncValue.data([batch, ...currentBatches]);
      
    } catch (e) {
      debugPrint('Error initiating batch: $e');
      rethrow;
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
    } catch (e) {
      if (!silent) state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addCut(MeatCut cut) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned to user');
      final cutWithBranch = cut.copyWith(branchCode: branchCode);
      
      // 1. Add to Offline Queue
      await OfflineSyncService.addToQueue(
        actionType: 'CUT', 
        data: cutWithBranch.toJson(),
      );

      // 2. Optimistic Update
      state.whenData((cuts) {
        state = AsyncValue.data([cutWithBranch, ...cuts]);
      });
    } catch (e) {
      debugPrint('Error adding meat cut: $e');
    }
  }

  Future<void> addCuts(List<MeatCut> cuts) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      if (branchCode == null) throw Exception('No branch code assigned to user');
      
      final cutsWithBranch = cuts.map((c) => c.copyWith(branchCode: branchCode)).toList();
      for (var cut in cutsWithBranch) {
        await OfflineSyncService.addToQueue(
          actionType: 'CUT', 
          data: cut.toJson(),
        );
      }
      
      state.whenData((currentCuts) {
        state = AsyncValue.data([...cutsWithBranch, ...currentCuts]);
      });
    } catch (e) {
      debugPrint('Error adding multiple cuts: $e');
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
    } catch (e) {
      if (!silent) state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addWaste(String batchId, String reason, double weight) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      final code = branchCode ?? 'GLOBAL';
      
      final Map<String, dynamic> wasteData = {
        'branch_code': code,
        'batch_id': batchId,
        'reason': reason,
        'weight': weight,
        'recorded_at': DateTime.now().toIso8601String(),
      };

      // 1. Add to Offline Queue (Hive)
      await OfflineSyncService.addToQueue(
        actionType: 'WASTE', 
        data: wasteData,
      );

      // 1b. Audit Log
      await AuditService.log(
        ref: ref,
        action: 'WASTE_RECORDED',
        entityType: 'BUTCHER_WASTE',
        newData: wasteData,
      );

      // 2. Optimistic UI update (refresh list)
      loadWaste(silent: true); 
    } catch (e) {
      debugPrint('Error adding waste (Queue): $e');
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
    } catch (e) {
      if (!silent) state = AsyncValue.error(e, StackTrace.current);
    }
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

  Future<void> addOrder(ButcherOrder order) async {
    try {
      final branchCode = ref.read(currentUserProvider)?.branchCode;
      final orderWithBranch = order.copyWith(branchCode: branchCode);
      await _service.addButcherOrder(orderWithBranch);
      state.whenData((orders) {
        state = AsyncValue.data([orderWithBranch, ...orders]);
      });
    } catch (e) {
      debugPrint('Error adding butcher order: $e');
      rethrow;
    }
  }
}

final butcherOrdersProvider = StateNotifierProvider<ButcherOrderNotifier, AsyncValue<List<ButcherOrder>>>((ref) {
  return ButcherOrderNotifier(ref.watch(butcherServiceProvider), ref);
});
