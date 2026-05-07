enum UserRole { superAdmin, admin, butcher, cashier }
enum AccountStatus { pending, approved, suspended }

class UserAccount {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? shopLocation;
  final AccountStatus status;
  final DateTime createdAt;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.shopLocation,
    this.status = AccountStatus.approved,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  UserAccount copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? shopLocation,
    AccountStatus? status,
    DateTime? createdAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      shopLocation: shopLocation ?? this.shopLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
