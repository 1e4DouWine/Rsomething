import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'permission_service.dart';

/// 本地通知服务
///
/// 负责初始化通知插件、配置本地时区，以及调度待办提醒。
class NotificationService {
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  static const String _reminderChannelId = 'rs_reminders';
  static const String _processingChannelId = 'rs_processing';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      linux: LinuxInitializationSettings(defaultActionName: '打开'),
      windows: WindowsInitializationSettings(
        appName: 'RS 智能助手',
        appUserModelId: 'RememberSomething.RS.App',
        guid: 'd9c8e5e0-3454-4cf4-bc1f-2a8d7f5a1f77',
      ),
    );

    await _notifications.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<void> showProcessingComplete({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    if (!await PermissionService.instance.ensureNotificationPermission()) {
      return;
    }

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _processingDetails,
    );
  }

  Future<void> scheduleTodoReminder({
    required int todoId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    if (!scheduledAt.isAfter(DateTime.now())) return;

    await _ensureInitialized();
    if (!await PermissionService.instance.ensureNotificationPermission()) {
      return;
    }

    await _notifications.zonedSchedule(
      id: _todoNotificationId(todoId),
      title: '待办提醒',
      body: title,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'todo:$todoId',
    );
  }

  Future<void> cancelTodoReminder(int todoId) async {
    await _ensureInitialized();
    await _notifications.cancel(id: _todoNotificationId(todoId));
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  int _todoNotificationId(int todoId) => 100000 + todoId;

  static const NotificationDetails _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _reminderChannelId,
      '待办提醒',
      channelDescription: '待办事项到期前提醒',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(defaultActionName: '打开'),
    windows: WindowsNotificationDetails(
      scenario: WindowsNotificationScenario.reminder,
    ),
  );

  static const NotificationDetails _processingDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _processingChannelId,
      '内容处理',
      channelDescription: '分享内容分析完成通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(defaultActionName: '打开'),
    windows: WindowsNotificationDetails(),
  );
}
