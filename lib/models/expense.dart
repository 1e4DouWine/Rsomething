class Expense {
  final int? id;
  final int memoryId;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;
  final String? note;

  Expense({
    this.id,
    required this.memoryId,
    required this.amount,
    this.currency = 'CNY',
    required this.category,
    DateTime? date,
    this.note,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'memory_id': memoryId,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      memoryId: map['memory_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'CNY',
      category: map['category'] as String? ?? '其他',
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
}
