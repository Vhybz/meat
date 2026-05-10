import '../models/product.dart';
import 'product_service.dart';
import 'user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductSeeder {
  final Ref ref;
  ProductSeeder(this.ref);

  Future<void> seedProducts() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.branchCode == null) return;

    final service = ref.read(productServiceProvider);
    
    final List<Map<String, List<String>>> data = [
      {
        'Chicken': [
          'Hard Thigh', 'Soft Thigh', 'Hard Breast', 'Soft Breast', 
          'Hard Back', 'Soft Back', 'Hard Wings', 'Soft Wings', 
          'Hard Half Chicken', 'Soft Half Chicken', 'Hard Whole Chicken', 
          'Soft Whole Chicken', 'Hard Drumsticks', 'Soft Drumsticks'
        ]
      },
      {
        'Beef': [
          'Mixed Meat', 'Boneless', 'Offals / Yemadeɛ', 'Beef Steak', 
          'Liver & Lungs', 'Grounded Meat', 'Feet', 'Head', 'Tail / Padua'
        ]
      },
      {
        'Goat': [
          'Mixed Meat', 'Boneless', 'Offals / Yemadeɛ', 'Head', 'Feet'
        ]
      },
      {
        'Pork': [
          'Mixed Meat', 'Boneless Meat', 'Offals / Yemadeɛ', 'Pork Steak', 
          'Head', 'Ear', 'Feet', 'Liver', 'Skin'
        ]
      },
    ];

    for (var categoryMap in data) {
      final category = categoryMap.keys.first;
      final productNames = categoryMap.values.first;

      for (var name in productNames) {
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String suffix = (timestamp.length > 12) ? timestamp.substring(timestamp.length - 12) : timestamp.padLeft(12, '0');
        final String validUuid = '00000000-0000-0000-0000-$suffix';

        final product = Product(
          id: validUuid,
          branchCode: user.branchCode,
          name: name,
          retailPrice: 0.0,
          wholesalePrice: 0.0,
          imageUrl: '', // Default empty, admin can upload later
          category: category,
          stockQuantity: 0.0,
          unit: 'kg',
        );
        
        await service.addProduct(product);
      }
    }
  }
}

final productSeederProvider = Provider<ProductSeeder>((ref) => ProductSeeder(ref));
