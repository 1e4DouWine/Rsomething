import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';

class AIProvider with ChangeNotifier {
  final AIService _aiService = AIService.instance;
  final SettingsService _settingsService;
  bool _isAnalyzing = false;
  String? _error;

  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;

  AIProvider(this._settingsService) {
    _initAIConfig();
  }

  void _initAIConfig() {
    if (_settingsService.isAIConfigured()) {
      _aiService.setConfig(AIConfig(
        baseUrl: _settingsService.getBaseUrl(),
        apiKey: _settingsService.getApiKey(),
        modelName: _settingsService.getModelName(),
      ));
    }
  }

  void updateConfig() {
    _initAIConfig();
  }

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

  Future<AnalysisResult?> analyzeImage(String base64Image, {String? text}) async {
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

  Future<bool> testConnection() async {
    return await _aiService.testConnection();
  }
}
