class TransactionModel {
  final String id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final bool isIncome;

   TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.isIncome,
  });
   Map<String, dynamic> toMap() {
  return {
    'id': id,
    'amount': amount,
    'category': category,
    'note': note,
    'date': date.toIso8601String(),
    'isIncome': isIncome ? 1 : 0,
  };
}
  factory 
TransactionModel.fromMap(Map<String,dynamic> map) {
  return TransactionModel(
    id: map['id'],
    amount: map['amount'],
    category: map['category'],
    note: map['note'],
    date: DateTime.parse(map['date']),
    isIncome: map['isIncome'] == 1,
  );
}
}
