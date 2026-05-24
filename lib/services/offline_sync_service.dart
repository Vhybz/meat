import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// This service manages the "Offline-First" logic for Mi Corazon.
/// It uses Hive as a fast, schema-less storage for pending cloud actions.
class OfflineSyncService {
  static const String queueBoxName = 'sync_queue';
  static const String productsBoxName = 'products_cache';
  static const String customersBoxName = 'customers_cache';
  static const String salesBoxName = 'sales_cache';
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _isProcessing = false;

  /// Initialize Hive and the sync monitoring
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(queueBoxName);
      await Hive.openBox(productsBoxName);
      await Hive.openBox(customersBoxName);
      await Hive.openBox(salesBoxName);
      
      // Listen for connectivity changes to trigger sync automatically
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          debugPrint('Connectivity Restored: Triggering background sync...');
          processQueue();
        }
      });
      
      // Initial check
      processQueue();
    } catch (e) {
      if (e.toString().contains('lock failed')) {
        debugPrint('OFFLINE ENGINE WARNING: Database is already locked by another process.');
        // We don't rethrow here so the app can still boot, though offline sync will be disabled for this session
      } else {
        rethrow;
      }
    }
  }

  /// Add a data action (Sale, Intake, Waste, etc.) to the local Hive queue.
  /// This returns immediately, allowing the UI to stay fast.
  static Future<void> addToQueue({
    required String actionType,
    required Map<String, dynamic> data,
  }) async {
    final box = Hive.box(queueBoxName);
    final String requestId = '${DateTime.now().millisecondsSinceEpoch}_$actionType';
    
    await box.put(requestId, {
      'type': actionType,
      'payload': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    debugPrint('Offline Engine: Action "$actionType" cached in Hive (ID: $requestId)');
    
    // Attempt sync immediately (will fail silently if no net)
    processQueue();
  }

  /// Processes all pending items in the Hive Box and pushes them to Supabase
  static Future<void> processQueue() async {
    if (_isProcessing) return;
    
    final results = await Connectivity().checkConnectivity();
    if (results.every((result) => result == ConnectivityResult.none)) {
      debugPrint('Sync Monitor: Device is offline. Waiting for connection...');
      return;
    }

    final box = Hive.box(queueBoxName);
    if (box.isEmpty) return;

    _isProcessing = true;
    debugPrint('Sync Monitor: ${box.length} pending items found. Starting cloud push...');

    final List<dynamic> keys = List.from(box.keys);

    for (final key in keys) {
      final item = box.get(key);
      final String type = item['type'];
      final Map<String, dynamic> payload = item['payload'];

      try {
        bool success = false;
        
        switch (type) {
          case 'SALE':
            await Supabase.instance.client.from('sales').insert(payload);
            success = true;
            break;
          case 'INTAKE':
            await Supabase.instance.client.from('slaughter_logs').insert(payload);
            success = true;
            break;
          case 'WASTE':
            await Supabase.instance.client.from('waste_records').insert(payload);
            success = true;
            break;
          case 'EXPENSE':
            await Supabase.instance.client.from('expenses').insert(payload);
            success = true;
            break;
          case 'CUSTOMER':
            await Supabase.instance.client.from('customers').insert(payload);
            success = true;
            break;
          default:
            debugPrint('Sync Monitor: Unknown action type "$type". Removing from queue.');
            await box.delete(key);
            continue;
        }

        if (success) {
          await box.delete(key);
          debugPrint('Sync Monitor: SUCCESS! Item $key pushed to Supabase.');
        }
      } catch (e) {
        debugPrint('Sync Monitor: FAILED to push item $key. Will retry later. Error: $e');
        // Stop processing this batch if it's a network error, try again next heartbeat
        if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
          break;
        }
      }
    }
    
    _isProcessing = false;
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
  }
}
