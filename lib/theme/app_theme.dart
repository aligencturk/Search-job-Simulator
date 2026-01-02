import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData theme() {
    final textTheme = _getTextTheme();
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

    return _buildTheme(colorScheme, textTheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, TextTheme textTheme) {
    RoundedRectangleBorder roundedShape([double radius = 10]) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: roundedShape(10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: roundedShape(10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: roundedShape(10),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: roundedShape(8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: roundedShape(16),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
      cardTheme: CardThemeData(
        shape: roundedShape(12),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData.fromDefaults(
        secondaryColor: colorScheme.secondary,
        brightness: Brightness.light,
        labelStyle: textTheme.labelLarge ?? const TextStyle(),
      ).copyWith(
        shape: roundedShape(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      dialogTheme: DialogThemeData(
        shape: roundedShape(14),
        backgroundColor: colorScheme.surface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: roundedShape(12),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  static TextTheme _getTextTheme() {
    try {
      return GoogleFonts.poppinsTextTheme();
    } catch (_) {
      return const TextTheme();
    }
  }
}




