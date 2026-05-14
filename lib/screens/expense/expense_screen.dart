import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_layout.dart';

/// 账本页面
///
/// 展示和管理消费记录，功能包括：
/// - 月份切换（左右箭头选择年月）
/// - 月度消费总额展示（带动画数字滚动效果）
/// - 按分类统计消费占比（进度条 + 百分比）
/// - 消费记录列表（按日期倒序）
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// 头部入场动画控制器
  late AnimationController _animationController;

  /// 头部淡入 + 上滑动画
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初始化头部入场动画
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    // 页面加载后自动获取消费数据和当月统计
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadExpenses();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reloadExpenses();
    }
  }

  Future<void> _reloadExpenses() async {
    final provider = context.read<ExpenseProvider>();
    await provider.loadExpenses();
    await provider.loadMonthlyStats(
      provider.selectedYear,
      provider.selectedMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildMonthSelector(theme, provider),
                      ),
                      SliverToBoxAdapter(
                        child: _buildMonthlySummary(theme, provider),
                      ),
                      SliverToBoxAdapter(
                        child: _buildCategoryLegend(theme, provider),
                      ),
                      _buildExpenseList(theme, provider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 构建页面头部
  /// 包含标题"账本"、副标题和账单图标
  Widget _buildHeader(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AdaptiveContent(
          padding: AdaptiveLayout.pageInsetsForWidth(
            constraints.maxWidth,
            top: 16,
            bottom: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '账本',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '追踪你的每一笔消费',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.billColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.billColor,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建月份选择器
  /// 左右箭头切换年月，中间显示当前选中的年月
  Widget _buildMonthSelector(ThemeData theme, ExpenseProvider provider) {
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AdaptiveContent(
          padding: EdgeInsets.symmetric(
            horizontal: AdaptiveLayout.horizontalPaddingForWidth(
              constraints.maxWidth,
            ),
            vertical: 12,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 上个月按钮
                IconButton(
                  tooltip: '上个月',
                  onPressed: () {
                    int year = provider.selectedYear;
                    int month = provider.selectedMonth - 1;
                    if (month < 1) {
                      month = 12;
                      year--;
                    }
                    provider.changeMonth(year, month);
                  },
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                // 当前年月显示（带动画切换效果）
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: FittedBox(
                      key: ValueKey(
                        '${provider.selectedYear}-${provider.selectedMonth}',
                      ),
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${provider.selectedYear}年${provider.selectedMonth}月',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                // 下个月按钮
                IconButton(
                  tooltip: '下个月',
                  onPressed: () {
                    int year = provider.selectedYear;
                    int month = provider.selectedMonth + 1;
                    if (month > 12) {
                      month = 1;
                      year++;
                    }
                    provider.changeMonth(year, month);
                  },
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建月度消费总额卡片
  /// 带入场动画（淡入 + 上滑），金额数字有滚动动画效果
  Widget _buildMonthlySummary(ThemeData theme, ExpenseProvider provider) {
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _headerAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_headerAnimation),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AdaptiveContent(
              padding: AdaptiveLayout.pageInsetsForWidth(
                constraints.maxWidth,
                top: 8,
                bottom: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '本月支出',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 金额数字滚动动画
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: provider.monthlyTotal),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '¥${value.toStringAsFixed(2)}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        );
                      },
                    ),
                    // 分类统计饼图标签（仅在有数据时显示）
                    if (provider.categoryStats.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              colorScheme.onPrimary.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildCategoryStats(theme, provider),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建分类统计标签
  /// 以 Wrap 布局展示各分类的颜色圆点、名称和百分比
  Widget _buildCategoryStats(ThemeData theme, ExpenseProvider provider) {
    final colorScheme = theme.colorScheme;
    final stats = provider.categoryStats;
    final total = stats.values.fold(0.0, (sum, value) => sum + value);

    return Wrap(
      spacing: 20,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: stats.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0;
        final color = AppTheme.getCategoryColor(entry.key);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.key} ${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// 构建分类消费详情卡片
  /// 以列表形式展示各分类的消费金额和占比进度条
  Widget _buildCategoryLegend(ThemeData theme, ExpenseProvider provider) {
    if (provider.categoryStats.isEmpty) return const SizedBox.shrink();

    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AdaptiveContent(
          padding: AdaptiveLayout.pageInsetsForWidth(
            constraints.maxWidth,
            top: 0,
            bottom: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '消费分类',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ...provider.categoryStats.entries.map((entry) {
                  final color = AppTheme.getCategoryColor(entry.key);
                  final total = provider.monthlyTotal;
                  final percentage = total > 0
                      ? (entry.value / total * 100)
                      : 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // 分类图标
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getCategoryIcon(entry.key),
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 分类名称和金额
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Flexible(
                                    child: Text(
                                      '¥${entry.value.toStringAsFixed(2)}',
                                      textAlign: TextAlign.end,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onSurface,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 占比进度条
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: color.withValues(
                                    alpha: 0.12,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建消费记录列表
  /// 空列表时显示引导页面，否则显示消费记录卡片列表
  Widget _buildExpenseList(ThemeData theme, ExpenseProvider provider) {
    final colorScheme = theme.colorScheme;

    if (provider.expenses.isEmpty) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final screenHeight = MediaQuery.sizeOf(context).height;
      final isCompactHeight = screenHeight < 420;
      final horizontal = AdaptiveLayout.horizontalPaddingForWidth(screenWidth);
      final vertical = isCompactHeight ? 24.0 : 48.0;
      final iconExtent = isCompactHeight ? 84.0 : 100.0;
      final iconSize = isCompactHeight ? 40.0 : 48.0;

      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontal,
              vertical: vertical,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconExtent,
                  height: iconExtent,
                  decoration: BoxDecoration(
                    color: AppTheme.billColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: iconSize,
                    color: AppTheme.billColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '暂无账单记录',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '分享消费小票到 RS\n自动识别并记录',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AdaptiveSliverList(
      itemCount: provider.expenses.length,
      itemBuilder: (context, index) {
        final expense = provider.expenses[index];
        final color = AppTheme.getCategoryColor(expense.category);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 分类图标
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // 备注/分类名称和日期
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.note ?? expense.category,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MM月dd日').format(expense.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 金额
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: Text(
                  '¥${expense.amount.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 根据消费分类名称获取对应的图标
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '餐饮':
        return Icons.restaurant_rounded;
      case '交通':
        return Icons.directions_car_rounded;
      case '购物':
        return Icons.shopping_bag_rounded;
      case '娱乐':
        return Icons.sports_esports_rounded;
      case '住房':
        return Icons.home_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
