import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import 'responsive_layout.dart';
import '../services/notification_service.dart';
import '../services/theme_provider.dart';
import '../services/user_provider.dart';
import '../models/user_model.dart';
import '../models/system_models.dart';
import 'calculator_dialog.dart';
import 'ai_chatbot_sheet.dart';

class MainAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
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
  ConsumerState<MainAppBar> createState() => _MainAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _MainAppBarState extends ConsumerState<MainAppBar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final role = user?.activePrimaryRole;
    
    final themeState = ref.watch(themeProvider);
    final bool isDark = themeState.mode == ThemeMode.dark;
    
    final Color roleColor = _getRoleColor(role, isDark, theme);
    const Color contentColor = Colors.white; 
    
    final now = DateTime.now();
    final List<SystemNotification> notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    final Widget body = Container(
      decoration: BoxDecoration(
        color: roleColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark ? Border(bottom: BorderSide(color: theme.dividerColor)) : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
          child: Row(
            children: [
              if (!isDesktop && widget.showMenuButton)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              if (!isDesktop && widget.showMenuButton) const SizedBox(width: AppSpacing.s),
              
              // Dynamic Title Section
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isCollapsed
                        ? Row(
                            key: const ValueKey('collapsed_mode'),
                            children: [
                              _buildProfileAvatar(context, ref, roleColor),
                              const SizedBox(width: AppSpacing.m),
                              if (isDesktop) ...[
                                _buildInfoChip(
                                  context,
                                  icon: Icons.calendar_today_rounded,
                                  label: DateFormat('EEE, MMM dd').format(now),
                                ),
                                const SizedBox(width: AppSpacing.s),
                                _buildInfoChip(
                                  context,
                                  icon: Icons.access_time_rounded,
                                  label: DateFormat('hh:mm a').format(now),
                                ),
                                const SizedBox(width: AppSpacing.s),
                              ],
                              _buildNotificationButton(context, unreadCount, () => _showNotificationsDialog(context, ref, notifications)),
                              const SizedBox(width: AppSpacing.s),
                              _buildRoundButton(
                                context, 
                                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                                () => ref.read(themeProvider.notifier).toggleTheme(!isDark),
                              ),
                              if (widget.actions != null) ...[
                                const SizedBox(width: AppSpacing.s),
                                ...widget.actions!,
                              ],
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 18),
                            ],
                          )
                        : Column(
                            key: const ValueKey('expanded_mode'),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        widget.title,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: contentColor,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildLiveIndicator(ref),
                                  const Spacer(),
                                  _buildRoundButton(
                                    context, 
                                    Icons.calculate_rounded, 
                                    () => showDialog(
                                      context: context, 
                                      builder: (context) => const CalculatorDialog()
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  _buildRoundButton(
                                    context, 
                                    Icons.auto_awesome, 
                                    () => _showAiChatbot(context),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  const Icon(Icons.chevron_left_rounded, color: Colors.white54, size: 18),
                                ],
                              ),
                              Text(
                                user != null 
                                  ? '${user.name} • ${user.activePrimaryRole.name.toUpperCase()}'
                                  : 'Mi~Corazon Butchery System',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              if (!_isCollapsed) ...[
                const SizedBox(width: AppSpacing.s),
                _buildProfileAvatar(context, ref, roleColor),
              ],
            ],
          ),
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: body,
    );
  }

  Widget _buildLiveIndicator(WidgetRef ref) {
    final heartbeat = ref.watch(liveHeartbeatProvider);
    return heartbeat.when(
      data: (tick) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const Icon(Icons.sync_problem, size: 12, color: Colors.white),
    );
  }

  Color _getRoleColor(UserRole? role, bool isDark, ThemeData theme) {
    if (isDark) return theme.appBarTheme.backgroundColor ?? const Color(0xFF1E1E1E);
    return theme.colorScheme.primary;
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

  // Show Notifications
  void _showNotificationsDialog(BuildContext context, WidgetRef ref, List<SystemNotification> notifications) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        backgroundColor: theme.colorScheme.surface,
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
                child: const Center(
                  child: Text(
                    'Recent Notifications', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
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
                        leading: Icon(
                          n.title.contains('BUTCHER') ? Icons.warning : Icons.report, 
                          color: Colors.orange
                        ),
                        title: Text(n.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text(n.message, style: const TextStyle(fontSize: 11)),
                        trailing: Text(DateFormat('hh:mm').format(n.createdAt), style: const TextStyle(fontSize: 10)),
                        tileColor: n.isRead ? null : Colors.orange.withValues(alpha: 0.05),
                        onTap: () {
                          ref.read(notificationProvider.notifier).markAsRead(n.id);
                        },
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s),
                child: TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Dismiss View')
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, WidgetRef ref, Color roleColor) {
    final user = ref.watch(currentUserProvider);

    return InkWell(
      onTap: () {
        if (widget.onProfileTap != null) {
          widget.onProfileTap!();
        } else {
          Navigator.pushNamed(context, '/profile');
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
        child: SizedBox(
          width: 32,
          height: 32,
          child: ClipOval(
            child: user?.photoUrl != null
                ? Image.network(
                    user!.photoUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Profile image load error: $error');
                      return Container(
                        color: Colors.white,
                        child: Icon(Icons.person_rounded, size: 20, color: roleColor),
                      );
                    },
                  )
                : Container(
                    color: Colors.white,
                    child: Icon(Icons.person_rounded, size: 20, color: roleColor),
                  ),
          ),
        ),
      ),
    );
  }

  void _showAiChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiChatbotSheet(),
    );
  }
}
