import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_handler/share_handler.dart';
import 'services/settings_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  final settingsService = await SettingsService.getInstance();

  SharedMedia? initialMedia;
  try {
    initialMedia = await ShareHandlerPlatform.instance.getInitialSharedMedia();
  } catch (_) {
    initialMedia = null;
  }

  runApp(MyApp(
    settingsService: settingsService,
    initialSharedMedia: initialMedia,
  ));
}
