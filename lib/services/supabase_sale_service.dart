import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import '../core/supabase_config.dart';

class SupabaseSaleService {
  final _client = SupabaseConfig.client;

  Future<List<SaleRecord>> getSales() async {
    final response = await _client
        .from('sales')
        .select()
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
}
