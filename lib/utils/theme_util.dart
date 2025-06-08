import 'package:flutter/material.dart';
import '../models/transaction.dart';

class ThemeUtil {
  // 主色调
  static const Color primaryColor = Color(0xFF2E7D32); // 绿色
  static const Color accentColor = Color(0xFF66BB6A);

  // 收入和支出的颜色
  static const Color incomeColor = Color(0xFF2E7D32); // 绿色
  static const Color expenseColor = Color(0xFFD32F2F); // 红色

  // 浅色模式颜色
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightCardColor = Colors.white;
  static const Color lightTextPrimaryColor = Color(0xFF212121);
  static const Color lightTextSecondaryColor = Color(0xFF757575);
  static const Color lightTextLightColor = Color(0xFFBDBDBD);

  // 深色模式颜色
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkTextPrimaryColor = Color(0xFFE0E0E0);
  static const Color darkTextSecondaryColor = Color(0xFFBDBDBD);
  static const Color darkTextLightColor = Color(0xFF757575);

  // 图表颜色
  static const List<Color> chartColors = [
    Color(0xFF2E7D32), // 绿色
    Color(0xFFD32F2F), // 红色
    Color(0xFF1976D2), // 蓝色
    Color(0xFFFFA000), // 琥珀色
    Color(0xFF7B1FA2), // 紫色
    Color(0xFF0097A7), // 青色
    Color(0xFFC2185B), // 粉色
    Color(0xFF00796B), // 蓝绿色
    Color(0xFF5D4037), // 棕色
    Color(0xFF455A64), // 蓝灰色
  ];

  // 获取应用主题
  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: lightBackgroundColor, // Use surface instead of background
        // background: lightBackgroundColor, // Removed deprecated background
        error: expenseColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface:
            lightTextPrimaryColor, // Use onSurface instead of onBackground
        // onBackground: lightTextPrimaryColor, // Removed deprecated onBackground
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      cardTheme: const CardThemeData(
        color: lightCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightTextPrimaryColor),
        titleTextStyle: TextStyle(
          color: lightTextPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: lightTextPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
        displayMedium: TextStyle(
          color: lightTextPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
        displaySmall: TextStyle(
          color: lightTextPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
        bodyLarge: TextStyle(
          color: lightTextPrimaryColor,
          fontSize: 16,
          fontFamily: 'Montserrat',
        ),
        bodyMedium: TextStyle(
          color: lightTextSecondaryColor,
          fontSize: 14,
          fontFamily: 'Montserrat',
        ),
        bodySmall: TextStyle(
          color: lightTextLightColor,
          fontSize: 12,
          fontFamily: 'Montserrat',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCardColor, // Use lightCardColor for light theme
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightTextLightColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightTextLightColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: expenseColor, width: 2),
        ),
        labelStyle: const TextStyle(
          color: lightTextSecondaryColor,
          fontSize: 16,
          fontFamily: 'Montserrat',
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCardColor, // Use lightCardColor for light theme
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextLightColor,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontFamily: 'Montserrat'),
      ),
    );
  }

  // 获取应用深色主题
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: darkBackgroundColor, // Use surface instead of background
        // background: darkBackgroundColor, // Removed deprecated background
        error: expenseColor,
        onPrimary: Colors.white, // Text on primary color
        onSecondary: Colors.white, // Text on accent color
        onSurface:
            darkTextPrimaryColor, // Use onSurface instead of onBackground
        // onBackground: darkTextPrimaryColor, // Removed deprecated onBackground
        onError: Colors.white, // Text on error color
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      cardTheme: const CardThemeData(
        color: darkCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextPrimaryColor),
        titleTextStyle: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
        displayMedium: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
        displaySmall: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
        bodyLarge: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 16,
          fontFamily: 'Montserrat',
        ),
        bodyMedium: TextStyle(
          color: darkTextSecondaryColor,
          fontSize: 14,
          fontFamily: 'Montserrat',
        ),
        bodySmall: TextStyle(
          color: darkTextLightColor,
          fontSize: 12,
          fontFamily: 'Montserrat',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white, // Text on button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor, // Use darkCardColor for dark theme
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkTextLightColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkTextLightColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: accentColor,
            width: 2,
          ), // Use accentColor for focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: expenseColor, width: 2),
        ),
        labelStyle: const TextStyle(
          color: darkTextSecondaryColor,
          fontSize: 16,
          fontFamily: 'Montserrat',
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCardColor, // Use darkCardColor for dark theme
        selectedItemColor: accentColor, // Use accentColor for selected items
        unselectedItemColor: darkTextLightColor,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontFamily: 'Montserrat'),
      ),
    );
  }

  // 获取类别颜色
  static Color getCategoryColor(Category category) {
    // 这里可以根据类别返回不同的颜色，或者从chartColors中选择
    // 为了简单起见，这里只是一个示例，可以根据实际需求进行更复杂的映射
    switch (category) {
      case Category.food:
        return chartColors[0];
      case Category.transportation:
        return chartColors[1];
      case Category.entertainment:
        return chartColors[2];
      case Category.shopping:
        return chartColors[3];
      case Category.utilities:
        return chartColors[4];
      case Category.health:
        return chartColors[5];
      case Category.education:
        return chartColors[6];
      case Category.salary:
        return chartColors[7];
      case Category.gift:
        return chartColors[8];
      case Category.other:
        return chartColors[9];
      case Category.takeout:
        return chartColors[10 % chartColors.length];
      case Category.daily:
        return chartColors[11 % chartColors.length];
      case Category.pets:
        return chartColors[12 % chartColors.length];
      case Category.campus:
        return chartColors[13 % chartColors.length];
      case Category.phone:
        return chartColors[14 % chartColors.length];
      case Category.drinks:
        return chartColors[15 % chartColors.length];
      case Category.study:
        return chartColors[16 % chartColors.length];
      case Category.clothes:
        return chartColors[17 % chartColors.length];
      case Category.internet:
        return chartColors[18 % chartColors.length];
      case Category.snacks:
        return chartColors[19 % chartColors.length];
      case Category.digital:
        return chartColors[20 % chartColors.length];
      case Category.beauty:
        return chartColors[21 % chartColors.length];
      case Category.smoke:
        return chartColors[22 % chartColors.length];
      case Category.sports:
        return chartColors[23 % chartColors.length];
      case Category.travel:
        return chartColors[24 % chartColors.length];
      case Category.water:
        return chartColors[25 % chartColors.length];
      case Category.fastmail:
        return chartColors[26 % chartColors.length];
      case Category.rent:
        return chartColors[27 % chartColors.length];
      case Category.otherExpense:
        return chartColors[28 % chartColors.length];
    }
  }
}
