import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'supabase_product_service.dart';

abstract class ProductService {
  Future<List<Product>> getProducts();
  Future<Product> getProductById(String id);
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
  Future<void> updateStock(String id, double newQuantity);
  Future<void> applyPromotion(String id, double percentage, DateTime? start, DateTime? end, PromoTarget target, PromoCustomerTarget customerTarget);
  Future<String?> uploadProductImage(Uint8List bytes, String fileName);
}

final productServiceProvider = Provider<ProductService>((ref) {
  return SupabaseProductService();
});

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductService _service;
  ProductNotifier(this._service) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      final products = await _service.getProducts();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _service.addProduct(product);
      state.whenData((products) {
        state = AsyncValue.data([...products, product]);
      });
    } catch (e) {}
  }

  Future<void> updateProduct(Product updatedProduct) async {
    try {
      await _service.updateProduct(updatedProduct);
      state.whenData((products) {
        state = AsyncValue.data(products.map((p) => p.id == updatedProduct.id ? updatedProduct : p).toList());
      });
    } catch (e) {}
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      state.whenData((products) {
        state = AsyncValue.data(products.map((p) => p.id == id ? p.copyWith(isDeleted: true) : p).toList());
      });
    } catch (e) {}
  }

  Future<void> restoreProduct(String id) async {
    state.whenData((products) {
      state = AsyncValue.data(products.map((p) => p.id == id ? p.copyWith(isDeleted: false) : p).toList());
    });
  }

  Future<void> updateStock(String id, double quantityChange) async {
    state.whenData((products) async {
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
    });
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
      } catch (e) {}
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
      } catch (e) {}
    });
  }

  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    return await _service.uploadProductImage(bytes, fileName);
  }
}

final productsFutureProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductNotifier(ref.watch(productServiceProvider));
});
