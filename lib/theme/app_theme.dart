import 'package:flutter/material.dart';

/// Uygulamanın renk paleti ve tema tanımları.
class AppColors {
  static const Color mor = Color(0xFF6C4DF6);
  static const Color morAcik = Color(0xFF9A86FD);
  static const Color camgobegi = Color(0xFF22D3EE);
  static const Color yesil = Color(0xFF34D399);
  static const Color amber = Color(0xFFFBBF24);
  static const Color kirmizi = Color(0xFFF87171);

  /// Ana ekran / tarama arka planı için marka gradyanı.
  static const List<Color> markaGradyan = [
    Color(0xFF6C4DF6),
    Color(0xFF8B5CF6),
    Color(0xFF22D3EE),
  ];

  static const List<Color> koyuArkaplan = [
    Color(0xFF0F1020),
    Color(0xFF16172E),
    Color(0xFF1B1235),
  ];

  static const List<Color> acikArkaplan = [
    Color(0xFFF3F1FF),
    Color(0xFFEAF7FF),
    Color(0xFFF7F3FF),
  ];
}

class AppTheme {
  static ThemeData _base(Brightness brightness, Color bg) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.mor,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1430),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: isDark ? Colors.white : const Color(0xFF1A1430),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.75),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get dark =>
      _base(Brightness.dark, AppColors.koyuArkaplan.first);

  static ThemeData get light =>
      _base(Brightness.light, AppColors.acikArkaplan.first);
}
