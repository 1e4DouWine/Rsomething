import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../theme/app_theme.dart';

/// 记忆卡片组件
/// 设计特点: 类型色彩条 + 渐变背景 + 浮动操作按钮
class MemoryCard extends StatefulWidget {
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
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
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
                color: typeColor.withOpacity(_isPressed ? 0.2 : 0.08),
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
                  // 左侧类型色彩条
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          typeColor,
                          typeColor.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  
                  // 主要内容
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(theme, typeColor),
                          const SizedBox(height: 16),
                          _buildContent(theme),
                          if (widget.memory.structuredData.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildStructuredPreview(theme, typeColor),
                          ],
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

  Widget _buildHeader(ThemeData theme, Color typeColor) {
    return Row(
      children: [
        // 类型图标
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getTypeIcon(widget.memory.type),
            color: typeColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        
        // 类型和时间
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
                  color: AppTheme.textTertiary,
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
              color: AppTheme.errorColor.withOpacity(0.6),
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.errorColor.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

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
        color = AppTheme.textTertiary;
        text = '已忽略';
        icon = Icons.close_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
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

  Widget _buildContent(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            widget.memory.rawContentType == RawContentType.image
                ? Icons.image_rounded
                : Icons.text_snippet_rounded,
            size: 18,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.memory.rawContentSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredPreview(ThemeData theme, Color typeColor) {
    final data = widget.memory.structuredData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${entry.value}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
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

  Widget _buildActions(ThemeData theme, Color typeColor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('忽略'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: AppTheme.dividerColor,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
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
              shadowColor: typeColor.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(MemoryType type) {
    switch (type) {
      case MemoryType.bill:
        return Icons.receipt_long_rounded;
      case MemoryType.todo:
        return Icons.check_circle_outline_rounded;
      case MemoryType.event:
        return Icons.event_rounded;
      case MemoryType.summary:
        return Icons.summarize_rounded;
      case MemoryType.unknown:
        return Icons.help_outline_rounded;
    }
  }
}