import 'package:flutter/material.dart';

// Cores
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF8B1D3F);
  static const Color primaryDark = Color(0xFF6E1732);

  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1F2023);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color border = Color(0xFFE5E7EB);
  static const Color inputBorder = Color(0xFFD1D5DB);

  // Status
  static const Color concluidaBg = Color(0xFFDCFCE7);
  static const Color concluidaFg = Color(0xFF16A34A);

  static const Color agendadaBg = Color(0xFFFDEBD3);
  static const Color agendadaFg = Color(0xFFB45309);

  static const Color rascunhoBg = Color(0xFFEEEFF1);
  static const Color rascunhoFg = Color(0xFF6B7280);

  // Destaques e alertas
  static const Color brandCoral = Color(0xFFE5283B);
  static const Color brandNavy = Color(0xFF103A58);
  static const Color brandGold = Color(0xFFF5A623);

  static const Color dangerBg = Color(0xFFFCE8E8);
  static const Color dangerFg = Color(0xFFDC2626);

  static const Color pillActiveBg = Color(0xFFFCE8E8);
}

// Raios de borda
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

// Espaçamentos
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

// Breakpoints
class AppBreakpoints {
  AppBreakpoints._();
  static const double compact = 600; // celular
  static const double medium = 1024; // tablet
  static const double maxContentWidth = 480; // largura "mobile" de referência
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.inputBorder),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
  );
}
