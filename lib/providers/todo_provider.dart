import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// 待办事项状态管理器
///
/// 管理待办事项列表的状态，包括加载、新增、完成状态切换、删除等操作。
/// 支持显示/隐藏已完成项目的切换。
class TodoProvider with ChangeNotifier {
  /// 数据库服务实例
  final DatabaseService _dbService = DatabaseService();

  /// 当前待办事项列表
  List<Todo> _todos = [];

  /// 是否显示已完成的待办项
  bool _showCompleted = false;

  /// 公开的状态访问器
  List<Todo> get todos => _todos;
  bool get showCompleted => _showCompleted;

  /// 加载待办事项列表
  /// 根据 [showCompleted] 状态决定是否包含已完成项目
  Future<void> loadTodos() async {
    if (_showCompleted) {
      _todos = await _dbService.getAllTodos();
    } else {
      _todos = await _dbService.getAllTodos(completed: false);
    }
    notifyListeners();
  }

  /// 添加新待办事项
  Future<int> addTodo(Todo todo) async {
    final id = await _dbService.insertTodo(todo);
    await loadTodos();
    return id;
  }

  /// 在同一事务中创建关联记忆和待办事项。
  Future<int> addTodoWithMemory(Memory memory, Todo todo) async {
    final todoId = await _dbService.insertMemoryWithTodo(memory, todo);
    await loadTodos();
    return todoId;
  }

  /// 切换待办事项的完成状态
  /// [id] 待办 ID，[isCompleted] 目标完成状态
  Future<void> toggleCompletion(int id, bool isCompleted) async {
    await _dbService.updateTodoCompletion(id, isCompleted);
    if (isCompleted) {
      await NotificationService.instance.cancelTodoReminder(id);
    }
    await loadTodos();
  }

  /// 删除待办事项
  Future<void> deleteTodo(int id) async {
    await _dbService.deleteTodo(id);
    await NotificationService.instance.cancelTodoReminder(id);
    await loadTodos();
  }

  /// 取消指定记忆关联待办的提醒。
  ///
  /// 删除记忆会通过外键级联删除待办记录，因此需要在删除记忆前调用。
  Future<void> cancelReminderForMemory(int memoryId) async {
    final todo = await _dbService.getTodoByMemoryId(memoryId);
    if (todo?.id == null) return;

    await NotificationService.instance.cancelTodoReminder(todo!.id!);
  }

  /// 切换是否显示已完成的待办项
  void toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    loadTodos();
  }

  /// 清空所有内存缓存数据
  void clearAll() {
    _todos = [];
    _showCompleted = false;
    notifyListeners();
  }
}
