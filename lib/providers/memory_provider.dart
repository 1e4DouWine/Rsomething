import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';

/// 记忆状态管理器
///
/// 管理记忆列表的状态，包括加载、搜索、筛选、增删改操作。
/// 使用 ChangeNotifier 模式，配合 Provider 实现响应式 UI 更新。
class MemoryProvider with ChangeNotifier {
  /// 数据库服务实例
  final DatabaseService _dbService = DatabaseService();

  /// 当前记忆列表
  List<Memory> _memories = [];

  /// 当前筛选类型（null 表示显示全部）
  MemoryType? _filterType;

  /// 是否正在加载数据
  bool _isLoading = false;

  /// 最近一次加载/搜索的错误信息
  String? _error;

  /// 加载序号，用于忽略较早返回的异步请求结果
  int _loadGeneration = 0;

  /// 公开的状态访问器
  List<Memory> get memories => _memories;
  MemoryType? get filterType => _filterType;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载记忆列表
  /// [type] 可选的类型筛选条件，为 null 时加载全部
  Future<void> loadMemories({MemoryType? type}) async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _error = null;
    _filterType = type;
    notifyListeners();

    try {
      final memories = await _dbService.getAllMemories(type: type);
      if (generation != _loadGeneration) return;

      _memories = memories;
    } catch (e) {
      if (generation != _loadGeneration) return;
      _error = e.toString();
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 搜索记忆
  /// [query] 搜索关键词，为空时恢复显示全部（或按当前筛选条件）
  Future<void> searchMemories(String query) async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final memories = query.isEmpty
          ? await _dbService.getAllMemories(type: _filterType)
          : await _dbService.searchMemories(query);
      if (generation != _loadGeneration) return;

      _memories = memories;
    } catch (e) {
      if (generation != _loadGeneration) return;
      _error = e.toString();
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 添加新记忆
  /// 返回新插入记录的 ID
  Future<int> addMemory(Memory memory) async {
    final id = await _dbService.insertMemory(memory);
    await loadMemories(type: _filterType);
    return id;
  }

  /// 在事务中确认记忆并写入关联业务记录。
  Future<int?> confirmWithRelatedRecord(
    int memoryId, {
    Expense? expense,
    Todo? todo,
    CalendarEvent? calendarEvent,
  }) async {
    final relatedId = await _dbService.confirmMemoryWithRelatedRecord(
      memoryId: memoryId,
      expense: expense,
      todo: todo,
      calendarEvent: calendarEvent,
    );
    await loadMemories(type: _filterType);
    return relatedId;
  }

  /// 更新记忆状态（确认/忽略）
  Future<void> updateStatus(int id, MemoryStatus status) async {
    await _dbService.updateMemoryStatus(id, status);
    await loadMemories(type: _filterType);
  }

  /// 删除记忆
  Future<void> deleteMemory(int id) async {
    await _dbService.deleteMemory(id);
    await loadMemories(type: _filterType);
  }

  /// 设置筛选类型并重新加载数据
  void setFilterType(MemoryType? type) {
    _filterType = type;
    loadMemories(type: type);
  }

  /// 清空所有内存缓存数据
  void clearAll() {
    _memories = [];
    _filterType = null;
    _isLoading = false;
    _error = null;
    _loadGeneration++;
    notifyListeners();
  }
}
