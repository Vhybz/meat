import '../models/sale_model.dart';
import '../core/supabase_config.dart';

class SupabaseSaleService {
  final _client = SupabaseConfig.client;

  Future<List<SaleRecord>> getSales(String branchCode) async {
    final response = await _client
        .from('sales')
        .select()
        .eq('branch_code', branchCode)
        .order('timestamp', ascending: false);
    
    return (response as List).map((json) => SaleRecord.fromJson(json)).toList();
  }

  Future<void> saveSale(SaleRecord sale) async {
    await _client.from('sales').insert(sale.toJson());
  }

  Future<void> updateSale(SaleRecord sale) async {
    await _client
        .from('sales')
        .update(sale.toJson())
        .eq('id', sale.id);
  }

  Stream<List<SaleRecord>> getSalesStream(String branchCode) {
    return _client
        .from('sales')
        .stream(primaryKey: ['id'])
        .eq('branch_code', branchCode)
        .order('timestamp', ascending: false)
        .map((data) => data.map((json) => SaleRecord.fromJson(json)).toList());
  }
}
