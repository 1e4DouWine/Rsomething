class Todo {
  final int? id;
  final int memoryId;
  final String title;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool reminder;

  Todo({
    this.id,
    required this.memoryId,
    required this.title,
    this.dueDate,
    this.isCompleted = false,
    this.reminder = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'memory_id': memoryId,
      'title': title,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'reminder': reminder ? 1 : 0,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      memoryId: map['memory_id'] as int,
      title: map['title'] as String,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      isCompleted: (map['is_completed'] as int?) == 1,
      reminder: (map['reminder'] as int?) == 1,
    );
  }
}
