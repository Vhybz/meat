import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import 'admin_menu_items.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/settings';

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: const MainAppBar(title: 'System Settings', showMenuButton: true),
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
                  const Text('General Configuration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSection(
                    'Shop Information',
                    [
                      _settingTile(Icons.store, 'Shop Name', 'Mi CORAZON FRESHMEAT BUTCHERY'),
                      _settingTile(Icons.location_on, 'Location', 'New Town, Road linking From Water works Ltd. to Atronie Road'),
                      _settingTile(Icons.gps_fixed, 'GPS Address', 'BS-0006-1566'),
                      _settingTile(Icons.phone, 'Contact', '0209276200 / 0209276217 / 0243672146'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSection(
                    'Brand Identity',
                    [
                      _settingTile(Icons.auto_awesome, 'Slogan', 'Uncompromising Quality, Unforgettable Taste'),
                      _settingTile(Icons.color_lens, 'Primary Theme', 'Maroon & White'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSection(
                    'Finance & Taxes',
                    [
                      _settingTile(Icons.currency_exchange, 'Default Currency', 'GHS (Ghana Cedi)'),
                      _settingTile(Icons.receipt_long, 'Tax Rate (VAT)', '15.0%'),
                      _settingTile(Icons.print, 'Receipt Footer', '“Give thanks to the Lord...”'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSection(
                    'User & Security',
                    [
                      _settingTile(Icons.lock, 'Admin Password', '••••••••'),
                      _settingTile(Icons.backup, 'Database Backup', 'Last synced: 2 hours ago'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      'Meat Shop Management System v1.0.0 (Build +1)',
                      style: TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryMaroon)),
        const SizedBox(height: AppSpacing.m),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.m),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textLight),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textLight),
        ],
      ),
      onTap: () {},
    );
  }
}
