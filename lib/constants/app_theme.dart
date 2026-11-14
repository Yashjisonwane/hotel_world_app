import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
      fontFamilyFallback: const ['Roboto', 'Noto Sans', 'Arial', 'sans-serif'],
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamilyFallback: const ['Roboto', 'Noto Sans', 'Arial', 'sans-serif'],
      primaryColor: AppColors.primary500,
      scaffoldBackgroundColor: AppColors.slate50,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary500,
        primaryContainer: AppColors.primary100,
        secondary: AppColors.slate800,
        secondaryContainer: AppColors.slate100,
        surface: AppColors.white,
        error: AppColors.error,
        onPrimary: AppColors.slate950,
        onSecondary: AppColors.white,
        onSurface: AppColors.slate900,
        onError: AppColors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.slate950,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.slate900,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.slate800,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.slate800,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.slate700,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.slate500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.slate950,
        foregroundColor: AppColors.primary400,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.primary400,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary400),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1,
        shadowColor: AppColors.slate950.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.slate200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.slate300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.slate300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.slate600),
        hintStyle: const TextStyle(color: AppColors.slate400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: AppColors.slate950,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate800,
          side: const BorderSide(color: AppColors.slate300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate200,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
