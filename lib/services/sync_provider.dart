import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transfer_provider.dart';
import 'customer_provider.dart';
import 'expense_provider.dart';
import 'user_provider.dart';
import 'butcher_service.dart';

class SyncNotifier extends StateNotifier<DateTime> {
  final Ref ref;
  Timer? _timer;

  SyncNotifier(this.ref) : super(DateTime.now()) {
    _startSyncTimer();
  }

  void _startSyncTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _syncAll();
    });
  }

  Future<void> _syncAll() async {
    // Only sync if user is logged in
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Refresh non-stream providers (Silent reloads to prevent UI flickering)
    ref.read(transferProvider.notifier).loadTransfers();
    ref.read(customerProvider.notifier).loadCustomers();
    ref.read(expenseProvider.notifier).loadExpenses();
    ref.read(userProvider.notifier).loadUsers(silent: true);
    
    // Refresh butcher-specific data (Silent reloads to prevent UI flickering)
    ref.read(slaughterLogsProvider.notifier).loadLogs(silent: true);
    ref.read(meatBatchesProvider.notifier).loadBatches(silent: true);
    ref.read(recentCutsProvider.notifier).loadCuts(silent: true);
    ref.read(butcherWasteProvider.notifier).loadWaste(silent: true);
    ref.read(butcherOrdersProvider.notifier).loadOrders(silent: true);

    state = DateTime.now(); // Update timestamp to show last sync
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, DateTime>((ref) {
  return SyncNotifier(ref);
});
