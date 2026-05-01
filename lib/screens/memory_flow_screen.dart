import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../providers/app_providers.dart';
import '../widgets/memory_card.dart';

/// 记忆流页面
class MemoryFlowScreen extends StatefulWidget {
  const MemoryFlowScreen({super.key});

  @override
  State<MemoryFlowScreen> createState() => _MemoryFlowScreenState();
}

class _MemoryFlowScreenState extends State<MemoryFlowScreen> {
  MemoryType? _selectedType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemoryProvider>().loadMemories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆流'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildMemoryList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('全部'),
            selected: _selectedType == null,
            onSelected: (selected) {
              setState(() => _selectedType = null);
              context.read<MemoryProvider>().setFilterType(null);
            },
          ),
          const SizedBox(width: 8),
          ...MemoryType.values.where((t) => t != MemoryType.unknown).map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.label),
                selected: _selectedType == type,
                onSelected: (selected) {
                  setState(() => _selectedType = selected ? type : null);
                  context.read<MemoryProvider>().setFilterType(
                    selected ? type : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryList() {
    return Consumer<MemoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.memories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '还没有记忆',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击 + 或分享内容到 RS 开始记录',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.memories.length,
          itemBuilder: (context, index) {
            final memory = provider.memories[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MemoryCard(
                memory: memory,
                onTap: () => _showMemoryDetail(memory),
                onConfirm: () => _confirmMemory(memory),
                onDismiss: () => _dismissMemory(memory),
                onDelete: () => _deleteMemory(memory),
              ),
            );
          },
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索记忆'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '输入关键词...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MemoryProvider>().searchMemories(
                _searchController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddContentSheet(),
    );
  }

  void _showMemoryDetail(Memory memory) {
    showDialog(
      context: context,
      builder: (context) => MemoryDetailDialog(memory: memory),
    );
  }

  Future<void> _confirmMemory(Memory memory) async {
    await context.read<MemoryProvider>().updateStatus(
      memory.id!,
      MemoryStatus.confirmed,
    );
    
    // 根据类型执行相应操作
    switch (memory.type) {
      case MemoryType.bill:
        await _saveExpense(memory);
        break;
      case MemoryType.todo:
        await _saveTodo(memory);
        break;
      case MemoryType.event:
        await _saveCalendarEvent(memory);
        break;
      default:
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已确认并保存')),
      );
    }
  }

  Future<void> _dismissMemory(Memory memory) async {
    await context.read<MemoryProvider>().updateStatus(
      memory.id!,
      MemoryStatus.dismissed,
    );
  }

  Future<void> _deleteMemory(Memory memory) async {
    await context.read<MemoryProvider>().deleteMemory(memory.id!);
  }

  Future<void> _saveExpense(Memory memory) async {
    final data = memory.structuredData;
    final expense = Expense(
      memoryId: memory.id!,
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

  Future<void> _saveTodo(Memory memory) async {
    final data = memory.structuredData;
    final todo = Todo(
      memoryId: memory.id!,
      title: data['title'] as String? ?? '未命名待办',
      dueDate: data['due_date'] != null
          ? DateTime.parse(data['due_date'] as String)
          : null,
      reminder: data['reminder'] as bool? ?? true,
    );
    await context.read<TodoProvider>().addTodo(todo);
  }

  Future<void> _saveCalendarEvent(Memory memory) async {
    final data = memory.structuredData;
    // TODO: 保存到系统日历
    // final event = CalendarEvent(
    //   memoryId: memory.id!,
    //   title: data['title'] as String? ?? '未命名事件',
    //   startTime: DateTime.parse(data['start_time'] as String),
    //   endTime: data['end_time'] != null
    //       ? DateTime.parse(data['end_time'] as String)
    //       : null,
    //   location: data['location'] as String?,
    //   notes: data['notes'] as String?,
    // );
  }
}

/// 添加内容底部表单
class AddContentSheet extends StatefulWidget {
  const AddContentSheet({super.key});

  @override
  State<AddContentSheet> createState() => _AddContentSheetState();
}

class _AddContentSheetState extends State<AddContentSheet> {
  final TextEditingController _textController = TextEditingController();
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '添加新内容',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '输入或粘贴内容...\n例如：今天午饭花了35元',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeContent,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isAnalyzing ? '分析中...' : '智能分析'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _analyzeContent() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final aiProvider = context.read<AIProvider>();
      final result = await aiProvider.analyzeText(text);

      if (result != null && mounted) {
        // 创建记忆
        final memory = Memory(
          type: _getMemoryType(result.action),
          rawContentType: RawContentType.text,
          rawContentSummary: text.length > 50 ? '${text.substring(0, 50)}...' : text,
          structuredData: result.data,
        );

        await context.read<MemoryProvider>().addMemory(memory);
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加到记忆流')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: ${aiProvider.error ?? "未知错误"}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
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
}

/// 记忆详情对话框
class MemoryDetailDialog extends StatelessWidget {
  final Memory memory;

  const MemoryDetailDialog({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(memory.type.label),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '原始内容',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(memory.rawContentSummary),
            const SizedBox(height: 16),
            Text(
              '识别结果',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _buildStructuredData(),
            const SizedBox(height: 8),
            Text(
              '创建时间: ${DateFormat('yyyy-MM-dd HH:mm').format(memory.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildStructuredData() {
    final data = memory.structuredData;
    if (data.isEmpty) {
      return const Text('无结构化数据');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('${entry.key}: ${entry.value}'),
        );
      }).toList(),
    );
  }
}