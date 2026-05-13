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

  List<String> get standardCuts {
    switch (this) {
      case AnimalType.cow:
      case AnimalType.bull:
        return [
          'Mixed Meat',
          'Boneless',
          'Offals / Yemadeɛ',
          'Beef Steak',
          'Liver & Lungs',
          'Grounded Meat',
          'Feet',
          'Head',
          'Tail / Padua',
          'Bones',
        ];
      case AnimalType.pig:
        return [
          'Mixed Meat',
          'Boneless Meat',
          'Offals / Yemadeɛ',
          'Pork Steak',
          'Head',
          'Ear',
          'Feet',
          'Liver/lungs',
          'Skin',
        ];
      case AnimalType.goat:
      case AnimalType.sheep:
        return [
          'Mixed Meat',
          'Boneless',
          'Offals / Yemadeɛ',
          'Head',
          'Feet',
        ];
      case AnimalType.hardChicken:
        return [
          'Hard Thigh',
          'Hard Breast',
          'Hard Back',
          'Hard Wings',
          'Hard Half Chicken',
          'Hard Whole Chicken',
          'Hard Drumsticks',
          'Gizzards',
          'Feet',
        ];
      case AnimalType.softChicken:
        return [
          'Soft Thigh',
          'Soft Breast',
          'Soft Back',
          'Soft Wings',
          'Soft Half Chicken',
          'Soft Whole Chicken',
          'Soft Drumsticks',
          'Gizzards',
          'Feet',
        ];
      case AnimalType.turkey:
        return ['Whole Turkey', 'Breast', 'Thighs', 'Drumsticks', 'Wings', 'Gizzards', 'Feet'];
      case AnimalType.rabbit:
        return ['Whole Rabbit', 'Legs', 'Saddle', 'Shoulders'];
    }
  }
}

class SlaughterLog {
  final String id;
  final String? branchCode;
  final String animalId;
  final AnimalType type;
  final double weight;
  final DateTime? slaughterTime;
  final SlaughterStatus status;

  SlaughterLog({
    required this.id,
    this.branchCode,
    required this.animalId,
    required this.type,
    required this.weight,
    this.slaughterTime,
    required this.status,
  });

  double get estimatedYield => weight * type.dressingPercentage;

  SlaughterLog copyWith({
    String? id,
    String? branchCode,
    String? animalId,
    AnimalType? type,
    double? weight,
    DateTime? slaughterTime,
    SlaughterStatus? status,
  }) {
    return SlaughterLog(
      id: id ?? this.id,
      branchCode: branchCode ?? this.branchCode,
      animalId: animalId ?? this.animalId,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      slaughterTime: slaughterTime ?? this.slaughterTime,
      status: status ?? this.status,
    );
  }

  factory SlaughterLog.fromJson(Map<String, dynamic> json) {
    return SlaughterLog(
      id: json['id'] as String,
      branchCode: json['branch_code'] as String?,
      animalId: json['animal_id'] as String,
      type: AnimalType.values.firstWhere((e) => e.name == json['type']),
      weight: (json['initial_weight'] as num).toDouble(),
      slaughterTime: json['slaughter_time'] != null ? DateTime.parse(json['slaughter_time'] as String) : null,
      status: SlaughterStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_code': branchCode,
    'animal_id': animalId,
    'type': type.name,
    'initial_weight': weight,
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
  final String? branchCode;
  final String meatType;
  final double weight;
  final DateTime createdAt;
  final String status;
  final BatchSource source;
  final String? inspectedBy;
  final String? receivedBy;

  MeatBatch({
    required this.id,
    this.branchCode,
    required this.meatType,
    required this.weight,
    required this.createdAt,
    required this.status,
    required this.source,
    this.inspectedBy,
    this.receivedBy,
  });

  MeatBatch copyWith({
    String? id,
    String? branchCode,
    String? meatType,
    double? weight,
    DateTime? createdAt,
    String? status,
    BatchSource? source,
    String? inspectedBy,
    String? receivedBy,
  }) {
    return MeatBatch(
      id: id ?? this.id,
      branchCode: branchCode ?? this.branchCode,
      meatType: meatType ?? this.meatType,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      source: source ?? this.source,
      inspectedBy: inspectedBy ?? this.inspectedBy,
      receivedBy: receivedBy ?? this.receivedBy,
    );
  }

  factory MeatBatch.fromJson(Map<String, dynamic> json) {
    return MeatBatch(
      id: json['id'] as String,
      branchCode: json['branch_code'] as String?,
      meatType: json['meat_type'] as String,
      weight: (json['initial_weight'] as num).toDouble(),
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_code': branchCode,
    'meat_type': meatType,
    'initial_weight': weight,
    'current_weight': weight,
    'status': status,
    'source_name': source.name,
    'source_location': source.location,
    'owner_name': source.owner,
    'inspected_by': inspectedBy,
    'received_by': receivedBy,
    'created_at': createdAt.toIso8601String(),
  };
}

class MeatCut {
  final String id;
  final String? branchCode;
  final String name;
  final String batchId;
  final double weight;
  final DateTime processedAt;

  MeatCut({
    required this.id,
    this.branchCode,
    required this.name,
    required this.batchId,
    required this.weight,
    required this.processedAt,
  });

  MeatCut copyWith({
    String? id,
    String? branchCode,
    String? name,
    String? batchId,
    double? weight,
    DateTime? processedAt,
  }) {
    return MeatCut(
      id: id ?? this.id,
      branchCode: branchCode ?? this.branchCode,
      name: name ?? this.name,
      batchId: batchId ?? this.batchId,
      weight: weight ?? this.weight,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  factory MeatCut.fromJson(Map<String, dynamic> json) {
    return MeatCut(
      id: json['id'] as String,
      branchCode: json['branch_code'] as String?,
      name: json['name'] as String,
      batchId: json['batch_id'] as String,
      weight: (json['weight'] as num).toDouble(),
      processedAt: DateTime.parse(json['processed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_code': branchCode,
    'batch_id': batchId,
    'name': name,
    'weight': weight,
    'processed_at': processedAt.toIso8601String(),
  };
}

enum ButcherOrderStatus { pending, preparing, ready, completed }

class ButcherOrder {
  final String id;
  final String? branchCode;
  final String customerName;
  final List<String> items;
  final double totalWeight;
  final DateTime dueDate;
  final ButcherOrderStatus status;

  ButcherOrder({
    required this.id,
    this.branchCode,
    required this.customerName,
    required this.items,
    required this.totalWeight,
    required this.dueDate,
    required this.status,
  });

  ButcherOrder copyWith({
    String? id,
    String? branchCode,
    String? customerName,
    List<String>? items,
    double? totalWeight,
    DateTime? dueDate,
    ButcherOrderStatus? status,
  }) {
    return ButcherOrder(
      id: id ?? this.id,
      branchCode: branchCode ?? this.branchCode,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalWeight: totalWeight ?? this.totalWeight,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  factory ButcherOrder.fromJson(Map<String, dynamic> json) {
    return ButcherOrder(
      id: json['id'] as String,
      branchCode: json['branch_code'] as String?,
      customerName: json['customer_name'] as String,
      items: List<String>.from(json['items'] ?? []),
      totalWeight: (json['total_weight'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: ButcherOrderStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_code': branchCode,
    'customer_name': customerName,
    'items': items,
    'total_weight': totalWeight,
    'due_date': dueDate.toIso8601String(),
    'status': status.name,
  };
}
