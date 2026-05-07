import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class UserNotifier extends StateNotifier<List<UserAccount>> {
  UserNotifier() : super([
    UserAccount(id: 'USR-001', name: 'Ramon Dela Cruz', email: 'ramon@meatshop.com', role: UserRole.butcher),
    UserAccount(id: 'USR-002', name: 'Maria Santos', email: 'maria@meatshop.com', role: UserRole.cashier, shopLocation: 'Main Branch POS'),
    UserAccount(id: 'USR-003', name: 'Juan Luna', email: 'juan@meatshop.com', role: UserRole.cashier, shopLocation: 'West Side Outlet'),
  ]);

  void addAccount(UserAccount account) {
    state = [...state, account];
  }

  List<UserAccount> getCashiers() {
    return state.where((u) => u.role == UserRole.cashier).toList();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, List<UserAccount>>((ref) {
  return UserNotifier();
});
