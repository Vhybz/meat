import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/report_service.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/sale_provider.dart';
import '../../services/expense_provider.dart';
import '../../widgets/responsive_layout.dart';
import '../../models/user_model.dart';
import '../../models/sale_model.dart';

class DocumentsScreen extends ConsumerWidget {
  final bool isNested;
  const DocumentsScreen({super.key, this.isNested = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final bool isAdmin = user.activeRoles.contains(UserRole.admin) || user.activeRoles.contains(UserRole.superAdmin);
    
    // We only want the Scaffold if we are in the Admin route and NOT nested in another shell
    final bool showScaffold = isAdmin && !isNested;
    
    final String currentRoute = isAdmin ? '/admin/documents' : 'butcher:documents';
    final menuItems = ref.watch(isAdmin ? menuItemsProvider : butcherMenuItemsProvider);

    // Data for GRA Tax Report
    final now = DateTime.now();
    final allSales = ref.watch(saleHistoryProvider);
    final allExpenses = ref.watch(expenseProvider).records;

    final monthlySales = allSales.where((s) => 
      s.status != SaleStatus.cancelled &&
      s.timestamp.month == now.month && 
      s.timestamp.year == now.year
    ).toList();

    final monthlyExpenses = allExpenses.where((e) => 
      e.date.month == now.month && e.date.year == now.year
    ).toList();

    final totalSales = monthlySales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalExpenses = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final grossProfit = totalSales - totalExpenses;

    // GRA Tax Logic
    final double taxExclusiveBase = totalSales / 1.219;
    final double nhil = taxExclusiveBase * 0.025;
    final double getFund = taxExclusiveBase * 0.025;
    final double covid = taxExclusiveBase * 0.01;
    final double taxableValueForVat = taxExclusiveBase + nhil + getFund + covid;
    final double vat = taxableValueForVat * 0.15;
    final double totalTax = nhil + getFund + covid + vat;

    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth < 600 ? (constraints.maxWidth - 48) / 2 : (constraints.maxWidth - 64) / 4;
              return Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  _buildCategoryCard('Compliance', Icons.verified_user, Colors.green, cardWidth),
                  _buildCategoryCard('Permits', Icons.article, Colors.blue, cardWidth),
                  _buildCategoryCard('Invoices', Icons.receipt_long, Colors.orange, cardWidth),
                  _buildCategoryCard('Logbooks', Icons.book, Colors.purple, cardWidth),
                ],
              );
            }
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Compliance & Operating Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSpacing.m),
          Card(
            child: Column(
              children: [
                _buildDocItem(
                  'GRA Tax Compliance Report', 
                  'Monthly Profit & Tax Breakdown (${DateFormat('MMMM').format(now)})', 
                  'Calculated', 
                  AppColors.primaryMaroon,
                  onTap: () => ReportService.generateTaxComplianceReport(
                    date: now,
                    totalSales: totalSales,
                    totalExpenses: totalExpenses,
                    grossProfit: grossProfit,
                    taxBreakdown: {
                      'NHIL': nhil,
                      'GETFund': getFund,
                      'COVID': covid,
                      'VAT': vat,
                      'TOTAL': totalTax,
                    },
                  ),
                ),
                const Divider(height: 1),
                _buildDocItem(
                  'Health Inspection Certificate 2024', 
                  'Official GRA & Health Dept Approval', 
                  'Verified', 
                  Colors.green,
                  onTap: () => ReportService.generateHealthCertificate(),
                ),
                const Divider(height: 1),
                _buildDocItem(
                  'Standard Slaughter SOP v2.1', 
                  'Step-by-step butchery standards', 
                  'Active', 
                  Colors.blue,
                  onTap: () => ReportService.generateSlaughterSOP(),
                ),
                const Divider(height: 1),
                _buildDocItem(
                  'GRA Meat Retail License', 
                  'Business operating permit', 
                  'Active', 
                  Colors.purple,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (showScaffold) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: const MainAppBar(title: 'Compliance Documents'),
        drawer: isDesktop ? null : Drawer(
          child: AppSidebar(
            userId: user.id,
            userName: user.name,
            userRole: user.activePrimaryRole.name.toUpperCase(),
            currentRoute: currentRoute,
            items: menuItems,
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
                items: menuItems,
                onTap: (route) => MenuService.navigate(context, route, currentRoute),
              ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return content;
  }

  Widget _buildDocItem(String title, String subtitle, String tag, Color tagColor, {required VoidCallback onTap}) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.download, size: 20, color: AppColors.textLight),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
              Text(title == 'Compliance' ? 'Verified' : 'Access', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
