/// 账单/消费记录数据模型
///
/// 表示一笔消费记录，与 Memory 关联（通过 memoryId）。
/// 当用户确认一条类型为"账单"的记忆时，会创建对应的 Expense 记录。
class Expense {
  /// 数据库自增主键，新建时为 null
  final int? id;

  /// 关联的记忆 ID（外键，指向 memories 表）
  final int memoryId;

  /// 消费金额
  final double amount;

  /// 币种，默认为 'CNY'（人民币）
  final String currency;

  /// 消费分类（如：餐饮、交通、购物、娱乐、住房、其他）
  final String category;

  /// 消费日期
  final DateTime date;

  /// 备注信息（可选）
  final String? note;

  /// 构造函数
  /// [currency] 默认为 'CNY'，[date] 默认为当前时间
  Expense({
    this.id,
    required this.memoryId,
    required this.amount,
    this.currency = 'CNY',
    required this.category,
    DateTime? date,
    this.note,
  }) : date = date ?? DateTime.now();

  /// 将模型转换为 Map，用于数据库插入/更新
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

  /// 从数据库 Map 创建 Expense 实例的工厂方法
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
