import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import 'responsive_layout.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                      Text(
                        'Meat Shop Management System',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : AppColors.textLight,
                          fontWeight: FontWeight.w400,
                        ),
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
              
              _buildRoundButton(context, Icons.notifications_none_rounded, () {}),
              const SizedBox(width: AppSpacing.s),
              
              _buildProfileAvatar(context),
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
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.borderGray.withValues(alpha: 0.5)),
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
      color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surfaceWhite,
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
          border: Border.all(color: AppColors.primaryMaroon.withValues(alpha: 0.2), width: 2),
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
