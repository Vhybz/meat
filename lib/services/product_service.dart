import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

abstract class ProductService {
  Future<List<Product>> getProducts();
  Future<Product> getProductById(String id);
}

class MockProductService implements ProductService {
  @override
  Future<List<Product>> getProducts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Product(id: '1', name: 'Beef Brisket', price: 420.0, imageUrl: 'assets/images/beef.jpg', category: 'Beef', stockQuantity: 25.5, unit: 'kg'),
      Product(id: '2', name: 'Pork Liempo', price: 310.0, imageUrl: 'assets/images/pork.jpg', category: 'Pork', stockQuantity: 15.0, unit: 'kg'),
      Product(id: '3', name: 'Chicken Thigh', price: 180.0, imageUrl: 'assets/images/chicken.jpg', category: 'Chicken', stockQuantity: 40.0, unit: 'kg'),
      Product(id: '4', name: 'Beef Ribs', price: 380.0, imageUrl: 'assets/images/beef_art.jpg', category: 'Beef', stockQuantity: 5.0, unit: 'kg'),
      Product(id: '5', name: 'Special Cut Pork', price: 340.0, imageUrl: 'assets/images/pork_art.jpg', category: 'Pork', stockQuantity: 12.0, unit: 'kg'),
      Product(id: '6', name: 'Meat Assortment', price: 550.0, imageUrl: 'assets/images/meat_on_scale.jpg', category: 'Beef', stockQuantity: 8.0, unit: 'kg'),
    ];
  }

  @override
  Future<Product> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Product(id: id, name: 'Product $id', price: 100.0, imageUrl: '', category: 'Meat');
  }
}

final productServiceProvider = Provider<ProductService>((ref) {
  return MockProductService();
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

  void addProduct(Product product) {
    state.whenData((products) {
      state = AsyncValue.data([...products, product]);
    });
  }

  void updateStock(String id, double quantity) {
    state.whenData((products) {
      state = AsyncValue.data(products.map((p) {
        if (p.id == id) {
          return Product(
            id: p.id,
            name: p.name,
            price: p.price,
            imageUrl: p.imageUrl,
            category: p.category,
            stockQuantity: p.stockQuantity + quantity,
            unit: p.unit,
          );
        }
        return p;
      }).toList());
    });
  }
}

final productsFutureProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductNotifier(ref.watch(productServiceProvider));
});
