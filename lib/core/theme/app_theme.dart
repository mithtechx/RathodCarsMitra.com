import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgCream,
      primaryColor: AppColors.primaryOrange,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOrange,
        surface: AppColors.bgCream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}