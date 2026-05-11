import 'package:share_handler/share_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/type_helpers.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

/// 分享内容接收处理页面
///
/// 当用户通过系统分享功能将内容发送到本应用时，此页面负责：
/// 1. 接收并展示分享的文本/图片内容
/// 2. 调用 AI 服务分析内容，识别内容类型
/// 3. 展示分析结果（类型、置信度、结构化数据）
/// 4. 用户确认后保存到记忆流，或选择忽略
class ShareReceiverScreen extends StatefulWidget {
  /// 分享的文本内容（可选）
  final String? sharedText;

  /// 分享的图片路径列表（可选）
  final List<String>? sharedImages;

  const ShareReceiverScreen({super.key, this.sharedText, this.sharedImages});

  @override
  State<ShareReceiverScreen> createState() => _ShareReceiverScreenState();
}

class _ShareReceiverScreenState extends State<ShareReceiverScreen> {
  /// 分享的文本内容
  String? _sharedText;

  /// 分享的图片路径列表
  List<String> _sharedImages = [];

  /// 是否正在处理中
  bool _isProcessing = false;

  /// 当前状态描述文字
  String _status = '准备处理...';

  /// AI 分析结果
  AnalysisResult? _result;

  /// 从分析结果创建的记忆对象
  Memory? _memory;

  @override
  void initState() {
    super.initState();
    _sharedText = widget.sharedText;
    _sharedImages = widget.sharedImages ?? [];
    _initShareHandler();

    // 如果已有分享内容，自动开始处理
    if (_sharedText != null || _sharedImages.isNotEmpty) {
      _startProcessing();
    }
  }

  /// 初始化分享处理器
  /// 检查是否有通过冷启动传入的初始分享内容
  void _initShareHandler() {
    final handler = ShareHandlerPlatform.instance;
    handler.getInitialSharedMedia().then((media) {
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

  /// 开始 AI 分析处理流程
  /// 区分图片和文本内容，调用对应的 AI 分析接口
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
        setState(() => _status = '正在压缩图片...');
        final base64Image = await _compressImageToBase64(_sharedImages.first);
        if (!mounted) return;
        setState(() => _status = '正在分析图片内容...');
        result = await aiProvider.analyzeImage(base64Image, text: _sharedText);
      } else if (_sharedText != null) {
        // 文本分析
        result = await aiProvider.analyzeText(_sharedText!);
      }

      if (result != null) {
        // 创建记忆对象
        final memory = Memory(
          type: getMemoryTypeFromAction(result.action),
          rawContentType: _sharedImages.isNotEmpty
              ? RawContentType.image
              : RawContentType.text,
          rawContentSummary: _sharedText ?? '图片内容',
          structuredData: result.data,
        );

        if (!mounted) return;
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

  Future<String> _compressImageToBase64(String imagePath) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      imagePath,
      minWidth: 1600,
      minHeight: 1600,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (compressed == null || compressed.isEmpty) {
      throw Exception('图片读取或压缩失败');
    }

    return base64Encode(compressed);
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

  /// 构建来源内容展示区
  /// 显示用户分享的原始文本和图片信息
  Widget _buildSourceContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分享内容',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_sharedText != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
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
                    .map(
                      (_) => const Chip(
                        avatar: Icon(Icons.image, size: 18),
                        label: Text('图片'),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建状态展示区
  /// 显示当前处理状态，处理中时显示加载指示器
  Widget _buildStatusSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _isProcessing
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 构建分析结果展示区
  /// 显示识别的类型、置信度和结构化数据
  Widget _buildResultSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  getTypeIcon(_memory!.type),
                  color: getTypeColor(_memory!.type),
                ),
                const SizedBox(width: 8),
                Text(
                  '识别为: ${_memory!.type.label}',
                  style: theme.textTheme.titleLarge?.copyWith(
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
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '置信度: ${(_result!.confidence * 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ..._result!.data.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${entry.key}:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Text('${entry.value}')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮区
  /// 包含"忽略"和"确认保存"两个按钮
  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _dismissMemory,
            icon: const Icon(Icons.close),
            label: const Text('忽略'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
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
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建重试按钮（分析失败时显示）
  Widget _buildRetryButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _startProcessing,
        icon: const Icon(Icons.refresh),
        label: const Text('重试'),
      ),
    );
  }

  /// 确认保存记忆
  /// 更新记忆状态为已确认，并根据类型保存到对应模块（账单/待办/日程）
  Future<void> _confirmMemory() async {
    if (_memory == null) return;

    final memory = _memory!;
    final memoryProvider = context.read<MemoryProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final todoProvider = context.read<TodoProvider>();

    try {
      // 根据记忆类型保存到对应模块。状态更新和业务记录写入在同一事务中完成。
      switch (memory.type) {
        case MemoryType.bill:
          await memoryProvider.confirmWithRelatedRecord(
            memory.id!,
            expense: _buildExpense(memory.id!, _result!.data),
          );
          await expenseProvider.loadExpenses();
          await expenseProvider.loadMonthlyStats(
            expenseProvider.selectedYear,
            expenseProvider.selectedMonth,
          );
          break;
        case MemoryType.todo:
          final todo = _buildTodo(memory.id!, _result!.data);
          final todoId = await memoryProvider.confirmWithRelatedRecord(
            memory.id!,
            todo: todo,
          );
          await todoProvider.loadTodos();
          if (todoId != null) {
            await _scheduleTodoReminder(todo.copyWith(id: todoId));
          }
          break;
        case MemoryType.event:
          await memoryProvider.confirmWithRelatedRecord(memory.id!);
          break;
        default:
          await memoryProvider.confirmWithRelatedRecord(memory.id!);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已保存到记忆流')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  /// 忽略记忆
  /// 更新记忆状态为已忽略
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

  /// 从结构化数据构建消费记录。
  Expense _buildExpense(int memoryId, Map<String, dynamic> data) {
    return Expense(
      memoryId: memoryId,
      amount: readAmount(data['amount']),
      currency: data['currency']?.toString() ?? 'CNY',
      category: data['category']?.toString() ?? '其他',
      date: readDateTime(data['date']) ?? DateTime.now(),
      note: data['note']?.toString(),
    );
  }

  /// 从结构化数据构建待办事项。
  Todo _buildTodo(int memoryId, Map<String, dynamic> data) {
    final title = data['title']?.toString().trim();
    return Todo(
      memoryId: memoryId,
      title: title == null || title.isEmpty ? '未命名待办' : title,
      dueDate: readDateTime(data['due_date']),
      reminder: readBool(data['reminder']),
    );
  }

  Future<void> _scheduleTodoReminder(Todo todo) async {
    if (!todo.reminder || todo.dueDate == null || todo.id == null) return;

    final settings = await SettingsService.getInstance();
    final reminderAt = todo.dueDate!.subtract(
      Duration(minutes: settings.getDefaultReminderMinutes()),
    );
    try {
      await NotificationService.instance.scheduleTodoReminder(
        todoId: todo.id!,
        title: todo.title,
        scheduledAt: reminderAt,
      );
    } catch (_) {
      // Reminder scheduling must not roll back already saved content.
    }
  }
}
