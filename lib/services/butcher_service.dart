import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/butcher_models.dart';

abstract class ButcherService {
  Future<List<SlaughterLog>> getSlaughterLogs();
  Future<List<MeatBatch>> getActiveBatches();
}

class MockButcherService implements ButcherService {
  @override
  Future<List<SlaughterLog>> getSlaughterLogs() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      SlaughterLog(id: 'SL-001', animalId: 'ANM-12', type: AnimalType.cow, weight: 450.0, status: SlaughterStatus.completed, slaughterTime: DateTime.now()),
      SlaughterLog(id: 'SL-002', animalId: 'ANM-13', type: AnimalType.cow, weight: 420.0, status: SlaughterStatus.completed, slaughterTime: DateTime.now()),
      SlaughterLog(id: 'SL-003', animalId: 'ANM-14', type: AnimalType.bull, weight: 500.0, status: SlaughterStatus.processing),
      SlaughterLog(id: 'SL-004', animalId: 'ANM-15', type: AnimalType.cow, weight: 430.0, status: SlaughterStatus.pending),
    ];
  }

  @override
  Future<List<MeatBatch>> getActiveBatches() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      MeatBatch(id: 'BCH-001', meatType: 'Beef Brisket', weight: 42.5, createdAt: DateTime.now(), status: 'Ready'),
      MeatBatch(id: 'BCH-002', meatType: 'Beef Ribs', weight: 35.8, createdAt: DateTime.now(), status: 'Ready'),
    ];
  }
}

final butcherServiceProvider = Provider<ButcherService>((ref) => MockButcherService());

final slaughterLogsProvider = FutureProvider<List<SlaughterLog>>((ref) {
  return ref.watch(butcherServiceProvider).getSlaughterLogs();
});

final activeBatchesProvider = FutureProvider<List<MeatBatch>>((ref) {
  return ref.watch(butcherServiceProvider).getActiveBatches();
});
