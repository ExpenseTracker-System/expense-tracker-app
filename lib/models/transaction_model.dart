class TransactionModel {
  final String id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final bool isIncome;
  final String walletId;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.isIncome,
    this.walletId = 'default_wallet',
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    bool? isIncome,
    String? walletId,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      walletId: walletId ?? this.walletId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // للتخزين المحلي في SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toLocal().toIso8601String().replaceAll('Z', ''),
      'isIncome': isIncome ? 1 : 0,
      'walletId': walletId,
      'isDeleted': isDeleted ? 1 : 0,
      'createdAt': createdAt.toLocal().toIso8601String().replaceAll('Z', ''),
      'updatedAt': updatedAt.toLocal().toIso8601String().replaceAll('Z', ''),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: (map['note'] ?? '') as String,
      date: DateTime.parse(map['date'] as String),
      isIncome: (map['isIncome'] as int) == 1,
      walletId: (map['walletId'] ?? 'default_wallet') as String,
      isDeleted: (map['isDeleted'] ?? 0) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      isSynced: (map['isSynced'] ?? 0) == 1,
    );
  }

  // للإرسال والاستقبال عبر JSON مع سيرفر Spring Boot
 Map<String, dynamic> toJson() {
    final String dateIso = date.toLocal().toIso8601String().replaceAll('Z', '');
    final String createdIso = createdAt.toLocal().toIso8601String().replaceAll('Z', '');
    final String updatedIso = updatedAt.toLocal().toIso8601String().replaceAll('Z', '');
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'isIncome': isIncome,
      'income': isIncome,
      'transactionDate': dateIso,
      'transactionsDate': dateIso,
      'walletId': walletId,
      'isDeleted': isDeleted,
      'deleted': isDeleted,
      'createdAt': createdIso,
      'updatedAt': updatedIso,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['transactionDate'] ?? json['transactionsDate'] ?? json['date'];
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      note: (json['note'] ?? '') as String,
      date: rawDate != null ? DateTime.parse(rawDate.toString()) : DateTime.now(),
      isIncome: (json['isIncome'] ?? json['income'] ?? false) as bool,
      walletId: json['walletId'] as String,
      isDeleted: (json['isDeleted'] ?? json['deleted'] ?? false) as bool,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      isSynced: true,
    );
  }
}