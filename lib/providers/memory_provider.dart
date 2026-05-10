import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class MemoryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Memory> _memories = [];
  MemoryType? _filterType;
  bool _isLoading = false;

  List<Memory> get memories => _memories;
  MemoryType? get filterType => _filterType;
  bool get isLoading => _isLoading;

  Future<void> loadMemories({MemoryType? type}) async {
    _isLoading = true;
    notifyListeners();

    _filterType = type;
    _memories = await _dbService.getAllMemories(type: type);

    _isLoading = false;
    notifyListeners();
  }

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

  Future<int> addMemory(Memory memory) async {
    final id = await _dbService.insertMemory(memory);
    await loadMemories(type: _filterType);
    return id;
  }

  Future<void> updateStatus(int id, MemoryStatus status) async {
    await _dbService.updateMemoryStatus(id, status);
    await loadMemories(type: _filterType);
  }

  Future<void> deleteMemory(int id) async {
    await _dbService.deleteMemory(id);
    await loadMemories(type: _filterType);
  }

  void setFilterType(MemoryType? type) {
    _filterType = type;
    loadMemories(type: type);
  }
}
