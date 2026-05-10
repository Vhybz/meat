import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/sale_provider.dart';
import '../../services/expense_provider.dart';
import '../../models/sale_model.dart';
import '../../services/receipt_service.dart';
import 'package:intl/intl.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';

class SalesReportsScreen extends ConsumerStatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  ConsumerState<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends ConsumerState<SalesReportsScreen> {
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  SaleStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final salesHistory = ref.watch(saleHistoryProvider);
    
    final filteredSales = salesHistory.where((sale) {
      final matchesSearch = sale.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == null || sale.status == _statusFilter;
      final matchesDate = (_startDate == null || sale.timestamp.isAfter(_startDate!)) &&
                         (_endDate == null || sale.timestamp.isBefore(_endDate!.add(const Duration(days: 1))));
      return matchesSearch && matchesStatus && matchesDate;
    }).toList();

    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/sales';

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: const MainAppBar(title: 'Sales & Analytics', showMenuButton: true),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, filteredSales),
                  const SizedBox(height: AppSpacing.xl),
                  _buildFilters(),
                  const SizedBox(height: AppSpacing.l),
                  _buildSummaryCards(context, filteredSales),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSalesTable(filteredSales),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: AppSpacing.m,
              runSpacing: AppSpacing.m,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: constraints.maxWidth < 600 ? constraints.maxWidth : 250,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search Receipt ID...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth < 600 ? constraints.maxWidth : 220,
                  child: DropdownButtonFormField<SaleStatus>(
                    value: _statusFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Status')),
                      ...SaleStatus.values.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s.name.replaceAll(RegExp(r'(?=[A-Z])'), ' ').toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_startDate == null
                      ? 'Filter Date'
                      : '${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate!)}'),
                ),
                if (_startDate != null || _statusFilter != null || _searchQuery.isNotEmpty)
                  IconButton(
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                      _statusFilter = null;
                      _searchQuery = '';
                    }),
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear Filters',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<SaleRecord> filteredSales) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      
      final headerText = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Transaction History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Detailed breakdown of all shop revenue (${filteredSales.length} items)',
            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
        ],
      );

      final exportButton = ElevatedButton.icon(
        onPressed: () => ReceiptService.printSalesReport(filteredSales),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Export to PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMaroon,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      );

      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerText,
            const SizedBox(height: AppSpacing.m),
            SizedBox(width: double.infinity, child: exportButton),
          ],
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: headerText),
          const SizedBox(width: 16),
          exportButton,
        ],
      );
    });
  }

  Widget _buildSummaryCards(BuildContext context, List<SaleRecord> sales) {
    final totalRevenue = sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    final expensesState = ref.watch(expenseProvider);
    final totalExpenses = expensesState.records.fold(0.0, (sum, e) => sum + e.amount);
    final netProfit = totalRevenue - totalExpenses;

    return LayoutBuilder(builder: (context, constraints) {
      final bool useColumn = constraints.maxWidth < 900;
      
      if (useColumn) {
        return Column(
          children: [
            _reportCard('Gross Volume', '₵ ${totalRevenue.toStringAsFixed(2)}', Icons.payments, Colors.blue),
            const SizedBox(height: AppSpacing.m),
            _reportCard('Total Expenses', '₵ ${totalExpenses.toStringAsFixed(2)}', Icons.trending_down, Colors.red),
            const SizedBox(height: AppSpacing.m),
            _reportCard('Net Profit', '₵ ${netProfit.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.green),
          ],
        );
      }
      
      return Row(
        children: [
          Expanded(child: _reportCard('Gross Volume', '₵ ${totalRevenue.toStringAsFixed(2)}', Icons.payments, Colors.blue)),
          const SizedBox(width: AppSpacing.m),
          Expanded(child: _reportCard('Total Expenses', '₵ ${totalExpenses.toStringAsFixed(2)}', Icons.trending_down, Colors.red)),
          const SizedBox(width: AppSpacing.m),
          Expanded(child: _reportCard('Net Profit', '₵ ${netProfit.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.green)),
        ],
      );
    });
  }

  Widget _reportCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.m),
          Text(
            title,
            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTable(List<SaleRecord> sales) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.l),
            child: Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          if (sales.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Text('No transactions found.')))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('Invoice ID')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: sales.map<DataRow>((sale) {
                    return DataRow(cells: [
                      DataCell(Text(sale.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(DateFormat('MMM dd, HH:mm').format(sale.timestamp))),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            sale.customerName ?? 'Walk-in',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('₵ ${sale.totalAmount.toStringAsFixed(2)}')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(sale.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sale.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(sale.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed: return Colors.green;
      case SaleStatus.rectified: return Colors.blue;
      case SaleStatus.pendingCorrection: return Colors.orange;
      case SaleStatus.cancelled: return Colors.red;
    }
  }
}
