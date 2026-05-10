enum SlaughterStatus { pending, processing, completed }

enum AnimalType { cow, bull, pig, sheep, goat, hardChicken, softChicken, turkey, rabbit }

extension AnimalTypeX on AnimalType {
  String get displayName {
    switch (this) {
      case AnimalType.hardChicken: return 'Hard Chicken (Layers)';
      case AnimalType.softChicken: return 'Soft Chicken (Broilers)';
      default: return name[0].toUpperCase() + name.substring(1);
    }
  }

  String get shortCode {
    switch (this) {
      case AnimalType.cow: return 'BF'; // Beef
      case AnimalType.bull: return 'BL';
      case AnimalType.pig: return 'PK'; // Pork
      case AnimalType.sheep: return 'SH';
      case AnimalType.goat: return 'GT';
      case AnimalType.hardChicken: return 'CH-H';
      case AnimalType.softChicken: return 'CH-S';
      case AnimalType.turkey: return 'TK';
      case AnimalType.rabbit: return 'RB';
    }
  }

  /// Typical dressing percentage for various animals
  double get dressingPercentage {
    switch (this) {
      case AnimalType.cow: return 0.62;
      case AnimalType.bull: return 0.60;
      case AnimalType.pig: return 0.74;
      case AnimalType.sheep: return 0.50;
      case AnimalType.goat: return 0.48;
      case AnimalType.hardChicken: return 0.70;
      case AnimalType.softChicken: return 0.72;
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
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      type: AnimalType.values.firstWhere((e) => e.name == json['type']),
      weight: (json['weight'] as num).toDouble(),
      slaughterTime: json['slaughter_time'] != null ? DateTime.parse(json['slaughter_time'] as String) : null,
      status: SlaughterStatus.values.firstWhere((e) => e.name == json['status']),
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

class BatchSource {
  final String name;
  final String location;
  final String owner;

  BatchSource({required this.name, required this.location, required this.owner});

  factory BatchSource.empty() => BatchSource(name: '', location: '', owner: '');
}

class MeatBatch {
  final String id;
  final String meatType;
  final double weight;
  final DateTime createdAt;
  final String status;
  final BatchSource source;
  final String? inspectedBy;
  final String? receivedBy;

  MeatBatch({
    required this.id,
    required this.meatType,
    required this.weight,
    required this.createdAt,
    required this.status,
    required this.source,
    this.inspectedBy,
    this.receivedBy,
  });

  factory MeatBatch.fromJson(Map<String, dynamic> json) {
    return MeatBatch(
      id: json['id'] as String,
      meatType: json['meat_type'] as String,
      weight: (json['weight'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String,
      source: BatchSource(
        name: json['source_name'] ?? '',
        location: json['source_location'] ?? '',
        owner: json['owner_name'] ?? '',
      ),
      inspectedBy: json['inspected_by'] as String?,
      receivedBy: json['received_by'] as String?,
    );
  }
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
      id: json['id'] as String,
      name: json['name'] as String,
      batchId: json['batch_id'] as String,
      weight: (json['weight'] as num).toDouble(),
      processedAt: DateTime.parse(json['processed_at'] as String),
    );
  }
}
