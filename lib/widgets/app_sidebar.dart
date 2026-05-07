import 'package:flutter/material.dart';
import '../core/constants.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;

  SidebarItem({required this.icon, required this.label, required this.route});
}

class AppSidebar extends StatelessWidget {
  final List<SidebarItem> items;
  final String currentRoute;
  final String userName;
  final String userRole;
  final Function(String route)? onTap;

  const AppSidebar({
    super.key,
    required this.items,
    required this.currentRoute,
    required this.userName,
    required this.userRole,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarColor = isDark ? const Color(0xFF0F0404) : AppColors.primaryMaroon;

    return Container(
      width: 260,
      color: sidebarColor,
      child: Column(
        children: [
          _buildLogo(),
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
                      return _buildMenuItem(context, item, isSelected);
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildUserSection(),
          _buildLogoutButton(context),
        ],
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
                  'Freshmeat Butchery',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, SidebarItem item, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!(item.route);
          }
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 12),
          decoration: BoxDecoration(
            border: isSelected ? const Border(left: BorderSide(color: Colors.white, width: 4)) : null,
            color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(item.icon, color: isSelected ? Colors.white : Colors.white70, size: 20),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                Text(userRole, style: const TextStyle(color: Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: TextButton.icon(
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
        label: const Expanded(child: Text('Log Out', style: TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis)),
        style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s)),
      ),
    );
  }
}
