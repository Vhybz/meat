import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/status_chip.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final users = ref.watch(userProvider);
    final activeUsers = users.where((u) => !u.isDeleted).toList();
    final pendingUsers = activeUsers.where((u) => u.status == AccountStatus.pending).toList();
    final approvedUsers = activeUsers.where((u) => u.status != AccountStatus.pending).toList();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/users';

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: const MainAppBar(title: 'Staff Management', showMenuButton: true),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AppSidebar(
                userId: user.id,
                userName: user.name,
                userRole: user.activePrimaryRole.name.toUpperCase(),
                currentRoute: currentRoute,
                items: MenuService.getMenuItemsForUser(user),
                onTap: (route) => MenuService.navigate(context, route, currentRoute),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              userId: user.id,
              userName: user.name,
              userRole: user.activePrimaryRole.name.toUpperCase(),
              currentRoute: currentRoute,
              items: MenuService.getMenuItemsForUser(user),
              onTap: (route) => MenuService.navigate(context, route, currentRoute),
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
                  const Text('Team Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.m),
                  _buildUserList(context, ref, approvedUsers),
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
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: Icon(_getRoleIcon(user.role), color: Colors.orange),
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.role.name.toUpperCase()} • ${user.email}'),
                Text('Phone: ${user.phone ?? "N/A"} • Gender: ${user.gender ?? "N/A"}', style: const TextStyle(fontSize: 11)),
              ],
            ),
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
            onTap: () => _showUserDetails(context, user),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
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

  Widget _buildUserList(BuildContext context, WidgetRef ref, List<UserAccount> users) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
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
              final isSuspended = user.status == AccountStatus.suspended;
              final effectiveRole = user.activePrimaryRole;
              final isPromoted = user.hasActivePromotion;

              return ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.m),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(effectiveRole).withOpacity(isSuspended ? 0.05 : 0.1),
                  child: Icon(_getRoleIcon(effectiveRole), color: _getRoleColor(effectiveRole).withOpacity(isSuspended ? 0.3 : 1.0), size: 24),
                ),
                title: Row(
                  children: [
                    Text(user.name, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: isSuspended ? AppColors.textLight : AppColors.textDark,
                        decoration: isSuspended ? TextDecoration.lineThrough : null,
                      )
                    ),
                    if (isSuspended) ...[
                      const SizedBox(width: 8),
                      StatusChip(label: 'SUSPENDED', color: Colors.red),
                    ],
                    if (isPromoted) ...[
                      const SizedBox(width: 8),
                      StatusChip(label: 'TEMP ROLE', color: Colors.purple),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                    if (isPromoted)
                      Text('Temporary ${effectiveRole.name.toUpperCase()} until ${DateFormat('MMM dd').format(user.tempRoleEnd!)}', 
                        style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRoleColor(effectiveRole).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getRoleColor(effectiveRole).withOpacity(0.5)),
                      ),
                      child: Text(
                        effectiveRole.name.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getRoleColor(effectiveRole)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (action) => _handleUserAction(context, ref, user, action),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'promote',
                          child: Row(
                            children: const [
                              Icon(Icons.trending_up, size: 18),
                              SizedBox(width: 8),
                              Text('Temporary Promotion'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'manage_roles',
                          child: Row(
                            children: const [
                              Icon(Icons.assignment_ind_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Manage Duties/Roles'),
                            ],
                          ),
                        ),
                        if (isPromoted)
                          PopupMenuItem(
                            value: 'clear_promo',
                            child: Row(
                              children: const [
                                Icon(Icons.layers_clear, size: 18),
                                SizedBox(width: 8),
                                Text('Clear Promotion'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: isSuspended ? 'activate' : 'suspend',
                          child: Row(
                            children: [
                              Icon(isSuspended ? Icons.play_circle_outline : Icons.pause_circle_outline, size: 18),
                              const SizedBox(width: 8),
                              Text(isSuspended ? 'Activate Account' : 'Suspend Account'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: const [
                              Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Delete Staff', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => _showUserDetails(context, user),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserAccount user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: Text('Staff Details: ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Full Name', user.name),
            _detailRow('Email', user.email),
            _detailRow('Phone', user.phone ?? 'Not provided'),
            _detailRow('Gender', user.gender ?? 'Not provided'),
            _detailRow('Date of Birth', user.dob != null ? DateFormat('yyyy-MM-dd').format(user.dob!) : 'Not provided'),
            _detailRow('Role', user.role.name.toUpperCase()),
            _detailRow('Status', user.status.name.toUpperCase()),
            _detailRow('Joined On', DateFormat('MMMM d, yyyy').format(user.createdAt)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _handleUserAction(BuildContext context, WidgetRef ref, UserAccount user, String action) {
    switch (action) {
      case 'suspend':
        ref.read(userProvider.notifier).suspendUser(user.id);
        break;
      case 'activate':
        ref.read(userProvider.notifier).activateUser(user.id);
        break;
      case 'delete':
        _confirmDelete(context, ref, user);
        break;
      case 'promote':
        _showPromotionDialog(context, ref, user);
        break;
      case 'manage_roles':
        _showManageRolesDialog(context, ref, user);
        break;
      case 'clear_promo':
        ref.read(userProvider.notifier).clearTemporaryPromotion(user.id);
        break;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, UserAccount user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: const Text('Delete Staff Account?'),
        content: Text('Are you sure you want to permanently delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(userProvider.notifier).deleteUser(user.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showManageRolesDialog(BuildContext context, WidgetRef ref, UserAccount user) {
    UserRole selectedPrimary = user.role;
    List<UserRole> selectedSecondary = List.from(user.secondaryRoles);
    Set<String> selectedPermissions = Set.from(user.enabledPermissions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: Text('Manage Access: ${user.name}'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assign specific roles and menu duties. Items unchecked will disappear from their sidebar menu.', 
                    style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                  const SizedBox(height: 24),
                  const Text('PRIMARY ROLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryMaroon)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedPrimary,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setState(() {
                      selectedPrimary = v!;
                      // Auto-enable core permissions for the new role if they weren't set
                      if (v == UserRole.admin) selectedPermissions.add('/admin');
                    }),
                  ),
                  const SizedBox(height: 24),
                  const Text('SPECIFIC MENU DUTIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryMaroon)),
                  const Divider(),
                  ...MenuService.getAllAvailableDuties().map((duty) {
                    final bool isEnabled = selectedPermissions.contains(duty['route']);
                    return CheckboxListTile(
                      title: Text(duty['label']!, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(duty['route']!, style: const TextStyle(fontSize: 10)),
                      value: isEnabled,
                      onChanged: (val) {
                        setState(() {
                          if (val!) {
                            selectedPermissions.add(duty['route']!);
                          } else {
                            selectedPermissions.remove(duty['route']!);
                          }
                        });
                      },
                      dense: true,
                      activeColor: AppColors.primaryMaroon,
                      controlAffinity: ListTileControlAffinity.trailing,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text('SECONDARY ROLES (Permissions)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: UserRole.values.map((r) => FilterChip(
                      label: Text(r.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                      selected: selectedSecondary.contains(r),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedSecondary.add(r);
                          } else {
                            selectedSecondary.remove(r);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryMaroon.withOpacity(0.2),
                      checkmarkColor: AppColors.primaryMaroon,
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                ref.read(userProvider.notifier).updateRoles(
                  user.id,
                  primaryRole: selectedPrimary,
                  secondaryRoles: selectedSecondary,
                );
                // Also update permissions
                // We need a specific method for this in UserNotifier if we didn't add it
                // Oh wait, I added togglePermission but not updatePermissions
                // I'll update UserNotifier to have setPermissions
                ref.read(userProvider.notifier).setPermissions(user.id, selectedPermissions);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Updated access for ${user.name}. Menu changes are now active.'),
                    backgroundColor: AppColors.accentGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPromotionDialog(BuildContext context, WidgetRef ref, UserAccount user) {
    DateTimeRange? selectedRange;
    UserRole selectedRole = UserRole.admin;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: Text('Temporarily Promote ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set a temporary role for a specific period. After the period ends, the user will revert to their original role.', 
                style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 24),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Temporary Role', border: OutlineInputBorder()),
                items: UserRole.values
                    .where((r) => r != UserRole.superAdmin && r != user.role)
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => selectedRole = v!),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (range != null) {
                    setState(() => selectedRange = range);
                  }
                },
                icon: const Icon(Icons.date_range),
                label: Text(selectedRange == null 
                  ? 'Select Date Range' 
                  : '${DateFormat('MMM dd').format(selectedRange!.start)} - ${DateFormat('MMM dd').format(selectedRange!.end)}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: selectedRange == null ? Colors.grey : AppColors.primaryMaroon),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedRange == null ? null : () {
                ref.read(userProvider.notifier).promoteTemporarily(
                  user.id, 
                  selectedRole, 
                  selectedRange!.start, 
                  selectedRange!.end
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} promoted to ${selectedRole.name} until ${DateFormat('MMM dd').format(selectedRange!.end)}')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
              child: const Text('Apply Promotion'),
            ),
          ],
        ),
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
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.cashier;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: const Text('Create Staff Account'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: surnameController,
                    decoration: const InputDecoration(labelText: 'Surname', border: OutlineInputBorder()),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'System Role', border: OutlineInputBorder()),
                    items: UserRole.values
                        .where((r) => r != UserRole.superAdmin)
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setState(() => selectedRole = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newUser = UserAccount(
                    id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
                    firstName: firstNameController.text,
                    surname: surnameController.text,
                    email: emailController.text,
                    role: selectedRole,
                    status: AccountStatus.approved, // Admin created accounts are pre-approved
                  );
                  ref.read(userProvider.notifier).addAccount(newUser);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
