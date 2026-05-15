import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'supabase_user_service.dart';
import 'sms_service.dart';

class UserNotifier extends StateNotifier<List<UserAccount>> {
  final SupabaseUserService service;
  final Ref ref;

  UserNotifier(this.service, this.ref) : super([]);

  // Centralized method to update local state and notify session listeners
  void _updateLocalAndSession(UserAccount updatedUser) {
    // 1. Update the main list state
    state = [
      for (final u in state)
        if (u.id == updatedUser.id) updatedUser else u
    ];

    // 2. If this is the currently logged-in user, update their session profile instantly
    if (updatedUser.id == ref.read(currentUserIdProvider)) {
      ref.read(sessionUserProfileProvider.notifier).state = updatedUser;
    }
  }

  Future<void> loadUsers({bool silent = false}) async {
    try {
      final currentId = ref.read(currentUserIdProvider);
      if (currentId == null) return;

      final currentUser = await service.getUserById(currentId);
      
      // Update session profile only if it changed to avoid unnecessary rebuilds
      if (currentUser != null) {
        final existing = ref.read(sessionUserProfileProvider);
        if (existing == null || existing.toJson().toString() != currentUser.toJson().toString()) {
          ref.read(sessionUserProfileProvider.notifier).state = currentUser;
        }
      }

      final allUsers = await service.getUsers();
      List<UserAccount> filteredUsers = allUsers;
      
      if (currentUser?.role != UserRole.superAdmin && currentUser?.branchCode != null) {
        filteredUsers = allUsers.where((u) => u.branchCode == currentUser!.branchCode).toList();
      }
      
      // Update state only if list changed
      if (state.length != filteredUsers.length || state.toString() != filteredUsers.toString()) {
         state = filteredUsers;
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
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          firstName: firstName,
          surname: surname,
          phone: phone,
          gender: gender,
          dob: dob,
          branchCode: branchCode,
        );
        
        _updateLocalAndSession(updatedUser); // Instant UI Update
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Profile Update Error: $e');
    }
  }

  Future<void> updateRoles(String userId, {UserRole? primaryRole, List<UserRole>? secondaryRoles}) async {
    try {
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          role: primaryRole,
          secondaryRoles: secondaryRoles,
        );
        _updateLocalAndSession(updatedUser); // Instant UI Update
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Role Update Error: $e');
    }
  }

  Future<void> approveUser(String userId) async {
    try {
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(status: AccountStatus.approved);
        _updateLocalAndSession(updatedUser);
        await service.updateUser(updatedUser);
        
        // Notify approved user via SMS
        await SmsService.sendApprovalSms(updatedUser);
      }
    } catch (e) {
      debugPrint('Approve User Error: $e');
    }
  }

  Future<void> suspendUser(String userId) async {
    try {
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(status: AccountStatus.suspended);
        _updateLocalAndSession(updatedUser);
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Suspend User Error: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await service.hardDeleteUser(userId);
      state = state.where((u) => u.id != userId).toList();
    } catch (e) {
      debugPrint('Delete User Error: $e');
    }
  }

  Future<void> restoreUser(String userId) async {
    try {
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(isDeleted: false);
        _updateLocalAndSession(updatedUser);
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Restore User Error: $e');
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(status: AccountStatus.approved);
        _updateLocalAndSession(updatedUser);
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Activate User Error: $e');
    }
  }

  Future<void> setPermissions(String userId, Set<String> permissions) async {
    try {
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          newlyAddedPermissions: permissions.difference(user.enabledPermissions),
          enabledPermissions: permissions,
        );
        _updateLocalAndSession(updatedUser); // Instant UI Update
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Set Permissions Error: $e');
    }
  }

  Future<void> updatePhoto(String userId, Uint8List bytes) async {
    try {
      final url = await service.uploadProfilePicture(userId, bytes);
      if (url != null) {
        final user = await _getUser(userId);
        if (user != null) {
          final updatedUser = user.copyWith(photoUrl: url);
          _updateLocalAndSession(updatedUser);
          await service.updateUser(updatedUser);
        }
      }
    } catch (e) {
      debugPrint('Update Photo Error: $e');
    }
  }

  Future<void> markPermissionAsSeen(String userId, String permission) async {
    try {
      final user = await _getUser(userId);
      if (user != null && user.newlyAddedPermissions.contains(permission)) {
        final updatedUser = user.copyWith(
          newlyAddedPermissions: (Set.from(user.newlyAddedPermissions)..remove(permission)),
        );
        _updateLocalAndSession(updatedUser);
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Mark Permission Error: $e');
    }
  }

  Future<void> promoteTemporarily(String userId, UserRole tempRole, DateTime start, DateTime end) async {
    try {
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          temporaryRole: tempRole, 
          tempRoleStart: start, 
          tempRoleEnd: end
        );
        _updateLocalAndSession(updatedUser);
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Promote Error: $e');
    }
  }

  Future<void> clearTemporaryPromotion(String userId) async {
    try {
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(clearPromotion: true);
        _updateLocalAndSession(updatedUser);
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Clear Promotion Error: $e');
    }
  }

  Future<void> togglePermission(String userId, String permission) async {
    try {
      final user = await _getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          enabledPermissions: user.enabledPermissions.contains(permission)
              ? (Set.from(user.enabledPermissions)..remove(permission))
              : (Set.from(user.enabledPermissions)..add(permission)),
        );
        _updateLocalAndSession(updatedUser);
        await service.updateUser(updatedUser);
      }
    } catch (e) {
      debugPrint('Toggle Permission Error: $e');
    }
  }

  // Helper to find a user even if they aren't in the currently filtered state list
  Future<UserAccount?> _getUser(String id) async {
    try {
      return state.firstWhere((u) => u.id == id);
    } catch (_) {
      return await service.getUserById(id);
    }
  }

  Future<void> permanentlyDeleteUser(String userId) async {
    try {
      await service.hardDeleteUser(userId);
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

// This holds the currently logged-in user's profile and is updated instantly locally
final sessionUserProfileProvider = StateProvider<UserAccount?>((ref) => null);

/// Listens for real-time changes to the current user's profile from the database
final currentUserStreamProvider = StreamProvider<UserAccount?>((ref) {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) return const Stream.empty();
  
  return ref.watch(userServiceProvider).streamUser(id).handleError((error) {
    debugPrint('Real-time User Stream Error: $error');
  });
});

/// A synchronous provider that gives access to the current user profile.
/// It prioritizes the manual session state for instant UI updates.
final currentUserProvider = Provider<UserAccount?>((ref) {
  final currentId = ref.watch(currentUserIdProvider);
  if (currentId == null) return null;

  // 1. Check the manual session state first (updated instantly by UserNotifier)
  final sessionUser = ref.watch(sessionUserProfileProvider);
  
  // 2. Check the real-time stream (source of truth for remote updates)
  final streamUser = ref.watch(currentUserStreamProvider).value;
  
  // Prioritize sessionUser for instant feedback, then streamUser, then fallback to current list
  if (sessionUser != null) return sessionUser;
  if (streamUser != null) return streamUser;

  try {
    return ref.watch(userProvider).firstWhere((u) => u.id == currentId);
  } catch (_) {
    return null;
  }
});

final userProvider = StateNotifierProvider<UserNotifier, List<UserAccount>>((ref) {
  return UserNotifier(ref.watch(userServiceProvider), ref);
});

/// A heartbeat provider that triggers every 3 seconds to keep things "live"
final liveHeartbeatProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 3), (count) => count);
});
