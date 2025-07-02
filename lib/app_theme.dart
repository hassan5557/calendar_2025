// app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF1B191A);
  static const Color eventDeletedColor = Color.fromARGB(255, 132, 70, 65);

  // ignore: prefer_typing_uninitialized_variables
  static var dialogBackgroundColor;

  static ThemeData get customDarkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.dark(
        primary: Colors.blueAccent,
        onPrimary: Colors.white,
        surface: backgroundColor,
        onSurface: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      cardColor: Colors.grey[850], dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF242424)),
    );
  }

  static SystemUiOverlayStyle get systemOverlayStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    );
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'delay':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  static Color getStatusButtonColor(String? status) {
    if (status == null) return Colors.grey[700]!;
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'delay':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey[700]!;
    }
  }
}