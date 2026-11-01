class WalletModel {
  final String id;
  final String name;
  final String currency;
  final String? userId;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  WalletModel({
    required this.id,
    required this.name,
    this.currency = 'ريال',
    this.userId,
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WalletModel copyWith({
    String? id,
    String? name,
    String? currency,
    String? userId,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      userId: userId ?? this.userId,
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
      'name': name,
      'currency': currency.isNotEmpty ? currency : 'ريال',
      'userId': userId,
      'isDeleted': isDeleted ? 1 : 0,
      'createdAt': createdAt.toLocal().toIso8601String().replaceAll('Z', ''),
      'updatedAt': updatedAt.toLocal().toIso8601String().replaceAll('Z', ''),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    final String rawCurrency = (map['currency'] ?? 'ريال').toString();
    return WalletModel(
      id: map['id'] as String,
      name: map['name'] as String,
      currency: rawCurrency.isNotEmpty ? rawCurrency : 'ريال',
      userId: map['userId'] as String?,
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
    return {
      'id': id,
      'name': name,
      'currency': currency.isNotEmpty ? currency : 'ريال',
      'userId': userId,
      'isDeleted': isDeleted,
      'deleted': isDeleted,
      'createdAt': createdAt.toLocal().toIso8601String().replaceAll('Z', ''),
      'updatedAt': updatedAt.toLocal().toIso8601String().replaceAll('Z', ''),
    };
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final String rawCurrency = (json['currency'] ?? 'ريال').toString();
    return WalletModel(
      id: json['id'] as String,
      name: json['name'] as String,
      currency: rawCurrency.isNotEmpty ? rawCurrency : 'ريال',
      userId: json['userId'] as String?,
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