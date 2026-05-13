import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseService databaseService;

  Future<void> resetDatabase() async {
    databaseService = DatabaseService();
    await databaseService.close();
    final path = p.join(await getDatabasesPath(), 'rs_database.db');
    await deleteDatabase(path);
  }

  setUp(resetDatabase);

  tearDown(() async {
    await databaseService.close();
  });

  test('confirming an event memory writes a calendar event', () async {
    final memoryId = await databaseService.insertMemory(
      Memory(
        type: MemoryType.event,
        rawContentType: RawContentType.text,
        rawContentSummary: '明天上午开会',
        structuredData: {
          'title': '项目会',
          'start_time': '2026-05-14T09:00:00',
          'end_time': '2026-05-14T10:00:00',
          'location': '会议室 A',
        },
      ),
    );

    final eventId = await databaseService.confirmMemoryWithRelatedRecord(
      memoryId: memoryId,
      calendarEvent: CalendarEvent(
        memoryId: memoryId,
        title: '项目会',
        startTime: DateTime(2026, 5, 14, 9),
        endTime: DateTime(2026, 5, 14, 10),
        location: '会议室 A',
      ),
    );

    final memory = await databaseService.getMemoryById(memoryId);
    final events = await databaseService.getAllCalendarEvents();

    expect(eventId, isNotNull);
    expect(memory?.status, MemoryStatus.confirmed);
    expect(events, hasLength(1));
    expect(events.single.memoryId, memoryId);
    expect(events.single.title, '项目会');
  });

  test('deleting a todo from the todo side removes its memory too', () async {
    final todoId = await databaseService.insertMemoryWithTodo(
      Memory(
        type: MemoryType.todo,
        rawContentType: RawContentType.text,
        rawContentSummary: '取快递',
        structuredData: {'title': '取快递'},
        status: MemoryStatus.confirmed,
      ),
      Todo(memoryId: 0, title: '取快递'),
    );

    expect(await databaseService.getAllTodos(), hasLength(1));
    expect(await databaseService.getAllMemories(), hasLength(1));

    await databaseService.deleteTodoWithMemory(todoId);

    expect(await databaseService.getAllTodos(), isEmpty);
    expect(await databaseService.getAllMemories(), isEmpty);
  });
}
