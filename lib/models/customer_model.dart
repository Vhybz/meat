class Customer {
  final String id;
  final String? branchCode;
  final String name;
  final String phone;
  final String? location;
  final bool isFavorite;
  final double loyaltyPoints;
  final int visitCount;

  Customer({
    required this.id,
    this.branchCode,
    required this.name,
    required this.phone,
    this.location,
    this.isFavorite = false,
    this.loyaltyPoints = 0.0,
    this.visitCount = 0,
  });

  Customer copyWith({
    String? id,
    String? branchCode,
    String? name,
    String? phone,
    String? location,
    bool? isFavorite,
    double? loyaltyPoints,
    int? visitCount,
  }) {
    return Customer(
      id: id ?? this.id,
      branchCode: branchCode ?? this.branchCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      isFavorite: isFavorite ?? this.isFavorite,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      visitCount: visitCount ?? this.visitCount,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      branchCode: json['branch_code'],
      name: json['name'],
      phone: json['phone'],
      location: json['location'],
      isFavorite: json['is_favorite'] ?? false,
      loyaltyPoints: (json['loyalty_points'] as num? ?? 0.0).toDouble(),
      visitCount: json['visit_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_code': branchCode,
      'name': name,
      'phone': phone,
      'location': location,
      'is_favorite': isFavorite,
      'loyalty_points': loyaltyPoints,
      'visit_count': visitCount,
    };
  }
}
