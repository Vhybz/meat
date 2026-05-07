import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/butcher_navigation_provider.dart';
import 'butcher_dashboard.dart';
import 'animal_intake_screen.dart';
import 'slaughter_log_screen.dart';
import 'batch_management_screen.dart';
import 'meat_processing_screen.dart';
import 'stock_transfer_screen.dart';
import 'inventory_screen.dart';
import 'orders_screen.dart';
import 'waste_management_screen.dart';
import 'documents_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'how_to_use_screen.dart';

class ButcherShell extends ConsumerWidget {
  const ButcherShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScreen = ref.watch(butcherNavProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: MainAppBar(
        title: _getScreenTitle(currentScreen),
        onProfileTap: () => ref.read(butcherNavProvider.notifier).setScreen(ButcherScreen.profile),
      ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(ref, currentScreen)),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(ref, currentScreen),
          Expanded(
            child: Container(
              color: const Color(0xFFFBFBFB), // Slightly different white for content background
              child: _buildContent(currentScreen),
            ),
          ),
        ],
      ),
    );
  }

  String _getScreenTitle(ButcherScreen screen) {
    switch (screen) {
      case ButcherScreen.dashboard: return 'Butcher Dashboard';
      case ButcherScreen.animalIntake: return 'Animal Intake';
      case ButcherScreen.slaughterLog: return 'Slaughter Logs';
      case ButcherScreen.meatProcessing: return 'Meat Processing';
      case ButcherScreen.batchManagement: return 'Batch Management';
      case ButcherScreen.stockTransfer: return 'Stock Transfer';
      case ButcherScreen.inventory: return 'Butcher Inventory';
      case ButcherScreen.orders: return 'Processing Orders';
      case ButcherScreen.wasteManagement: return 'Waste Management';
      case ButcherScreen.documents: return 'Documents & Compliance';
      case ButcherScreen.reports: return 'Operational Reports';
      case ButcherScreen.settings: return 'Workstation Settings';
      case ButcherScreen.profile: return 'Personal Profile';
      case ButcherScreen.howToUse: return 'How to Use System';
    }
  }

  Widget _buildSidebar(WidgetRef ref, ButcherScreen current) {
    return AppSidebar(
      userName: 'Ramon Dela Cruz',
      userRole: 'Butcher Control',
      currentRoute: current.name,
      items: [
        SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: ButcherScreen.dashboard.name),
        SidebarItem(icon: Icons.pets_rounded, label: 'Animal Intake', route: ButcherScreen.animalIntake.name),
        SidebarItem(icon: Icons.list_alt_rounded, label: 'Slaughter Log', route: ButcherScreen.slaughterLog.name),
        SidebarItem(icon: Icons.layers_rounded, label: 'Meat Processing', route: ButcherScreen.meatProcessing.name),
        SidebarItem(icon: Icons.inventory_2_rounded, label: 'Batch Management', route: ButcherScreen.batchManagement.name),
        SidebarItem(icon: Icons.sync_alt_rounded, label: 'Stock Transfer', route: ButcherScreen.stockTransfer.name),
        SidebarItem(icon: Icons.inventory_rounded, label: 'Inventory', route: ButcherScreen.inventory.name),
        SidebarItem(icon: Icons.shopping_cart_rounded, label: 'Orders', route: ButcherScreen.orders.name),
        SidebarItem(icon: Icons.delete_outline_rounded, label: 'Waste Management', route: ButcherScreen.wasteManagement.name),
        SidebarItem(icon: Icons.description_rounded, label: 'Documents', route: ButcherScreen.documents.name),
        SidebarItem(icon: Icons.bar_chart_rounded, label: 'Reports', route: ButcherScreen.reports.name),
        SidebarItem(icon: Icons.settings_rounded, label: 'Settings', route: ButcherScreen.settings.name),
        SidebarItem(icon: Icons.help_outline_rounded, label: 'How to Use', route: ButcherScreen.howToUse.name),
      ],
      onTap: (route) {
        final screen = ButcherScreen.values.firstWhere((e) => e.name == route);
        ref.read(butcherNavProvider.notifier).setScreen(screen);
      },
    );
  }

  Widget _buildContent(ButcherScreen screen) {
    switch (screen) {
      case ButcherScreen.dashboard: return const ButcherDashboard();
      case ButcherScreen.animalIntake: return const AnimalIntakeScreen();
      case ButcherScreen.slaughterLog: return const SlaughterLogScreen();
      case ButcherScreen.meatProcessing: return const MeatProcessingScreen();
      case ButcherScreen.batchManagement: return const BatchManagementScreen();
      case ButcherScreen.stockTransfer: return const StockTransferScreen();
      case ButcherScreen.inventory: return const InventoryScreen();
      case ButcherScreen.orders: return const OrdersScreen();
      case ButcherScreen.wasteManagement: return const WasteManagementScreen();
      case ButcherScreen.documents: return const DocumentsScreen();
      case ButcherScreen.reports: return const ReportsScreen();
      case ButcherScreen.settings: return const SettingsScreen();
      case ButcherScreen.profile: return const ProfileScreen();
      case ButcherScreen.howToUse: return const HowToUseScreen();
    }
  }
}
