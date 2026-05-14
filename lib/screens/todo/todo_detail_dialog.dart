import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';

/// 待办详情对话框
///
/// 以弹窗形式展示待办事项的完整信息，包括：
/// - 完成状态图标和标签
/// - 截止时间
/// - 待办标题
/// - 提醒状态
class TodoDetailDialog extends StatelessWidget {
  /// 待展示的待办数据
  final Todo todo;

  const TodoDetailDialog({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dueDate = todo.dueDate;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：状态图标 + 状态标签 + 时间 + 关闭按钮
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    todo.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.isCompleted ? '已完成' : '待完成',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (dueDate != null)
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(dueDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 待办标题
            Text(
              todo.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            // 截止时间详情行
            if (dueDate != null) ...[
              _buildDetailRow(
                context,
                Icons.access_time_rounded,
                '截止时间',
                DateFormat('yyyy年MM月dd日 HH:mm').format(dueDate),
              ),
              const SizedBox(height: 12),
            ],
            // 状态详情行
            _buildDetailRow(
              context,
              todo.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              '状态',
              todo.isCompleted ? '已完成' : '未完成',
            ),
            const SizedBox(height: 12),
            // 提醒状态详情行
            _buildDetailRow(
              context,
              todo.reminder
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              '提醒',
              todo.reminder ? '已开启' : '未开启',
            ),
            const SizedBox(height: 28),
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

  /// 构建详情行（图标 + 标签 + 值）
  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
