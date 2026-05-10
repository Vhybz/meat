import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/expense_provider.dart';
import '../../models/expense_model.dart';

class ButcherExpenseScreen extends ConsumerWidget {
  const ButcherExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider);
    // Filter expenses that are typically butcher-related for their view
    final butcherExpenses = expenseState.records.where((e) => 
      ['Vet Check', 'Animal Transport', 'Slaughter Fee', 'Maintenance'].contains(e.category)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const SizedBox(height: AppSpacing.xl),
          const Text('Recent Butcher Unit Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.m),
          if (butcherExpenses.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: butcherExpenses.length,
              itemBuilder: (context, index) {
                final exp = butcherExpenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.surfaceWhite,
                      child: Icon(Icons.medication_liquid, color: AppColors.primaryMaroon),
                    ),
                    title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${exp.category} • ${DateFormat('MMM dd').format(exp.date)}'),
                    trailing: Text('GHS ${exp.amount.toStringAsFixed(2)}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operational Expenses', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Record vet checks, transport and local costs', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddExpenseDialog(context, ref),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Record New Expense'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.borderGray),
            const SizedBox(height: 16),
            const Text('No operational expenses logged yet.', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final butcherCategories = ['Vet Check', 'Animal Transport', 'Slaughter Fee', 'Maintenance', 'Cleaning Supplies'];
    String selectedCategory = butcherCategories.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primaryMaroon),
              SizedBox(width: 12),
              Text('Log Operational Expense'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Expense Description', hintText: 'e.g. Dr. Mensah Vet Visit', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: butcherCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: 'GHS ', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
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
                  final newExp = ExpenseRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    category: selectedCategory,
                    amount: double.tryParse(amountController.text) ?? 0,
                    date: DateTime.now(),
                  );
                  ref.read(expenseProvider.notifier).addExpense(newExp);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense logged successfully.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
