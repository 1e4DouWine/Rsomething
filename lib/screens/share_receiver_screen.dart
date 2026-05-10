import 'package:share_handler/share_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/type_helpers.dart';
import '../services/ai_service.dart';

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

  const ShareReceiverScreen({
    super.key,
    this.sharedText,
    this.sharedImages,
  });

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
        // 图片分析功能尚未实现，返回占位结果
        setState(() => _status = '图片分析功能开发中...');
        await Future.delayed(const Duration(seconds: 1));
        result = AnalysisResult(
          action: 'unknown',
          confidence: 0.0,
          data: {'reason': '图片分析功能暂未实现'},
        );
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
                    .map((_) => const Chip(
                          avatar: Icon(Icons.image, size: 18),
                          label: Text('图片'),
                        ))
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
            color: _isProcessing ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
            ..._result!.data.entries.map((entry) => Padding(
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

    await context.read<MemoryProvider>().updateStatus(
      _memory!.id!,
      MemoryStatus.confirmed,
    );

    // 根据记忆类型保存到对应模块
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

  /// 保存消费记录到账本模块
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

  /// 保存待办事项到待办模块
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

  /// 保存日程事件（TODO: 对接系统日历）
  Future<void> _saveCalendarEvent() async {
    // TODO: 保存到系统日历
  }
}
