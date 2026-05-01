import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../providers/app_providers.dart';
import '../widgets/memory_card.dart';
import '../theme/app_theme.dart';

/// 记忆流页面
/// 设计特点: 大标题 + 卡片流 + 柔和阴影
class MemoryFlowScreen extends StatefulWidget {
  const MemoryFlowScreen({super.key});

  @override
  State<MemoryFlowScreen> createState() => _MemoryFlowScreenState();
}

class _MemoryFlowScreenState extends State<MemoryFlowScreen>
    with SingleTickerProviderStateMixin {
  MemoryType? _selectedType;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
    _fabAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemoryProvider>().loadMemories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0E1B) : AppTheme.backgroundColor,
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
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.auto_awesome, size: 20),
          label: const Text(
            '新记忆',
            style: TextStyle(
              fontFamily: 'NotoSansSC',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '让碎片信息变得有序',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          _buildSearchButton(theme),
        ],
      ),
    );
  }

  Widget _buildSearchButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.search_rounded,
          color: AppTheme.textSecondary,
        ),
        onPressed: _showSearchDialog,
      ),
    );
  }

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

  Widget _buildChip(ThemeData theme, String label, MemoryType? type) {
    final isSelected = _selectedType == type;
    final color = type != null
        ? AppTheme.getMemoryTypeColor(type.value)
        : AppTheme.primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansSC',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedType = selected ? type : null);
          context.read<MemoryProvider>().setFilterType(
            selected ? type : null,
          );
        },
        backgroundColor: theme.colorScheme.surface,
        selectedColor: color,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? color : AppTheme.dividerColor,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: isSelected ? 2 : 0,
        shadowColor: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
      ),
    );
  }

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

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 56,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '还没有记忆',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '点击下方按钮或分享内容到 RS\n开始你的智能记忆之旅',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加第一条记忆'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(Icons.search_rounded, color: AppTheme.accentColor),
            const SizedBox(width: 12),
            const Text('搜索记忆'),
          ],
        ),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '输入关键词...',
            prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: AppTheme.textSecondary),
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
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddContentSheet(),
    );
  }

  void _showMemoryDetail(Memory memory) {
    showDialog(
      context: context,
      builder: (context) => MemoryDetailDialog(memory: memory),
    );
  }

  Future<void> _confirmMemory(Memory memory) async {
    await context.read<MemoryProvider>().updateStatus(
      memory.id!,
      MemoryStatus.confirmed,
    );

    switch (memory.type) {
      case MemoryType.bill:
        await _saveExpense(memory);
        break;
      case MemoryType.todo:
        await _saveTodo(memory);
        break;
      case MemoryType.event:
        await _saveCalendarEvent(memory);
        break;
      default:
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已确认并保存'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _dismissMemory(Memory memory) async {
    await context.read<MemoryProvider>().updateStatus(
      memory.id!,
      MemoryStatus.dismissed,
    );
  }

  Future<void> _deleteMemory(Memory memory) async {
    await context.read<MemoryProvider>().deleteMemory(memory.id!);
  }

  Future<void> _saveExpense(Memory memory) async {
    final data = memory.structuredData;
    final expense = Expense(
      memoryId: memory.id!,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'CNY',
      category: data['category'] as String? ?? '其他',
      date: data['date'] != null
          ? DateTime.parse(data['date'] as String)
          : DateTime.now(),
      note: data['note'] as String?,
    );
    await context.read<ExpenseProvider>().addExpense(expense);
  }

  Future<void> _saveTodo(Memory memory) async {
    final data = memory.structuredData;
    final todo = Todo(
      memoryId: memory.id!,
      title: data['title'] as String? ?? '未命名待办',
      dueDate: data['due_date'] != null
          ? DateTime.parse(data['due_date'] as String)
          : null,
      reminder: data['reminder'] as bool? ?? true,
    );
    await context.read<TodoProvider>().addTodo(todo);
  }

  Future<void> _saveCalendarEvent(Memory memory) async {
    // TODO: 保存到系统日历
  }
}

/// 添加内容底部表单
/// 设计特点: 圆角顶部 + 渐变背景 + 动画按钮
class AddContentSheet extends StatefulWidget {
  const AddContentSheet({super.key});

  @override
  State<AddContentSheet> createState() => _AddContentSheetState();
}

class _AddContentSheetState extends State<AddContentSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool _isAnalyzing = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 拖拽指示器
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '添加新记忆',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI 将自动识别内容类型',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 输入框
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.dividerColor,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _textController,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                hintText: '输入或粘贴内容...\n例如：今天午饭花了35元',
                hintStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  height: 1.5,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          
          // 分析按钮
          ScaleTransition(
            scale: _buttonScaleAnimation,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.accentColor.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: _isAnalyzing ? 0 : 4,
                shadowColor: AppTheme.accentColor.withValues(alpha: 0.4),
              ),
              child: _isAnalyzing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('AI 分析中...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '智能分析',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _analyzeContent() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请输入内容'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    _buttonAnimationController.forward();

    try {
      final aiProvider = context.read<AIProvider>();
      final result = await aiProvider.analyzeText(text);

      if (result != null && mounted) {
        final memory = Memory(
          type: _getMemoryType(result.action),
          rawContentType: RawContentType.text,
          rawContentSummary:
              text.length > 50 ? '${text.substring(0, 50)}...' : text,
          structuredData: result.data,
        );

        await context.read<MemoryProvider>().addMemory(memory);

        if (!mounted) return;
        Navigator.pop(context);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已添加到记忆流'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分析失败: ${aiProvider.error ?? "未知错误"}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      _buttonAnimationController.reverse();
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  MemoryType _getMemoryType(String action) {
    switch (action) {
      case 'add_expense':
        return MemoryType.bill;
      case 'add_todo':
        return MemoryType.todo;
      case 'add_event':
        return MemoryType.event;
      case 'summarize_video':
        return MemoryType.summary;
      default:
        return MemoryType.unknown;
    }
  }
}

/// 记忆详情对话框
/// 设计特点: 模态卡片 + 类型色彩 + 结构化展示
class MemoryDetailDialog extends StatelessWidget {
  final Memory memory;

  const MemoryDetailDialog({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = AppTheme.getMemoryTypeColor(memory.type.value);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _getTypeIcon(memory.type),
                    color: typeColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.type.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm')
                            .format(memory.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            
            // 原始内容
            _buildSection(
              theme,
              '原始内容',
              Icons.text_snippet_outlined,
              memory.rawContentSummary,
            ),
            const SizedBox(height: 20),
            
            // 识别结果
            _buildStructuredDataSection(theme, typeColor),
            const SizedBox(height: 28),
            
            // 关闭按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  foregroundColor: Colors.white,
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

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    String content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStructuredDataSection(ThemeData theme, Color typeColor) {
    final data = memory.structuredData;
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.data_array, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              '识别结果',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: typeColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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