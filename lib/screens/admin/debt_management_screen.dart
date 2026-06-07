import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/sale_provider.dart';
import '../../services/sms_service.dart';
import '../../services/receipt_service.dart';
import '../../models/sale_model.dart';
import 'package:intl/intl.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/role_pop_scope.dart';

class DebtManagementScreen extends ConsumerStatefulWidget {
  const DebtManagementScreen({super.key});

  @override
  ConsumerState<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends ConsumerState<DebtManagementScreen> {
  String _searchQuery = '';
  bool _showPaidInvoices = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final salesHistory = ref.watch(saleHistoryProvider);
    
    // Filter logic
    final filteredSales = salesHistory.where((s) {
      if (s.status == SaleStatus.cancelled) return false;
      
      final isDebt = s.balance > 0.01;
      
      // A sale is a "Cleared Debt" if it's fully paid AND has more than 1 payment 
      // OR a payment reference indicating a manual collection.
      final isClearedDebt = s.balance <= 0.01 && 
          (s.payments.length > 1 || s.payments.any((p) => p.reference?.contains('Collection') ?? false));

      if (_showPaidInvoices) {
        if (!isClearedDebt) return false;
      } else {
        if (!isDebt) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = s.customerName?.toLowerCase().contains(query) ?? false;
        final matchesPhone = s.customerPhone?.contains(query) ?? false;
        final matchesId = s.id.toLowerCase().contains(query);
        return matchesName || matchesPhone || matchesId;
      }

      return true;
    }).toList();

    // Sort by most recent first
    filteredSales.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final totalDebt = salesHistory
        .where((s) => s.status != SaleStatus.cancelled)
        .fold(0.0, (sum, s) => sum + (s.balance > 0.01 ? s.balance : 0));
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/debts';

    return RolePopScope(
      currentRoute: currentRoute,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: const MainAppBar(title: 'Debt & Credit Tracker', showMenuButton: true),
        drawer: isDesktop
            ? null
            : Drawer(
                child: AppSidebar(
                  userId: user.id,
                  userName: user.name,
                  userRole: user.activePrimaryRole.name.toUpperCase(),
                  currentRoute: currentRoute,
                  items: MenuService.getMenuItemsForUser(user),
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
                items: MenuService.getMenuItemsForUser(user),
                onTap: (route) => MenuService.navigate(context, route, currentRoute),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildDebtSummary(context, totalDebt, salesHistory.where((s) => s.balance > 0).length),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
                    SliverToBoxAdapter(child: _buildControls(theme)),
                    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
                    if (filteredSales.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildDebtTile(context, filteredSales[index]),
                            childCount: filteredSales.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    final isSmall = MediaQuery.of(context).size.width < 500;
    return Flex(
      direction: isSmall ? Axis.vertical : Axis.horizontal,
      children: [
        Expanded(
          flex: isSmall ? 0 : 1,
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search Name, Phone or Invoice #',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
            ),
          ),
        ),
        if (isSmall) const SizedBox(height: AppSpacing.s) else const SizedBox(width: AppSpacing.m),
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: const Text('Show Fully Paid', style: TextStyle(fontSize: 12)),
            selected: _showPaidInvoices,
            onSelected: (v) => setState(() => _showPaidInvoices = v),
            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            checkmarkColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtSummary(BuildContext context, double totalDebt, int debtCount) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;
    final salesHistory = ref.watch(saleHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: isMobile ? 32 : 48),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Total Debt', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      '₵${totalDebt.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.white, fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold),
                    ),
                    Text('Across $debtCount pending transactions', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              if (!isMobile)
                ElevatedButton.icon(
                  onPressed: () {
                    if (_showPaidInvoices) {
                      final clearedDebts = salesHistory.where((s) => 
                        s.balance <= 0.01 && 
                        (s.payments.length > 1 || s.payments.any((p) => p.reference?.contains('Collection') ?? false))
                      ).toList();
                      ReceiptService.printPaidInvoicesReport(clearedDebts);
                    } else {
                      ReceiptService.printDebtReport(salesHistory.where((s) => s.balance > 0).toList());
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: theme.colorScheme.primary),
                  label: Text(_showPaidInvoices ? 'Cleared Debts Report' : 'Debt Report'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 120,
            child: _buildTrendChart(salesHistory),
          ),
          if (isMobile) ...[
            const SizedBox(height: AppSpacing.m),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_showPaidInvoices) {
                    final clearedDebts = salesHistory.where((s) => 
                      s.balance <= 0.01 && 
                      (s.payments.length > 1 || s.payments.any((p) => p.reference?.contains('Collection') ?? false))
                    ).toList();
                    ReceiptService.printPaidInvoicesReport(clearedDebts);
                  } else {
                    ReceiptService.printDebtReport(salesHistory.where((s) => s.balance > 0).toList());
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: theme.colorScheme.primary),
                label: Text(_showPaidInvoices ? 'Generate Cleared Debts Report' : 'Generate Debt Report'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<SaleRecord> sales) {
    final activeSales = sales.where((s) => s.status != SaleStatus.cancelled).toList();
    if (activeSales.isEmpty) return const Center(child: Text('No debt data for trend', style: TextStyle(color: Colors.white54)));

    // Group debt by day for the last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    
    double maxDebt = 0;
    final spots = last7Days.asMap().entries.map((entry) {
      final date = entry.value;
      final totalDebtOnDay = activeSales
          .where((s) => s.timestamp.year == date.year && s.timestamp.month == date.month && s.timestamp.day == date.day)
          .fold(0.0, (sum, s) => sum + (s.balance > 0.01 ? s.balance : 0));
      
      if (totalDebtOnDay > maxDebt) maxDebt = totalDebtOnDay;
      return FlSpot(entry.key.toDouble(), totalDebtOnDay);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.white,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '₵${s.y.toStringAsFixed(2)}',
              const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 12),
            )).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (val, meta) {
                final index = val.toInt();
                if (index >= 0 && index < 7) {
                  final date = last7Days[index];
                  return Text(
                    DateFormat('E').format(date).toUpperCase(), 
                    style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxDebt == 0 ? 100 : maxDebt * 1.5, // Give some headroom
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: Colors.white,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.primaryMaroon,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtTile(BuildContext context, SaleRecord sale) {
    final theme = Theme.of(context);
    final isPaid = sale.balance <= 0.01;
    final ageInDays = DateTime.now().difference(sale.timestamp).inDays;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(color: isPaid ? Colors.green.withValues(alpha: 0.2) : theme.dividerColor),
      ),
      elevation: 0,
      borderOnForeground: true,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.m),
        leading: CircleAvatar(
          backgroundColor: isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
          child: Icon(isPaid ? Icons.check_circle_outline : Icons.person, color: isPaid ? Colors.green : Colors.orange),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                sale.customerName ?? 'Walk-in Customer', 
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isPaid && ageInDays > 7)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('Overdue', style: TextStyle(color: Colors.red.shade800, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice: ${sale.id} • ${DateFormat('MMM dd, HH:mm').format(sale.timestamp)}', 
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (sale.customerPhone != null)
              Text('Phone: ${sale.customerPhone}', style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isPaid ? 'Fully Paid' : 'Balance Due', 
                style: TextStyle(fontSize: 9, color: isPaid ? Colors.green : theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.right,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '₵${sale.balance.toStringAsFixed(2)}',
                  style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        onTap: () => _showCollectionDialog(context, sale),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text('No matching records found.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
          Text('Try adjusting your search or filters.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _showCollectionDialog(BuildContext context, SaleRecord sale) {
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    bool isSaving = false;
    final isPaid = sale.balance <= 0.01;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: Text(isPaid ? 'Transaction Details' : 'Record Payment Collection'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Invoice ID', sale.id, theme),
                  _detailRow('Customer', sale.customerName ?? 'N/A', theme),
                  _detailRow('Phone', sale.customerPhone ?? 'N/A', theme),
                  _detailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(sale.timestamp), theme),
                  const Divider(height: 32),
                  _detailRow('Total Bill', '₵${sale.totalAmount.toStringAsFixed(2)}', theme),
                  _detailRow('Paid So Far', '₵${(sale.totalAmount - sale.balance).toStringAsFixed(2)}', theme),
                  _detailRow('Current Outstanding', '₵${sale.balance.toStringAsFixed(2)}', theme, color: isPaid ? Colors.green : Colors.red, isBold: true),
                  
                  if (!isPaid) ...[
                    const SizedBox(height: 24),
                    Text('Record New Payment', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Amount Received',
                        prefixText: '₵ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  ...sale.payments.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${p.method.name.toUpperCase()} (${p.reference ?? "Direct"})', style: const TextStyle(fontSize: 10)),
                        Text('₵${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          actions: [
            if (sale.customerPhone != null && !isPaid)
              TextButton.icon(
                onPressed: () {
                  SmsService.sendDebtReminderSms(sale);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debt reminder SMS sent to customer.')));
                },
                icon: const Icon(Icons.sms, size: 18),
                label: const Text('Send Reminder'),
              ),
            const Spacer(),
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context), 
              child: Text(isPaid ? 'Close' : 'Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
            ),
            if (!isPaid)
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount <= 0) return;
                  if (amount > sale.balance + 0.01) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount exceeds balance.')));
                    return;
                  }
                  
                  setState(() => isSaving = true);
                  
                  try {
                    final newPayment = PaymentDetail(
                      method: PaymentMethod.cash, 
                      amount: amount,
                      reference: 'Manual Collection ${DateFormat('yyMMdd').format(DateTime.now())}',
                    );
                    
                    final updatedPayments = [...sale.payments, newPayment];
                    final updatedSale = sale.copyWith(
                      payments: updatedPayments,
                    );

                    await ref.read(saleHistoryProvider.notifier).updateSale(updatedSale);
                    
                    // Always send SMS status update
                    await SmsService.sendReceiptSms(updatedSale);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Payment of ₵${amount.toStringAsFixed(2)} recorded! SMS sent.'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Record Payment'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, ThemeData theme, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}
