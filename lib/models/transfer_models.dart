enum TransferStatus { pending, received, rejected }

class StockTransfer {
  final String id;
  final String batchId;
  final String meatType;
  final double weight;
  final String destination;
  final DateTime transferTime;
  final TransferStatus status;

  StockTransfer({
    required this.id,
    required this.batchId,
    required this.meatType,
    required this.weight,
    required this.destination,
    required this.transferTime,
    this.status = TransferStatus.pending,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: json['id'],
      batchId: json['batch_id'],
      meatType: json['meat_type'],
      weight: (json['weight'] as num).toDouble(),
      destination: json['destination'],
      transferTime: DateTime.parse(json['transfer_time']),
      status: TransferStatus.values.byName(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'meat_type': meatType,
      'weight': weight,
      'destination': destination,
      'transfer_time': transferTime.toIso8601String(),
      'status': status.name,
    };
  }

  StockTransfer copyWith({
    TransferStatus? status,
  }) {
    return StockTransfer(
      id: id,
      batchId: batchId,
      meatType: meatType,
      weight: weight,
      destination: destination,
      transferTime: transferTime,
      status: status ?? this.status,
    );
  }
}
