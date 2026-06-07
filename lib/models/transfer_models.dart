enum TransferStatus { pending, received, rejected, awaitingPayment }

class StockTransfer {
  final String id;
  final String? branchCode;
  final String batchId;
  final String meatType;
  final double weight;
  final String destination;
  final DateTime transferTime;
  final TransferStatus status;
  final bool isThirdParty;
  final bool isPaid;
  final bool isIndividual;
  final String? customerName;
  final String? customerPhone;
  final String? customerLocation;

  StockTransfer({
    required this.id,
    this.branchCode,
    required this.batchId,
    required this.meatType,
    required this.weight,
    required this.destination,
    required this.transferTime,
    this.status = TransferStatus.pending,
    this.isThirdParty = false,
    this.isPaid = false,
    this.isIndividual = false,
    this.customerName,
    this.customerPhone,
    this.customerLocation,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: json['id'],
      branchCode: json['branch_code'],
      batchId: json['batch_id'],
      meatType: json['meat_type'],
      weight: (json['weight'] as num).toDouble(),
      destination: json['destination'],
      transferTime: DateTime.parse(json['transfer_time']),
      status: TransferStatus.values.byName(json['status']),
      isThirdParty: json['is_third_party'] ?? false,
      isPaid: json['is_paid'] ?? false,
      isIndividual: json['is_individual'] ?? false,
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      customerLocation: json['customer_location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_code': branchCode,
      'batch_id': batchId,
      'meat_type': meatType,
      'weight': weight,
      'destination': destination,
      'transfer_time': transferTime.toIso8601String(),
      'status': status.name,
      'is_third_party': isThirdParty,
      'is_paid': isPaid,
      'is_individual': isIndividual,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_location': customerLocation,
    };
  }

  StockTransfer copyWith({
    TransferStatus? status,
    bool? isPaid,
    String? destination,
    bool? isIndividual,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? branchCode,
  }) {
    return StockTransfer(
      id: id,
      branchCode: branchCode ?? this.branchCode,
      batchId: batchId,
      meatType: meatType,
      weight: weight,
      destination: destination ?? this.destination,
      transferTime: transferTime,
      status: status ?? this.status,
      isThirdParty: isThirdParty,
      isPaid: isPaid ?? this.isPaid,
      isIndividual: isIndividual ?? this.isIndividual,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerLocation: customerLocation ?? this.customerLocation,
    );
  }
}
