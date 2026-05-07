import 'product.dart';

enum PaymentMethod { cash, mobileMoney, card }

class PaymentDetail {
  final PaymentMethod method;
  final double amount;
  final String? reference; // For mobile/card refs

  PaymentDetail({
    required this.method,
    required this.amount,
    this.reference,
  });
}

class SaleItem {
  final Product product;
  final double quantity;
  final double priceAtSale;

  SaleItem({
    required this.product,
    required this.quantity,
    required this.priceAtSale,
  });

  double get total => quantity * priceAtSale;
}

class SaleRecord {
  final String id;
  final List<SaleItem> items;
  final double totalAmount;
  final List<PaymentDetail> payments;
  final DateTime timestamp;
  final String cashierName;
  final String? customerName;
  final String? customerPhone;

  SaleRecord({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.payments,
    required this.timestamp,
    required this.cashierName,
    this.customerName,
    this.customerPhone,
  });

  double get amountPaid => payments.fold(0, (sum, p) => sum + p.amount);
  double get balance => totalAmount - amountPaid;
}
