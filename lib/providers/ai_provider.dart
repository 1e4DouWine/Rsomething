import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';

/// AI 服务状态管理器
///
/// 管理 AI 分析相关的状态，包括配置初始化、文本/图片分析、连接测试等。
/// 作为 UI 层与 AIService 之间的桥梁，处理加载状态和错误信息。
class AIProvider with ChangeNotifier {
  /// AI 服务单例
  final AIService _aiService = AIService.instance;

  /// 设置服务实例（用于读取 AI 配置）
  final SettingsService _settingsService;

  /// 是否正在进行 AI 分析
  bool _isAnalyzing = false;

  /// 最近一次操作的错误信息
  String? _error;

  /// 公开的状态访问器
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;

  /// 构造函数
  /// 初始化时自动从设置服务加载 AI 配置
  AIProvider(this._settingsService) {
    _initAIConfig();
  }

  /// 从设置服务读取 AI 配置并应用到 AI 服务
  void _initAIConfig() {
    if (_settingsService.isAIConfigured()) {
      _aiService.setConfig(
        AIConfig(
          baseUrl: _settingsService.getBaseUrl(),
          apiKey: _settingsService.getApiKey(),
          modelName: _settingsService.getModelName(),
        ),
      );
    } else {
      _aiService.clearConfig();
    }
  }

  /// 更新 AI 配置（当用户修改设置后调用）
  void updateConfig() {
    _initAIConfig();
  }

  /// 分析文本内容
  /// [text] 待分析的文本
  /// 返回分析结果，失败时返回 null 并设置错误信息
  Future<AnalysisResult?> analyzeText(String text) async {
    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _aiService.analyzeText(text);
      _isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isAnalyzing = false;
      notifyListeners();
      return null;
    }
  }

  /// 分析图片内容
  /// [base64Image] Base64 编码的图片数据，[text] 可选的附加文本信息
  /// 返回分析结果，失败时返回 null 并设置错误信息
  Future<AnalysisResult?> analyzeImage(
    String base64Image, {
    String? text,
  }) async {
    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _aiService.analyzeImage(base64Image, text: text);
      _isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isAnalyzing = false;
      notifyListeners();
      return null;
    }
  }

  /// 测试 AI API 连接是否正常
  Future<bool> testConnection() async {
    return await _aiService.testConnection();
  }
}
