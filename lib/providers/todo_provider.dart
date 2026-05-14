import 'dart:collection';

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
  final DatabaseService _dbService;

  final NotificationService _notificationService;

  TodoProvider({
    DatabaseService? databaseService,
    NotificationService? notificationService,
  }) : _dbService = databaseService ?? DatabaseService(),
       _notificationService =
           notificationService ?? NotificationService.instance;

  /// 当前待办事项列表（内部可变，外部只读）
  List<Todo> _todos = [];

  /// 是否显示已完成的待办项
  bool _showCompleted = false;

  /// 最近一次加载错误
  String? _error;

  /// 加载序号，用于忽略较早返回的异步请求结果
  int _loadGeneration = 0;

  /// 防止重入标记
  bool _loading = false;

  /// 公开的状态访问器。
  ///
  /// 返回只读视图，避免 UI 层直接修改 Provider 内部状态。
  List<Todo> get todos => UnmodifiableListView(_todos);
  bool get showCompleted => _showCompleted;
  String? get error => _error;

  /// 加载待办事项列表
  /// 根据 [showCompleted] 状态决定是否包含已完成项目
  Future<void> loadTodos() async {
    if (_loading) return;
    _loading = true;

    final generation = ++_loadGeneration;
    _error = null;

    try {
      final todos = _showCompleted
          ? await _dbService.getAllTodos()
          : await _dbService.getAllTodos(completed: false);
      if (generation != _loadGeneration) return;

      _todos = todos;
    } catch (e) {
      if (generation != _loadGeneration) return;
      _error = e.toString();
    } finally {
      _loading = false;
      if (generation == _loadGeneration) {
        notifyListeners();
      }
    }
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
      await _notificationService.cancelTodoReminder(id);
    }
    await loadTodos();
  }

  /// 删除待办事项
  Future<void> deleteTodo(int id) async {
    await _dbService.deleteTodoWithMemory(id);
    await _notificationService.cancelTodoReminder(id);
    await loadTodos();
  }

  /// 取消指定记忆关联待办的提醒。
  ///
  /// 删除记忆会通过外键级联删除待办记录，因此需要在删除记忆前调用。
  Future<void> cancelReminderForMemory(int memoryId) async {
    final todo = await _dbService.getTodoByMemoryId(memoryId);
    final todoId = todo?.id;
    if (todoId == null) return;

    await _notificationService.cancelTodoReminder(todoId);
  }

  /// 切换是否显示已完成的待办项
  Future<void> toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    return loadTodos();
  }

  /// 清空所有内存缓存数据
  void clearAll() {
    _todos = [];
    _showCompleted = false;
    _error = null;
    _loadGeneration++;
    notifyListeners();
  }
}
