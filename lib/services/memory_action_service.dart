import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/type_helpers.dart';
import 'notification_service.dart';
import 'settings_service.dart';

/// Coordinates memory confirmation/deletion side effects across modules.
///
/// Screens provide the current providers, while this service owns the domain
/// workflow so the same rules are not duplicated across entry points.
class MemoryActionService {
  final MemoryProvider memoryProvider;
  final ExpenseProvider expenseProvider;
  final TodoProvider todoProvider;
  final NotificationService _notificationService;
  final Future<SettingsService> Function() _settingsFactory;

  MemoryActionService({
    required this.memoryProvider,
    required this.expenseProvider,
    required this.todoProvider,
    NotificationService? notificationService,
    Future<SettingsService> Function()? settingsFactory,
  }) : _notificationService =
           notificationService ?? NotificationService.instance,
       _settingsFactory = settingsFactory ?? SettingsService.getInstance;

  Future<void> confirm(Memory memory) async {
    final memoryId = memory.id;
    if (memoryId == null) return;

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
  }

  Future<void> dismiss(Memory memory) async {
    final memoryId = memory.id;
    if (memoryId == null) return;

    await memoryProvider.updateStatus(memoryId, MemoryStatus.dismissed);
  }

  Future<void> delete(Memory memory) async {
    final memoryId = memory.id;
    if (memoryId == null) return;

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

  Todo _buildTodo(int memoryId, Map<String, dynamic> data) {
    final title = data['title']?.toString().trim();
    return Todo(
      memoryId: memoryId,
      title: title == null || title.isEmpty ? '未命名待办' : title,
      dueDate: readDateTime(data['due_date']),
      reminder: readBool(data['reminder']),
    );
  }

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

    final settings = await _settingsFactory();
    final reminderAt = dueDate.subtract(
      Duration(minutes: settings.getDefaultReminderMinutes()),
    );
    try {
      await _notificationService.scheduleTodoReminder(
        todoId: todoId,
        title: todo.title,
        scheduledAt: reminderAt,
      );
    } catch (_) {
      // Reminder failures should not roll back already-saved memory content.
    }
  }
}
