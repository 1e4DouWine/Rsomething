import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/memory.dart';

/// 数据库服务
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'rs_database.db';
  static const int _dbVersion = 1;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 记忆表
    await db.execute('''
      CREATE TABLE memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        raw_content_type TEXT NOT NULL,
        raw_content_summary TEXT,
        structured_data TEXT,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        source_app TEXT
      )
    ''');

    // 账单表
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memory_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'CNY',
        category TEXT DEFAULT '其他',
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (memory_id) REFERENCES memories (id) ON DELETE CASCADE
      )
    ''');

    // 待办表
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memory_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        due_date TEXT,
        is_completed INTEGER DEFAULT 0,
        reminder INTEGER DEFAULT 1,
        FOREIGN KEY (memory_id) REFERENCES memories (id) ON DELETE CASCADE
      )
    ''');

    // 日程事件表
    await db.execute('''
      CREATE TABLE calendar_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memory_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        location TEXT,
        notes TEXT,
        FOREIGN KEY (memory_id) REFERENCES memories (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== 记忆操作 ====================

  /// 插入记忆
  Future<int> insertMemory(Memory memory) async {
    final db = await database;
    return await db.insert('memories', memory.toMap());
  }

  /// 获取所有记忆（按时间倒序）
  Future<List<Memory>> getAllMemories({MemoryType? type}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    
    if (type != null) {
      where = 'type = ?';
      whereArgs = [type.value];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Memory.fromMap(map)).toList();
  }

  /// 根据ID获取记忆
  Future<Memory?> getMemoryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Memory.fromMap(maps.first);
  }

  /// 更新记忆状态
  Future<void> updateMemoryStatus(int id, MemoryStatus status) async {
    final db = await database;
    await db.update(
      'memories',
      {'status': status.value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除记忆
  Future<void> deleteMemory(int id) async {
    final db = await database;
    await db.delete('memories', where: 'id = ?', whereArgs: [id]);
  }

  /// 搜索记忆
  Future<List<Memory>> searchMemories(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'raw_content_summary LIKE ? OR structured_data LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Memory.fromMap(map)).toList();
  }

  // ==================== 账单操作 ====================

  /// 插入账单
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  /// 获取所有账单
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  /// 获取月度账单总额
  Future<double> getMonthlyExpenseTotal(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0).toIso8601String();

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total FROM expenses
      WHERE date >= ? AND date <= ?
    ''', [startDate, endDate]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// 获取分类账单统计
  Future<Map<String, double>> getCategoryExpenses(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0).toIso8601String();

    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total FROM expenses
      WHERE date >= ? AND date <= ?
      GROUP BY category
    ''', [startDate, endDate]);

    Map<String, double> categoryMap = {};
    for (var row in result) {
      categoryMap[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return categoryMap;
  }

  // ==================== 待办操作 ====================

  /// 插入待办
  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    return await db.insert('todos', todo.toMap());
  }

  /// 获取所有待办
  Future<List<Todo>> getAllTodos({bool? completed}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (completed != null) {
      where = 'is_completed = ?';
      whereArgs = [completed ? 1 : 0];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  /// 更新待办完成状态
  Future<void> updateTodoCompletion(int id, bool isCompleted) async {
    final db = await database;
    await db.update(
      'todos',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除待办
  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 日程操作 ====================

  /// 插入日程事件
  Future<int> insertCalendarEvent(CalendarEvent event) async {
    final db = await database;
    return await db.insert('calendar_events', event.toMap());
  }

  /// 获取所有日程事件
  Future<List<CalendarEvent>> getAllCalendarEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calendar_events',
      orderBy: 'start_time ASC',
    );

    return maps.map((map) => CalendarEvent.fromMap(map)).toList();
  }

  /// 删除日程事件
  Future<void> deleteCalendarEvent(int id) async {
    final db = await database;
    await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 统计操作 ====================

  /// 获取记忆类型统计
  Future<Map<MemoryType, int>> getMemoryTypeStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT type, COUNT(*) as count FROM memories
      GROUP BY type
    ''');

    Map<MemoryType, int> stats = {};
    for (var row in result) {
      stats[MemoryType.fromString(row['type'] as String)] = row['count'] as int;
    }
    return stats;
  }

  /// 清空所有数据
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('calendar_events');
    await db.delete('todos');
    await db.delete('expenses');
    await db.delete('memories');
  }
}