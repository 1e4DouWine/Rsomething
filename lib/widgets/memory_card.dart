import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';

/// 记忆卡片组件
class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelete;

  const MemoryCard({
    super.key,
    required this.memory,
    this.onTap,
    this.onConfirm,
    this.onDismiss,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildContent(),
              const SizedBox(height: 12),
              _buildStructuredPreview(),
              if (memory.status == MemoryStatus.pending) ...[
                const SizedBox(height: 12),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildTypeIcon(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memory.type.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(memory.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildStatusChip(),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            color: Colors.red[300],
          ),
      ],
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (memory.type) {
      case MemoryType.bill:
        icon = Icons.receipt_long;
        color = Colors.orange;
        break;
      case MemoryType.todo:
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case MemoryType.event:
        icon = Icons.event;
        color = Colors.green;
        break;
      case MemoryType.summary:
        icon = Icons.summarize;
        color = Colors.purple;
        break;
      case MemoryType.unknown:
        icon = Icons.help_outline;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;

    switch (memory.status) {
      case MemoryStatus.pending:
        color = Colors.orange;
        text = '待处理';
        break;
      case MemoryStatus.confirmed:
        color = Colors.green;
        text = '已确认';
        break;
      case MemoryStatus.dismissed:
        color = Colors.grey;
        text = '已忽略';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            memory.rawContentType == RawContentType.image
                ? Icons.image
                : Icons.text_snippet,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              memory.rawContentSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredPreview() {
    final data = memory.structuredData;
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTypeColor().withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '识别结果',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...data.entries.take(3).map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  '${entry.key}: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (memory.type) {
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

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('忽略'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('确认'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}