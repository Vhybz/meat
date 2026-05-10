import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'supabase_user_service.dart';

class UserNotifier extends StateNotifier<List<UserAccount>> {
  final SupabaseUserService service;

  UserNotifier(this.service) : super([]) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final users = await service.getUsers();
      state = users;
    } catch (e) {
      debugPrint('Load Users Error: $e');
    }
  }

  Future<void> addAccount(UserAccount account) async {
    try {
      debugPrint('Attempting to add user profile to database: ${account.id}');
      await service.addUser(account);
      state = [...state, account];
      debugPrint('User profile saved successfully.');
    } catch (e) {
      debugPrint('DATABASE ERROR (addUser): $e');
      rethrow;
    }
  }

  Future<void> updateProfile(String userId, {String? firstName, String? surname, String? phone, String? gender, DateTime? dob}) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(
        firstName: firstName,
        surname: surname,
        phone: phone,
        gender: gender,
        dob: dob,
      );
      
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Profile Update Error: $e');
    }
  }

  Future<void> updateRoles(String userId, {UserRole? primaryRole, List<UserRole>? secondaryRoles}) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(
        role: primaryRole,
        secondaryRoles: secondaryRoles,
      );
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Role Update Error: $e');
    }
  }

  Future<void> approveUser(String userId) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(status: AccountStatus.approved);
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Approve User Error: $e');
    }
  }

  Future<void> suspendUser(String userId) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(status: AccountStatus.suspended);
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Suspend User Error: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await service.deleteUser(userId);
      state = [
        for (final u in state)
          if (u.id == userId) u.copyWith(isDeleted: true) else u
      ];
    } catch (e) {
      debugPrint('Delete User Error: $e');
    }
  }

  Future<void> restoreUser(String userId) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(isDeleted: false);
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Restore User Error: $e');
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(status: AccountStatus.approved);
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Activate User Error: $e');
    }
  }

  Future<void> setPermissions(String userId, Set<String> permissions) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(
        newlyAddedPermissions: permissions.difference(user.enabledPermissions),
        enabledPermissions: permissions,
      );
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Set Permissions Error: $e');
    }
  }

  Future<void> markPermissionAsSeen(String userId, String permission) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      if (user.newlyAddedPermissions.contains(permission)) {
        final updatedUser = user.copyWith(
          newlyAddedPermissions: (Set.from(user.newlyAddedPermissions)..remove(permission)),
        );
        await service.updateUser(updatedUser);
        state = [
          for (final u in state)
            if (u.id == userId) updatedUser else u
        ];
      }
    } catch (e) {
      debugPrint('Mark Permission Error: $e');
    }
  }

  Future<void> promoteTemporarily(String userId, UserRole tempRole, DateTime start, DateTime end) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(
        temporaryRole: tempRole, 
        tempRoleStart: start, 
        tempRoleEnd: end
      );
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Promote Error: $e');
    }
  }

  Future<void> clearTemporaryPromotion(String userId) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(clearPromotion: true);
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Clear Promotion Error: $e');
    }
  }

  Future<void> togglePermission(String userId, String permission) async {
    try {
      final user = state.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(
        enabledPermissions: user.enabledPermissions.contains(permission)
            ? (Set.from(user.enabledPermissions)..remove(permission))
            : (Set.from(user.enabledPermissions)..add(permission)),
      );
      await service.updateUser(updatedUser);
      state = [
        for (final u in state)
          if (u.id == userId) updatedUser else u
      ];
    } catch (e) {
      debugPrint('Toggle Permission Error: $e');
    }
  }

  Future<void> permanentlyDeleteUser(String userId) async {
    try {
      state = state.where((u) => u.id != userId).toList();
    } catch (e) {}
  }

  Future<UserAccount?> fetchUserById(String id) async {
    try {
      final user = await service.getUserById(id);
      if (user != null) {
        state = [...state.where((u) => u.id != id), user];
      }
      return user;
    } catch (e) {
      debugPrint('Fetch User Error: $e');
      return null;
    }
  }

  Future<bool> checkPhoneExists(String phone) async {
    return await service.checkPhoneExists(phone);
  }

  List<UserAccount> getPendingUsers() {
    return state.where((u) => !u.isDeleted && u.status == AccountStatus.pending).toList();
  }

  List<UserAccount> getCashiers() {
    return state.where((u) => !u.isDeleted && u.role == UserRole.cashier && u.status == AccountStatus.approved).toList();
  }

  bool get isAdminExists => state.any((u) => u.role == UserRole.admin && u.status == AccountStatus.approved);
}

final userServiceProvider = Provider<SupabaseUserService>((ref) {
  return SupabaseUserService();
});

final userProvider = StateNotifierProvider<UserNotifier, List<UserAccount>>((ref) {
  return UserNotifier(ref.watch(userServiceProvider));
});

// Real logged-in user tracking
final currentUserIdProvider = StateProvider<String?>((ref) => null);

final currentUserProvider = Provider<UserAccount?>((ref) {
  final users = ref.watch(userProvider);
  final currentId = ref.watch(currentUserIdProvider);
  if (currentId == null) return null;
  try {
    return users.firstWhere((u) => u.id == currentId);
  } catch (_) {
    return null;
  }
});
