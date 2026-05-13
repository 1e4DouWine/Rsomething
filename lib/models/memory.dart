import 'dart:convert';

/// 记忆类型枚举
/// 定义了系统支持的所有记忆分类
enum MemoryType {
  /// 账单类型（如消费记录、小票等）
  bill('bill', '账单'),

  /// 待办类型（如待办事项、取件码等）
  todo('todo', '待办'),

  /// 日程类型（如会议、活动等）
  event('event', '日程'),

  /// 摘要类型（如视频摘要等）
  summary('summary', '摘要'),

  /// 未知类型（无法识别的内容）
  unknown('unknown', '未知');

  /// 枚举的字符串值
  final String value;

  /// 枚举的中文标签
  final String label;

  const MemoryType(this.value, this.label);

  /// 从字符串解析出对应的 MemoryType 枚举值
  /// 如果无法匹配则返回 [MemoryType.unknown]
  static MemoryType fromString(String value) {
    return MemoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MemoryType.unknown,
    );
  }
}

/// 原始内容类型枚举
/// 定义了记忆原始内容的载体形式
enum RawContentType {
  /// 文本内容
  text('text', '文本'),

  /// 图片内容
  image('image', '图片'),

  /// 视频内容
  video('video', '视频');

  /// 枚举的字符串值
  final String value;

  /// 枚举的中文标签
  final String label;

  const RawContentType(this.value, this.label);

  /// 从字符串解析出对应的 RawContentType 枚举值
  /// 如果无法匹配则默认返回 [RawContentType.text]
  static RawContentType fromString(String value) {
    return RawContentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RawContentType.text,
    );
  }
}

/// 记忆状态枚举
/// 定义了记忆在生命周期中的各种状态
enum MemoryStatus {
  /// 待处理状态（新创建的记忆，等待用户确认）
  pending('pending', '待处理'),

  /// 已确认状态（用户已确认，数据已保存到对应模块）
  confirmed('confirmed', '已确认'),

  /// 已忽略状态（用户选择忽略该记忆）
  dismissed('dismissed', '已忽略');

  /// 枚举的字符串值
  final String value;

  /// 枚举的中文标签
  final String label;

  const MemoryStatus(this.value, this.label);

  /// 从字符串解析出对应的 MemoryStatus 枚举值
  /// 如果无法匹配则默认返回 [MemoryStatus.pending]
  static MemoryStatus fromString(String value) {
    return MemoryStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MemoryStatus.pending,
    );
  }
}

/// 记忆数据模型
///
/// 核心数据模型，表示系统中的一条记忆记录。
/// 每条记忆由 AI 分析后生成，包含原始内容摘要和结构化数据。
/// 记忆可以是账单、待办、日程等不同类型。
class Memory {
  /// 数据库自增主键，新建时为 null
  final int? id;

  /// 记忆类型（账单/待办/日程/摘要/未知）
  final MemoryType type;

  /// 原始内容的载体类型（文本/图片/视频）
  final RawContentType rawContentType;

  /// 原始内容的摘要文本（用于列表展示）
  final String rawContentSummary;

  /// AI 识别后的结构化数据（JSON 格式，字段取决于记忆类型）
  final Map<String, dynamic> structuredData;

  /// 记忆创建时间
  final DateTime createdAt;

  /// 记忆状态（待处理/已确认/已忽略）
  final MemoryStatus status;

  /// 来源应用名称（可选，记录内容来自哪个应用）
  final String? sourceApp;

  /// 构造函数
  /// [createdAt] 默认为当前时间，[status] 默认为待处理
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

  /// 将模型转换为 Map，用于数据库插入/更新
  /// [id] 为 null 时不包含在 Map 中（由数据库自动生成）
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.value,
      'raw_content_type': rawContentType.value,
      'raw_content_summary': rawContentSummary,
      'structured_data': json.encode(structuredData),
      'created_at': createdAt.toIso8601String(),
      'status': status.value,
      'source_app': sourceApp,
    };
  }

  /// 从数据库 Map 创建 Memory 实例的工厂方法
  factory Memory.fromMap(Map<String, dynamic> map) {
    return Memory(
      id: map['id'] as int?,
      type: MemoryType.fromString(map['type'] as String),
      rawContentType: RawContentType.fromString(
        map['raw_content_type'] as String,
      ),
      rawContentSummary: map['raw_content_summary'] as String? ?? '',
      structuredData: _parseStructuredData(map['structured_data'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      status: MemoryStatus.fromString(map['status'] as String? ?? 'pending'),
      sourceApp: map['source_app'] as String?,
    );
  }

  /// 解析结构化数据 JSON 字符串
  /// 安全地处理 null、空字符串和格式错误的 JSON
  static Map<String, dynamic> _parseStructuredData(String? data) {
    if (data == null || data.isEmpty) return {};
    try {
      final decoded = json.decode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// 创建当前 Memory 的副本，可选择性地覆盖部分字段
  /// 常用于更新记忆状态后生成新实例
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
