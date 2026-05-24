import 'product.dart';

enum PaymentMethod { cash, mobileMoney }

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

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      method: PaymentMethod.values.byName(json['method']),
      amount: (json['amount'] as num).toDouble(),
      reference: json['reference'],
    );
  }

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
  final double originalPrice;

  SaleItem({
    required this.product,
    required this.quantity,
    required this.priceAtSale,
    required this.originalPrice,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      product: Product.fromJson(json['product']),
      quantity: (json['quantity'] as num).toDouble(),
      priceAtSale: (json['price_at_sale'] as num).toDouble(),
      originalPrice: (json['original_price'] as num? ?? (json['price_at_sale'] as num)).toDouble(),
    );
  }

  double get total => quantity * priceAtSale;
  double get discount => (originalPrice - priceAtSale) * quantity;

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'price_at_sale': priceAtSale,
    'original_price': originalPrice,
  };
}

class SaleRecord {
  final String id;
  final String? branchCode;
  final List<SaleItem> items;
  final double totalAmount; // This is the Net Invoice Value (After Discount)
  final double totalDiscount; // Total revenue loss from promotions
  final String? appliedPromo; // Description of applied promo
  final List<PaymentDetail> payments;
  final DateTime timestamp;
  final String cashierName;
  final String cashierId;
  final String? customerName;
  final String? customerPhone;
  final SaleStatus status;
  final String? correctionReason;

  SaleRecord({
    required this.id,
    this.branchCode,
    required this.items,
    required this.totalAmount,
    this.totalDiscount = 0.0,
    this.appliedPromo,
    required this.payments,
    required this.timestamp,
    required this.cashierName,
    required this.cashierId,
    this.customerName,
    this.customerPhone,
    this.status = SaleStatus.completed,
    this.correctionReason,
  });

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      id: json['id'],
      branchCode: json['branch_code'],
      items: (json['items'] as List).map((e) => SaleItem.fromJson(e)).toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      totalDiscount: (json['total_discount'] as num? ?? 0.0).toDouble(),
      appliedPromo: json['applied_promo'],
      payments: (json['payments'] as List).map((e) => PaymentDetail.fromJson(e)).toList(),
      timestamp: DateTime.parse(json['timestamp']),
      cashierName: json['cashier_name'],
      cashierId: json['cashier_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      status: SaleStatus.values.byName(json['status'] ?? 'completed'),
      correctionReason: json['correction_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_code': branchCode,
      'items': items.map((e) => e.toJson()).toList(),
      'total_amount': totalAmount,
      'total_discount': totalDiscount,
      'applied_promo': appliedPromo,
      'payments': payments.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'cashier_name': cashierName,
      'cashier_id': cashierId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'status': status.name,
      'correction_reason': correctionReason,
    };
  }

  // Financial Breakdown Calculations
  double get totalQty => items.fold(0, (sum, item) => sum + item.quantity);
  int get productCount => items.length;
  
  // Base total before discounts
  double get baseTotal => totalAmount + totalDiscount;

  // Calculations based on the Ghanaian Tax system (Standard Rate)
  // Basic Amount (Exclusive of Levies and VAT)
  double get taxExclusiveAmount => totalAmount / 1.219; // Mathematical reverse of standard rate

  double get getFundAmount => taxExclusiveAmount * 0.025;
  double get nhilAmount => taxExclusiveAmount * 0.025;
  double get covidLevyAmount => taxExclusiveAmount * 0.01;
  
  // Taxable Value for VAT = Exclusive + Levies
  double get taxableValueForVat => taxExclusiveAmount + getFundAmount + nhilAmount + covidLevyAmount;
  
  double get vatAmount => taxableValueForVat * 0.15;

  // Verification: taxExclusiveAmount + getFund + nhil + covid + vat should approx totalAmount
  
  // Alternative: Flat Rate (3% + 1% COVID) = 4% total on top
  double get flatRateVatAmount => totalAmount * 0.03;
  double get flatRateCovidAmount => totalAmount * 0.01;

  double get netInvoiceValue => totalAmount;

  // Aliases for backward compatibility
  double get basicAmount => taxExclusiveAmount;
  double get getFund => getFundAmount;
  double get nhil => nhilAmount;
  double get vat => vatAmount;
  double get subTotal => totalAmount;

  double get amountPaid => payments.fold(0, (sum, p) => sum + p.amount);
  double get balance => totalAmount - amountPaid;

  SaleRecord copyWith({
    String? branchCode,
    List<SaleItem>? items,
    double? totalAmount,
    double? totalDiscount,
    String? appliedPromo,
    List<PaymentDetail>? payments,
    SaleStatus? status,
    String? correctionReason,
    String? customerName,
    String? customerPhone,
  }) {
    return SaleRecord(
      id: id,
      branchCode: branchCode ?? this.branchCode,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      appliedPromo: appliedPromo ?? this.appliedPromo,
      payments: payments ?? this.payments,
      timestamp: timestamp,
      cashierName: cashierName,
      cashierId: cashierId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      status: status ?? this.status,
      correctionReason: correctionReason ?? this.correctionReason,
    );
  }
}
