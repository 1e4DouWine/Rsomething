import 'dart:convert';

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
      'structured_data': json.encode(structuredData),
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
      final decoded = json.decode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
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
