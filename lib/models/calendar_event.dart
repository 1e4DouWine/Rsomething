/// 日历日程数据模型
///
/// 表示一条日程/事件记录，与 Memory 关联（通过 memoryId）。
/// 当用户确认一条类型为"日程"的记忆时，会创建对应的 CalendarEvent 记录。
class CalendarEvent {
  /// 数据库自增主键，新建时为 null
  final int? id;

  /// 关联的记忆 ID（外键，指向 memories 表）
  final int memoryId;

  /// 日程标题
  final String title;

  /// 开始时间
  final DateTime startTime;

  /// 结束时间，默认为开始时间后 1 小时
  final DateTime endTime;

  /// 地点（可选）
  final String? location;

  /// 备注信息（可选）
  final String? notes;

  /// 构造函数
  /// [endTime] 默认为 [startTime] 加 1 小时
  CalendarEvent({
    this.id,
    required this.memoryId,
    required this.title,
    required this.startTime,
    DateTime? endTime,
    this.location,
    this.notes,
  }) : endTime = endTime ?? startTime.add(const Duration(hours: 1));

  /// 将模型转换为 Map，用于数据库插入/更新
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'memory_id': memoryId,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'notes': notes,
    };
  }

  /// 从数据库 Map 创建 CalendarEvent 实例的工厂方法
  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as int?,
      memoryId: map['memory_id'] as int,
      title: map['title'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
