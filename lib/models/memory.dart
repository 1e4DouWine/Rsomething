/// 记忆类型枚举
enum MemoryType {
  bill('bill', '账单'),
  todo('todo', '待办'),
  event('event', '日程'),
  summary('summary', '摘要'),
  unknown('unknown', '未知');

  final String value;
  final String label;
  const MemoryType(this.value, this.label);

  static MemoryType fromString(String value) {
    return MemoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MemoryType.unknown,
    );
  }
}

/// 原始内容类型
enum RawContentType {
  text('text', '文本'),
  image('image', '图片'),
  video('video', '视频');

  final String value;
  final String label;
  const RawContentType(this.value, this.label);

  static RawContentType fromString(String value) {
    return RawContentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RawContentType.text,
    );
  }
}

/// 记忆状态
enum MemoryStatus {
  pending('pending', '待处理'),
  confirmed('confirmed', '已确认'),
  dismissed('dismissed', '已忽略');

  final String value;
  final String label;
  const MemoryStatus(this.value, this.label);

  static MemoryStatus fromString(String value) {
    return MemoryStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MemoryStatus.pending,
    );
  }
}

/// 记忆数据模型
class Memory {
  final int? id;
  final MemoryType type;
  final RawContentType rawContentType;
  final String rawContentSummary;
  final Map<String, dynamic> structuredData;
  final DateTime createdAt;
  final MemoryStatus status;
  final String? sourceApp;

  Memory({
    this.id,
    required this.type,
    required this.rawContentType,
    required this.rawContentSummary,
    required this.structuredData,
    DateTime? createdAt,
    this.status = MemoryStatus.pending,
    this.sourceApp,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.value,
      'raw_content_type': rawContentType.value,
      'raw_content_summary': rawContentSummary,
      'structured_data': structuredData.toString(), // JSON字符串
      'created_at': createdAt.toIso8601String(),
      'status': status.value,
      'source_app': sourceApp,
    };
  }

  factory Memory.fromMap(Map<String, dynamic> map) {
    return Memory(
      id: map['id'] as int?,
      type: MemoryType.fromString(map['type'] as String),
      rawContentType: RawContentType.fromString(map['raw_content_type'] as String),
      rawContentSummary: map['raw_content_summary'] as String? ?? '',
      structuredData: _parseStructuredData(map['structured_data'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      status: MemoryStatus.fromString(map['status'] as String? ?? 'pending'),
      sourceApp: map['source_app'] as String?,
    );
  }

  static Map<String, dynamic> _parseStructuredData(String? data) {
    if (data == null || data.isEmpty) return {};
    try {
      // 简单的JSON解析，实际项目中应使用dart:convert
      return {};
    } catch (e) {
      return {};
    }
  }

  Memory copyWith({
    int? id,
    MemoryType? type,
    RawContentType? rawContentType,
    String? rawContentSummary,
    Map<String, dynamic>? structuredData,
    DateTime? createdAt,
    MemoryStatus? status,
    String? sourceApp,
  }) {
    return Memory(
      id: id ?? this.id,
      type: type ?? this.type,
      rawContentType: rawContentType ?? this.rawContentType,
      rawContentSummary: rawContentSummary ?? this.rawContentSummary,
      structuredData: structuredData ?? this.structuredData,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      sourceApp: sourceApp ?? this.sourceApp,
    );
  }
}

/// 账单数据模型
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

/// 待办数据模型
class Todo {
  final int? id;
  final int memoryId;
  final String title;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool reminder;

  Todo({
    this.id,
    required this.memoryId,
    required this.title,
    this.dueDate,
    this.isCompleted = false,
    this.reminder = true,
  });

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

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      memoryId: map['memory_id'] as int,
      title: map['title'] as String,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      isCompleted: (map['is_completed'] as int?) == 1,
      reminder: (map['reminder'] as int?) == 1,
    );
  }
}

/// 日程事件数据模型
class CalendarEvent {
  final int? id;
  final int memoryId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? notes;

  CalendarEvent({
    this.id,
    required this.memoryId,
    required this.title,
    required this.startTime,
    DateTime? endTime,
    this.location,
    this.notes,
  }) : endTime = endTime ?? startTime.add(const Duration(hours: 1));

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