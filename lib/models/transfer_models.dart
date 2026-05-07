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
