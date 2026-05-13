import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/user_provider.dart';
import '../services/customer_provider.dart';
import '../services/sale_provider.dart';
import '../services/product_service.dart';
import '../services/expense_provider.dart';
import '../services/branch_provider.dart';
import '../services/transfer_provider.dart';
import '../services/butcher_service.dart';
import '../services/auth_provider.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;
  final bool isCatchy;

  SidebarItem({
    required this.icon, 
    required this.label, 
    required this.route,
    this.isCatchy = false,
  });
}

class AppSidebar extends ConsumerWidget {
  final List<SidebarItem> items;
  final String currentRoute;
  final String userName;
  final String userRole;
  final String userId;
  final Function(String route)? onTap;

  const AppSidebar({
    super.key,
    required this.items,
    required this.currentRoute,
    required this.userName,
    required this.userRole,
    required this.userId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarColor = isDark ? theme.colorScheme.surface : AppColors.primaryMaroon;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: sidebarColor,
          border: isDark ? const Border(right: BorderSide(color: Color(0xFF2C2C2C))) : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(4, 0),
              ),
          ],
        ),
        child: Column(
          children: [
            // Ensure logo doesn't collide with status bar on mobile
            SafeArea(
              bottom: false,
              child: _buildLogo(),
            ),
            const Divider(height: 1, color: Colors.white10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = currentRoute == item.route;
                        return _buildMenuItem(context, ref, item, isSelected);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            _buildUserSection(context, ref, isDark),
            _buildBottomActions(context, ref, isDark),
            // Ensure content doesn't get hidden under system navigation bar
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.s),
              border: Border.all(color: Colors.white24),
              image: const DecorationImage(
                image: AssetImage('assets/logo/logo.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi CORAZON',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Butchery System',
                  style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, WidgetRef ref, SidebarItem item, bool isSelected) {
    final bool showCatchy = item.isCatchy && !isSelected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: () {
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
          
          if (item.isCatchy) {
            ref.read(userProvider.notifier).markPermissionAsSeen(userId, item.route);
          }
          
          Future.delayed(const Duration(milliseconds: 100), () {
            if (onTap != null) onTap!(item.route);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 12),
          decoration: BoxDecoration(
            border: isSelected 
              ? Border(left: BorderSide(color: isDark ? Theme.of(context).colorScheme.primary : Colors.white, width: 4)) 
              : null,
            color: isSelected 
              ? Colors.white.withValues(alpha: 0.1) 
              : (showCatchy ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                item.icon, 
                color: isSelected 
                  ? Colors.white 
                  : (showCatchy ? Colors.orangeAccent : Colors.white70), 
                size: 20
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected 
                      ? Colors.white 
                      : (showCatchy ? Colors.orangeAccent : Colors.white70),
                    fontWeight: (isSelected || showCatchy) ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showCatchy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context, WidgetRef ref, bool isDark) {
    final user = ref.watch(currentUserProvider);
    final displayPhoto = user?.photoUrl;

    return InkWell(
      onTap: () {
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold?.isDrawerOpen ?? false) {
          Navigator.pop(context);
        }
        Navigator.pushNamed(context, '/profile');
      },
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white12 : Colors.white24,
              ),
              child: ClipOval(
                child: displayPhoto != null 
                  ? Image.network(
                      displayPhoto,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)));
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 20),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                  Text(user?.activePrimaryRole.name.toUpperCase() ?? userRole, style: const TextStyle(color: Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _handleRefresh(context, ref),
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            tooltip: 'Refresh System Data',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton.icon(
              onPressed: () async {
                await GlobalLogout.perform(ref);
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
              label: const Text(
                'Log Out System', 
                style: TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft, 
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRefresh(BuildContext context, WidgetRef ref) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 16),
              Text('Refreshing system data...'),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.primaryMaroon,
        ),
      );

      ref.invalidate(currentUserProvider);
      ref.invalidate(customerProvider);
      ref.invalidate(saleHistoryProvider);
      ref.invalidate(productsFutureProvider);
      ref.invalidate(expenseProvider);
      ref.invalidate(branchesProvider);
      ref.invalidate(transferProvider);
      ref.invalidate(slaughterLogsProvider);
      ref.invalidate(activeBatchesProvider);
      ref.invalidate(recentCutsProvider);
      ref.invalidate(butcherWasteProvider);
      
      debugPrint('System Refresh triggered');
    } catch (e) {
      debugPrint('Refresh Error: $e');
    }
  }
}
