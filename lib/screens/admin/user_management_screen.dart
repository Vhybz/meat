import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/main_app_bar.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import 'admin_menu_items.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(userProvider);
    final pendingUsers = ref.watch(userProvider.notifier).getPendingUsers();
    final approvedUsers = users.where((u) => u.status == AccountStatus.approved).toList();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/users';

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: const MainAppBar(title: 'Staff Management', showMenuButton: true),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AppSidebar(
                userName: 'Admin User',
                userRole: 'Administrator',
                currentRoute: currentRoute,
                items: getAdminMenuItems(),
                onTap: (route) => navigateAdmin(context, route, currentRoute),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              userName: 'Admin User',
              userRole: 'Administrator',
              currentRoute: currentRoute,
              items: getAdminMenuItems(),
              onTap: (route) => navigateAdmin(context, route, currentRoute),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, ref),
                  if (pendingUsers.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Text('Pending Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: AppSpacing.m),
                    _buildPendingList(context, ref, pendingUsers),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  const Text('Active Team Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.m),
                  _buildUserList(approvedUsers),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList(BuildContext context, WidgetRef ref, List<UserAccount> pending) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pending.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = pending[index];
          return ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.m),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: Icon(_getRoleIcon(user.role), color: Colors.orange),
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${user.role.name.toUpperCase()} • ${user.email}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () {
                    ref.read(userProvider.notifier).approveUser(user.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Approved ${user.name} as ${user.role.name}')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => ref.read(userProvider.notifier).deleteUser(user.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Employee Accounts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Manage roles and permissions', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(context, ref),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Staff'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee Accounts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Manage roles and permissions for your team', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddUserDialog(context, ref),
          icon: const Icon(Icons.person_add),
          label: const Text('Add New Staff'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(List<UserAccount> users) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.m),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
                  child: Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role), size: 24),
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                    if (user.shopLocation != null)
                      Text('Branch: ${user.shopLocation}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    Text('Joined: ${DateFormat('MMM d, yyyy').format(user.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getRoleColor(user.role).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getRoleColor(user.role)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return Colors.black;
      case UserRole.admin: return Colors.purple;
      case UserRole.butcher: return AppColors.primaryMaroon;
      case UserRole.cashier: return Colors.blue;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return Icons.security;
      case UserRole.admin: return Icons.admin_panel_settings;
      case UserRole.butcher: return Icons.restaurant;
      case UserRole.cashier: return Icons.point_of_sale;
    }
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final locationController = TextEditingController();
    UserRole selectedRole = UserRole.cashier;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: const Text('Create Staff Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'System Role',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                  ),
                  items: UserRole.values
                      .where((r) => r != UserRole.superAdmin)
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setState(() => selectedRole = v!),
                ),
                if (selectedRole == UserRole.cashier) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Assigned Branch',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final newUser = UserAccount(
                  id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  email: emailController.text,
                  role: selectedRole,
                  shopLocation: selectedRole == UserRole.cashier ? locationController.text : null,
                );
                ref.read(userProvider.notifier).addAccount(newUser);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
              ),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
