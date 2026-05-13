import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import 'permission_service.dart';

/// Android-only bridge for share-processing status surfaces.
///
/// On Android 16+ this maps to the platform promoted ongoing notification
/// surface used by Live Updates. Other platforms simply return false/no-op.
class AndroidShareStatusService {
  static final AndroidShareStatusService instance =
      AndroidShareStatusService._();

  AndroidShareStatusService._();

  static const MethodChannel _channel = MethodChannel(
    'rs_android/share_status',
  );

  Future<bool> supportsLiveUpdate() async {
    if (!Platform.isAndroid) return false;

    try {
      return await _channel.invokeMethod<bool>('supportsLiveUpdate') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> showAnalyzing({required int id}) async {
    if (!Platform.isAndroid) return false;
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

  Future<bool> showComplete({
    required int id,
    required String memoryTypeLabel,
  }) async {
    if (!Platform.isAndroid) return false;

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

  Future<bool> showFailed({required int id, required String message}) async {
    if (!Platform.isAndroid) return false;

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

  Future<void> cancel({required int id}) async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod<void>('cancel', {'id': id});
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
