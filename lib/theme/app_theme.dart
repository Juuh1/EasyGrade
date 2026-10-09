import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const primary = Color(0xFF7952B9);
  static const primaryDark = Color(0xFF342047);
  static const lavender = Color(0xFFB79AD8);
  static const softPurple = Color(0xFFF0EAF8);
  static const background = Color(0xFFF8F6FA);
  static const pageBackground = Color(0xFFEEE8F4);
  static const surface = Colors.white;
  static const textPrimary = primaryDark;
  static const textSecondary = Color(0xFF766781);
  static const textMuted = Color(0xFF7A6A87);
  static const onDarkSecondary = Color(0xFFD8CDE4);
  static const darkBorder = Color(0xFF583B70);
  static const border = Color(0xFFE7DFEE);
  static const inputBorder = border;
  static const concluidaBg = softPurple;
  static const concluidaFg = primary;
  static const agendadaBg = Color(0xFFFFF2D9);
  static const agendadaFg = Color(0xFF91621C);
  static const rascunhoBg = Color(0xFFF2EFF5);
  static const rascunhoFg = textSecondary;
  static const dangerBg = Color(0xFFFFEEEA);
  static const dangerFg = Color(0xFFB95443);
  static const pillActiveBg = softPurple;
}

class AppRadius {
  AppRadius._();
  static const double sm = 12, md = 18, lg = 26, pill = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
}

class AppBreakpoints {
  AppBreakpoints._();
  static const double compact = 600, medium = 1024, maxContentWidth = 600;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.lavender,
      surface: AppColors.surface,
      error: AppColors.dangerFg,
    ),
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return base.copyWith(
    textTheme: base.textTheme
        .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary)
        .copyWith(
          headlineLarge: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.2,
              color: AppColors.textPrimary),
          headlineMedium: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: AppColors.textPrimary),
          titleLarge: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
              color: AppColors.textPrimary),
          titleMedium: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          bodyMedium: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary),
        ),
    appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 68,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 54),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            elevation: 0,
            shape: shape,
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            minimumSize: const Size(0, 52),
            side: const BorderSide(color: AppColors.border),
            shape: shape,
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700))),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
                fontFamily: 'Manrope', fontWeight: FontWeight.w700))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        selectedColor: AppColors.softPurple,
        backgroundColor: Colors.white,
        labelStyle: const TextStyle(
            fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w600)),
    dividerTheme:
        const DividerThemeData(color: AppColors.border, space: 1, thickness: 1),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: shape),
    datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primaryDark,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        dayShape: const WidgetStatePropertyAll(CircleBorder()),
        todayBorder: const BorderSide(color: AppColors.primary)),
    timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
  );
}
