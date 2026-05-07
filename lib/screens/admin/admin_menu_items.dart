import 'package:flutter/material.dart';
import '../../widgets/app_sidebar.dart';

List<SidebarItem> getAdminMenuItems() => [
      SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/admin'),
      SidebarItem(icon: Icons.bar_chart_rounded, label: 'Sales Reports', route: '/admin/sales'),
      SidebarItem(icon: Icons.account_balance_wallet_rounded, label: 'Debt Tracker', route: '/admin/debts'),
      SidebarItem(icon: Icons.inventory_2_rounded, label: 'Inventory Control', route: '/admin/stock'),
      SidebarItem(icon: Icons.people_alt_rounded, label: 'Staff Management', route: '/admin/users'),
      SidebarItem(icon: Icons.settings_suggest_rounded, label: 'System Settings', route: '/admin/settings'),
    ];

void navigateAdmin(BuildContext context, String route, String currentRoute) {
  if (route == currentRoute) return;
  Navigator.pushReplacementNamed(context, route);
}
