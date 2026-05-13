import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'supabase_product_service.dart';
import 'user_provider.dart';
import 'notification_service.dart';
import 'sms_service.dart';

abstract class ProductService {
  Future<List<Product>> getProducts(String branchCode);
  Future<Product> getProductById(String id);
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
  Future<void> updateStock(String id, double newQuantity);
  Future<void> applyPromotion(String id, double percentage, DateTime? start, DateTime? end, PromoTarget target, PromoCustomerTarget customerTarget);
  Future<String?> uploadProductImage(Uint8List bytes, String fileName);
  Stream<List<Product>> watchProducts(String branchCode);
}

final productServiceProvider = Provider<ProductService>((ref) {
  return SupabaseProductService();
});

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductService _service;
  final Ref ref;
  StreamSubscription<List<Product>>? _subscription;

  ProductNotifier(this._service, this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // 1. Watch current user and restart subscription if branch changes
    ref.listen(currentUserProvider, (previous, next) {
      if (next?.branchCode != previous?.branchCode) {
        _startSubscription();
      }
    });

    // 2. Background Heartbeat: Silent refresh logic every 3 seconds
    ref.listen(liveHeartbeatProvider, (_, __) {
      final products = state.value;
      if (products != null) {
        _checkStockAlerts(products);
        // We removed the forced rebuild [...products] to prevent UI flickering.
        // Rebuilds will now only happen when Supabase stream sends real updates.
      }
    });
    
    _startSubscription();
  }

  void _startSubscription() {
    _subscription?.cancel();
    final user = ref.read(currentUserProvider);
    if (user != null && user.branchCode != null) {
      _subscription = _service.watchProducts(user.branchCode!).listen(
        (products) {
          state = AsyncValue.data(products);
          _checkStockAlerts(products);
        },
        onError: (e, st) => state = AsyncValue.error(e, st),
      );
    } else {
      state = const AsyncValue.data([]);
    }
  }

  void _checkStockAlerts(List<Product> products) {
    for (final product in products) {
      if (!product.isDeleted && product.stockQuantity <= product.lowStockThreshold) {
        final title = 'LOW STOCK ALERT: ${product.name}';
        final message = '${product.name} is below safety threshold (${product.stockQuantity}${product.unit} remaining).';
        
        // Avoid duplicate notifications for the same state
        final existing = ref.read(notificationProvider).any((n) => n.title == title && !n.isRead);
        if (!existing) {
          ref.read(notificationProvider.notifier).addNotification(title, message);
          
          // Optionally notify admin via SMS
          SmsService.notifyAdmin(title: title, message: message);
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadProducts() async {
    // The stream handles loading automatically, but we can keep this for manual refreshes if needed
    _startSubscription();
  }

  Future<void> addProduct(Product product) async {
    try {
      final user = ref.read(currentUserProvider);
      final productWithBranch = product.copyWith(branchCode: user?.branchCode);
      await _service.addProduct(productWithBranch);
      // No need to manually update state, the stream will catch it
    } catch (e) {
      debugPrint('Add Product Error: $e');
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    try {
      await _service.updateProduct(updatedProduct);
      state.whenData((products) {
        state = AsyncValue.data(products.map((p) => p.id == updatedProduct.id ? updatedProduct : p).toList());
      });
    } catch (e) {
      debugPrint('Update Product Error: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      state.whenData((products) {
        state = AsyncValue.data(products.map((p) => p.id == id ? p.copyWith(isDeleted: true) : p).toList());
      });
    } catch (e) {
      debugPrint('Delete Product Error: $e');
    }
  }

  Future<void> restoreProduct(String id) async {
    state.whenData((products) {
      state = AsyncValue.data(products.map((p) => p.id == id ? p.copyWith(isDeleted: false) : p).toList());
    });
  }

  Future<void> updateStock(String id, double quantityChange) async {
    final products = state.value;
    if (products == null) return;

    try {
      final product = products.firstWhere((p) => p.id == id);
      final newQuantity = product.stockQuantity + quantityChange;
      await _service.updateStock(id, newQuantity);
      state = AsyncValue.data(products.map((p) {
        if (p.id == id) {
          return p.copyWith(stockQuantity: newQuantity);
        }
        return p;
      }).toList());
    } catch (e) {
      debugPrint('Stock Update Error: $e');
    }
  }

  Future<void> applyPromotion(double percentage, DateTime start, DateTime end, PromoTarget target, PromoCustomerTarget customerTarget, {List<String>? selectedIds}) async {
    state.whenData((products) async {
      final productsToUpdate = selectedIds == null 
          ? products 
          : products.where((p) => selectedIds.contains(p.id)).toList();
      
      try {
        for (var p in productsToUpdate) {
          await _service.applyPromotion(p.id, percentage, start, end, target, customerTarget);
        }
        
        state = AsyncValue.data(products.map((p) {
          if (selectedIds == null || selectedIds.contains(p.id)) {
            return p.copyWith(
              discountPercentage: percentage,
              promoStartDate: start,
              promoEndDate: end,
              promoTarget: target,
              promoCustomerTarget: customerTarget,
            );
          }
          return p;
        }).toList());
      } catch (e) {
        debugPrint('Apply Promotion Error: $e');
      }
    });
  }

  Future<void> clearPromotions() async {
    state.whenData((products) async {
      try {
        for (var p in products) {
          if (p.discountPercentage > 0) {
            await _service.applyPromotion(p.id, 0, null, null, PromoTarget.both, PromoCustomerTarget.all);
          }
        }
        state = AsyncValue.data(products.map((p) => p.copyWith(
          discountPercentage: 0,
          promoStartDate: null,
          promoEndDate: null,
        )).toList());
      } catch (e) {
        debugPrint('Clear Promotions Error: $e');
      }
    });
  }

  Future<void> removePromotion(String productId) async {
    state.whenData((products) async {
      try {
        await _service.applyPromotion(productId, 0, null, null, PromoTarget.both, PromoCustomerTarget.all);
        state = AsyncValue.data(products.map((p) {
          if (p.id == productId) {
            return p.copyWith(
              discountPercentage: 0,
              promoStartDate: null,
              promoEndDate: null,
            );
          }
          return p;
        }).toList());
      } catch (e) {
        debugPrint('Remove Promotion Error: $e');
      }
    });
  }

  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    return await _service.uploadProductImage(bytes, fileName);
  }
}

final productsFutureProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductNotifier(ref.watch(productServiceProvider), ref);
});
