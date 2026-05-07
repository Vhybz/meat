import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../services/theme_provider.dart';
import '../../services/butcher_navigation_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSection(
            context,
            'Appearance',
            [
              ListTile(
                leading: Icon(
                  themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.primaryMaroon,
                ),
                title: const Text('Theme Mode'),
                subtitle: Text(themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (isDark) {
                    ref.read(themeProvider.notifier).toggleTheme(isDark);
                  },
                  activeThumbColor: AppColors.primaryMaroon,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildSettingsSection(
            context,
            'Workstation Configuration',
            [
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Label Printer'),
                subtitle: const Text('Zebra ZD421 - Connected'),
                trailing: TextButton(onPressed: () {}, child: const Text('Configure')),
              ),
              ListTile(
                leading: const Icon(Icons.scale),
                title: const Text('Digital Scale'),
                subtitle: const Text('Toledo 8450 - Calibrated'),
                trailing: TextButton(onPressed: () {}, child: const Text('Recalibrate')),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildSettingsSection(
            context,
            'App Preferences',
            [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Inventory Alerts'),
                subtitle: const Text('Notify when stock is below threshold'),
                value: true,
                onChanged: (v) {},
                activeColor: AppColors.primaryMaroon,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.timer_outlined),
                title: const Text('Process Timing'),
                subtitle: const Text('Track duration of each slaughter'),
                value: true,
                onChanged: (v) {},
                activeColor: AppColors.primaryMaroon,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildSettingsSection(
            context,
            'Personal Profile',
            [
              ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.primaryMaroon, child: Icon(Icons.person, color: Colors.white)),
                title: const Text('Ramon Dela Cruz'),
                subtitle: const Text('ID: BTC-0042 • Butcher Level 3'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  ref.read(butcherNavProvider.notifier).setScreen(ButcherScreen.profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change PIN'),
                subtitle: const Text('Used for workstation authorization'),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16, 
              color: AppColors.primaryMaroon,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
