import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';

/// 账本页面
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpenseProvider>();
      provider.loadExpenses();
      provider.loadMonthlyStats(
        DateTime.now().year,
        DateTime.now().month,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账本'),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildMonthSelector(provider),
              _buildMonthlySummary(provider),
              Expanded(child: _buildExpenseList(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(ExpenseProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              int year = provider.selectedYear;
              int month = provider.selectedMonth - 1;
              if (month < 1) {
                month = 12;
                year--;
              }
              provider.changeMonth(year, month);
            },
          ),
          Text(
            '${provider.selectedYear}年${provider.selectedMonth}月',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              int year = provider.selectedYear;
              int month = provider.selectedMonth + 1;
              if (month > 12) {
                month = 1;
                year++;
              }
              provider.changeMonth(year, month);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(ExpenseProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '本月支出',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${provider.monthlyTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (provider.categoryStats.isNotEmpty) ...[
            const Divider(color: Colors.white30),
            const SizedBox(height: 12),
            _buildCategoryStats(provider),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryStats(ExpenseProvider provider) {
    final stats = provider.categoryStats;
    final total = stats.values.fold(0.0, (sum, value) => sum + value);

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: stats.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getCategoryColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key} ${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '餐饮':
        return Colors.orange;
      case '交通':
        return Colors.blue;
      case '购物':
        return Colors.pink;
      case '娱乐':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildExpenseList(ExpenseProvider provider) {
    if (provider.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无账单记录',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '分享消费小票到 RS 自动记账',
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
      itemCount: provider.expenses.length,
      itemBuilder: (context, index) {
        final expense = provider.expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(expense.category).withOpacity(0.1),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: _getCategoryColor(expense.category),
              ),
            ),
            title: Text(expense.note ?? expense.category),
            subtitle: Text(
              DateFormat('yyyy-MM-dd').format(expense.date),
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Text(
              '¥${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '餐饮':
        return Icons.restaurant;
      case '交通':
        return Icons.directions_car;
      case '购物':
        return Icons.shopping_bag;
      case '娱乐':
        return Icons.sports_esports;
      default:
        return Icons.category;
    }
  }
}