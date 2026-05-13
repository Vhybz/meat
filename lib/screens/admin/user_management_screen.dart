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
import '../../services/branch_provider.dart';
import '../../widgets/role_pop_scope.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh user list whenever this screen is initialized (opened)
    Future.microtask(() => ref.read(userProvider.notifier).loadUsers());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final users = ref.watch(userProvider);
    final activeUsers = users.where((u) => !u.isDeleted).toList();
    final pendingUsers = activeUsers.where((u) => u.status == AccountStatus.pending).toList();
    final approvedUsers = activeUsers.where((u) => u.status != AccountStatus.pending).toList();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/users';

    return RolePopScope(
      currentRoute: currentRoute,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
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
                    const SizedBox(height: AppSpacing.m),
                    _buildSummaryInfo(context, activeUsers, pendingUsers),
                    if (pendingUsers.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text('Pending Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                      const SizedBox(height: AppSpacing.m),
                      _buildPendingList(context, ref, pendingUsers),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Text('Team Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: AppSpacing.m),
                    _buildUserList(context, ref, approvedUsers),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList(BuildContext context, WidgetRef ref, List<UserAccount> pending) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pending.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
        itemBuilder: (context, index) {
          final user = pending[index];
          return ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.m),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
              child: Icon(_getRoleIcon(user.role), color: theme.colorScheme.secondary),
            ),
            title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.role.name.toUpperCase()} • ${user.email}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                Text('Branch: ${user.branchCode ?? "Global"} • Phone: ${user.phone ?? "N/A"}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _confirmApproval(context, ref, user),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _confirmDelete(context, ref, user),
                ),
              ],
            ),
            onTap: () => _showUserDetails(context, user),
          );
        },
      ),
    );
  }

  void _confirmApproval(BuildContext context, WidgetRef ref, UserAccount user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: const Text('Approve Staff Access?'),
        content: Text('Are you sure you want to approve ${user.name} as a ${user.role.name}? They will be notified via SMS and can log in immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(userProvider.notifier).approveUser(user.id);
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Success'),
                  content: Text('${user.name} has been approved and notified.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: isMobile ? 0 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Staff & Access Control', 
                style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('Manage system roles, permissions, and team approvals', 
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isMobile) const SizedBox(height: AppSpacing.m) else const SizedBox(width: 16),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
              onPressed: () => ref.read(userProvider.notifier).loadUsers(),
              tooltip: 'Refresh Staff List',
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(context, ref),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Staff'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryInfo(BuildContext context, List<UserAccount> active, List<UserAccount> pending) {
    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      children: [
        _miniStatCard(context, 'Total Staff', active.length.toString(), Icons.people, Colors.blue),
        _miniStatCard(context, 'Awaiting Approval', pending.length.toString(), Icons.hourglass_top, Colors.orange),
        _miniStatCard(context, 'Active Today', active.where((u) => u.status == AccountStatus.approved).length.toString(), Icons.check_circle_outline, Colors.green),
      ],
    );
  }

  Widget _miniStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.2 : 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildUserList(BuildContext context, WidgetRef ref, List<UserAccount> users) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    if (users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: theme.dividerColor),
            const SizedBox(height: AppSpacing.m),
            Text('No staff members found in this branch.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
        border: isDark ? Border.all(color: theme.dividerColor) : null,
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
            itemBuilder: (context, index) {
              final user = users[index];
              final isSuspended = user.status == AccountStatus.suspended;
              final effectiveRole = user.activePrimaryRole;
              final isPromoted = user.hasActivePromotion;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 22 : 26,
                      backgroundColor: _getRoleColor(effectiveRole).withValues(alpha: isSuspended ? 0.05 : 0.1),
                      child: Icon(_getRoleIcon(effectiveRole), color: _getRoleColor(effectiveRole).withValues(alpha: isSuspended ? 0.3 : 1.0), size: isMobile ? 20 : 24),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isSuspended ? Colors.red : Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.cardTheme.color!, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(user.name, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: isMobile ? 14 : 16,
                          color: isSuspended ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                          decoration: isSuspended ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isPromoted) ...[
                      const StatusChip(label: 'PROMO', color: Colors.purple),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(user.email, 
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(Icons.map_outlined, size: 10, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(user.branchCode ?? "Global HQ", style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                          const SizedBox(width: 12),
                          Icon(Icons.phone_outlined, size: 10, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(user.phone ?? "No Phone", style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMobile)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(effectiveRole).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getRoleColor(effectiveRole).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          effectiveRole.name.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getRoleColor(effectiveRole), letterSpacing: 0.5),
                        ),
                      ),
                    const SizedBox(width: 4),
                    _buildUserActionMenu(context, ref, user, isSuspended, isPromoted),
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

  Widget _buildUserActionMenu(BuildContext context, WidgetRef ref, UserAccount user, bool isSuspended, bool isPromoted) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      onSelected: (action) => _handleUserAction(context, ref, user, action),
      icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'manage_roles',
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, size: 18, color: Colors.blue),
              SizedBox(width: 12),
              Text('Edit Permissions', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'promote',
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: Colors.purple.shade700),
              const SizedBox(width: 12),
              const Text('Temporary Role', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        if (isPromoted)
          const PopupMenuItem(
            value: 'clear_promo',
            child: Row(
              children: [
                Icon(Icons.layers_clear_outlined, size: 18, color: Colors.orange),
                SizedBox(width: 12),
                Text('Reset to Original Role', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        PopupMenuItem(
          value: isSuspended ? 'activate' : 'suspend',
          child: Row(
            children: [
              Icon(isSuspended ? Icons.play_circle_outline : Icons.pause_circle_outline, 
                size: 18, color: isSuspended ? Colors.green : Colors.orange),
              const SizedBox(width: 12),
              Text(isSuspended ? 'Reactivate Staff' : 'Suspend Staff', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
              SizedBox(width: 12),
              Text('Remove Member', style: TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ),
        ),
      ],
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
    final theme = Theme.of(context);
    final currentUser = ref.read(currentUserProvider);
    UserRole selectedPrimary = user.role;
    List<UserRole> selectedSecondary = List.from(user.secondaryRoles);
    Set<String> selectedPermissions = Set.from(user.enabledPermissions);
    String? selectedBranchCode = user.branchCode;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Access Control: ${user.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      const Text('Configure branch, roles, and menu permissions', style: TextStyle(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'ASSIGNED BRANCH', Icons.map_outlined),
                  Consumer(
                    builder: (context, ref, _) {
                      final branchesAsync = ref.watch(branchesProvider);
                      final isSuperAdmin = currentUser?.role == UserRole.superAdmin;
                      
                      return branchesAsync.when(
                        data: (branches) => DropdownButtonFormField<String>(
                          initialValue: selectedBranchCode,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(), 
                            isDense: true, 
                            helperText: isSuperAdmin ? null : 'Branch transfers require Super Admin access',
                          ),
                          items: branches.map((b) => DropdownMenuItem(
                            value: b.code, 
                            child: Text('${b.name} (${b.location})')
                          )).toList(),
                          onChanged: isSuperAdmin ? (v) => setState(() => selectedBranchCode = v) : null,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => const Text('Error loading branches', style: TextStyle(color: Colors.red, fontSize: 11)),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'PRIMARY SYSTEM ROLE', Icons.work_outline),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedPrimary,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setState(() {
                      selectedPrimary = v!;
                      if (v == UserRole.admin) selectedPermissions.add('/admin');
                    }),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'SPECIFIC MENU ACCESS', Icons.menu_open_rounded),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.s),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: MenuService.getAllAvailableDuties().map((duty) {
                        final bool isEnabled = selectedPermissions.contains(duty['route']);
                        return CheckboxListTile(
                          title: Text(duty['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          subtitle: Text(duty['route']!, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
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
                          activeColor: theme.colorScheme.primary,
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'SECONDARY PERMISSIONS', Icons.layers_outlined),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: theme.colorScheme.primary,
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setState(() => isSaving = true);
                try {
                  await ref.read(userProvider.notifier).updateRoles(
                    user.id,
                    primaryRole: selectedPrimary,
                    secondaryRoles: selectedSecondary,
                  );
                  await ref.read(userProvider.notifier).updateProfile(user.id, branchCode: selectedBranchCode);
                  await ref.read(userProvider.notifier).setPermissions(user.id, selectedPermissions);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Access updated for ${user.name}'), backgroundColor: AppColors.accentGreen),
                    );
                  }
                } catch (e) {
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                } finally {
                  if (context.mounted) setState(() => isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.primary, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  void _showPromotionDialog(BuildContext context, WidgetRef ref, UserAccount user) {
    final theme = Theme.of(context);
    DateTimeRange? selectedRange;
    final availableRoles = UserRole.values
        .where((r) => r != UserRole.superAdmin && r != user.role)
        .toList();
    
    if (availableRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other roles available for promotion.')),
      );
      return;
    }

    UserRole selectedRole = availableRoles.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: Text('Temporarily Promote ${user.name}', overflow: TextOverflow.ellipsis),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set a temporary role for a specific period. After the period ends, the user will revert to their original role.', 
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              DropdownButtonFormField<UserRole>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Temporary Role'),
                items: availableRoles
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
                  side: BorderSide(color: selectedRange == null ? theme.dividerColor : theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          actionsOverflowButtonSpacing: 8,
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
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
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
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
    final currentUser = ref.read(currentUserProvider);
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.cashier;
    String? selectedBranchCode = currentUser?.branchCode;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Register Staff Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                Text('Create a managed account for your employee', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          content: Form(
            key: formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 300) {
                            return Column(
                              children: [
                                _buildFormTextField(
                                  context: context,
                                  controller: firstNameController,
                                  label: 'First Name',
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
                                ),
                                const SizedBox(height: AppSpacing.m),
                                _buildFormTextField(
                                  context: context,
                                  controller: surnameController,
                                  label: 'Surname',
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _buildFormTextField(
                                  context: context,
                                  controller: firstNameController,
                                  label: 'First Name',
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: _buildFormTextField(
                                  context: context,
                                  controller: surnameController,
                                  label: 'Surname',
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.m),
                      _buildFormTextField(
                        context: context,
                        controller: emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Managed Role',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        items: UserRole.values
                            .where((r) => r != UserRole.superAdmin)
                            .map((r) => DropdownMenuItem(
                              value: r, 
                              child: Text(r.name.toUpperCase(), overflow: TextOverflow.ellipsis)
                            ))
                            .toList(),
                        onChanged: (v) => setState(() => selectedRole = v!),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Consumer(
                        builder: (context, ref, _) {
                          final branchesAsync = ref.watch(branchesProvider);
                          final isSuperAdmin = currentUser?.role == UserRole.superAdmin;

                          return branchesAsync.when(
                            data: (branches) => DropdownButtonFormField<String>(
                              initialValue: selectedBranchCode,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Assign to Branch',
                                prefixIcon: const Icon(Icons.map_outlined),
                                fillColor: isSuperAdmin ? null : theme.colorScheme.surfaceContainerHighest,
                                helperText: isSuperAdmin ? 'Select destination branch' : 'Locked to your current branch',
                              ),
                              items: branches.map((b) => DropdownMenuItem(
                                value: b.code, 
                                child: Text('${b.name} (${b.location})', overflow: TextOverflow.ellipsis)
                              )).toList(),
                              onChanged: isSuperAdmin ? (v) => setState(() => selectedBranchCode = v!) : null,
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: LinearProgressIndicator(),
                              ),
                            ),
                            error: (err, _) => const Text(
                              'Error loading branches. Ensure they are created in Admin.',
                              style: TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                          border: Border.all(color: Colors.blue.withOpacity(0.1)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'The employee will need to set their own password upon first login or contact support.',
                                style: TextStyle(fontSize: 10, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() => isSaving = true);
                  try {
                    final String email = emailController.text.trim();
                    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                    final String suffix = timestamp.substring(timestamp.length - 12);
                    final String validUuid = '00000000-0000-0000-0000-$suffix';

                    final newUser = UserAccount(
                      id: validUuid,
                      firstName: firstNameController.text.trim(),
                      surname: surnameController.text.trim(),
                      email: email,
                      role: selectedRole,
                      branchCode: selectedBranchCode,
                      status: AccountStatus.approved,
                    );
                    await ref.read(userProvider.notifier).addAccount(newUser);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Account created for ${newUser.name}'),
                          backgroundColor: AppColors.accentGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating account: $e'), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (context.mounted) setState(() => isSaving = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm & Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      ),
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
    );
  }
}
