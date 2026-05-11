/// 待办事项数据模型
///
/// 表示一条待办事项，与 Memory 关联（通过 memoryId）。
/// 当用户确认一条类型为"待办"的记忆时，会创建对应的 Todo 记录。
class Todo {
  /// 数据库自增主键，新建时为 null
  final int? id;

  /// 关联的记忆 ID（外键，指向 memories 表）
  final int memoryId;

  /// 待办事项标题
  final String title;

  /// 截止日期（可选）
  final DateTime? dueDate;

  /// 是否已完成
  final bool isCompleted;

  /// 是否开启提醒
  final bool reminder;

  /// 构造函数
  /// [isCompleted] 默认为 false，[reminder] 默认为 true
  Todo({
    this.id,
    required this.memoryId,
    required this.title,
    this.dueDate,
    this.isCompleted = false,
    this.reminder = true,
  });

  /// 将模型转换为 Map，用于数据库插入/更新
  /// 布尔值转换为整数存储（0/1）
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'memory_id': memoryId,
      'title': title,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'reminder': reminder ? 1 : 0,
    };
  }

  /// 从数据库 Map 创建 Todo 实例的工厂方法
  /// 整数值自动转换回布尔类型
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      memoryId: map['memory_id'] as int,
      title: map['title'] as String,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      isCompleted: (map['is_completed'] as int?) == 1,
      reminder: (map['reminder'] as int?) == 1,
    );
  }

  /// 创建当前 Todo 的副本，可选择性覆盖部分字段。
  Todo copyWith({
    int? id,
    int? memoryId,
    String? title,
    DateTime? dueDate,
    bool? isCompleted,
    bool? reminder,
  }) {
    return Todo(
      id: id ?? this.id,
      memoryId: memoryId ?? this.memoryId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      reminder: reminder ?? this.reminder,
    );
  }
}
