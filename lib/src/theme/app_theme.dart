import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFAE0F0A);
  static const Color secondaryColor = Color(0xFF8B0000);
  static const Color backgroundColor = Color.fromARGB(255, 240, 240, 240);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF1C1B1F);
  static const Color textSecondaryColor = Color(0xFF49454F);

  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.light).copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      surface: surfaceColor,
      onSurface: textPrimaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: cs.primary,
      canvasColor: cs.surface,
      iconTheme: IconThemeData(color: cs.onSurface),
      textTheme: TextTheme(
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: cs.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: cs.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: cs.surface,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF2F2F2),
        selectedColor: cs.primary,
        labelStyle: const TextStyle(color: Colors.black),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        brightness: Brightness.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: const BorderSide(color: Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color.fromARGB(255, 238, 238, 238),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.surface),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final ColorScheme cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF101014),
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: const Color(0xFFB33A3A),
      onSurface: Colors.white70,
      surfaceContainerHighest: const Color(0xFF161618),
      outline: Colors.white12,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0B0D),
      primaryColor: cs.primary,
      canvasColor: cs.surface,
      iconTheme: const IconThemeData(color: Colors.white70),
      textTheme: TextTheme(
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.92)),
        bodySmall: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.78)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 1,
        centerTitle: true,
        surfaceTintColor: cs.surfaceContainerHighest,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.surfaceContainerHighest.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(TextStyle(color: cs.onSurface, fontSize: 13)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: Colors.white60,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline.withValues(alpha: 0.16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: cs.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        contentTextStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.92)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.95)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: cs.outline.withValues(alpha: 0.12),
      
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white70,
        tileColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
