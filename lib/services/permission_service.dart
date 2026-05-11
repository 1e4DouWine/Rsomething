import 'package:permission_handler/permission_handler.dart';

/// 应用权限服务
///
/// 统一封装权限检查和申请，避免权限逻辑散落在页面层。
class PermissionService {
  static final PermissionService instance = PermissionService._();

  PermissionService._();

  /// 确保本地通知权限可用。
  ///
  /// 不支持通知权限的平台可能会抛出平台异常，此时不阻断业务流程。
  Future<bool> ensureNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted || status.isLimited) return true;

      final requested = await Permission.notification.request();
      return requested.isGranted || requested.isLimited;
    } catch (_) {
      return true;
    }
  }
}
