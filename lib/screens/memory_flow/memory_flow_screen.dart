import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/memory_card.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import '../../utils/type_helpers.dart';
import 'add_content_sheet.dart';
import 'memory_detail_dialog.dart';

/// 记忆流页面
///
/// 应用的核心页面，展示所有通过 AI 分析创建的记忆记录。
/// 功能包括：
/// - 按类型筛选记忆（全部/账单/待办/日程/摘要）
/// - 搜索记忆
/// - 新增记忆（手动输入内容由 AI 分析）
/// - 查看记忆详情
/// - 确认/忽略/删除记忆
class MemoryFlowScreen extends StatefulWidget {
  const MemoryFlowScreen({super.key});

  @override
  State<MemoryFlowScreen> createState() => _MemoryFlowScreenState();
}

class _MemoryFlowScreenState extends State<MemoryFlowScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// 当前选中的筛选类型（null 表示全部）
  MemoryType? _selectedType;

  /// 搜索输入控制器
  final TextEditingController _searchController = TextEditingController();

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

    // 页面加载后自动获取记忆列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadMemories();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reloadMemories();
    }
  }

  Future<void> _reloadMemories() {
    final query = _searchController.text.trim();
    final memoryProvider = context.read<MemoryProvider>();
    if (query.isEmpty) {
      return memoryProvider.loadMemories(type: _selectedType);
    }
    return memoryProvider.searchMemories(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            _buildFilterChips(theme),
            Expanded(child: _buildMemoryList(theme)),
          ],
        ),
      ),
      // 浮动按钮：新增记忆
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          heroTag: 'memoryFlowFab',
          onPressed: _showAddDialog,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 4,
          icon: const Icon(Icons.auto_awesome, size: 20),
          label: Text(
            '新记忆',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建页面头部
  /// 包含标题"记忆流"、副标题和搜索按钮
  Widget _buildHeader(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '记忆流',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '让碎片信息变得有序',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // 搜索按钮
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
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: _showSearchDialog,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建类型筛选标签栏
  /// 水平滚动的 FilterChip 列表，支持按记忆类型筛选
  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _buildChip(theme, '全部', null),
          const SizedBox(width: 10),
          _buildChip(theme, '账单', MemoryType.bill),
          const SizedBox(width: 10),
          _buildChip(theme, '待办', MemoryType.todo),
          const SizedBox(width: 10),
          _buildChip(theme, '日程', MemoryType.event),
          const SizedBox(width: 10),
          _buildChip(theme, '摘要', MemoryType.summary),
        ],
      ),
    );
  }

  /// 构建单个筛选标签
  /// [label] 显示文字，[type] 对应的 MemoryType（null 表示全部）
  Widget _buildChip(ThemeData theme, String label, MemoryType? type) {
    final isSelected = _selectedType == type;
    final colorScheme = theme.colorScheme;
    final color = type != null
        ? AppTheme.getMemoryTypeColor(type.value)
        : colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedType = selected ? type : null);
          context.read<MemoryProvider>().setFilterType(selected ? type : null);
        },
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: color,
        checkmarkColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? color : colorScheme.outline,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: isSelected ? 2 : 0,
        shadowColor: isSelected
            ? color.withValues(alpha: 0.3)
            : Colors.transparent,
      ),
    );
  }

  /// 构建记忆列表
  /// 根据加载状态显示加载指示器、空状态提示或记忆卡片列表
  Widget _buildMemoryList(ThemeData theme) {
    return Consumer<MemoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingState(theme);
        }

        if (provider.memories.isEmpty) {
          return _buildEmptyState(theme);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          itemCount: provider.memories.length,
          itemBuilder: (context, index) {
            final memory = provider.memories[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MemoryCard(
                memory: memory,
                onTap: () => _showMemoryDetail(memory),
                onConfirm: () => _confirmMemory(memory),
                onDismiss: () => _dismissMemory(memory),
                onDelete: () => _deleteMemory(memory),
              ),
            );
          },
        );
      },
    );
  }

  /// 构建加载状态 UI
  Widget _buildLoadingState(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('加载中...', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// 构建空状态 UI
  /// 当没有记忆记录时显示引导用户添加第一条记忆
  Widget _buildEmptyState(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  size: 56,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '还没有记忆',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '点击下方按钮或分享内容到 RS\n开始你的智能记忆之旅',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('添加第一条记忆'),
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
      ),
    );
  }

  /// 显示搜索对话框
  void _showSearchDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.search_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('搜索记忆'),
          ],
        ),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '输入关键词...',
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MemoryProvider>().searchMemories(
                _searchController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  /// 显示新增记忆底部弹窗
  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddContentSheet(),
    );
  }

  /// 显示记忆详情对话框
  void _showMemoryDetail(Memory memory) {
    showDialog(
      context: context,
      builder: (context) => MemoryDetailDialog(memory: memory),
    );
  }

  /// 确认记忆
  /// 将记忆状态更新为已确认，并根据类型保存到对应模块
  Future<void> _confirmMemory(Memory memory) async {
    final memoryId = memory.id;
    if (memoryId == null) return;

    final memoryProvider = context.read<MemoryProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final todoProvider = context.read<TodoProvider>();

    try {
      switch (memory.type) {
        case MemoryType.bill:
          await memoryProvider.confirmWithRelatedRecord(
            memoryId,
            expense: _buildExpense(memoryId, memory.structuredData),
          );
          await expenseProvider.loadExpenses();
          await expenseProvider.loadMonthlyStats(
            expenseProvider.selectedYear,
            expenseProvider.selectedMonth,
          );
          break;
        case MemoryType.todo:
          final todo = _buildTodo(memoryId, memory.structuredData);
          final todoId = await memoryProvider.confirmWithRelatedRecord(
            memoryId,
            todo: todo,
          );
          await todoProvider.loadTodos();
          if (todoId != null) {
            await _scheduleTodoReminder(todo.copyWith(id: todoId));
          }
          break;
        case MemoryType.event:
          await memoryProvider.confirmWithRelatedRecord(
            memoryId,
            calendarEvent: _buildCalendarEvent(memoryId, memory.structuredData),
          );
          break;
        default:
          await memoryProvider.confirmWithRelatedRecord(memoryId);
          break;
      }

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已确认并保存'),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// 忽略记忆
  Future<void> _dismissMemory(Memory memory) async {
    final memoryId = memory.id;
    if (memoryId == null) return;

    await context.read<MemoryProvider>().updateStatus(
      memoryId,
      MemoryStatus.dismissed,
    );
  }

  /// 删除记忆
  Future<void> _deleteMemory(Memory memory) async {
    final memoryId = memory.id;
    if (memoryId == null) return;

    final memoryProvider = context.read<MemoryProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final todoProvider = context.read<TodoProvider>();

    switch (memory.type) {
      case MemoryType.bill:
        await memoryProvider.deleteMemory(memoryId);
        await expenseProvider.loadExpenses();
        await expenseProvider.loadMonthlyStats(
          expenseProvider.selectedYear,
          expenseProvider.selectedMonth,
        );
        break;
      case MemoryType.todo:
        await todoProvider.cancelReminderForMemory(memoryId);
        await memoryProvider.deleteMemory(memoryId);
        await todoProvider.loadTodos();
        break;
      default:
        await memoryProvider.deleteMemory(memoryId);
        break;
    }
  }

  /// 从记忆结构化数据中构建消费记录。
  Expense _buildExpense(int memoryId, Map<String, dynamic> data) {
    return Expense(
      memoryId: memoryId,
      amount: readAmount(data['amount']),
      currency: data['currency']?.toString() ?? 'CNY',
      category: data['category']?.toString() ?? '其他',
      date: readDateTime(data['date']) ?? DateTime.now(),
      note: data['note']?.toString(),
    );
  }

  /// 从记忆结构化数据中构建待办事项。
  Todo _buildTodo(int memoryId, Map<String, dynamic> data) {
    final title = data['title']?.toString().trim();
    return Todo(
      memoryId: memoryId,
      title: title == null || title.isEmpty ? '未命名待办' : title,
      dueDate: readDateTime(data['due_date']),
      reminder: readBool(data['reminder']),
    );
  }

  /// 从记忆结构化数据中构建日程事件。
  CalendarEvent _buildCalendarEvent(int memoryId, Map<String, dynamic> data) {
    final title = data['title']?.toString().trim();
    final startTime = readDateTime(data['start_time']) ?? DateTime.now();

    return CalendarEvent(
      memoryId: memoryId,
      title: title == null || title.isEmpty ? '未命名日程' : title,
      startTime: startTime,
      endTime: readDateTime(data['end_time']),
      location: data['location']?.toString(),
      notes: data['notes']?.toString(),
    );
  }

  Future<void> _scheduleTodoReminder(Todo todo) async {
    final todoId = todo.id;
    final dueDate = todo.dueDate;
    if (!todo.reminder || dueDate == null || todoId == null) return;

    final settings = await SettingsService.getInstance();
    final reminderAt = dueDate.subtract(
      Duration(minutes: settings.getDefaultReminderMinutes()),
    );
    try {
      await NotificationService.instance.scheduleTodoReminder(
        todoId: todoId,
        title: todo.title,
        scheduledAt: reminderAt,
      );
    } catch (_) {
      // 提醒调度失败不应回滚已经保存的记忆内容。
    }
  }
}
