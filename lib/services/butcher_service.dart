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
      SlaughterLog(id: 'BF-20240501-0930-102', animalId: 'ANM-B01', type: AnimalType.cow, weight: 450.0, status: SlaughterStatus.completed, slaughterTime: DateTime.now().subtract(const Duration(hours: 4))),
      SlaughterLog(id: 'CH-H-20240501-1015-105', animalId: 'ANM-C01', type: AnimalType.hardChicken, weight: 3.5, status: SlaughterStatus.completed, slaughterTime: DateTime.now().subtract(const Duration(hours: 2))),
      SlaughterLog(id: 'BF-20240501-1100-108', animalId: 'ANM-L03', type: AnimalType.bull, weight: 500.0, status: SlaughterStatus.processing),
      SlaughterLog(id: 'CH-S-20240501-1130-110', animalId: 'ANM-C04', type: AnimalType.softChicken, weight: 2.8, status: SlaughterStatus.pending),
    ];
  }

  @override
  Future<List<MeatBatch>> getActiveBatches() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      MeatBatch(
        id: 'BF-20240501-0930-102', 
        meatType: 'Beef', 
        weight: 450.0, 
        createdAt: DateTime.now(), 
        status: 'Processing',
        source: BatchSource(name: 'Green Valley Farm', location: 'Sunyani', owner: 'John Mensah'),
      ),
      MeatBatch(
        id: 'PK-20240501-1420-105', 
        meatType: 'Pork', 
        weight: 220.0, 
        createdAt: DateTime.now(), 
        status: 'Processing',
        source: BatchSource(name: 'Healthy Pig Farm', location: 'Dormaa', owner: 'Kofi Boakye'),
      ),
    ];
  }

  @override
  Future<List<MeatCut>> getRecentCuts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      MeatCut(id: 'CUT-001', name: 'Beef Brisket', batchId: 'BF-20240501-0930-102', weight: 15.4, processedAt: DateTime.now().subtract(const Duration(minutes: 15))),
      MeatCut(id: 'CUT-002', name: 'Beef Ribs', batchId: 'BF-20240501-0930-102', weight: 8.2, processedAt: DateTime.now().subtract(const Duration(minutes: 45))),
      MeatCut(id: 'CUT-003', name: 'Pork Belly', batchId: 'PK-20240501-1420-105', weight: 12.0, processedAt: DateTime.now().subtract(const Duration(hours: 1))),
      MeatCut(id: 'CUT-004', name: 'Pork Chops', batchId: 'PK-20240501-1420-105', weight: 5.5, processedAt: DateTime.now().subtract(const Duration(hours: 2))),
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
