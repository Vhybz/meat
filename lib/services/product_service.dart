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
    await Future.delayed(const Duration(seconds: 1));
    return [
      Product(id: '1', name: 'Beef Brisket', price: 420.0, imageUrl: '', category: 'Beef'),
      Product(id: '2', name: 'Pork Liempo', price: 310.0, imageUrl: '', category: 'Pork'),
      Product(id: '3', name: 'Chicken Thigh', price: 180.0, imageUrl: '', category: 'Chicken'),
      Product(id: '4', name: 'Beef Ribs', price: 380.0, imageUrl: '', category: 'Beef'),
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

final productsFutureProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.watch(productServiceProvider);
  return service.getProducts();
});
