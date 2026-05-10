class Customer {
  final String id;
  final String name;
  final String phone;
  final String? location;
  final bool isFavorite;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.location,
    this.isFavorite = false,
  });

  Customer copyWith({
    String? name,
    String? phone,
    String? location,
    bool? isFavorite,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      location: json['location'],
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'location': location,
    'is_favorite': isFavorite,
  };
}
