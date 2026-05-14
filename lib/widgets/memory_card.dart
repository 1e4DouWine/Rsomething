import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/type_helpers.dart';

/// 记忆卡片组件（Material 3）
///
/// 使用 M3 的 [Card] + [InkWell] 构建，包含：
/// - 左侧彩色类型指示条
/// - 头部：类型图标 + 类型标签 + 时间 + 状态 [Chip]
/// - 内容区：原始内容摘要
/// - AI 识别结果预览（结构化数据）
/// - 操作按钮（确认/忽略，仅待处理状态显示）
class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelete;

  const MemoryCard({
    super.key,
    required this.memory,
    this.onTap,
    this.onConfirm,
    this.onDismiss,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = AppTheme.getMemoryTypeColor(memory.type.value);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [typeColor, typeColor.withValues(alpha: 0.6)],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme, colorScheme, typeColor),
                    const SizedBox(height: 16),
                    _buildContent(theme, colorScheme),
                    if (memory.structuredData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildStructuredPreview(theme, colorScheme, typeColor),
                    ],
                    if (memory.status == MemoryStatus.pending) ...[
                      const SizedBox(height: 20),
                      _buildActions(theme, colorScheme, typeColor),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    Color typeColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(getTypeIcon(memory.type), color: typeColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memory.type.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MM月dd日 HH:mm').format(memory.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildStatusChip(theme, colorScheme),
        if (onDelete != null)
          IconButton(
            tooltip: '删除记忆',
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: colorScheme.error.withValues(alpha: 0.6),
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.error.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme, ColorScheme colorScheme) {
    Color color;
    String text;
    IconData icon;

    switch (memory.status) {
      case MemoryStatus.pending:
        color = AppTheme.warningColor;
        text = '待处理';
        icon = Icons.schedule_rounded;
        break;
      case MemoryStatus.confirmed:
        color = AppTheme.successColor;
        text = '已确认';
        icon = Icons.check_circle_rounded;
        break;
      case MemoryStatus.dismissed:
        color = colorScheme.onSurfaceVariant;
        text = '已忽略';
        icon = Icons.close_rounded;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(text),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            memory.rawContentType == RawContentType.image
                ? Icons.image_rounded
                : Icons.text_snippet_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              memory.rawContentSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredPreview(
    ThemeData theme,
    ColorScheme colorScheme,
    Color typeColor,
  ) {
    final data = memory.structuredData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: typeColor),
              const SizedBox(width: 8),
              Text(
                'AI 识别结果',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...data.entries
              .take(3)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${entry.value}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildActions(
    ThemeData theme,
    ColorScheme colorScheme,
    Color typeColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('忽略'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('确认'),
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor,
              foregroundColor: typeColor.computeLuminance() < 0.5
                  ? Colors.white
                  : colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
