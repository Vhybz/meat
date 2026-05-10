import '../models/expense_model.dart';
import '../core/supabase_config.dart';

class SupabaseExpenseService {
  final _client = SupabaseConfig.client;

  Future<List<ExpenseRecord>> getExpenses(String branchCode) async {
    final response = await _client
        .from('expenses')
        .select()
        .eq('branch_code', branchCode)
        .order('date', ascending: false);
    
    return (response as List).map((json) => ExpenseRecord.fromJson(json)).toList();
  }

  Future<void> addExpense(ExpenseRecord expense) async {
    await _client.from('expenses').insert(expense.toJson());
  }

  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }
}
