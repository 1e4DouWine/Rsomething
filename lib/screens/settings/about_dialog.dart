import 'package:flutter/material.dart';

/// 关于对话框
///
/// 展示应用的基本信息，包括：
/// - 应用 Logo
/// - 应用名称"RS 智能助手"
/// - 版本号
/// - 应用简介
/// - 版权信息
class RSAboutDialog extends StatelessWidget {
  const RSAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 应用 Logo（渐变背景 + 图标）
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 40,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // 应用名称
            Text(
              'RS 智能助手',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // 版本号
            Text(
              'v1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // 应用简介
            Text(
              'RS 是一款智能个人知识助手，深度融入系统分享机制，让碎片信息被高效整理和记忆。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            // 版权信息
            Text(
              '© 2026 RS Team',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // 关闭按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 静态方法：显示关于对话框
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RSAboutDialog(),
    );
  }
}
