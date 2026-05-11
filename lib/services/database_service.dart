import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// 数据库服务类
///
/// 基于 SQLite (sqflite) 的本地数据库服务，负责所有数据的持久化操作。
/// 使用单例模式管理数据库连接，包含四张表：
/// - memories: 记忆表（核心表）
/// - expenses: 消费记录表
/// - todos: 待办事项表
/// - calendar_events: 日程事件表
class DatabaseService {
  /// 数据库实例（单例缓存）
  static Database? _database;

  /// 数据库文件名
  static const String _dbName = 'rs_database.db';

  /// 数据库版本号（用于迁移管理）
  static const int _dbVersion = 1;

  /// 获取数据库实例（懒加载模式）
  /// 如果已初始化则直接返回，否则执行初始化
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  /// 获取数据库文件路径并打开连接，首次创建时触发 [_onCreate]
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// 数据库首次创建时的回调
  /// 创建所有数据表及外键约束
  Future<void> _onCreate(Database db, int version) async {
    // 创建记忆表（核心表，其他表通过外键关联）
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

    // 创建消费记录表（外键关联 memories 表，级联删除）
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

    // 创建待办事项表（外键关联 memories 表，级联删除）
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

    // 创建日程事件表（外键关联 memories 表，级联删除）
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

  /// 插入一条记忆记录
  /// 返回新插入记录的自增 ID
  Future<int> insertMemory(Memory memory) async {
    final db = await database;
    return await db.insert('memories', memory.toMap());
  }

  /// 获取所有记忆记录
  /// [type] 可选的类型筛选条件
  /// 结果按创建时间倒序排列
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

  /// 根据 ID 获取单条记忆记录
  /// 未找到时返回 null
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

  /// 更新记忆的状态（确认/忽略）
  Future<void> updateMemoryStatus(int id, MemoryStatus status) async {
    final db = await database;
    await db.update(
      'memories',
      {'status': status.value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除指定 ID 的记忆记录
  /// 由于外键级联删除，关联的子表记录也会被自动删除
  Future<void> deleteMemory(int id) async {
    final db = await database;
    await db.delete('memories', where: 'id = ?', whereArgs: [id]);
  }

  /// 搜索记忆
  /// 在原始内容摘要和结构化数据中进行模糊匹配
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

  /// 插入一条消费记录
  /// 返回新插入记录的自增 ID
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  /// 获取所有消费记录
  /// 结果按日期倒序排列
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  /// 获取指定月份的消费总额
  /// [year] 年份，[month] 月份
  Future<double> getMonthlyExpenseTotal(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 1).toIso8601String();

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total FROM expenses
      WHERE date >= ? AND date < ?
    ''', [startDate, endDate]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// 获取指定月份按分类统计的消费金额
  /// 返回 Map<分类名称, 金额>
  Future<Map<String, double>> getCategoryExpenses(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 1).toIso8601String();

    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total FROM expenses
      WHERE date >= ? AND date < ?
      GROUP BY category
    ''', [startDate, endDate]);

    Map<String, double> categoryMap = {};
    for (var row in result) {
      categoryMap[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return categoryMap;
  }

  // ==================== 待办操作 ====================

  /// 插入一条待办事项
  /// 返回新插入记录的自增 ID
  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    return await db.insert('todos', todo.toMap());
  }

  /// 获取待办事项列表
  /// [completed] 可选的完成状态筛选（true=仅已完成，false=仅未完成，null=全部）
  /// 结果按截止日期升序排列
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

  /// 更新待办事项的完成状态
  Future<void> updateTodoCompletion(int id, bool isCompleted) async {
    final db = await database;
    await db.update(
      'todos',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除指定 ID 的待办事项
  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 日程操作 ====================

  /// 插入一条日程事件
  /// 返回新插入记录的自增 ID
  Future<int> insertCalendarEvent(CalendarEvent event) async {
    final db = await database;
    return await db.insert('calendar_events', event.toMap());
  }

  /// 获取所有日程事件
  /// 结果按开始时间升序排列
  Future<List<CalendarEvent>> getAllCalendarEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calendar_events',
      orderBy: 'start_time ASC',
    );

    return maps.map((map) => CalendarEvent.fromMap(map)).toList();
  }

  /// 删除指定 ID 的日程事件
  Future<void> deleteCalendarEvent(int id) async {
    final db = await database;
    await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 统计操作 ====================

  /// 获取各类型记忆的数量统计
  /// 返回 `Map<MemoryType, 数量>`
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

  /// 清空所有数据表
  /// 按照外键依赖顺序删除：先子表后主表
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('calendar_events');
    await db.delete('todos');
    await db.delete('expenses');
    await db.delete('memories');
  }
}
