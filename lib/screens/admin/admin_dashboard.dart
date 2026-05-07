import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/main_app_bar.dart';
import 'package:intl/intl.dart';
import '../../services/sale_provider.dart';
import '../../models/sale_model.dart';
import '../../core/utils.dart';
import '../../services/notification_service.dart';

import 'admin_menu_items.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);
    const currentRoute = '/admin';

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: const MainAppBar(title: 'Admin Command Center'),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AppSidebar(
                userName: 'Admin User',
                userRole: 'Administrator',
                currentRoute: currentRoute,
                items: getAdminMenuItems(),
                onTap: (route) => navigateAdmin(context, route, currentRoute),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              userName: 'Admin User',
              userRole: 'Administrator',
              currentRoute: currentRoute,
              items: getAdminMenuItems(),
              onTap: (route) => navigateAdmin(context, route, currentRoute),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, dateStr),
                  const SizedBox(height: AppSpacing.l),
                  _buildBanner(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildKPIGrid(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildPendingActions(context, ref),
                  const SizedBox(height: AppSpacing.xl),
                  _buildResponsiveMainContent(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildInventoryMonitor(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(saleHistoryProvider);
    final saleRequests = sales.where((s) => s.status == SaleStatus.pendingCorrection).toList();
    
    final notifications = ref.watch(notificationProvider);
    final butcherReports = notifications.where((n) => n.title.contains('BUTCHER') && !n.isRead).toList();

    if (saleRequests.isEmpty && butcherReports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (saleRequests.isNotEmpty) ...[
          _buildActionSection(
            context,
            ref,
            title: 'Sale Correction Requests',
            icon: Icons.receipt_long,
            color: Colors.orange,
            items: saleRequests,
            onAction: (sale) => _showRectifySaleDialog(context, ref, sale),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
        if (butcherReports.isNotEmpty) ...[
          _buildActionSection(
            context,
            ref,
            title: 'Butcher Unit Reports',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            items: butcherReports,
            onAction: (report) => _showRectifyButcherReportDialog(context, ref, report),
          ),
        ],
      ],
    );
  }

  Widget _buildActionSection(
    BuildContext context, 
    WidgetRef ref, 
    {required String title, required IconData icon, required Color color, required List items, required Function(dynamic) onAction}
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                '$title (${items.length})',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              String displayTitle = '';
              String displaySubtitle = '';
              
              if (item is SaleRecord) {
                displayTitle = 'Mistake in Sale ${item.id}';
                displaySubtitle = 'Reported by ${item.cashierName}: ${item.correctionReason}';
              } else if (item is AppNotification) {
                displayTitle = item.title;
                displaySubtitle = item.message;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(displaySubtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteAction(context, ref, item),
                        tooltip: 'Delete/Dismiss',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => onAction(item),
                        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                        child: const Text('Rectify'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAction(BuildContext context, WidgetRef ref, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(item is SaleRecord 
          ? 'Are you sure you want to CANCEL this sale completely? This action is irreversible.'
          : 'Are you sure you want to DISMISS this butcher report?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ElevatedButton(
            onPressed: () {
              if (item is SaleRecord) {
                ref.read(saleHistoryProvider.notifier).updateSale(item.copyWith(status: SaleStatus.cancelled));
              } else if (item is AppNotification) {
                ref.read(notificationProvider.notifier).deleteNotification(item.id);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Action deleted/cancelled.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  void _showRectifySaleDialog(BuildContext context, WidgetRef ref, SaleRecord sale) {
    final List<SaleItem> editedItems = List.from(sale.items);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double calculateNewTotal() => editedItems.fold(0, (sum, item) => sum + item.total);

          return AlertDialog(
            title: Text('Rectify Sale ${sale.id}'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Cashier Report: ${sale.correctionReason}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Edit Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    ...editedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.product.name, style: const TextStyle(fontSize: 12))),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: item.quantity.toString(),
                                decoration: const InputDecoration(suffixText: 'kg', isDense: true),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 12),
                                onChanged: (value) {
                                  final newQty = double.tryParse(value) ?? item.quantity;
                                  setState(() {
                                    editedItems[index] = SaleItem(
                                      product: item.product,
                                      quantity: newQty,
                                      priceAtSale: item.priceAtSale,
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Original Total:', style: TextStyle(fontSize: 12)),
                        Text('₵${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Corrected Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₵${calculateNewTotal().toStringAsFixed(2)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final newTotal = calculateNewTotal();
                  final rectifiedSale = sale.copyWith(
                    items: editedItems,
                    totalAmount: newTotal,
                    status: SaleStatus.rectified,
                  );
                  
                  // Update State (Future Supabase Update)
                  ref.read(saleHistoryProvider.notifier).updateSale(rectifiedSale);
                  
                  // Notify Cashier
                  ref.read(notificationProvider.notifier).addNotification(
                    'SALE RECTIFIED',
                    'Sale ${sale.id} has been rectified by Admin. Please reprint receipt for customer.',
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sale ${sale.id} rectified. Cashier notified.'),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
                child: const Text('Save & Notify Cashier'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRectifyButcherReportDialog(BuildContext context, WidgetRef ref, AppNotification report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rectify Butcher Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reported: ${report.message}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Resolution Action',
                hintText: 'e.g., Equipment repaired, Stock replenished',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).markAsRead(report.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Butcher report resolved and archived.'), backgroundColor: AppColors.accentGreen),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
            child: const Text('Mark as Resolved'),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.l),
        image: const DecorationImage(
          image: AssetImage('assets/logo/banner.jpg'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.l),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uncompromising Quality',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Unforgettable Taste',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String dateStr) {
    final isMobile = ResponsiveLayout.isMobile(context);
    
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome, Admin',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(dateStr, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: AppSpacing.m),
          _buildActionButtons(isMobile),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back, Administrator',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.textLight),
                const SizedBox(width: 8),
                Text(dateStr, style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              ],
            ),
          ],
        ),
        _buildActionButtons(false),
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryMaroon,
            side: const BorderSide(color: AppColors.primaryMaroon),
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20, 
              vertical: isMobile ? 10 : 15
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Staff'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20, 
              vertical: isMobile ? 10 : 15
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final bool isTablet = ResponsiveLayout.isTablet(context);
    
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    double aspectRatio = isMobile ? 3.5 : 2.2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.l,
      mainAxisSpacing: AppSpacing.l,
      childAspectRatio: aspectRatio,
      children: [
        _kpiWithTrend("Today's Sales", 'GHS 52,340', Icons.payments, AppColors.primaryMaroon, '+12.5%'),
        _kpiWithTrend("Kilos Sold", '248.7 kg', Icons.scale, Colors.blue, '+5.2%'),
        _kpiWithTrend('Gross Revenue', 'GHS 1.2M', Icons.trending_up, Colors.green, '+8.1%'),
        _kpiWithTrend('Active Orders', '356', Icons.shopping_bag, Colors.orange, '-2.4%'),
      ],
    );
  }

  Widget _kpiWithTrend(String title, String value, IconData icon, Color color, String trend) {
    final bool isPositive = trend.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.s)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trend,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveMainContent(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildPerformanceChart()),
          const SizedBox(width: AppSpacing.l),
          Expanded(flex: 1, child: _buildCriticalAlerts()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildPerformanceChart(),
          const SizedBox(height: AppSpacing.l),
          _buildCriticalAlerts(),
        ],
      );
    }
  }

  Widget _buildPerformanceChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Revenue Performance Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              DropdownButton<String>(
                value: 'Last 7 Days',
                underline: const SizedBox(),
                items: ['Today', 'Last 7 Days', 'Monthly'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.m),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryMaroon.withValues(alpha: 0.05), Colors.white],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: 0.05,
                      child: Image.asset('assets/images/meat_on_scale.jpg', fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.insights, size: 64, color: AppColors.primaryMaroon),
                        SizedBox(height: 16),
                        Text('Detailed Analytics Visualizer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                        Text('Syncing real-time market data...', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlerts() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notification_important, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('System Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: ListView(
              children: [
                _alertTile('Inventory Alert', 'Pork Belly is below safety stock level (2.4kg remaining).', Colors.orange, Icons.inventory_2),
                _alertTile('System Notice', 'New Staff account created for "John Doe" (Butcher).', Colors.blue, Icons.person_add),
                _alertTile('Payment Issue', 'A partial payment for INV-2034 is 3 days overdue.', Colors.red, Icons.warning_amber),
                _alertTile('Batch Approval', 'Animal Intake Batch #492 requires admin sign-off.', Colors.purple, Icons.assignment_turned_in),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertTile(String title, String subtitle, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryMonitor(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stock Level Monitoring', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: AppSpacing.l),
          if (isMobile)
            Column(
              children: [
                _stockIndicator('Beef Brisket', 0.85, Colors.green),
                const SizedBox(height: AppSpacing.m),
                _stockIndicator('Pork Ribs', 0.42, Colors.orange),
                const SizedBox(height: AppSpacing.m),
                _stockIndicator('Chicken Wings', 0.15, Colors.red),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _stockIndicator('Beef Brisket', 0.85, Colors.green)),
                const SizedBox(width: AppSpacing.l),
                Expanded(child: _stockIndicator('Pork Ribs', 0.42, Colors.orange)),
                const SizedBox(width: AppSpacing.l),
                Expanded(child: _stockIndicator('Chicken Wings', 0.15, Colors.red)),
                if (isTablet || ResponsiveLayout.isDesktop(context)) ...[
                  const SizedBox(width: AppSpacing.l),
                  Expanded(child: _stockIndicator('Goat Meat', 0.64, Colors.blue)),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _stockIndicator(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
