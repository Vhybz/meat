import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../services/butcher_navigation_provider.dart';
import '../../services/user_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Configure your workstation and profile', style: TextStyle(color: AppColors.textLight)),
          const SizedBox(height: AppSpacing.xl),

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
                activeThumbColor: AppColors.primaryMaroon,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.timer_outlined),
                title: const Text('Process Timing'),
                subtitle: const Text('Track duration of each slaughter'),
                value: true,
                onChanged: (v) {},
                activeThumbColor: AppColors.primaryMaroon,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildSettingsSection(
            context,
            'Personal Profile',
            [
              Builder(
                builder: (context) {
                  final user = ref.watch(currentUserProvider);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryMaroon,
                      backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                      child: user?.photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(user?.name ?? 'Butcher Profile'),
                    subtitle: Text('ID: ${user?.id.substring(0, 8).toUpperCase() ?? '---'} • ${user?.role.name.toUpperCase() ?? 'STAFF'}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      ref.read(butcherNavProvider.notifier).setScreen(ButcherScreen.profile);
                    },
                  );
                }
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
