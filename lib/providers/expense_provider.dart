import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';

/// 账单状态管理器
///
/// 管理账单/消费记录的状态，包括加载、新增消费记录、月度统计等。
/// 使用 ChangeNotifier 模式，配合 Provider 实现响应式 UI 更新。
class ExpenseProvider with ChangeNotifier {
  /// 数据库服务实例
  final DatabaseService _dbService = DatabaseService();

  /// 全部消费记录列表
  List<Expense> _expenses = [];

  /// 当前月度消费总额
  double _monthlyTotal = 0.0;

  /// 按分类统计的消费金额映射（分类名称 -> 金额）
  Map<String, double> _categoryStats = {};

  /// 当前选中的年份
  int _selectedYear = DateTime.now().year;

  /// 当前选中的月份
  int _selectedMonth = DateTime.now().month;

  /// 公开的状态访问器
  List<Expense> get expenses => _expenses;
  double get monthlyTotal => _monthlyTotal;
  Map<String, double> get categoryStats => _categoryStats;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  /// 加载全部消费记录
  Future<void> loadExpenses() async {
    _expenses = await _dbService.getAllExpenses();
    notifyListeners();
  }

  /// 加载指定月份的统计数据
  /// [year] 年份，[month] 月份
  /// 更新月度总额和分类统计数据
  Future<void> loadMonthlyStats(int year, int month) async {
    _selectedYear = year;
    _selectedMonth = month;
    _monthlyTotal = await _dbService.getMonthlyExpenseTotal(year, month);
    _categoryStats = await _dbService.getCategoryExpenses(year, month);
    notifyListeners();
  }

  /// 添加消费记录
  /// 插入后自动刷新列表和当月统计
  Future<void> addExpense(Expense expense) async {
    await _dbService.insertExpense(expense);
    await loadExpenses();
    await loadMonthlyStats(_selectedYear, _selectedMonth);
  }

  /// 切换查看的月份
  /// [year] 年份，[month] 月份
  void changeMonth(int year, int month) {
    loadMonthlyStats(year, month);
  }
}
