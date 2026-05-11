import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_config_profile.dart';

/// 设置服务
///
/// 基于 SharedPreferences 的本地持久化设置服务。
/// 使用单例模式，管理应用的所有配置项，包括：
/// - AI 模型配置（支持多份配置档案，可切换激活）
/// - 分享行为设置（静默模式）
/// - 提醒设置（默认提醒时间）
class SettingsService {
  /// 单例实例
  static SettingsService? _instance;

  /// SharedPreferences 实例
  late SharedPreferences _prefs;

  /// 系统安全存储，用于保存 API Key 等敏感信息
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// API Key 内存缓存，让现有同步 getter 不需要扩散成异步调用
  final Map<String, String> _secureApiKeys = {};

  // ==================== 配置键名常量 ====================
  // 旧版单配置键名（保留用于向后兼容）
  static const String _keyBaseUrl = 'ai_base_url';
  static const String _keyApiKey = 'ai_api_key';
  static const String _keyModelName = 'ai_model_name';
  static const String _keyUseDefaultBackend = 'use_default_backend';
  static const String _keySilentMode = 'silent_mode';
  static const String _keyDefaultReminderMinutes = 'default_reminder_minutes';
  // 多配置相关键名
  static const String _keyAiProfiles = 'ai_config_profiles';
  static const String _keyActiveProfileId = 'ai_active_profile_id';
  static const String _secureApiKeyPrefix = 'ai_profile_api_key_';

  // ==================== 默认值常量 ====================
  static const String _defaultBaseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _defaultApiKey = '';
  static const String _defaultModelName = 'minimax/minimax-m2.5:free';
  static const bool _defaultUseDefaultBackend = false;
  static const bool _defaultSilentMode = false;
  static const int _defaultReminderMinutes = 60;

  /// 私有构造函数（单例模式）
  SettingsService._();

  /// 获取设置服务单例实例
  /// 首次调用时会初始化 SharedPreferences，并执行旧数据迁移
  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      _instance!._prefs = await SharedPreferences.getInstance();
      await _instance!._migrateToProfiles();
      await _instance!._migrateApiKeysToSecureStorage();
      await _instance!._loadSecureApiKeys();
    }
    return _instance!;
  }

  /// 将旧版单配置迁移到多配置格式
  /// 仅在首次使用多配置功能时执行，将已有的单配置转为"默认配置"档案
  Future<void> _migrateToProfiles() async {
    final profilesJson = _prefs.getString(_keyAiProfiles);
    // 已有多配置数据，无需迁移
    if (profilesJson != null && profilesJson.isNotEmpty) return;

    // 读取旧版单配置，创建为"默认配置"档案
    final existingApiKey = getApiKey();
    final profile = AiConfigProfile(
      id: 'default',
      name: '默认配置',
      baseUrl: getBaseUrl(),
      apiKey: existingApiKey,
      modelName: getModelName(),
    );
    await _prefs.setString(_keyAiProfiles, json.encode([profile.toJson()]));
    await _prefs.setString(_keyActiveProfileId, 'default');
  }

  /// 将旧版明文 API Key 迁移到系统安全存储，并从 SharedPreferences 中移除。
  Future<void> _migrateApiKeysToSecureStorage() async {
    final legacyApiKey = _prefs.getString(_keyApiKey) ?? '';
    final profiles = _readProfilesFromPrefs();
    if (profiles.isEmpty) return;

    final hasPlainTextProfileKey = profiles.any(
      (profile) => profile.apiKey.isNotEmpty,
    );
    if (legacyApiKey.isEmpty && !hasPlainTextProfileKey) return;

    final migratedProfiles = <AiConfigProfile>[];
    for (final profile in profiles) {
      final existingSecureKey = await _secureStorage.read(
        key: _secureApiKey(profile.id),
      );
      final shouldUseLegacyKey =
          profile.id == 'default' && legacyApiKey.isNotEmpty;
      final apiKey = profile.apiKey.isNotEmpty
          ? profile.apiKey
          : shouldUseLegacyKey &&
                (existingSecureKey == null || existingSecureKey.isEmpty)
          ? legacyApiKey
          : existingSecureKey ?? '';
      migratedProfiles.add(profile.copyWith(apiKey: apiKey));
    }

    await saveProfiles(migratedProfiles);
    await _prefs.remove(_keyApiKey);
  }

  /// 初始化时从系统安全存储加载所有配置档案的 API Key
  Future<void> _loadSecureApiKeys() async {
    _secureApiKeys.clear();
    for (final profile in _readProfilesFromPrefs()) {
      final apiKey = await _secureStorage.read(key: _secureApiKey(profile.id));
      if (apiKey != null && apiKey.isNotEmpty) {
        _secureApiKeys[profile.id] = apiKey;
      }
    }
  }

  String _secureApiKey(String profileId) => '$_secureApiKeyPrefix$profileId';

  Future<void> _writeSecureApiKey(String profileId, String apiKey) async {
    final key = _secureApiKey(profileId);
    if (apiKey.isEmpty) {
      await _secureStorage.delete(key: key);
      _secureApiKeys.remove(profileId);
      return;
    }

    await _secureStorage.write(key: key, value: apiKey);
    _secureApiKeys[profileId] = apiKey;
  }

  Future<void> _deleteSecureApiKey(String profileId) async {
    await _secureStorage.delete(key: _secureApiKey(profileId));
    _secureApiKeys.remove(profileId);
  }

  List<AiConfigProfile> _readProfilesFromPrefs() {
    final profilesJson = _prefs.getString(_keyAiProfiles);
    if (profilesJson == null || profilesJson.isEmpty) return [];

    final decoded = json.decode(profilesJson);
    if (decoded is! List) return [];

    final profiles = <AiConfigProfile>[];
    for (final item in decoded) {
      if (item is String) {
        profiles.add(AiConfigProfile.fromJson(item));
      } else if (item is Map) {
        profiles.add(AiConfigProfile.fromMap(Map<String, dynamic>.from(item)));
      }
    }
    return profiles;
  }

  // ==================== 多配置管理 ====================

  /// 获取所有 AI 配置档案列表
  List<AiConfigProfile> getProfiles() {
    return _readProfilesFromPrefs()
        .map(
          (profile) => profile.copyWith(
            apiKey: _secureApiKeys[profile.id] ?? profile.apiKey,
          ),
        )
        .toList();
  }

  /// 保存完整的配置档案列表（覆盖写入）
  Future<void> saveProfiles(List<AiConfigProfile> profiles) async {
    final oldIds = _readProfilesFromPrefs().map((p) => p.id).toSet();
    final newIds = profiles.map((p) => p.id).toSet();
    for (final removedId in oldIds.difference(newIds)) {
      await _deleteSecureApiKey(removedId);
    }

    final sanitizedProfiles = <AiConfigProfile>[];
    for (final profile in profiles) {
      await _writeSecureApiKey(profile.id, profile.apiKey);
      sanitizedProfiles.add(profile.copyWith(apiKey: ''));
    }

    await _prefs.setString(
      _keyAiProfiles,
      json.encode(sanitizedProfiles.map((p) => p.toJson()).toList()),
    );
  }

  /// 获取当前激活的配置档案 ID
  String? getActiveProfileId() {
    return _prefs.getString(_keyActiveProfileId);
  }

  /// 设置激活的配置档案
  Future<void> setActiveProfileId(String id) async {
    await _prefs.setString(_keyActiveProfileId, id);
  }

  /// 获取当前激活的配置档案
  /// 若无激活项则返回第一份，若列表为空返回 null
  AiConfigProfile? getActiveProfile() {
    final profiles = getProfiles();
    final activeId = getActiveProfileId();
    if (profiles.isEmpty) return null;
    if (activeId == null) return profiles.first;
    try {
      return profiles.firstWhere((p) => p.id == activeId);
    } catch (_) {
      return profiles.first;
    }
  }

  /// 添加一份新的配置档案
  Future<void> addProfile(AiConfigProfile profile) async {
    final profiles = getProfiles();
    profiles.add(profile);
    await saveProfiles(profiles);
  }

  /// 更新指定配置档案（按 ID 匹配）
  Future<void> updateProfile(AiConfigProfile profile) async {
    final profiles = getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      profiles[index] = profile;
      await saveProfiles(profiles);
    }
  }

  /// 删除指定配置档案
  /// 若删除的是当前激活项，则自动切换到列表中的第一份
  Future<void> deleteProfile(String id) async {
    final profiles = getProfiles();
    profiles.removeWhere((p) => p.id == id);
    await saveProfiles(profiles);
    if (getActiveProfileId() == id && profiles.isNotEmpty) {
      await setActiveProfileId(profiles.first.id);
    } else if (profiles.isEmpty) {
      await _prefs.remove(_keyActiveProfileId);
    }
  }

  // ==================== 旧版单配置（兼容） ====================
  // 优先从激活的配置档案中读取，若无则回退到旧版存储

  /// 获取 API Base URL
  String getBaseUrl() {
    final active = getActiveProfile();
    if (active != null) return active.baseUrl;
    return _prefs.getString(_keyBaseUrl) ?? _defaultBaseUrl;
  }

  /// 设置 API Base URL
  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_keyBaseUrl, url);
  }

  /// 获取 API Key
  String getApiKey() {
    final active = getActiveProfile();
    if (active != null) return active.apiKey;
    return _prefs.getString(_keyApiKey) ?? _defaultApiKey;
  }

  /// 设置 API Key
  Future<void> setApiKey(String key) async {
    final active = getActiveProfile();
    if (active != null) {
      await updateProfile(active.copyWith(apiKey: key));
      return;
    }

    await _prefs.setString(_keyApiKey, key);
  }

  /// 获取模型名称
  String getModelName() {
    final active = getActiveProfile();
    if (active != null) return active.modelName;
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
    for (final profile in _readProfilesFromPrefs()) {
      await _deleteSecureApiKey(profile.id);
    }
    await _prefs.clear();
    _secureApiKeys.clear();
  }
}
