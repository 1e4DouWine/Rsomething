import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_handler/share_handler.dart';
import 'dart:async';
import '../models/memory.dart';
import '../providers/app_providers.dart';
import '../services/ai_service.dart';

/// 分享接收处理页面
class ShareReceiverScreen extends StatefulWidget {
  final String? sharedText;
  final List<String>? sharedImages;

  const ShareReceiverScreen({
    super.key,
    this.sharedText,
    this.sharedImages,
  });

  @override
  State<ShareReceiverScreen> createState() => _ShareReceiverScreenState();
}

class _ShareReceiverScreenState extends State<ShareReceiverScreen> {
  String? _sharedText;
  List<String> _sharedImages = [];
  bool _isProcessing = false;
  String _status = '准备处理...';
  AnalysisResult? _result;
  Memory? _memory;

  @override
  void initState() {
    super.initState();
    _sharedText = widget.sharedText;
    _sharedImages = widget.sharedImages ?? [];
    
    // 初始化分享处理器
    _initShareHandler();

    // 如果有初始数据，开始处理
    if (_sharedText != null || _sharedImages.isNotEmpty) {
      _startProcessing();
    }
  }

  void _initShareHandler() {
    final handler = ShareHandler();
    handler.getSharedMedia().then((media) {
      if (media != null && mounted) {
        if (media.content != null) {
          _sharedText = media.content;
        }
        if (media.attachments != null) {
          for (var attachment in media.attachments!) {
            if (attachment?.path != null) {
              _sharedImages.add(attachment!.path);
            }
          }
        }
        if (_sharedText != null || _sharedImages.isNotEmpty) {
          _startProcessing();
        }
      }
    });
  }

  Future<void> _startProcessing() async {
    if (_isProcessing) return;
    if (_sharedText == null && _sharedImages.isEmpty) {
      setState(() => _status = '没有接收到分享内容');
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = '正在分析内容...';
    });

    try {
      final aiProvider = context.read<AIProvider>();
      AnalysisResult? result;

      if (_sharedImages.isNotEmpty) {
        // TODO: 读取图片并转换为Base64
        // 暂时只处理文本
        setState(() => _status = '图片分析功能开发中...');
        await Future.delayed(const Duration(seconds: 1));
        result = AnalysisResult(
          action: 'unknown',
          confidence: 0.0,
          data: {'reason': '图片分析功能暂未实现'},
        );
      } else if (_sharedText != null) {
        result = await aiProvider.analyzeText(_sharedText!);
      }

      if (result != null) {
        // 创建记忆
        final memory = Memory(
          type: _getMemoryType(result.action),
          rawContentType: _sharedImages.isNotEmpty
              ? RawContentType.image
              : RawContentType.text,
          rawContentSummary: _sharedText ?? '图片内容',
          structuredData: result.data,
        );

        final memoryId = await context.read<MemoryProvider>().addMemory(memory);

        setState(() {
          _result = result;
          _memory = memory.copyWith(id: memoryId);
          _status = '分析完成';
          _isProcessing = false;
        });
      } else {
        setState(() {
          _status = '分析失败: ${aiProvider.error ?? "未知错误"}';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '处理出错: $e';
        _isProcessing = false;
      });
    }
  }

  MemoryType _getMemoryType(String action) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RS 内容处理'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSourceContent(),
            const SizedBox(height: 24),
            _buildStatusSection(),
            const SizedBox(height: 24),
            if (_result != null && _memory != null) ...[
              _buildResultSection(),
              const Spacer(),
              _buildActionButtons(),
            ] else if (!_isProcessing) ...[
              const Spacer(),
              _buildRetryButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分享内容',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_sharedText != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _sharedText!,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (_sharedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _sharedImages
                    .take(3)
                    .map((_) => Chip(
                          avatar: const Icon(Icons.image, size: 18),
                          label: const Text('图片'),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isProcessing) ...[
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          _status,
          style: TextStyle(
            fontSize: 16,
            color: _isProcessing ? Colors.blue : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(_memory!.type),
                  color: _getTypeColor(_memory!.type),
                ),
                const SizedBox(width: 8),
                Text(
                  '识别为: ${_memory!.type.label}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '置信度: ${(_result!.confidence * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ..._result!.data.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${entry.key}:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text('${entry.value}'),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _dismissMemory,
            icon: const Icon(Icons.close),
            label: const Text('忽略'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _confirmMemory,
            icon: const Icon(Icons.check),
            label: const Text('确认保存'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _startProcessing,
        icon: const Icon(Icons.refresh),
        label: const Text('重试'),
      ),
    );
  }

  IconData _getTypeIcon(MemoryType type) {
    switch (type) {
      case MemoryType.bill:
        return Icons.receipt_long;
      case MemoryType.todo:
        return Icons.check_circle_outline;
      case MemoryType.event:
        return Icons.event;
      case MemoryType.summary:
        return Icons.summarize;
      case MemoryType.unknown:
        return Icons.help_outline;
    }
  }

  Color _getTypeColor(MemoryType type) {
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

  Future<void> _confirmMemory() async {
    if (_memory == null) return;

    await context.read<MemoryProvider>().updateStatus(
      _memory!.id!,
      MemoryStatus.confirmed,
    );

    // 根据类型执行相应操作
    switch (_memory!.type) {
      case MemoryType.bill:
        await _saveExpense();
        break;
      case MemoryType.todo:
        await _saveTodo();
        break;
      case MemoryType.event:
        await _saveCalendarEvent();
        break;
      default:
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存到记忆流')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _dismissMemory() async {
    if (_memory == null) return;

    await context.read<MemoryProvider>().updateStatus(
      _memory!.id!,
      MemoryStatus.dismissed,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveExpense() async {
    final data = _result!.data;
    final expense = Expense(
      memoryId: _memory!.id!,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'CNY',
      category: data['category'] as String? ?? '其他',
      date: data['date'] != null
          ? DateTime.parse(data['date'] as String)
          : DateTime.now(),
      note: data['note'] as String?,
    );
    await context.read<ExpenseProvider>().addExpense(expense);
  }

  Future<void> _saveTodo() async {
    final data = _result!.data;
    final todo = Todo(
      memoryId: _memory!.id!,
      title: data['title'] as String? ?? '未命名待办',
      dueDate: data['due_date'] != null
          ? DateTime.parse(data['due_date'] as String)
          : null,
      reminder: data['reminder'] as bool? ?? true,
    );
    await context.read<TodoProvider>().addTodo(todo);
  }

  Future<void> _saveCalendarEvent() async {
    // TODO: 保存到系统日历
  }
}