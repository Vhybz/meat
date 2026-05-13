import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/app_sidebar.dart';
import '../services/menu_service.dart';
import '../services/user_provider.dart';
import '../widgets/role_pop_scope.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/settings';

    return RolePopScope(
      currentRoute: currentRoute,
      child: Scaffold(
        backgroundColor: AppColors.surfaceWhite,
        appBar: const MainAppBar(title: 'Account Settings'),
        drawer: isDesktop ? null : Drawer(
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
                    const Text('System & Profile Preferences', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Manage your account security and application display', style: TextStyle(color: AppColors.textLight)),
                    const SizedBox(height: AppSpacing.xl),
                    
                    _buildSection(
                      'Profile Details',
                      [
                        ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          trailing: const Icon(Icons.verified, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _buildSection(
                      'Security',
                      [
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Change Password'),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.vibration),
                          title: const Text('Two-Factor Authentication'),
                          trailing: Switch(value: false, onChanged: (v) {}),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Card(child: Column(children: children)),
      ],
    );
  }
}
