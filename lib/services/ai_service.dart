import 'package:dio/dio.dart';
import 'dart:convert';

/// AI分析结果
class AnalysisResult {
  final String action;
  final double confidence;
  final Map<String, dynamic> data;

  AnalysisResult({
    required this.action,
    required this.confidence,
    required this.data,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      action: json['action'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// AI服务配置
class AIConfig {
  final String baseUrl;
  final String apiKey;
  final String modelName;

  AIConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
  });
}

/// AI服务
class AIService {
  static AIService? _instance;
  late Dio _dio;
  AIConfig? _config;

  AIService._() {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  static AIService get instance {
    _instance ??= AIService._();
    return _instance!;
  }

  /// 设置AI配置
  void setConfig(AIConfig config) {
    _config = config;
    _dio.options.baseUrl = config.baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json',
    };
  }

  /// 分析文本内容
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
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      final jsonResult = json.decode(content);
      return AnalysisResult.fromJson(jsonResult);
    } on DioException catch (e) {
      throw Exception('AI分析失败: ${e.message}');
    }
  }

  /// 分析图片（Base64编码）
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
      // 尝试从内容中提取JSON
      final jsonStr = _extractJson(content);
      final jsonResult = json.decode(jsonStr);
      return AnalysisResult.fromJson(jsonResult);
    } on DioException catch (e) {
      throw Exception('AI图片分析失败: ${e.message}');
    }
  }

  /// 测试API连接
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

  String _extractJson(String content) {
    // 尝试提取JSON内容
    final jsonPattern = RegExp(r'\{[\s\S]*\}');
    final match = jsonPattern.firstMatch(content);
    if (match != null) {
      return match.group(0)!;
    }
    return content;
  }
}