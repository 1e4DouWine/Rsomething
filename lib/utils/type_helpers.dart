import 'package:flutter/material.dart';
import '../models/models.dart';

MemoryType getMemoryTypeFromAction(String action) {
  switch (action) {
    case 'add_expense':
      return MemoryType.bill;
    case 'add_todo':
      return MemoryType.todo;
    case 'add_event':
      return MemoryType.event;
    case 'summarize_video':
      return MemoryType.summary;
    default:
      return MemoryType.unknown;
  }
}

IconData getTypeIcon(MemoryType type) {
  switch (type) {
    case MemoryType.bill:
      return Icons.receipt_long_rounded;
    case MemoryType.todo:
      return Icons.check_circle_outline_rounded;
    case MemoryType.event:
      return Icons.event_rounded;
    case MemoryType.summary:
      return Icons.summarize_rounded;
    case MemoryType.unknown:
      return Icons.help_outline_rounded;
  }
}

Color getTypeColor(MemoryType type) {
  switch (type) {
    case MemoryType.bill:
      return Colors.orange;
    case MemoryType.todo:
      return Colors.blue;
    case MemoryType.event:
      return Colors.green;
    case MemoryType.summary:
      return Colors.purple;
    case MemoryType.unknown:
      return Colors.grey;
  }
}
