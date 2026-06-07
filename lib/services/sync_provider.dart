import 'dart:async';
import 'package:flutter/foundation.dart';
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
    // If the notifier is already being disposed, don't attempt another sync
    if (!mounted) return;

    try {
      // Only sync if user is logged in
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Check if providers are still alive before calling them
      // This prevents the 'Tried to use X after dispose' error
      _safeRefresh(transferProvider.notifier, (n) => n.loadTransfers());
      _safeRefresh(customerProvider.notifier, (n) => n.loadCustomers());
      _safeRefresh(expenseProvider.notifier, (n) => n.loadExpenses());
      _safeRefresh(userProvider.notifier, (n) => n.loadUsers(silent: true));
      
      _safeRefresh(slaughterLogsProvider.notifier, (n) => n.loadLogs(silent: true));
      _safeRefresh(meatBatchesProvider.notifier, (n) => n.loadBatches(silent: true));
      _safeRefresh(recentCutsProvider.notifier, (n) => n.loadCuts(silent: true));
      _safeRefresh(butcherWasteProvider.notifier, (n) => n.loadWaste(silent: true));
      _safeRefresh(butcherOrdersProvider.notifier, (n) => n.loadOrders(silent: true));

      if (mounted) {
        state = DateTime.now(); // Update timestamp to show last sync
      }
    } catch (e) {
      if (!e.toString().contains('disposed')) {
        debugPrint('Sync Heartbeat Warning: $e');
      }
    }
  }

  void _safeRefresh<T>(ProviderListenable<T> provider, Function(T) action) {
    try {
      final notifier = ref.read(provider);
      action(notifier);
    } catch (e) {
      // Silently ignore if provider is disposed or not found
    }
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
