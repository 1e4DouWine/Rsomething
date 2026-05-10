import 'package:shared_preferences/shared_preferences.dart';

/// 设置服务
///
/// 基于 SharedPreferences 的本地持久化设置服务。
/// 使用单例模式，管理应用的所有配置项，包括：
/// - AI 模型配置（API 地址、密钥、模型名称）
/// - 分享行为设置（静默模式）
/// - 提醒设置（默认提醒时间）
class SettingsService {
  /// 单例实例
  static SettingsService? _instance;

  /// SharedPreferences 实例
  late SharedPreferences _prefs;

  // ==================== 配置键名常量 ====================
  static const String _keyBaseUrl = 'ai_base_url';
  static const String _keyApiKey = 'ai_api_key';
  static const String _keyModelName = 'ai_model_name';
  static const String _keyUseDefaultBackend = 'use_default_backend';
  static const String _keySilentMode = 'silent_mode';
  static const String _keyDefaultReminderMinutes = 'default_reminder_minutes';

  // ==================== 默认值常量 ====================
  static const String _defaultBaseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _defaultApiKey = '';
  static const String _defaultModelName = 'minimax/minimax-m2.5:free';
  static const bool _defaultUseDefaultBackend = false;
  static const bool _defaultSilentMode = false;
  static const int _defaultReminderMinutes = 60;

  /// 私有构造函数（单例模式）
  SettingsService._();

  /// 获取设置服务单例实例
  /// 首次调用时会初始化 SharedPreferences
  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ==================== AI配置 ====================

  /// 获取 API Base URL
  String getBaseUrl() {
    return _prefs.getString(_keyBaseUrl) ?? _defaultBaseUrl;
  }

  /// 设置 API Base URL
  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_keyBaseUrl, url);
  }

  /// 获取 API Key
  String getApiKey() {
    return _prefs.getString(_keyApiKey) ?? _defaultApiKey;
  }

  /// 设置 API Key
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

  /// 是否静默模式（分享内容后直接后台处理，不打开应用界面）
  bool isSilentMode() {
    return _prefs.getBool(_keySilentMode) ?? _defaultSilentMode;
  }

  /// 设置静默模式
  Future<void> setSilentMode(bool value) async {
    await _prefs.setBool(_keySilentMode, value);
  }

  // ==================== 提醒设置 ====================

  /// 获取默认提醒时间（单位：分钟）
  int getDefaultReminderMinutes() {
    return _prefs.getInt(_keyDefaultReminderMinutes) ?? _defaultReminderMinutes;
  }

  /// 设置默认提醒时间（单位：分钟）
  Future<void> setDefaultReminderMinutes(int minutes) async {
    await _prefs.setInt(_keyDefaultReminderMinutes, minutes);
  }

  // ==================== 工具方法 ====================

  /// 检查 AI 配置是否完整（API Key 非空即视为已配置）
  bool isAIConfigured() {
    final apiKey = getApiKey();
    return apiKey.isNotEmpty;
  }

  /// 清除所有设置（恢复默认值）
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
