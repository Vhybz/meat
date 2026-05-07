class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String category;
  final double stockQuantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.stockQuantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      stockQuantity: (json['stockQuantity'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'stockQuantity': stockQuantity,
      };
}

class CartItem {
  final Product product;
  final double quantity;

  CartItem({required this.product, required this.quantity});

  double get total => product.price * quantity;
}
