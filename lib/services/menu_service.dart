import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_sidebar.dart';
import '../models/user_model.dart';
import 'user_provider.dart';

class MenuService {
  static List<SidebarItem> getMenuItemsForUser(UserAccount user, {bool inButcherShell = false}) {
    final List<SidebarItem> items = [];
    final roles = user.activeRoles;
    
    // Check if user is Admin or Super Admin
    final isAdmin = roles.contains(UserRole.admin) || roles.contains(UserRole.superAdmin);

    // List of all possible admin items
    final List<SidebarItem> adminItems = [
      SidebarItem(icon: Icons.dashboard_rounded, label: 'Admin Dashboard', route: '/admin'),
      SidebarItem(icon: Icons.bar_chart_rounded, label: 'Sales Analytics', route: '/admin/sales'),
      SidebarItem(icon: Icons.receipt_long_rounded, label: 'Business Expenses', route: '/admin/expenses'),
      SidebarItem(icon: Icons.people_outline_rounded, label: 'Customer Directory', route: '/admin/customers'),
      SidebarItem(icon: Icons.account_balance_wallet_rounded, label: 'Debt Tracker', route: '/admin/debts'),
      SidebarItem(icon: Icons.inventory_2_rounded, label: 'Master Stock Control', route: '/admin/stock'),
      SidebarItem(icon: Icons.people_alt_rounded, label: 'Staff Management', route: '/admin/users'),
    ];

    // 1. Admin Module
    if (roles.contains(UserRole.superAdmin) || isAdmin) {
      for (final item in adminItems) {
        final hasSpecificAdminPerms = user.enabledPermissions.any((p) => p.startsWith('/admin'));
        if (roles.contains(UserRole.superAdmin) || !hasSpecificAdminPerms || user.enabledPermissions.contains(item.route)) {
          items.add(SidebarItem(
            icon: item.icon,
            label: item.label,
            route: item.route,
            isCatchy: user.newlyAddedPermissions.contains(item.route),
          ));
        }
      }
    } else {
      // Check if non-admin has been granted specific admin duties
      for (final item in adminItems) {
        if (user.enabledPermissions.contains(item.route)) {
          items.add(SidebarItem(
            icon: item.icon,
            label: item.label,
            route: item.route,
            isCatchy: user.newlyAddedPermissions.contains(item.route),
          ));
        }
      }
    }

    // 2. Cashier Module
    final hasCashierAccess = roles.contains(UserRole.superAdmin) || 
                             roles.contains(UserRole.cashier) || 
                             user.enabledPermissions.contains('/cashier');
    
    if (hasCashierAccess) {
      items.add(SidebarItem(
        icon: Icons.point_of_sale_rounded, 
        label: 'Cashier POS', 
        route: '/cashier', 
        isCatchy: user.newlyAddedPermissions.contains('/cashier'),
      ));
    }

    // 3. Butcher Module
    final hasButcherAccess = roles.contains(UserRole.superAdmin) || 
                             roles.contains(UserRole.butcher) || 
                             user.enabledPermissions.contains('/butcher');

    if (hasButcherAccess) {
      if (inButcherShell) {
        // Detailed Butcher Menu
        items.addAll([
          SidebarItem(icon: Icons.dashboard_rounded, label: 'Butcher Home', route: 'butcher:dashboard'),
          SidebarItem(icon: Icons.pets_rounded, label: 'Animal Intake', route: 'butcher:animalIntake'),
          SidebarItem(icon: Icons.history_edu_rounded, label: 'Slaughter Logs', route: 'butcher:slaughterLog'),
          SidebarItem(icon: Icons.outdoor_grill, label: 'Meat Processing', route: 'butcher:meatProcessing'),
          SidebarItem(icon: Icons.layers_rounded, label: 'Batch Management', route: 'butcher:batchManagement'),
          SidebarItem(icon: Icons.local_shipping_rounded, label: 'Stock Transfer', route: 'butcher:stockTransfer'),
          SidebarItem(icon: Icons.inventory_2_rounded, label: 'Internal Inventory', route: 'butcher:inventory'),
          SidebarItem(icon: Icons.assignment_rounded, label: 'Processing Orders', route: 'butcher:orders'),
          SidebarItem(icon: Icons.delete_outline_rounded, label: 'Waste Management', route: 'butcher:wasteManagement'),
          SidebarItem(icon: Icons.receipt_long_rounded, label: 'Unit Expenses', route: 'butcher:expenses'),
          SidebarItem(icon: Icons.folder_open_rounded, label: 'Documents', route: 'butcher:documents'),
          SidebarItem(icon: Icons.bar_chart_rounded, label: 'Operational Reports', route: 'butcher:reports'),
        ]);
      } else {
        items.add(SidebarItem(
          icon: Icons.restaurant_rounded, 
          label: 'Butcher Operations', 
          route: '/butcher', 
          isCatchy: user.newlyAddedPermissions.contains('/butcher'),
        ));
      }
    }

    // 4. System Settings (Always visible)
    items.add(SidebarItem(icon: Icons.settings_suggest_rounded, label: 'System Settings', route: '/settings'));

    // Special: Super Admin Root Access
    if (roles.contains(UserRole.superAdmin)) {
      items.add(SidebarItem(icon: Icons.security, label: 'Root Access (Restore)', route: '/admin/super', isCatchy: true));
    }

    return _deduplicateItems(items);
  }

  static List<Map<String, String>> getAllAvailableDuties() {
    return [
      {'route': '/admin', 'label': 'Admin Dashboard'},
      {'route': '/admin/sales', 'label': 'Sales Analytics'},
      {'route': '/admin/expenses', 'label': 'Business Expenses'},
      {'route': '/admin/customers', 'label': 'Customer Directory'},
      {'route': '/admin/debts', 'label': 'Debt Tracker'},
      {'route': '/admin/stock', 'label': 'Master Stock Control'},
      {'route': '/admin/users', 'label': 'Staff Management'},
      {'route': '/cashier', 'label': 'Cashier POS Access'},
      {'route': '/butcher', 'label': 'Butcher Operations Access'},
      {'route': '/settings', 'label': 'System Settings'},
    ];
  }

  static List<SidebarItem> _deduplicateItems(List<SidebarItem> items) {
    final seen = <String>{};
    return items.where((item) => seen.add(item.route)).toList();
  }

  static void navigate(BuildContext context, String route, String currentRoute) {
    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }
}

/// A reactive provider for menu items based on the current user
final menuItemsProvider = Provider<List<SidebarItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return MenuService.getMenuItemsForUser(user);
});
