import 'package:flutter/material.dart';

/// 应用主题配置类
///
/// 定义全局颜色常量和 Material 3 主题配置。
/// 支持亮色和暗色两套主题，所有颜色均基于种子色 [seedColor] 生成。
class AppTheme {
  /// 私有构造函数（纯工具类，禁止实例化）
  AppTheme._();

  /// 主题种子色（深蓝色）
  static const Color seedColor = Color(0xFF1A1B4B);

  // ==================== 记忆类型颜色 ====================
  /// 账单类型颜色
  static const Color billColor = Color(0xFFFF6B6B);

  /// 待办类型颜色
  static const Color todoColor = Color(0xFF4ECDC4);

  /// 日程类型颜色
  static const Color eventColor = Color(0xFF45B7D1);

  /// 摘要类型颜色
  static const Color summaryColor = Color(0xFF96CEB4);

  /// 未知类型颜色
  static const Color unknownColor = Color(0xFF95A5A6);

  // ==================== 状态颜色 ====================
  /// 成功/确认状态颜色
  static const Color successColor = Color(0xFF4CAF50);

  /// 警告/待处理状态颜色
  static const Color warningColor = Color(0xFFFF9800);

  /// 信息提示颜色
  static const Color infoColor = Color(0xFF2196F3);

  /// 亮色主题配置
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      fontFamily: 'NotoSansSC',
      extensions: const [AppColors.light],
    );
  }

  /// 暗色主题配置
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      fontFamily: 'NotoSansSC',
      extensions: const [AppColors.dark],
    );
  }

  /// 根据记忆类型字符串获取对应颜色
  static Color getMemoryTypeColor(String type) {
    switch (type) {
      case 'bill':
        return billColor;
      case 'todo':
        return todoColor;
      case 'event':
        return eventColor;
      case 'summary':
        return summaryColor;
      default:
        return unknownColor;
    }
  }

  /// 根据消费分类名称获取对应颜色
  /// 用于账本页面的分类统计图表
  static Color getCategoryColor(String category) {
    switch (category) {
      case '餐饮':
        return const Color(0xFFFF6B6B);
      case '交通':
        return const Color(0xFF4ECDC4);
      case '购物':
        return const Color(0xFFFFBE76);
      case '娱乐':
        return const Color(0xFFA29BFE);
      case '住房':
        return const Color(0xFF6C5CE7);
      default:
        return const Color(0xFF95A5A6);
    }
  }
}

/// 应用自定义颜色扩展（ThemeExtension）
///
/// 通过 Theme.of(context).extension\<AppColors\>() 访问，
/// 确保自定义颜色在亮色/暗色模式下自动适配。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.billColor,
    required this.todoColor,
    required this.eventColor,
    required this.summaryColor,
    required this.unknownColor,
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
  });

  final Color billColor;
  final Color todoColor;
  final Color eventColor;
  final Color summaryColor;
  final Color unknownColor;
  final Color successColor;
  final Color warningColor;
  final Color infoColor;

  static const light = AppColors(
    billColor: Color(0xFFFF6B6B),
    todoColor: Color(0xFF4ECDC4),
    eventColor: Color(0xFF45B7D1),
    summaryColor: Color(0xFF96CEB4),
    unknownColor: Color(0xFF95A5A6),
    successColor: Color(0xFF4CAF50),
    warningColor: Color(0xFFFF9800),
    infoColor: Color(0xFF2196F3),
  );

  static const dark = AppColors(
    billColor: Color(0xFFFF8A80),
    todoColor: Color(0xFF64FFDA),
    eventColor: Color(0xFF80DEEA),
    summaryColor: Color(0xFFA5D6A7),
    unknownColor: Color(0xFFB0BEC5),
    successColor: Color(0xFF66BB6A),
    warningColor: Color(0xFFFFB74D),
    infoColor: Color(0xFF64B5F6),
  );

  @override
  AppColors copyWith({
    Color? billColor,
    Color? todoColor,
    Color? eventColor,
    Color? summaryColor,
    Color? unknownColor,
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
  }) {
    return AppColors(
      billColor: billColor ?? this.billColor,
      todoColor: todoColor ?? this.todoColor,
      eventColor: eventColor ?? this.eventColor,
      summaryColor: summaryColor ?? this.summaryColor,
      unknownColor: unknownColor ?? this.unknownColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      billColor: Color.lerp(billColor, other.billColor, t)!,
      todoColor: Color.lerp(todoColor, other.todoColor, t)!,
      eventColor: Color.lerp(eventColor, other.eventColor, t)!,
      summaryColor: Color.lerp(summaryColor, other.summaryColor, t)!,
      unknownColor: Color.lerp(unknownColor, other.unknownColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
    );
  }
}
