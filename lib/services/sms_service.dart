import 'package:flutter/foundation.dart';
import '../models/sale_model.dart';

class SmsService {
  static const String adminPhone = '0209276200'; // Admin's contact from receipt

  static Future<bool> sendReceiptSms(SaleRecord sale) async {
    if (sale.customerPhone == null || sale.customerPhone!.isEmpty) return false;
    
    // Mocking SMS sending
    debugPrint('Sending SMS to ${sale.customerPhone} for Sale ${sale.id}');
    debugPrint('Content: Hello ${sale.customerName ?? 'Customer'}, your total for order ${sale.id} is ₵${sale.totalAmount.toStringAsFixed(2)}. Thank you for shopping with us!');
    
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    return true;
  }

  static Future<void> notifyAdmin({required String title, required String message}) async {
    // In a real app, this would trigger an SMS gateway and a Push Notification (FCM/OneSignal)
    debugPrint('*** ADMIN SMS SENT to $adminPhone ***');
    debugPrint('TITLE: $title');
    debugPrint('MESSAGE: $message');
    
    // Simulate real-world delay
    await Future.delayed(const Duration(milliseconds: 800));
  }
}
