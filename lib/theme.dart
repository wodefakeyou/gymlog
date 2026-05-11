import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // Brand colors
  static const Color primary    = Color(0xFF6C63FF);
  static const Color green      = Color(0xFF34D399);
  static const Color teal       = Color(0xFF22D3EE);
  static const Color amber      = Color(0xFFF59E0B);
  static const Color red        = Color(0xFFEF4444);

  // Surface palette
  static const Color background = Color(0xFF07090E);
  static const Color surface    = Color(0xFF0F1218);
  static const Color card       = Color(0xFF141B26);
  static const Color border     = Color(0xFF1E2535);

  // Text
  static const Color textPrimary   = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF374151);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: teal,
        surface: surface,
        error: red,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: border,
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: textPrimary,   fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.5),
        titleLarge:    TextStyle(color: textPrimary,   fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium:   TextStyle(color: textPrimary,   fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall:    TextStyle(color: textPrimary,   fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge:     TextStyle(color: textPrimary,   fontSize: 15),
        bodyMedium:    TextStyle(color: textSecondary, fontSize: 13),
        labelSmall:    TextStyle(color: textSecondary, fontSize: 11, letterSpacing: 0.6),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        height: 64,
        elevation: 0,
        indicatorColor: primary.withOpacity(0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: textSecondary, fontSize: 11);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: primary.withOpacity(0.2),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        side: const BorderSide(color: border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Reusable card decoration
BoxDecoration cardDecoration({Color? borderColor, bool highlight = false}) {
  return BoxDecoration(
    color: AppTheme.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: highlight ? AppTheme.primary.withOpacity(0.4) : (borderColor ?? AppTheme.border),
      width: highlight ? 1.0 : 0.5,
    ),
  );
}

// Muscle group Chinese labels
const Map<String, String> muscleLabels = {
  'chest':     '胸肌',
  'back':      '背部',
  'legs':      '腿部',
  'shoulders': '肩膀',
  'biceps':    '二头肌',
  'triceps':   '三头肌',
  'core':      '核心',
  'cardio':    '有氧',
};

// Muscle group accent colors
const Map<String, Color> muscleColors = {
  'chest':     AppTheme.primary,
  'back':      AppTheme.teal,
  'legs':      AppTheme.green,
  'shoulders': AppTheme.amber,
  'biceps':    Color(0xFFF472B6),
  'triceps':   Color(0xFFA78BFA),
  'core':      Color(0xFF60A5FA),
  'cardio':    Color(0xFFFB923C),
};
