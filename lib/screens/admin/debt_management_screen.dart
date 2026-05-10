import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/sale_provider.dart';
import '../../models/sale_model.dart';
import 'package:intl/intl.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';

class DebtManagementScreen extends ConsumerWidget {
  const DebtManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final salesHistory = ref.watch(saleHistoryProvider);
    final debtSales = salesHistory.where((s) => s.balance > 0).toList();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/debts';

    return Scaffold(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDebtSummary(context, debtSales),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Outstanding Balances', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: AppSpacing.m),
                  Expanded(
                    child: debtSales.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            itemCount: debtSales.length,
                            itemBuilder: (context, index) => _buildDebtTile(context, debtSales[index]),
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

  Widget _buildDebtSummary(BuildContext context, List<SaleRecord> debtSales) {
    final theme = Theme.of(context);
    final totalDebt = debtSales.fold(0.0, (sum, s) => sum + s.balance);
    final isMobile = MediaQuery.of(context).size.width < 700;

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
      child: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                  const SizedBox(width: AppSpacing.m),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Outstanding Credit', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        'GHS ${totalDebt.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: theme.colorScheme.primary),
                  child: const Text('Generate Debt Report'),
                ),
              ),
            ],
          )
        : Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
              const SizedBox(width: AppSpacing.xl),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Outstanding Credit', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    'GHS ${totalDebt.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text('Across ${debtSales.length} pending transactions', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: theme.colorScheme.primary),
                child: const Text('Generate Debt Report'),
              ),
            ],
          ),
    );
  }

  Widget _buildDebtTile(BuildContext context, SaleRecord sale) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.m),
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: Colors.orange),
        ),
        title: Text(sale.customerName ?? 'Unregistered Customer', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        subtitle: Text('Invoice: ${sale.id} • ${DateFormat('MMM dd, HH:mm').format(sale.timestamp)}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Balance Due', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
            Text(
              'GHS ${sale.balance.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
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
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No outstanding debts!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
          Text('All transactions are fully paid.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _showCollectionDialog(BuildContext context, SaleRecord sale) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collecting for Invoice: ${sale.id}'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Amount Received',
                prefixText: 'GHS ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }
}
