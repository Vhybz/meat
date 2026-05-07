import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/butcher_models.dart';

abstract class ButcherService {
  Future<List<SlaughterLog>> getSlaughterLogs();
  Future<List<MeatBatch>> getActiveBatches();
  Future<List<MeatCut>> getRecentCuts();
}

class MockButcherService implements ButcherService {
  @override
  Future<List<SlaughterLog>> getSlaughterLogs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      SlaughterLog(id: 'SL-240501-102', animalId: 'ANM-B01', type: AnimalType.cow, weight: 450.0, status: SlaughterStatus.completed, slaughterTime: DateTime.now().subtract(const Duration(hours: 4))),
      SlaughterLog(id: 'SL-240501-105', animalId: 'ANM-B02', type: AnimalType.cow, weight: 420.0, status: SlaughterStatus.completed, slaughterTime: DateTime.now().subtract(const Duration(hours: 2))),
      SlaughterLog(id: 'SL-240501-108', animalId: 'ANM-L03', type: AnimalType.bull, weight: 500.0, status: SlaughterStatus.processing),
      SlaughterLog(id: 'SL-240501-110', animalId: 'ANM-B04', type: AnimalType.cow, weight: 430.0, status: SlaughterStatus.pending),
    ];
  }

  @override
  Future<List<MeatBatch>> getActiveBatches() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      MeatBatch(id: 'BCH-102', meatType: 'Beef', weight: 450.0, createdAt: DateTime.now(), status: 'Processing'),
      MeatBatch(id: 'BCH-105', meatType: 'Pork', weight: 220.0, createdAt: DateTime.now(), status: 'Processing'),
    ];
  }

  @override
  Future<List<MeatCut>> getRecentCuts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      MeatCut(id: 'CUT-001', name: 'Beef Brisket', batchId: 'BCH-102', weight: 15.4, processedAt: DateTime.now().subtract(const Duration(minutes: 15))),
      MeatCut(id: 'CUT-002', name: 'Beef Ribs', batchId: 'BCH-102', weight: 8.2, processedAt: DateTime.now().subtract(const Duration(minutes: 45))),
      MeatCut(id: 'CUT-003', name: 'Pork Belly', batchId: 'BCH-105', weight: 12.0, processedAt: DateTime.now().subtract(const Duration(hours: 1))),
      MeatCut(id: 'CUT-004', name: 'Pork Chops', batchId: 'BCH-105', weight: 5.5, processedAt: DateTime.now().subtract(const Duration(hours: 2))),
    ];
  }
}

final butcherServiceProvider = Provider<ButcherService>((ref) => MockButcherService());

// Using StateNotifier to manage the list locally before Supabase integration
class SlaughterLogNotifier extends StateNotifier<AsyncValue<List<SlaughterLog>>> {
  final ButcherService _service;
  SlaughterLogNotifier(this._service) : super(const AsyncValue.loading()) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    try {
      state = const AsyncValue.loading();
      final logs = await _service.getSlaughterLogs();
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addLog(SlaughterLog log) {
    state.whenData((logs) {
      state = AsyncValue.data([log, ...logs]);
    });
  }
}

final slaughterLogsProvider = StateNotifierProvider<SlaughterLogNotifier, AsyncValue<List<SlaughterLog>>>((ref) {
  return SlaughterLogNotifier(ref.watch(butcherServiceProvider));
});

final activeBatchesProvider = FutureProvider<List<MeatBatch>>((ref) {
  return ref.watch(butcherServiceProvider).getActiveBatches();
});

final recentCutsProvider = FutureProvider<List<MeatCut>>((ref) {
  return ref.watch(butcherServiceProvider).getRecentCuts();
});
