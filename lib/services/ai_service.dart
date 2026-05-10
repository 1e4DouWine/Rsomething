import 'package:dio/dio.dart';
import 'dart:convert';

/// AI 分析结果数据类
///
/// 封装 AI 对用户内容分析后返回的结果，包含：
/// - 动作类型（账单/待办/日程/未知）
/// - 置信度（0.0~1.0）
/// - 结构化数据（具体内容取决于动作类型）
class AnalysisResult {
  /// 动作类型：add_expense / add_todo / add_event / unknown
  final String action;

  /// 分析置信度（0.0~1.0）
  final double confidence;

  /// 结构化数据（字段取决于动作类型）
  final Map<String, dynamic> data;

  AnalysisResult({
    required this.action,
    required this.confidence,
    required this.data,
  });

  /// 从 JSON Map 创建 AnalysisResult 实例
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      action: json['action'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// AI 服务配置数据类
///
/// 存储 AI API 的连接配置信息
class AIConfig {
  /// API 请求地址
  final String baseUrl;

  /// API 密钥
  final String apiKey;

  /// 使用的模型名称
  final String modelName;

  AIConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
  });
}

/// AI 服务类
///
/// 封装与大语言模型 API 的交互逻辑，提供文本分析和图片分析功能。
/// 使用单例模式，基于 Dio 进行 HTTP 请求。
/// 支持 OpenAI 兼容格式的 API 接口。
class AIService {
  /// 单例实例
  static AIService? _instance;

  /// HTTP 客户端
  late Dio _dio;

  /// AI 配置（未设置时为 null）
  AIConfig? _config;

  /// 获取当前配置（只读）
  AIConfig? get currentConfig => _config;

  /// 私有构造函数，初始化 Dio 并设置超时时间
  AIService._() {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// 获取单例实例
  static AIService get instance {
    _instance ??= AIService._();
    return _instance!;
  }

  /// 设置 AI 配置
  /// 更新 Dio 的请求基地址和认证头
  void setConfig(AIConfig config) {
    _config = config;
    _dio.options.baseUrl = config.baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json',
    };
  }

  /// 分析文本内容
  /// [text] 待分析的文本
  /// 返回 [AnalysisResult]，包含动作类型和结构化数据
  Future<AnalysisResult> analyzeText(String text) async {
    if (_config == null) {
      throw Exception('AI服务未配置');
    }

    final systemPrompt = _buildSystemPrompt();
    final userPrompt = '请分析以下内容并返回JSON格式结果：\n\n$text';

    try {
      final response = await _dio.post(
        '',
        data: {
          'model': _config!.modelName,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.1,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      final jsonStr = _extractJson(content);
      final jsonResult = json.decode(jsonStr);
      return AnalysisResult.fromJson(jsonResult);
    } on DioException catch (e) {
      throw Exception('AI分析失败: ${e.message}');
    }
  }

  /// 分析图片内容（Base64 编码）
  /// [base64Image] Base64 编码的图片数据，[text] 可选的附加文本信息
  /// 返回 [AnalysisResult]
  Future<AnalysisResult> analyzeImage(String base64Image, {String? text}) async {
    if (_config == null) {
      throw Exception('AI服务未配置');
    }

    final systemPrompt = _buildSystemPrompt();
    String userContent = '请分析这张图片并返回JSON格式结果。';
    if (text != null && text.isNotEmpty) {
      userContent += '\n\n附加文本信息：$text';
    }

    try {
      final response = await _dio.post(
        '',
        data: {
          'model': _config!.modelName,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': userContent},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
              ],
            },
          ],
          'temperature': 0.1,
          'max_tokens': 1000,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      // 从返回内容中提取 JSON 部分（模型可能返回非 JSON 前缀文字）
      final jsonStr = _extractJson(content);
      final jsonResult = json.decode(jsonStr);
      return AnalysisResult.fromJson(jsonResult);
    } on DioException catch (e) {
      throw Exception('AI图片分析失败: ${e.message}');
    }
  }

  /// 测试 API 连接是否正常
  /// 发送一个简单的请求验证配置是否正确
  Future<bool> testConnection() async {
    if (_config == null) return false;

    try {
      final response = await _dio.post(
        '',
        data: {
          'model': _config!.modelName,
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'max_tokens': 10,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 构建系统提示词
  /// 定义 AI 的角色和输出格式要求，指导模型按指定 JSON 结构返回分析结果
  String _buildSystemPrompt() {
    return '''你是一个智能内容分析助手。请分析用户分享的内容，并返回JSON格式的分析结果。

返回格式：
{
  "action": "add_expense | add_todo | add_event | summarize_video | unknown",
  "confidence": 0.95,
  "data": { ... }
}

动作类型说明：
1. add_expense（账单）- 当内容包含消费、支出、账单、小票等信息时
   data字段：amount(金额), currency(币种，默认CNY), category(分类：餐饮/交通/购物/娱乐/其他), date(日期，格式YYYY-MM-DD), note(备注)

2. add_todo（待办）- 当内容包含待办事项、取件码、提醒等信息时
   data字段：title(标题), due_date(截止日期，可选), reminder(是否提醒，默认true)

3. add_event（日程）- 当内容包含会议、活动、日程等信息时
   data字段：title(标题), start_time(开始时间，ISO8601), end_time(结束时间，可选), location(地点，可选), notes(备注，可选)

4. unknown（未知）- 无法识别内容类型时
   data字段：reason(原因)

请只返回JSON，不要有其他文字。''';
  }

  /// 从文本中提取 JSON 字符串
  /// 使用正则匹配最外层花括号包裹的内容
  String _extractJson(String content) {
    final jsonPattern = RegExp(r'\{[\s\S]*\}');
    final match = jsonPattern.firstMatch(content);
    if (match != null) {
      return match.group(0)!;
    }
    return content;
  }
}
