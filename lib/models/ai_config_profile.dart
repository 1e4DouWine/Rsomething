import 'dart:convert';

/// AI 模型配置档案数据模型
///
/// 存储单份 AI 模型的连接配置信息，支持多份配置并存。
/// 每份配置包含唯一标识 [id]、显示名称 [name]、API 地址 [baseUrl]、
/// 认证密钥 [apiKey] 和模型名称 [modelName]。
///
/// 支持 JSON 序列化/反序列化，用于 SharedPreferences 持久化存储。
class AiConfigProfile {
  /// 配置唯一标识符（UUID）
  final String id;

  /// 配置显示名称（如"OpenAI"、"通义千问"）
  final String name;

  /// API 请求地址（应以 /chat/completions 结尾）
  final String baseUrl;

  /// API 认证密钥
  final String apiKey;

  /// 使用的 LLM 模型名称
  final String modelName;

  AiConfigProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
  });

  /// 转换为 Map（用于 JSON 编码）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'modelName': modelName,
    };
  }

  /// 从 Map 创建实例（用于 JSON 解码）
  factory AiConfigProfile.fromMap(Map<String, dynamic> map) {
    return AiConfigProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      baseUrl: map['baseUrl'] as String,
      apiKey: map['apiKey'] as String? ?? '',
      modelName: map['modelName'] as String,
    );
  }

  /// 转换为 JSON 字符串
  String toJson() => json.encode(toMap());

  /// 从 JSON 字符串创建实例。
  ///
  /// 先校验顶层结构，避免错误格式在强制类型转换时产生难以定位的异常。
  factory AiConfigProfile.fromJson(String source) {
    final decoded = json.decode(source);
    if (decoded is! Map) {
      throw const FormatException('AI 配置 JSON 必须是对象');
    }
    return AiConfigProfile.fromMap(Map<String, dynamic>.from(decoded));
  }

  /// 创建副本，可选择性覆盖指定字段
  AiConfigProfile copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? modelName,
  }) {
    return AiConfigProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
    );
  }
}
