import 'product.dart';

enum PaymentMethod { cash, mobileMoney, card }

enum SaleStatus { completed, pendingCorrection, rectified, cancelled }

class PaymentDetail {
  final PaymentMethod method;
  final double amount;
  final String? reference; // For mobile/card refs

  PaymentDetail({
    required this.method,
    required this.amount,
    this.reference,
  });

  Map<String, dynamic> toJson() => {
    'method': method.name,
    'amount': amount,
    'reference': reference,
  };
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

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'priceAtSale': priceAtSale,
  };
}

class SaleRecord {
  final String id;
  final List<SaleItem> items;
  final double totalAmount; // This is the Net Invoice Value
  final List<PaymentDetail> payments;
  final DateTime timestamp;
  final String cashierName;
  final String? customerName;
  final String? customerPhone;
  final SaleStatus status;
  final String? correctionReason;

  SaleRecord({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.payments,
    required this.timestamp,
    required this.cashierName,
    this.customerName,
    this.customerPhone,
    this.status = SaleStatus.completed,
    this.correctionReason,
  });

  // Financial Breakdown Calculations
  double get totalQty => items.fold(0, (sum, item) => sum + item.quantity);
  int get skuCount => items.length;
  
  // Calculations based on the provided receipt structure (Ghanaian Tax system)
  // Assumes totalAmount is the final Net Invoice Value
  double get basicAmount => totalAmount; // Taxes set to 0.00 as per request
  double get getFund => 0.00;
  double get nhil => 0.00;
  double get subTotal => totalAmount;
  double get vat => 0.00;
  double get netInvoiceValue => totalAmount;

  double get amountPaid => payments.fold(0, (sum, p) => sum + p.amount);
  double get balance => totalAmount - amountPaid;

  SaleRecord copyWith({
    List<SaleItem>? items,
    double? totalAmount,
    SaleStatus? status,
    String? correctionReason,
  }) {
    return SaleRecord(
      id: id,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      payments: payments,
      timestamp: timestamp,
      cashierName: cashierName,
      customerName: customerName,
      customerPhone: customerPhone,
      status: status ?? this.status,
      correctionReason: correctionReason ?? this.correctionReason,
    );
  }
}
