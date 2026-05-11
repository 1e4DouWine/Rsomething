import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_handler/share_handler.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'app.dart';

/// 应用入口函数
///
/// 执行以下初始化操作：
/// 1. 确保 Flutter 绑定初始化
/// 2. 设置系统状态栏样式（透明背景、深色图标）
/// 3. 初始化设置服务（SharedPreferences）
/// 4. 获取通过系统分享传入的初始媒体内容
/// 5. 启动应用
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式：透明背景、深色图标
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // 初始化设置服务单例
  final settingsService = await SettingsService.getInstance();
  await NotificationService.instance.initialize();

  // 获取通过系统分享启动应用时的初始媒体内容
  SharedMedia? initialMedia;
  try {
    initialMedia = await ShareHandlerPlatform.instance.getInitialSharedMedia();
  } catch (_) {
    initialMedia = null;
  }

  // 启动应用
  runApp(
    MyApp(settingsService: settingsService, initialSharedMedia: initialMedia),
  );
}
