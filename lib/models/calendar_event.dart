class CalendarEvent {
  final int? id;
  final int memoryId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? notes;

  CalendarEvent({
    this.id,
    required this.memoryId,
    required this.title,
    required this.startTime,
    DateTime? endTime,
    this.location,
    this.notes,
  }) : endTime = endTime ?? startTime.add(const Duration(hours: 1));

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'memory_id': memoryId,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'notes': notes,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as int?,
      memoryId: map['memory_id'] as int,
      title: map['title'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
