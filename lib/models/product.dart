import 'customer_model.dart';

enum PromoTarget { retail, wholesale, both }
enum PromoCustomerTarget { all, regularsOnly }

class PriceBracket {
  final double minWeight;
  final double maxWeight;
  final double price;

  PriceBracket({
    required this.minWeight, 
    required this.maxWeight, 
    required this.price
  });
}

class Product {
  final String id;
  final String? branchCode;
  final String name;
  final double retailPrice;
  final double wholesalePrice;
  final List<PriceBracket>? retailBrackets;
  final List<PriceBracket>? wholesaleBrackets;
  final String imageUrl;
  final String category;
  final double stockQuantity;
  final String unit;
  final double discountPercentage;
  final DateTime? promoStartDate;
  final DateTime? promoEndDate;
  final PromoTarget promoTarget;
  final PromoCustomerTarget promoCustomerTarget;
  final bool isDeleted; // Soft delete

  Product({
    required this.id,
    this.branchCode,
    required this.name,
    required this.retailPrice,
    required this.wholesalePrice,
    this.retailBrackets,
    this.wholesaleBrackets,
    required this.imageUrl,
    required this.category,
    this.stockQuantity = 0,
    this.unit = 'kg',
    this.discountPercentage = 0.0,
    this.promoStartDate,
    this.promoEndDate,
    this.promoTarget = PromoTarget.both,
    this.promoCustomerTarget = PromoCustomerTarget.all,
    this.isDeleted = false,
  });

  /// Logic to check if promotion is currently scheduled correctly by date
  bool get isPromoScheduled {
    if (discountPercentage <= 0) return false;
    if (promoStartDate == null || promoEndDate == null) return true;
    
    final now = DateTime.now();
    return !now.isBefore(promoStartDate!) && now.isBefore(promoEndDate!.add(const Duration(days: 1)));
  }

  /// Check if promo is active for a specific mode and customer
  bool isPromoActiveFor(bool isWholesale, Customer? customer, {bool ignoreCustomerFilter = false}) {
    if (!isPromoScheduled) return false;
    
    // Check mode target
    bool modeMatch = false;
    if (promoTarget == PromoTarget.both) {
      modeMatch = true;
    } else if (isWholesale) {
      modeMatch = (promoTarget == PromoTarget.wholesale);
    } else {
      modeMatch = (promoTarget == PromoTarget.retail);
    }

    if (!modeMatch) return false;

    // Check customer target
    if (ignoreCustomerFilter || promoCustomerTarget == PromoCustomerTarget.all) return true;
    return customer?.isFavorite ?? false;
  }

  /// Helper to get price based on mode, weight, and active discount
  double getPrice(bool isWholesale, {double? weight, Customer? customer, bool ignoreCustomerFilter = false}) {
    final brackets = isWholesale ? wholesaleBrackets : retailBrackets;
    double currentPrice = isWholesale ? wholesalePrice : retailPrice;
    
    if (weight != null && brackets != null && brackets.isNotEmpty) {
      for (var bracket in brackets) {
        if (weight >= bracket.minWeight && weight <= bracket.maxWeight) {
          currentPrice = bracket.price;
          break;
        }
      }
    }

    if (isPromoActiveFor(isWholesale, customer, ignoreCustomerFilter: ignoreCustomerFilter)) {
      return currentPrice * (1 - (discountPercentage / 100));
    }
    return currentPrice;
  }

  Product copyWith({
    String? name,
    String? branchCode,
    double? retailPrice,
    double? wholesalePrice,
    double? stockQuantity,
    double? discountPercentage,
    DateTime? promoStartDate,
    DateTime? promoEndDate,
    PromoTarget? promoTarget,
    PromoCustomerTarget? promoCustomerTarget,
    String? category,
    String? unit,
    String? imageUrl,
    bool? isDeleted,
  }) {
    return Product(
      id: id,
      branchCode: branchCode ?? this.branchCode,
      name: name ?? this.name,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailBrackets: retailBrackets,
      wholesaleBrackets: wholesaleBrackets,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      promoStartDate: promoStartDate ?? this.promoStartDate,
      promoEndDate: promoEndDate ?? this.promoEndDate,
      promoTarget: promoTarget ?? this.promoTarget,
      promoCustomerTarget: promoCustomerTarget ?? this.promoCustomerTarget,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      branchCode: json['branch_code'],
      name: json['name'] as String,
      retailPrice: (json['retail_price'] as num).toDouble(),
      wholesalePrice: (json['wholesale_price'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      category: json['category'] as String,
      stockQuantity: (json['stock_quantity'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      discountPercentage: (json['discount_percentage'] as num? ?? 0.0).toDouble(),
      promoStartDate: json['promo_start'] != null ? DateTime.parse(json['promo_start']) : null,
      promoEndDate: json['promo_end'] != null ? DateTime.parse(json['promo_end']) : null,
      promoTarget: PromoTarget.values.byName(json['promo_target'] ?? 'both'),
      promoCustomerTarget: PromoCustomerTarget.values.byName(json['promo_customer_target'] ?? 'all'),
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'branch_code': branchCode,
        'name': name,
        'retail_price': retailPrice,
        'wholesale_price': wholesalePrice,
        'image_url': imageUrl,
        'category': category,
        'stock_quantity': stockQuantity,
        'unit': unit,
        'discount_percentage': discountPercentage,
        'promo_start': promoStartDate?.toIso8601String(),
        'promo_end': promoEndDate?.toIso8601String(),
        'promo_target': promoTarget.name,
        'promo_customer_target': promoCustomerTarget.name,
        'is_deleted': isDeleted,
      };
}

class CartItem {
  final Product product;
  final double quantity;
  final double priceAtSale;
  final double originalPrice;

  CartItem({
    required this.product, 
    required this.quantity,
    required this.priceAtSale,
    required this.originalPrice,
  });

  double get total => priceAtSale * quantity;
  double get discount => (originalPrice - priceAtSale) * quantity;
}
