import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'supabase_user_service.dart';

class UserNotifier extends StateNotifier<List<UserAccount>> {
  final SupabaseUserService service;
  final Ref ref;

  UserNotifier(this.service, this.ref) : super([]) {
    // Note: Don't call loadUsers in constructor if it depends on providers that might not be ready
  }

  Future<void> loadUsers() async {
    try {
      final currentId = ref.read(currentUserIdProvider);
      if (currentId == null) return;

      // Fetch current user independently to avoid circular dependency
      final currentUser = await service.getUserById(currentId);
      final allUsers = await service.getUsers();
      
      if (currentUser?.role == UserRole.superAdmin) {
        state = allUsers;
      } else if (currentUser?.branchCode != null) {
        state = allUsers.where((u) => u.branchCode == currentUser!.branchCode).toList();
      } else {
        state = allUsers;
      }
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

  Future<void> updateProfile(String userId, {String? firstName, String? surname, String? phone, String? gender, DateTime? dob, String? branchCode}) async {
    try {
      final index = state.indexWhere((u) => u.id == userId);
      UserAccount? user;
      
      if (index != -1) {
        user = state[index];
      } else {
        user = await service.getUserById(userId);
      }

      if (user != null) {
        final updatedUser = user.copyWith(
          firstName: firstName,
          surname: surname,
          phone: phone,
          gender: gender,
          dob: dob,
          branchCode: branchCode,
        );
        
        await service.updateUser(updatedUser);
        
        if (index != -1) {
          state = [
            for (final u in state)
              if (u.id == userId) updatedUser else u
          ];
        }
      }
    } catch (e) {
      debugPrint('Profile Update Error: $e');
    }
  }

  Future<void> updateRoles(String userId, {UserRole? primaryRole, List<UserRole>? secondaryRoles}) async {
    try {
      final index = state.indexWhere((u) => u.id == userId);
      if (index == -1) return;

      final updatedUser = state[index].copyWith(
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
      final index = state.indexWhere((u) => u.id == userId);
      if (index == -1) return;

      final user = state[index];
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

  Future<void> updatePhoto(String userId, Uint8List bytes) async {
    try {
      final url = await service.uploadProfilePicture(userId, bytes);
      if (url != null) {
        // Find the user in current state
        final index = state.indexWhere((u) => u.id == userId);
        
        if (index != -1) {
          final updatedUser = state[index].copyWith(photoUrl: url);
          await service.updateUser(updatedUser);
          state = [
            for (final u in state)
              if (u.id == userId) updatedUser else u
          ];
        } else {
          // If user not in local state (e.g. current user but not in branch list)
          // Fetch, update and optionally add to state or just let the stream handle it
          final user = await service.getUserById(userId);
          if (user != null) {
            final updatedUser = user.copyWith(photoUrl: url);
            await service.updateUser(updatedUser);
            // We don't necessarily add to state here if they don't belong in this view's branch
          }
        }
      }
    } catch (e) {
      debugPrint('Update Photo Error: $e');
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
    } catch (e) {
      debugPrint('Delete Error: $e');
    }
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

// Real logged-in user tracking
final currentUserIdProvider = StateProvider<String?>((ref) => null);

/// Listens for real-time changes to the current user's profile from the database
final currentUserStreamProvider = StreamProvider<UserAccount?>((ref) {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) return const Stream.empty();
  
  return ref.watch(userServiceProvider).streamUser(id).handleError((error) {
    debugPrint('Real-time User Stream Error: $error');
  });
});

/// A synchronous provider that gives access to the current user profile.
/// It prioritizes the real-time stream to ensure remote permission updates are caught instantly,
/// but falls back to the local user list for immediate optimistic UI updates.
final currentUserProvider = Provider<UserAccount?>((ref) {
  final currentId = ref.watch(currentUserIdProvider);
  if (currentId == null) return null;

  // 1. Check the real-time stream first (source of truth for remote updates)
  final streamUser = ref.watch(currentUserStreamProvider).value;
  
  // 2. Check the local cache (source of truth for immediate local edits)
  final localUsers = ref.watch(userProvider);
  UserAccount? localUser;
  try {
    localUser = localUsers.firstWhere((u) => u.id == currentId);
  } catch (_) {}

  // If we have both, we should theoretically prefer the stream for remote changes.
  // However, to keep the UI snappy for the person making the changes, 
  // we can compare or just prioritize the stream if available.
  return streamUser ?? localUser;
});

final userProvider = StateNotifierProvider<UserNotifier, List<UserAccount>>((ref) {
  return UserNotifier(ref.watch(userServiceProvider), ref);
});
