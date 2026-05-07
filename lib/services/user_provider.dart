import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class UserNotifier extends StateNotifier<List<UserAccount>> {
  UserNotifier() : super([
    UserAccount(id: 'USR-001', name: 'Ramon Dela Cruz', email: 'ramon@meatshop.com', role: UserRole.butcher, status: AccountStatus.approved),
    UserAccount(id: 'USR-002', name: 'Maria Santos', email: 'maria@meatshop.com', role: UserRole.cashier, shopLocation: 'Main Branch POS', status: AccountStatus.approved),
    UserAccount(id: 'USR-003', name: 'Juan Luna', email: 'juan@meatshop.com', role: UserRole.cashier, shopLocation: 'West Side Outlet', status: AccountStatus.approved),
  ]);

  void addAccount(UserAccount account) {
    state = [...state, account];
  }

  void approveUser(String userId) {
    state = [
      for (final user in state)
        if (user.id == userId) user.copyWith(status: AccountStatus.approved) else user
    ];
  }

  void deleteUser(String userId) {
    state = state.where((u) => u.id != userId).toList();
  }

  bool hasAdmin() {
    return state.any((u) => u.role == UserRole.admin && u.status == AccountStatus.approved);
  }

  List<UserAccount> getPendingUsers() {
    return state.where((u) => u.status == AccountStatus.pending).toList();
  }

  List<UserAccount> getCashiers() {
    return state.where((u) => u.role == UserRole.cashier && u.status == AccountStatus.approved).toList();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, List<UserAccount>>((ref) {
  return UserNotifier();
});
