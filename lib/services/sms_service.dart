import '../models/sale_model.dart';

class SmsService {
  static Future<bool> sendReceiptSms(SaleRecord sale) async {
    if (sale.customerPhone == null || sale.customerPhone!.isEmpty) return false;
    
    // Mocking SMS sending
    print('Sending SMS to ${sale.customerPhone} for Sale ${sale.id}');
    print('Content: Hello ${sale.customerName ?? 'Customer'}, your total for order ${sale.id} is ₵${sale.totalAmount.toStringAsFixed(2)}. Thank you for shopping with us!');
    
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    return true;
  }
}
