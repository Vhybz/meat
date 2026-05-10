import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/product_seeder.dart';

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  bool _isSeeding = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/settings';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const MainAppBar(title: 'System Settings', showMenuButton: true),
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
                  Text('General Configuration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSection(
                    context,
                    'Shop Information',
                    [
                      _settingTile(context, Icons.store, 'Shop Name', 'Mi CORAZON FRESHMEAT BUTCHERY'),
                      _settingTile(context, Icons.location_on, 'Location', 'New Town, Road linking From Water works Ltd. to Atronie Road'),
                      _settingTile(context, Icons.gps_fixed, 'GPS Address', 'BS-0006-1566'),
                      _settingTile(context, Icons.phone, 'Contact', '0209276200 / 0209276217 / 0243672146'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSection(
                    context,
                    'Brand Identity',
                    [
                      _settingTile(context, Icons.auto_awesome, 'Slogan', 'Uncompromising Quality, Unforgettable Taste'),
                      _settingTile(context, Icons.color_lens, 'Primary Theme', 'Maroon & White'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSection(
                    context,
                    'Finance & Taxes',
                    [
                      _settingTile(context, Icons.currency_exchange, 'Default Currency', 'GHS (Ghana Cedi)'),
                      _settingTile(context, Icons.receipt_long, 'Tax Rate (VAT)', '15.0%'),
                      _settingTile(context, Icons.print, 'Receipt Footer', '“Give thanks to the Lord...”'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSection(
                    context,
                    'Database & Maintenance',
                    [
                      ListTile(
                        leading: Icon(Icons.inventory_2, color: theme.colorScheme.onSurfaceVariant),
                        title: Text('Initial Product Catalog', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface)),
                        subtitle: Text('Populate database with default Chicken, Beef, Pork and Goat items', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                        trailing: _isSeeding 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.upload_file, color: theme.colorScheme.primary),
                        onTap: _isSeeding ? null : () async {
                          setState(() => _isSeeding = true);
                          try {
                            await ref.read(productSeederProvider).seedProducts();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Product catalog populated successfully!'), backgroundColor: AppColors.accentGreen),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSeeding = false);
                          }
                        },
                      ),
                      _settingTile(context, Icons.backup, 'Cloud Backup', 'Last synced: 2 hours ago'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      'Meat Shop Management System v1.0.0 (Build +1)',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.m),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
            ],
            border: Border.all(color: theme.dividerColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.m),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _settingTile(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        ],
      ),
      onTap: () {},
    );
  }
}
