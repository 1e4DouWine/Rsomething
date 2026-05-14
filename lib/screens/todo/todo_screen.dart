import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/adaptive_layout.dart';
import 'add_todo_sheet.dart';
import 'todo_detail_dialog.dart';

/// 待办事项页面
///
/// 展示和管理待办事项列表，功能包括：
/// - 显示待办统计信息
/// - 添加新待办事项
/// - 切换待办完成状态
/// - 滑动删除待办
/// - 查看待办详情
/// - 显示/隐藏已完成的待办
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// FAB 弹出动画控制器
  late AnimationController _fabAnimationController;

  /// FAB 缩放动画
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初始化 FAB 弹出动画
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
    _fabAnimationController.forward();

    // 页面加载后自动获取待办列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadTodos();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reloadTodos();
    }
  }

  Future<void> _reloadTodos() {
    return context.read<TodoProvider>().loadTodos();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Consumer<TodoProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, provider),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      if (provider.todos.isNotEmpty)
                        provider.showCompleted
                            ? _buildProgressStats(theme, provider)
                            : _buildRemainingStats(theme, provider),
                      _buildTodoList(theme, provider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // 浮动按钮：新增待办
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          heroTag: 'todoFab',
          onPressed: () => _showAddTodoSheet(context),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            '新待办',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建页面头部
  /// 包含标题"待办"、待完成数量统计和显示/隐藏已完成按钮
  Widget _buildHeader(ThemeData theme, TodoProvider provider) {
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AdaptiveContent(
          padding: AdaptiveLayout.pageInsetsForWidth(
            constraints.maxWidth,
            top: 16,
            bottom: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '待办',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.todos.where((t) => !t.isCompleted).length} 项待完成',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 显示/隐藏已完成按钮
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    provider.showCompleted
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: provider.showCompleted
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  tooltip: provider.showCompleted ? '隐藏已完成' : '显示已完成',
                  onPressed: () => provider.toggleShowCompleted(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建完成进度统计卡片
  /// 使用环形进度指示器展示已完成/总数的百分比
  Widget _buildProgressStats(ThemeData theme, TodoProvider provider) {
    final total = provider.todos.length;
    final completed = provider.todos.where((t) => t.isCompleted).length;
    final progress = total > 0 ? completed / total : 0.0;
    final colorScheme = theme.colorScheme;

    return AdaptiveSliverBox(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // 环形进度指示器
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: colorScheme.onPrimary.withValues(
                          alpha: 0.2,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // 完成数量文字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '完成进度',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$completed / $total',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '已完成 / 总计',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建剩余待办统计卡片
  /// 隐藏已完成时列表只包含未完成待办，此时展示剩余数量更符合当前筛选口径。
  Widget _buildRemainingStats(ThemeData theme, TodoProvider provider) {
    final remaining = provider.todos.where((t) => !t.isCompleted).length;
    final colorScheme = theme.colorScheme;

    return AdaptiveSliverBox(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.pending_actions_rounded,
                  size: 32,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '剩余待办',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$remaining 项',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '隐藏已完成',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建待办列表
  /// 空列表时显示引导页面，否则显示待办卡片列表
  Widget _buildTodoList(ThemeData theme, TodoProvider provider) {
    if (provider.todos.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(theme),
      );
    }

    return AdaptiveSliverList(
      itemCount: provider.todos.length,
      itemSpacing: 0,
      itemBuilder: (context, index) {
        final todo = provider.todos[index];
        return _buildTodoItem(theme, todo, provider);
      },
    );
  }

  /// 构建空状态 UI
  /// 当没有待办事项时显示引导用户添加
  Widget _buildEmptyState(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 420;
    final horizontal = AdaptiveLayout.horizontalPaddingForWidth(screenWidth);
    final vertical = isCompact ? 24.0 : 48.0;
    final padding = EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
    final iconExtent = isCompact ? 96.0 : 120.0;
    final iconSize = isCompact ? 48.0 : 56.0;
    final largeGap = isCompact ? 20.0 : 32.0;
    final smallGap = isCompact ? 8.0 : 12.0;

    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconExtent,
              height: iconExtent,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: iconSize,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: largeGap),
            Text(
              '暂无待办事项',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: smallGap),
            Text(
              '点击下方按钮添加待办\n或分享取件码到 RS',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            SizedBox(height: largeGap),
            ElevatedButton.icon(
              onPressed: () => _showAddTodoSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加待办'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个待办项
  /// 支持滑动删除、点击查看详情、点击复选框切换完成状态
  Widget _buildTodoItem(ThemeData theme, Todo todo, TodoProvider provider) {
    final colorScheme = theme.colorScheme;
    final dueDate = todo.dueDate;
    final isOverdue =
        dueDate != null &&
        dueDate.isBefore(DateTime.now()) &&
        !todo.isCompleted;

    return Dismissible(
      key: Key('todo_${todo.id}'),
      direction: DismissDirection.endToStart,
      // 滑动删除背景
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_rounded, color: colorScheme.onError, size: 24),
      ),
      // 删除前弹出确认对话框
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('确认删除'),
            content: Text('确定要删除"${todo.title}"吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '取消',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        final todoId = todo.id;
        if (todoId == null) return;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final memoryProvider = context.read<MemoryProvider>();
          await provider.deleteTodo(todoId);
          await memoryProvider.loadMemories(type: memoryProvider.filterType);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showTodoDetail(context, todo),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // 自定义复选框（点击切换完成状态）
                  GestureDetector(
                    onTap: () {
                      final todoId = todo.id;
                      if (todoId == null) return;
                      provider.toggleCompletion(todoId, !todo.isCompleted);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: todo.isCompleted
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: todo.isCompleted
                              ? colorScheme.primary
                              : isOverdue
                              ? colorScheme.error
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: todo.isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 待办标题和截止时间
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: todo.isCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (dueDate != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: isOverdue
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                              ),
                              Text(
                                DateFormat('MM月dd日 HH:mm').format(dueDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isOverdue
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              // 过期标签
                              if (isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '已过期',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
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

  /// 显示添加待办底部弹窗
  void _showAddTodoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTodoSheet(),
    );
  }

  /// 显示待办详情对话框
  void _showTodoDetail(BuildContext context, Todo todo) {
    showDialog(
      context: context,
      builder: (context) => TodoDetailDialog(todo: todo),
    );
  }
}
