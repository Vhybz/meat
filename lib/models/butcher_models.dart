enum SlaughterStatus { pending, processing, completed }

enum AnimalType {
  cow,
  bull,
  pig,
  sheep,
  goat,
  chicken,
  turkey,
  rabbit
}

extension AnimalTypeX on AnimalType {
  String get displayName => name[0].toUpperCase() + name.substring(1);

  /// Typical dressing percentage for various animals
  double get dressingPercentage {
    switch (this) {
      case AnimalType.cow: return 0.62;
      case AnimalType.bull: return 0.60;
      case AnimalType.pig: return 0.74;
      case AnimalType.sheep: return 0.50;
      case AnimalType.goat: return 0.48;
      case AnimalType.chicken: return 0.72;
      case AnimalType.turkey: return 0.78;
      case AnimalType.rabbit: return 0.55;
    }
  }
}

class SlaughterLog {
  final String id;
  final String animalId;
  final AnimalType type;
  final double weight;
  final DateTime? slaughterTime;
  final SlaughterStatus status;

  SlaughterLog({
    required this.id,
    required this.animalId,
    required this.type,
    required this.weight,
    this.slaughterTime,
    required this.status,
  });

  double get estimatedYield => weight * type.dressingPercentage;

  factory SlaughterLog.fromJson(Map<String, dynamic> json) {
    return SlaughterLog(
      id: json['id'],
      animalId: json['animal_id'],
      type: AnimalType.values.byName(json['type']),
      weight: (json['weight'] as num).toDouble(),
      slaughterTime: json['slaughter_time'] != null ? DateTime.parse(json['slaughter_time']) : null,
      status: SlaughterStatus.values.byName(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'animal_id': animalId,
    'type': type.name,
    'weight': weight,
    'slaughter_time': slaughterTime?.toIso8601String(),
    'status': status.name,
  };
}

class MeatBatch {
  final String id;
  final String meatType;
  final double weight;
  final DateTime createdAt;
  final String status;

  MeatBatch({
    required this.id,
    required this.meatType,
    required this.weight,
    required this.createdAt,
    required this.status,
  });

  factory MeatBatch.fromJson(Map<String, dynamic> json) {
    return MeatBatch(
      id: json['id'],
      meatType: json['meat_type'],
      weight: (json['weight'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'meat_type': meatType,
    'weight': weight,
    'created_at': createdAt.toIso8601String(),
    'status': status,
  };
}

class MeatCut {
  final String id;
  final String name;
  final String batchId;
  final double weight;
  final DateTime processedAt;

  MeatCut({
    required this.id,
    required this.name,
    required this.batchId,
    required this.weight,
    required this.processedAt,
  });

  factory MeatCut.fromJson(Map<String, dynamic> json) {
    return MeatCut(
      id: json['id'],
      name: json['name'],
      batchId: json['batch_id'],
      weight: (json['weight'] as num).toDouble(),
      processedAt: DateTime.parse(json['processed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'batch_id': batchId,
    'weight': weight,
    'processed_at': processedAt.toIso8601String(),
  };
}
