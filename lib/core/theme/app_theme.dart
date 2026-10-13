import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna AdaptiLearn (mode terang).
abstract final class AppColors {
  static const Color primary = Color(0xFF1B8A5A);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFCDEEDC);
  static const Color onPrimaryContainer = Color(0xFF0B3D27);

  static const Color secondary = Color(0xFFFFC107);
  static const Color onSecondary = Color(0xFF3A2E00);
  static const Color secondaryContainer = Color(0xFFFFECB3);

  static const Color background = Color(0xFFF7FAF8);
  static const Color surface = Colors.white;
  static const Color onSurface = Color(0xFF14201A);

  static const Color error = Color(0xFFD32F2F);
  static const Color onError = Colors.white;
}

/// Tema bersama AdaptiLearn (Material 3, mode terang).
///
/// - Judul memakai Poppins, isi memakai Inter.
/// - Teks isi minimal 16 sp.
/// - Tombol minimal tinggi 48 dp.
abstract final class AppTheme {
  static const double buttonMinHeight = 48;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
        onError: AppColors.onError,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final poppins = GoogleFonts.poppinsTextTheme();
    final inter = GoogleFonts.interTextTheme();

    final textTheme = base.textTheme.copyWith(
      displayLarge: poppins.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium:
          poppins.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: poppins.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge:
          poppins.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium:
          poppins.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall:
          poppins.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: poppins.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: poppins.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: poppins.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: inter.bodyLarge?.copyWith(fontSize: 18, height: 1.5),
      bodyMedium: inter.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
      bodySmall: inter.bodySmall?.copyWith(fontSize: 14, height: 1.4),
      labelLarge: inter.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: inter.labelMedium?.copyWith(fontSize: 14),
      labelSmall: inter.labelSmall?.copyWith(fontSize: 12),
    );

    const buttonMinSize = Size(48, buttonMinHeight);
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    final buttonTextStyle = inter.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: inter.labelMedium?.copyWith(fontSize: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonMinSize,
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonMinSize,
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: inter.bodyMedium?.copyWith(fontSize: 16),
        hintStyle: inter.bodyMedium?.copyWith(
          fontSize: 16,
          color: Colors.grey.shade600,
        ),
        errorStyle: inter.bodySmall?.copyWith(
          fontSize: 14,
          color: AppColors.error,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
