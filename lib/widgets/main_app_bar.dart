import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import 'responsive_layout.dart';
import '../services/notification_service.dart';
import '../services/theme_provider.dart';
import '../services/user_provider.dart';

class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenuButton;
  final VoidCallback? onProfileTap;

  const MainAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showMenuButton = true,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final now = DateTime.now();
    final notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
          child: Row(
            children: [
              if (!isDesktop && showMenuButton)
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : AppColors.primaryMaroon),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              if (!isDesktop && showMenuButton) const SizedBox(width: AppSpacing.s),
              
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isDesktop)
                      Consumer(
                        builder: (context, ref, _) {
                          final user = ref.watch(currentUserProvider);
                          return Text(
                            user != null 
                              ? '${user.name} • ${user.activePrimaryRole.name.toUpperCase()}'
                              : 'Freshmeat Butchery Management System',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : AppColors.textLight,
                              fontWeight: FontWeight.w400,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              if (isDesktop) ...[
                _buildInfoChip(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: DateFormat('EEE, MMM dd').format(now),
                ),
                const SizedBox(width: AppSpacing.m),
                _buildInfoChip(
                  context,
                  icon: Icons.access_time_rounded,
                  label: DateFormat('hh:mm a').format(now),
                ),
                const SizedBox(width: AppSpacing.l),
              ],

              if (actions != null) ...actions!,
              
              const SizedBox(width: AppSpacing.m),
              
              // Theme Toggle
              _buildRoundButton(
                context, 
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                () => ref.read(themeProvider.notifier).toggleTheme(!isDark),
              ),
              const SizedBox(width: AppSpacing.s),

              _buildNotificationButton(context, unreadCount, () => _showNotificationsDialog(context, ref, notifications)),
              const SizedBox(width: AppSpacing.s),
              
              _buildProfileAvatar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, int count, VoidCallback onTap) {
    return Stack(
      children: [
        _buildRoundButton(context, Icons.notifications_none_rounded, onTap),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationsDialog(BuildContext context, WidgetRef ref, List<AppNotification> notifications) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: const BoxDecoration(
                  color: AppColors.primaryMaroon,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
                ),
                child: const Text('Recent Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (notifications.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Text('No new notifications.'))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return ListTile(
                        leading: Icon(n.title.contains('BUTCHER') ? Icons.warning : Icons.report, color: Colors.orange),
                        title: Text(n.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text(n.message, style: const TextStyle(fontSize: 11)),
                        trailing: Text(DateFormat('hh:mm').format(n.timestamp), style: const TextStyle(fontSize: 10)),
                        tileColor: n.isRead ? null : Colors.orange.withOpacity(0.05),
                        onTap: () {
                          ref.read(notificationProvider.notifier).markAsRead(n.id);
                        },
                      );
                    },
                  ),
                ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.borderGray.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryMaroon),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(BuildContext context, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white.withOpacity(0.05) : AppColors.surfaceWhite,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: isDark ? Colors.white70 : AppColors.textDark),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return InkWell(
      onTap: onProfileTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.2), width: 2),
        ),
        child: const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryMaroon,
          child: Icon(Icons.person_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
