import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/type_helpers.dart';

/// 记忆卡片组件
///
/// 展示单条记忆信息的卡片组件，包含：
/// - 左侧彩色类型指示条
/// - 头部：类型图标 + 类型标签 + 时间 + 状态标签
/// - 内容区：原始内容摘要
/// - AI 识别结果预览（结构化数据）
/// - 操作按钮（确认/忽略，仅待处理状态显示）
///
/// 支持点击缩放动画效果。
class MemoryCard extends StatefulWidget {
  /// 记忆数据
  final Memory memory;

  /// 卡片点击回调
  final VoidCallback? onTap;

  /// 确认按钮回调
  final VoidCallback? onConfirm;

  /// 忽略按钮回调
  final VoidCallback? onDismiss;

  /// 删除按钮回调
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
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  /// 缩放动画控制器
  late AnimationController _animationController;

  /// 缩放动画（按下时缩小到 0.98，松开恢复）
  late Animation<double> _scaleAnimation;

  /// 是否处于按下状态
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = AppTheme.getMemoryTypeColor(widget.memory.type.value);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _animationController.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: typeColor.withValues(alpha: _isPressed ? 0.2 : 0.08),
                blurRadius: _isPressed ? 16 : 12,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 左侧类型颜色指示条（渐变效果）
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          typeColor,
                          typeColor.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // 右侧内容区域
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 头部：图标 + 类型 + 时间 + 状态 + 删除
                          _buildHeader(theme, typeColor),
                          const SizedBox(height: 16),
                          // 原始内容摘要
                          _buildContent(theme),
                          // AI 识别结果预览（仅在有结构化数据时显示）
                          if (widget.memory.structuredData.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildStructuredPreview(theme, typeColor),
                          ],
                          // 操作按钮（仅待处理状态显示）
                          if (widget.memory.status == MemoryStatus.pending) ...[
                            const SizedBox(height: 20),
                            _buildActions(theme, typeColor),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建卡片头部
  /// 包含类型图标、类型标签、创建时间、状态标签和删除按钮
  Widget _buildHeader(ThemeData theme, Color typeColor) {
    return Row(
      children: [
        // 类型图标容器
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            getTypeIcon(widget.memory.type),
            color: typeColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        // 类型名称和时间
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.memory.type.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MM月dd日 HH:mm').format(widget.memory.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // 状态标签
        _buildStatusChip(theme),
        // 删除按钮
        if (widget.onDelete != null)
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.error.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建状态标签
  /// 栅记忆状态显示不同的颜色和文字（待处理/已确认/已忽略）
  Widget _buildStatusChip(ThemeData theme) {
    Color color;
    String text;
    IconData icon;

    switch (widget.memory.status) {
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
        color = theme.colorScheme.onSurfaceVariant;
        text = '已忽略';
        icon = Icons.close_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'NotoSansSC',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容展示区
  /// 显示原始内容摘要，最多 3 行，超出部分省略
  Widget _buildContent(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 内容类型图标（文本/图片）
          Icon(
            widget.memory.rawContentType == RawContentType.image
                ? Icons.image_rounded
                : Icons.text_snippet_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.memory.rawContentSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 AI 识别结果预览
  /// 展示结构化数据的前 3 个字段，以键值对形式排列
  Widget _buildStructuredPreview(ThemeData theme, Color typeColor) {
    final data = widget.memory.structuredData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: typeColor,
              ),
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
          // 数据字段列表（最多显示 3 个）
          ...data.entries.take(3).map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.value}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// 构建操作按钮区
  /// 包含"忽略"和"确认"两个按钮，仅在待处理状态显示
  Widget _buildActions(ThemeData theme, Color typeColor) {
    return Row(
      children: [
        // 忽略按钮（描边样式）
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('忽略'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // 确认按钮（填充样式，使用类型颜色）
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onConfirm,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('确认'),
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: typeColor.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}
