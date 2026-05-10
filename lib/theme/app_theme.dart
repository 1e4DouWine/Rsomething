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

  /// 错误/危险状态颜色
  static const Color errorColor = Color(0xFFE53935);

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
