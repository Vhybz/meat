enum UserRole { admin, butcher, cashier }

class UserAccount {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? shopLocation;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.shopLocation,
  });
}
