import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/expense_provider.dart';
import '../../models/expense_model.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';

class ExpenseManagementScreen extends ConsumerWidget {
  const ExpenseManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final expenseState = ref.watch(expenseProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/expenses';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const MainAppBar(title: 'Business Expenses'),
      drawer: isDesktop ? null : Drawer(
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
                  _buildHeader(context, ref),
                  const SizedBox(height: AppSpacing.xl),
                  _buildMonthlySummary(context, expenseState.records),
                  const SizedBox(height: AppSpacing.xl),
                  _buildExpenseList(context, ref, expenseState.records),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expense Tracking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            Text('Manage operational costs and taxes', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showAddCategoryDialog(context, ref),
              icon: const Icon(Icons.settings),
              label: const Text('Customize Categories'),
            ),
            const SizedBox(width: AppSpacing.m),
            ElevatedButton.icon(
              onPressed: () => _showAddExpenseDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlySummary(BuildContext context, List<ExpenseRecord> expenses) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final thisMonthExpenses = expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_rounded, color: Colors.white, size: 40),
          const SizedBox(width: AppSpacing.xl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${DateFormat('MMMM yyyy').format(now)} Total Expenses', 
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text('GHS ${thisMonthExpenses.toStringAsFixed(2)}', 
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, WidgetRef ref, List<ExpenseRecord> expenses) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: AppSpacing.m),
        if (expenses.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No expenses recorded yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final exp = expenses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                  ),
                  title: Text(exp.title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  subtitle: Text('${exp.category} • ${DateFormat('MMM dd, yyyy').format(exp.date)}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('GHS ${exp.amount.toStringAsFixed(2)}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => ref.read(expenseProvider.notifier).deleteExpense(exp.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: const Text('Add Expense Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Licensing'),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(expenseProvider.notifier).addCategory(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final expenseState = ref.read(expenseProvider);
    final theme = Theme.of(context);
    String selectedCategory = expenseState.categories.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: const Text('Add Business Expense'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Expense Title', hintText: 'e.g. ECG Bill - May'),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]'))],
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: expenseState.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: 'GHS '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                  final String suffix = timestamp.substring(timestamp.length - 12);
                  final String validUuid = '00000000-0000-0000-0000-$suffix';

                  final newExp = ExpenseRecord(
                    id: validUuid,
                    title: titleController.text,
                    category: selectedCategory,
                    amount: double.tryParse(amountController.text) ?? 0,
                    date: DateTime.now(),
                  );
                  ref.read(expenseProvider.notifier).addExpense(newExp);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
