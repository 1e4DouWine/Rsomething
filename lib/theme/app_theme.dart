import 'package:flutter/material.dart';

/// RS 智能助手主题配置
/// 设计方向: Soft Luxury - 柔和奢华风格
/// 使用深靛蓝为主色，金色为点缀，营造高级感
class AppTheme {
  // 私有构造函数，防止实例化
  AppTheme._();

  // ==================== 颜色定义 ====================
  
  // 主色调 - 深靛蓝
  static const Color primaryColor = Color(0xFF1A1B4B);
  static const Color primaryLight = Color(0xFF2D2E6B);
  static const Color primaryDark = Color(0xFF0D0E2B);
  
  // 点缀色 - 金色/琥珀
  static const Color accentColor = Color(0xFFD4A574);
  static const Color accentLight = Color(0xFFE8C9A0);
  static const Color accentDark = Color(0xFFB8864E);
  
  // 功能色
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF2196F3);
  
  // 中性色
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color backgroundColor = Color(0xFFF8F9FE);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  // 卡片类型颜色
  static const Color billColor = Color(0xFFFF6B6B);
  static const Color todoColor = Color(0xFF4ECDC4);
  static const Color eventColor = Color(0xFF45B7D1);
  static const Color summaryColor = Color(0xFF96CEB4);
  static const Color unknownColor = Color(0xFF95A5A6);

  // ==================== 亮色主题 ====================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // 配色方案
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        tertiary: accentLight,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      
      // 背景色
      scaffoldBackgroundColor: backgroundColor,
      
      // AppBar主题
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: textPrimary,
        ),
      ),
      
      // 卡片主题
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // 底部导航栏主题
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: accentColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: 'NotoSansSC',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return TextStyle(
            fontFamily: 'NotoSansSC',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: primaryColor,
              size: 24,
            );
          }
          return IconThemeData(
            color: textTertiary,
            size: 24,
          );
        }),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: errorColor),
        ),
        hintStyle: TextStyle(
          fontFamily: 'NotoSansSC',
          color: textTertiary,
          fontSize: 14,
        ),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontFamily: 'NotoSansSC',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
          textStyle: TextStyle(
            fontFamily: 'NotoSansSC',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // FAB主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Chip主题
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: accentColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: dividerColor),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Checkbox主题
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      
      // 文字主题
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textTertiary,
        ),
      ),
    );
  }

  // ==================== 暗色主题 ====================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentLight,
        tertiary: accentDark,
        surface: Color(0xFF1E1E2E),
        error: errorColor,
        onPrimary: primaryDark,
        onSecondary: primaryDark,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: Color(0xFF0D0E1B),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: Color(0xFF1E1E2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E2E),
        elevation: 0,
        height: 65,
        indicatorColor: accentColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: 'NotoSansSC',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            );
          }
          return TextStyle(
            fontFamily: 'NotoSansSC',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: accentColor,
              size: 24,
            );
          }
          return IconThemeData(
            color: Colors.white54,
            size: 24,
          );
        }),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF252540),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        hintStyle: TextStyle(
          fontFamily: 'NotoSansSC',
          color: Colors.white38,
          fontSize: 14,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: primaryDark,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: primaryDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -1,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white70,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.white54,
          height: 1.5,
        ),
      ),
    );
  }
  
  // ==================== 工具方法 ====================
  
  /// 获取记忆类型对应的颜色
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
  
  /// 获取分类对应的颜色
  static Color getCategoryColor(String category) {
    switch (category) {
      case '餐饮':
        return Color(0xFFFF6B6B);
      case '交通':
        return Color(0xFF4ECDC4);
      case '购物':
        return Color(0xFFFFBE76);
      case '娱乐':
        return Color(0xFFA29BFE);
      case '住房':
        return Color(0xFF6C5CE7);
      default:
        return Color(0xFF95A5A6);
    }
  }
}