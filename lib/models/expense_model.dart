class ExpenseRecord {
  final String id;
  final String? branchCode;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? notes;

  ExpenseRecord({
    required this.id,
    this.branchCode,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    return ExpenseRecord(
      id: json['id'],
      branchCode: json['branch_code'],
      title: json['title'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_code': branchCode,
    'title': title,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  ExpenseRecord copyWith({
    String? id,
    String? branchCode,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    String? notes,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      branchCode: branchCode ?? this.branchCode,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
