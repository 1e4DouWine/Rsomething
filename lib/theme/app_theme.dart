import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFF1A1B4B);

  static const Color billColor = Color(0xFFFF6B6B);
  static const Color todoColor = Color(0xFF4ECDC4);
  static const Color eventColor = Color(0xFF45B7D1);
  static const Color summaryColor = Color(0xFF96CEB4);
  static const Color unknownColor = Color(0xFF95A5A6);

  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF2196F3);

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
