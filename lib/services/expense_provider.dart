import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import 'supabase_expense_service.dart';
import 'user_provider.dart';

class ExpenseState {
  final List<ExpenseRecord> records;
  final List<String> categories;

  ExpenseState({required this.records, required this.categories});

  ExpenseState copyWith({List<ExpenseRecord>? records, List<String>? categories}) {
    return ExpenseState(
      records: records ?? this.records,
      categories: categories ?? this.categories,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final SupabaseExpenseService _service;
  final Ref ref;

  ExpenseNotifier(this._service, this.ref) : super(ExpenseState(
    records: [],
    categories: ['Electricity', 'GRA Tax', 'Water', 'Rent', 'Wages', 'Transport', 'Vet Check', 'Animal Transport', 'Maintenance'],
  )) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null || user.branchCode == null) return;

      final expenses = await _service.getExpenses(user.branchCode!);
      state = state.copyWith(records: expenses);
    } catch (e) {}
  }

  Future<void> addExpense(ExpenseRecord expense) async {
    try {
      final user = ref.read(currentUserProvider);
      final expenseWithBranch = expense.copyWith(branchCode: user?.branchCode);
      await _service.addExpense(expenseWithBranch);
      state = state.copyWith(records: [expenseWithBranch, ...state.records]);
    } catch (e) {}
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _service.deleteExpense(id);
      state = state.copyWith(records: state.records.where((e) => e.id != id).toList());
    } catch (e) {}
  }

  void addCategory(String category) {
    if (!state.categories.contains(category)) {
      state = state.copyWith(categories: [...state.categories, category]);
    }
  }

  double getTotalExpensesForMonth(int month, int year) {
    return state.records
        .where((e) => e.date.month == month && e.date.year == year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}

final expenseServiceProvider = Provider<SupabaseExpenseService>((ref) {
  return SupabaseExpenseService();
});

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier(ref.watch(expenseServiceProvider), ref);
});
