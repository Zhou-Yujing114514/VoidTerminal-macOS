import 'package:flutter/material.dart';

class AppColors {
  // 深色
  static const vtBg = Color(0xFF0f1117);
  static const vtCard = Color(0xFF171a23);
  static const vtBorder = Color(0xFF262b38);
  static const vtText = Color(0xFFe6e9f0);
  static const vtMuted = Color(0xFF8b93a7);
  static const vtAccent = Color(0xFF4f8cff);
  static const vtGreen = Color(0xFF34c98a);
  static const vtRed = Color(0xFFff5c6c);
  static const vtAmber = Color(0xFFf5b64c);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: dark ? AppColors.vtBg : const Color(0xFFf5f5f0),
    cardColor: dark ? AppColors.vtCard : Colors.white,
    dividerColor: dark ? AppColors.vtBorder : const Color(0xFFe0e0e0),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.vtAccent,
      brightness: brightness,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.vtCard : Colors.white,
      foregroundColor: dark ? AppColors.vtText : const Color(0xFF333333),
      elevation: 0,
    ),
    useMaterial3: true,
  );
}
