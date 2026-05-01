import 'package:flutter/foundation.dart';
import '../models/memory.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';

/// 记忆状态管理
class MemoryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Memory> _memories = [];
  MemoryType? _filterType;
  bool _isLoading = false;

  List<Memory> get memories => _memories;
  MemoryType? get filterType => _filterType;
  bool get isLoading => _isLoading;

  /// 加载记忆列表
  Future<void> loadMemories({MemoryType? type}) async {
    _isLoading = true;
    notifyListeners();

    _filterType = type;
    _memories = await _dbService.getAllMemories(type: type);

    _isLoading = false;
    notifyListeners();
  }

  /// 搜索记忆
  Future<void> searchMemories(String query) async {
    _isLoading = true;
    notifyListeners();

    if (query.isEmpty) {
      _memories = await _dbService.getAllMemories(type: _filterType);
    } else {
      _memories = await _dbService.searchMemories(query);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 添加记忆
  Future<int> addMemory(Memory memory) async {
    final id = await _dbService.insertMemory(memory);
    await loadMemories(type: _filterType);
    return id;
  }

  /// 更新记忆状态
  Future<void> updateStatus(int id, MemoryStatus status) async {
    await _dbService.updateMemoryStatus(id, status);
    await loadMemories(type: _filterType);
  }

  /// 删除记忆
  Future<void> deleteMemory(int id) async {
    await _dbService.deleteMemory(id);
    await loadMemories(type: _filterType);
  }

  /// 设置筛选类型
  void setFilterType(MemoryType? type) {
    _filterType = type;
    loadMemories(type: type);
  }
}

/// 账单状态管理
class ExpenseProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Expense> _expenses = [];
  double _monthlyTotal = 0.0;
  Map<String, double> _categoryStats = {};
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  List<Expense> get expenses => _expenses;
  double get monthlyTotal => _monthlyTotal;
  Map<String, double> get categoryStats => _categoryStats;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  /// 加载账单列表
  Future<void> loadExpenses() async {
    _expenses = await _dbService.getAllExpenses();
    notifyListeners();
  }

  /// 加载月度统计
  Future<void> loadMonthlyStats(int year, int month) async {
    _selectedYear = year;
    _selectedMonth = month;
    _monthlyTotal = await _dbService.getMonthlyExpenseTotal(year, month);
    _categoryStats = await _dbService.getCategoryExpenses(year, month);
    notifyListeners();
  }

  /// 添加账单
  Future<void> addExpense(Expense expense) async {
    await _dbService.insertExpense(expense);
    await loadExpenses();
    await loadMonthlyStats(_selectedYear, _selectedMonth);
  }

  /// 切换月份
  void changeMonth(int year, int month) {
    loadMonthlyStats(year, month);
  }
}

/// 待办状态管理
class TodoProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Todo> _todos = [];
  bool _showCompleted = false;

  List<Todo> get todos => _todos;
  bool get showCompleted => _showCompleted;

  /// 加载待办列表
  Future<void> loadTodos() async {
    if (_showCompleted) {
      _todos = await _dbService.getAllTodos();
    } else {
      _todos = await _dbService.getAllTodos(completed: false);
    }
    notifyListeners();
  }

  /// 添加待办
  Future<void> addTodo(Todo todo) async {
    await _dbService.insertTodo(todo);
    await loadTodos();
  }

  /// 切换完成状态
  Future<void> toggleCompletion(int id, bool isCompleted) async {
    await _dbService.updateTodoCompletion(id, isCompleted);
    await loadTodos();
  }

  /// 删除待办
  Future<void> deleteTodo(int id) async {
    await _dbService.deleteTodo(id);
    await loadTodos();
  }

  /// 切换显示已完成
  void toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    loadTodos();
  }
}

/// AI分析状态管理
class AIProvider with ChangeNotifier {
  final AIService _aiService = AIService.instance;
  final SettingsService _settingsService;
  bool _isAnalyzing = false;
  String? _error;

  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;

  AIProvider(this._settingsService) {
    _initAIConfig();
  }

  void _initAIConfig() {
    if (_settingsService.isAIConfigured()) {
      _aiService.setConfig(AIConfig(
        baseUrl: _settingsService.getBaseUrl(),
        apiKey: _settingsService.getApiKey(),
        modelName: _settingsService.getModelName(),
      ));
    }
  }

  /// 更新AI配置
  void updateConfig() {
    _initAIConfig();
  }

  /// 分析文本
  Future<AnalysisResult?> analyzeText(String text) async {
    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _aiService.analyzeText(text);
      _isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isAnalyzing = false;
      notifyListeners();
      return null;
    }
  }

  /// 分析图片
  Future<AnalysisResult?> analyzeImage(String base64Image, {String? text}) async {
    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _aiService.analyzeImage(base64Image, text: text);
      _isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isAnalyzing = false;
      notifyListeners();
      return null;
    }
  }

  /// 测试连接
  Future<bool> testConnection() async {
    return await _aiService.testConnection();
  }
}