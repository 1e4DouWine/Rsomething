import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';

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

  Future<void> loadExpenses() async {
    _expenses = await _dbService.getAllExpenses();
    notifyListeners();
  }

  Future<void> loadMonthlyStats(int year, int month) async {
    _selectedYear = year;
    _selectedMonth = month;
    _monthlyTotal = await _dbService.getMonthlyExpenseTotal(year, month);
    _categoryStats = await _dbService.getCategoryExpenses(year, month);
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _dbService.insertExpense(expense);
    await loadExpenses();
    await loadMonthlyStats(_selectedYear, _selectedMonth);
  }

  void changeMonth(int year, int month) {
    loadMonthlyStats(year, month);
  }
}
