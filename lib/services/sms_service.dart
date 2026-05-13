import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';

class SmsService {
  static String get _apiKey => dotenv.env['ARKESEL_API_KEY'] ?? 'ZGhHekhSWnpHbmF1VWlGR0ZqemI';
  static String get _senderId => dotenv.env['ARKESEL_SENDER_ID'] ?? 'MiCorazon';
  static String get _adminPhone => dotenv.env['ADMIN_PHONE'] ?? '0209276200';

  static Future<bool> _sendSms(String to, String message) async {
    if (_apiKey.isEmpty) {
      debugPrint('SMS Error: API Key is missing');
      return false;
    }

    // Format phone number to 233 format (remove leading zero, add 233)
    String formattedPhone = to.trim();
    if (formattedPhone.startsWith('0') && formattedPhone.length == 10) {
      formattedPhone = '233${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('233') && formattedPhone.length == 9) {
      formattedPhone = '233$formattedPhone';
    }

    final url = Uri.parse(
      'https://sms.arkesel.com/sms/api?action=send-sms'
      '&api_key=$_apiKey'
      '&to=$formattedPhone'
      '&from=$_senderId'
      '&sms=${Uri.encodeComponent(message)}'
    );

    try {
      debugPrint('Attempting to send SMS to $formattedPhone via Arkesel...');
      final response = await http.get(url);
      
      // Arkesel returns status codes inside the response body
      // Typical success body: {"code":"1000","message":"Successfully Sent"}
      if (response.statusCode == 200) {
        if (response.body.contains('"code":"1000"') || response.body.contains('1000')) {
          debugPrint('SMS sent successfully to $formattedPhone');
          return true;
        } else {
          debugPrint('Arkesel API Error: ${response.body}');
          return false;
        }
      } else {
        debugPrint('HTTP Error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('SMS Exception: $e');
      return false;
    }
  }

  static Future<bool> sendReceiptSms(SaleRecord sale, {double? discountAmount}) async {
    if (sale.customerPhone == null || sale.customerPhone!.isEmpty) return false;
    
    String message = 'Hello ${sale.customerName ?? 'Customer'}, your total for order ${sale.id} is GHC${sale.totalAmount.toStringAsFixed(2)}.';
    
    if (sale.balance > 0.01) {
      message += ' Amount Paid: GHC${sale.amountPaid.toStringAsFixed(2)}. Outstanding Balance: GHC${sale.balance.toStringAsFixed(2)}. Please settle at your earliest convenience.';
    }

    if (discountAmount != null && discountAmount > 0) {
      message += ' You saved GHC${discountAmount.toStringAsFixed(2)}! Thank you for being a valued customer.';
    } else {
      if (sale.balance <= 0.01) {
        message += ' Thank you for shopping with us!';
      }
    }

    return await _sendSms(sale.customerPhone!, message);
  }

  static Future<void> sendApprovalRequestSms(UserAccount applicant, List<UserAccount> admins) async {
    final message = 'New user registration needs approval. Name: ${applicant.firstName} ${applicant.surname}, Role: ${applicant.role.name.toUpperCase()}. Please log in to approve.';
    
    // Collect all admin and superAdmin phone numbers
    final adminPhones = admins
        .where((u) => (u.role == UserRole.admin || u.role == UserRole.superAdmin) && u.phone != null && u.phone!.isNotEmpty)
        .map((u) => u.phone!)
        .toSet()
        .toList();

    // Also include the hardcoded fallback admin phone from .env
    if (_adminPhone.isNotEmpty && !adminPhones.contains(_adminPhone)) {
      adminPhones.add(_adminPhone);
    }

    // Send to each admin
    for (final phone in adminPhones) {
      await _sendSms(phone, message);
    }
  }

  static Future<void> sendSignupConfirmationSms(UserAccount user, bool isAutoApproved) async {
    if (user.phone == null || user.phone!.isEmpty) return;

    final statusMessage = isAutoApproved 
        ? 'Your account has been approved. You can now log in.' 
        : 'Your application is pending administrator approval. You will be notified once approved.';

    String message = 'Hello ${user.firstName}, thank you for registering with Mi Corazon Freshmeat Butchery. $statusMessage';
    
    if (user.role == UserRole.admin && user.branchCode != null) {
      message += ' Your Branch Code is: ${user.branchCode}. Please share this with your staff.';
    }
    
    await _sendSms(user.phone!, message);
  }

  static Future<void> sendStaffOnboardingSms(UserAccount user) async {
    if (user.phone == null || user.phone!.isEmpty) return;

    final String roleName = user.role.name.toUpperCase();
    final String message = 'Welcome to the team, ${user.firstName}! Your account has been linked to your staff profile as a $roleName at Mi Corazon. You can now log in and start working. We are glad to have you!';

    await _sendSms(user.phone!, message);
  }

  static Future<void> sendApprovalSms(UserAccount user) async {
    if (user.phone == null || user.phone!.isEmpty) return;

    final String message = 'Congratulations ${user.firstName}! Your Mi Corazon account has been approved by the administrator. You can now log in instantly and start using the system.';

    await _sendSms(user.phone!, message);
  }

  static Future<void> sendCustomerWelcomeSms(String name, String phone, String? branchName) async {
    if (phone.isEmpty) return;

    final String branchText = branchName != null ? '($branchName Branch)' : '';
    final String message = 'Hello $name, thank you for being part of our favorite customers at Mi Corazon Freshmeat Butchery $branchText. We value your patronage!';

    await _sendSms(phone, message);
  }

  static Future<void> sendDebtReminderSms(SaleRecord sale) async {
    if (sale.customerPhone == null || sale.customerPhone!.isEmpty) return;

    final String message = 'DEBT REMINDER: Hello ${sale.customerName}, this is a reminder regarding your outstanding balance of GHC${sale.balance.toStringAsFixed(2)} for invoice ${sale.id} at Mi Corazon Butchery. Please settle as soon as possible. Thank you.';

    await _sendSms(sale.customerPhone!, message);
  }

  static Future<void> notifyAdmin({required String title, required String message}) async {
    final fullMessage = '$title: $message';
    await _sendSms(_adminPhone, fullMessage);
  }
}
