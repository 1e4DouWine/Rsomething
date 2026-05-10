import 'package:flutter/material.dart';
import '../models/models.dart';

/// 根据 AI 分析的动作类型字符串转换为 MemoryType 枚举
/// [action] AI 返回的动作类型标识符
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

/// 根据 MemoryType 获取对应的图标
/// 用于记忆卡片和详情页的图标展示
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

/// 根据 MemoryType 获取对应的主题色
/// 用于记忆卡片的视觉区分
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
