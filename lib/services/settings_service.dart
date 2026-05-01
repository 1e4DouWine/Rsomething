import 'package:shared_preferences/shared_preferences.dart';

/// 设置服务
class SettingsService {
  static SettingsService? _instance;
  late SharedPreferences _prefs;

  // 配置键
  static const String _keyBaseUrl = 'ai_base_url';
  static const String _keyApiKey = 'ai_api_key';
  static const String _keyModelName = 'ai_model_name';
  static const String _keyUseDefaultBackend = 'use_default_backend';
  static const String _keySilentMode = 'silent_mode';
  static const String _keyDefaultReminderMinutes = 'default_reminder_minutes';

  // 默认值
  static const String _defaultBaseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _defaultApiKey = '';
  static const String _defaultModelName = 'minimax/minimax-m2.5:free';
  static const bool _defaultUseDefaultBackend = false;
  static const bool _defaultSilentMode = false;
  static const int _defaultReminderMinutes = 60;

  SettingsService._();

  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ==================== AI配置 ====================

  /// 获取API Base URL
  String getBaseUrl() {
    return _prefs.getString(_keyBaseUrl) ?? _defaultBaseUrl;
  }

  /// 设置API Base URL
  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_keyBaseUrl, url);
  }

  /// 获取API Key
  String getApiKey() {
    return _prefs.getString(_keyApiKey) ?? _defaultApiKey;
  }

  /// 设置API Key
  Future<void> setApiKey(String key) async {
    await _prefs.setString(_keyApiKey, key);
  }

  /// 获取模型名称
  String getModelName() {
    return _prefs.getString(_keyModelName) ?? _defaultModelName;
  }

  /// 设置模型名称
  Future<void> setModelName(String name) async {
    await _prefs.setString(_keyModelName, name);
  }

  /// 是否使用默认后端
  bool isUseDefaultBackend() {
    return _prefs.getBool(_keyUseDefaultBackend) ?? _defaultUseDefaultBackend;
  }

  /// 设置是否使用默认后端
  Future<void> setUseDefaultBackend(bool value) async {
    await _prefs.setBool(_keyUseDefaultBackend, value);
  }

  // ==================== 分享设置 ====================

  /// 是否静默模式
  bool isSilentMode() {
    return _prefs.getBool(_keySilentMode) ?? _defaultSilentMode;
  }

  /// 设置静默模式
  Future<void> setSilentMode(bool value) async {
    await _prefs.setBool(_keySilentMode, value);
  }

  // ==================== 提醒设置 ====================

  /// 获取默认提醒时间（分钟）
  int getDefaultReminderMinutes() {
    return _prefs.getInt(_keyDefaultReminderMinutes) ?? _defaultReminderMinutes;
  }

  /// 设置默认提醒时间
  Future<void> setDefaultReminderMinutes(int minutes) async {
    await _prefs.setInt(_keyDefaultReminderMinutes, minutes);
  }

  // ==================== 工具方法 ====================

  /// 检查AI配置是否完整
  bool isAIConfigured() {
    final apiKey = getApiKey();
    return apiKey.isNotEmpty;
  }

  /// 清除所有设置
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}