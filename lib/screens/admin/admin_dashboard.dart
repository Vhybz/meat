import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/main_app_bar.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  List<SidebarItem> _getMenuItems() => [
        SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/admin'),
        SidebarItem(icon: Icons.bar_chart_rounded, label: 'Sales', route: '/admin/sales'),
        SidebarItem(icon: Icons.inventory_rounded, label: 'Stock', route: '/admin/stock'),
        SidebarItem(icon: Icons.people_rounded, label: 'Users', route: '/admin/users'),
        SidebarItem(icon: Icons.settings_rounded, label: 'Settings', route: '/admin/settings'),
      ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: const MainAppBar(title: 'Admin Dashboard'),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AppSidebar(
                userName: 'Admin User',
                userRole: 'Administrator',
                currentRoute: '/admin',
                items: _getMenuItems(),
                onTap: (route) => Navigator.pushNamed(context, route),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              userName: 'Admin User',
              userRole: 'Administrator',
              currentRoute: '/admin',
              items: _getMenuItems(),
              onTap: (route) => Navigator.pushNamed(context, route),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('System Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.l),
                  _buildKPIGrid(context),
                  const SizedBox(height: AppSpacing.l),
                  _buildResponsiveMainContent(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
    int crossAxisCount = ResponsiveLayout.isMobile(context) ? 2 : 4;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.m,
      mainAxisSpacing: AppSpacing.m,
      childAspectRatio: 2.5,
      children: const [
        KPICard(
          title: "Today's Sales",
          value: '₵52,340',
          icon: Icons.payments,
          iconColor: Colors.white,
          iconBgColor: AppColors.primaryMaroon,
        ),
        KPICard(
          title: "Kilos Sold",
          value: '248.7 kg',
          icon: Icons.scale,
          iconColor: Colors.blue,
          iconBgColor: Color(0xFFE3F2FD),
        ),
        KPICard(
          title: 'Gross Revenue',
          value: '₵1.2M',
          icon: Icons.trending_up,
          iconColor: Colors.green,
          iconBgColor: Color(0xFFE8F5E9),
        ),
        KPICard(
          title: 'Active Orders',
          value: '356',
          icon: Icons.shopping_bag,
          iconColor: Colors.orange,
          iconBgColor: Color(0xFFFFF3E0),
        ),
      ],
    );
  }

  Widget _buildResponsiveMainContent(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildSalesChart()),
          const SizedBox(width: AppSpacing.l),
          Expanded(flex: 1, child: _buildAlertsSection()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildSalesChart(),
          const SizedBox(height: AppSpacing.l),
          _buildAlertsSection(),
        ],
      );
    }
  }

  Widget _buildSalesChart() {
    return Card(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(AppSpacing.l),
        child: const Column(
          children: [
            Row(
              children: [
                Text('Sales Trend', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Expanded(child: Center(child: Text('Chart Placeholder', style: TextStyle(color: AppColors.textLight)))),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.m),
            _alertItem('Low Stock: Pork Belly', Colors.orange),
            _alertItem('Pending Batch Approval', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _alertItem(String msg, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(msg, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
