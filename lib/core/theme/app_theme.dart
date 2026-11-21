import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Tinggi minimum target sentuh (AGENTS.md: minimal 44x44 dp).
const double kMinTouchTarget = 44;

/// Tinggi field dan tombol utama sesuai mockup.
const double kControlHeight = 48;

const double kRadius = 12;

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    secondary: AppColors.out,
    onSecondary: AppColors.white,
    error: AppColors.error,
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.ink,
    outline: AppColors.lineStrong,
    outlineVariant: AppColors.line,
  );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadius),
    borderSide: const BorderSide(color: AppColors.line),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    dividerColor: AppColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyLarge: TextStyle(fontSize: 15, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.ink),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.muted),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      hintStyle: const TextStyle(color: AppColors.subtle),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kControlHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kControlHeight),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.lineStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
