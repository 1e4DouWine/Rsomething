import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/adaptive_layout.dart';

/// 添加待办底部弹窗
///
/// 提供手动添加待办事项的表单，包括：
/// - 待办标题输入
/// - 可选的截止日期/时间选择
/// - 提交后自动创建关联的 Memory 记录和 Todo 记录
class AddTodoSheet extends StatefulWidget {
  const AddTodoSheet({super.key});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  /// 待办标题输入控制器
  final TextEditingController _titleController = TextEditingController();

  /// 选中的截止日期（可选）
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedDate = _selectedDate;
    final horizontalPadding = AdaptiveLayout.horizontalPaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AdaptiveSheetFrame(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: horizontalPadding,
          right: horizontalPadding,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部拖拽指示条
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 标题区
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '添加待办',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 待办标题输入框
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '输入待办事项...',
                  prefixIcon: Icon(
                    Icons.edit_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              // 截止日期选择器
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today_rounded,
                    color: selectedDate != null
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    selectedDate != null
                        ? DateFormat('yyyy年MM月dd日 HH:mm').format(selectedDate)
                        : '设置截止时间（可选）',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectedDate != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: selectedDate != null
                      ? IconButton(
                          tooltip: '清除提醒时间',
                          icon: Icon(
                            Icons.clear_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() => _selectedDate = null);
                          },
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () => _pickDateTime(context),
                ),
              ),
              const SizedBox(height: 24),
              // 添加按钮
              ElevatedButton(
                onPressed: _addTodo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                ),
                child: Text(
                  '添加待办',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 弹出日期和时间选择器
  /// 先选择日期，再选择时间
  Future<void> _pickDateTime(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 选择日期
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: colorScheme.copyWith(primary: colorScheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      if (!context.mounted) return;
      // 选择时间
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: theme.copyWith(
              colorScheme: colorScheme.copyWith(primary: colorScheme.primary),
            ),
            child: child!,
          );
        },
      );
      if (time != null) {
        if (!mounted) return;
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  /// 提交添加待办
  /// 1. 验证标题不为空
  /// 2. 创建 Memory 记录（类型为 todo）
  /// 3. 创建 Todo 记录并关联 Memory
  /// 4. 关闭弹窗
  Future<void> _addTodo() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请输入待办内容'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final selectedDate = _selectedDate;

    // 创建关联的 Memory 记录
    final memory = Memory(
      type: MemoryType.todo,
      rawContentType: RawContentType.text,
      rawContentSummary: title,
      structuredData: {
        'title': title,
        if (selectedDate != null) 'due_date': selectedDate.toIso8601String(),
        'reminder': true,
      },
      status: MemoryStatus.confirmed,
    );

    final todo = Todo(memoryId: 0, title: title, dueDate: selectedDate);

    final memoryProvider = context.read<MemoryProvider>();
    final todoProvider = context.read<TodoProvider>();
    final todoId = await todoProvider.addTodoWithMemory(memory, todo);
    await memoryProvider.loadMemories(type: memoryProvider.filterType);
    await _scheduleTodoReminder(todo.copyWith(id: todoId));

    if (!mounted) return;
    Navigator.pop(context);
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
      // 提醒调度失败不应阻塞待办保存。
    }
  }
}
