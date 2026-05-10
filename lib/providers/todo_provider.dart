import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class TodoProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Todo> _todos = [];
  bool _showCompleted = false;

  List<Todo> get todos => _todos;
  bool get showCompleted => _showCompleted;

  Future<void> loadTodos() async {
    if (_showCompleted) {
      _todos = await _dbService.getAllTodos();
    } else {
      _todos = await _dbService.getAllTodos(completed: false);
    }
    notifyListeners();
  }

  Future<void> addTodo(Todo todo) async {
    await _dbService.insertTodo(todo);
    await loadTodos();
  }

  Future<void> toggleCompletion(int id, bool isCompleted) async {
    await _dbService.updateTodoCompletion(id, isCompleted);
    await loadTodos();
  }

  Future<void> deleteTodo(int id) async {
    await _dbService.deleteTodo(id);
    await loadTodos();
  }

  void toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    loadTodos();
  }
}
