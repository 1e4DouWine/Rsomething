import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'permission_service.dart';

/// Android 分享处理状态桥接服务。
///
/// Android 16+ 会映射到系统 Live Updates 使用的高优先级持续通知能力。
/// 其他平台不执行平台通道调用，直接返回 false 或空操作，保证跨平台编译安全。
class AndroidShareStatusService {
  static final AndroidShareStatusService instance =
      AndroidShareStatusService._();

  AndroidShareStatusService._();

  static const MethodChannel _channel = MethodChannel(
    'rs_android/share_status',
  );

  /// 当前平台是否可调用 Android 专属平台通道。
  ///
  /// 避免直接依赖 `dart:io Platform`，否则 Web 构建阶段会因 `dart:io` 不可用而失败。
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 检查当前 Android 设备是否支持分享处理状态面板。
  Future<bool> supportsLiveUpdate() async {
    if (!_isAndroid) return false;

    try {
      return await _channel.invokeMethod<bool>('supportsLiveUpdate') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// 展示“正在分析”的平台状态。
  Future<bool> showAnalyzing({required int id}) async {
    if (!_isAndroid) return false;
    if (!await supportsLiveUpdate()) return false;
    if (!await PermissionService.instance.ensureNotificationPermission()) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('showAnalyzing', {'id': id}) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// 展示“分析完成”的平台状态。
  Future<bool> showComplete({
    required int id,
    required String memoryTypeLabel,
  }) async {
    if (!_isAndroid) return false;

    try {
      return await _channel.invokeMethod<bool>('showComplete', {
            'id': id,
            'memoryType': memoryTypeLabel,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// 展示“分析失败”的平台状态。
  Future<bool> showFailed({required int id, required String message}) async {
    if (!_isAndroid) return false;

    try {
      return await _channel.invokeMethod<bool>('showFailed', {
            'id': id,
            'message': message,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// 取消指定的分享处理状态。
  Future<void> cancel({required int id}) async {
    if (!_isAndroid) return;

    try {
      await _channel.invokeMethod<void>('cancel', {'id': id});
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
