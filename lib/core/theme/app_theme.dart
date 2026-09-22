import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette « YMS Premium » inspirée de la maquette :
/// brun profonde, crème, doré.
abstract final class AppColors {
  static const brown950 = Color(0xFF1E140B);
  static const brown900 = Color(0xFF2C1D11);
  static const brown800 = Color(0xFF40291A);
  static const brown700 = Color(0xFF5A3B24);

  static const cream = Color(0xFFFBF7F0);
  static const white = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFEFE8D9);

  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE9D28F);

  static const ink = Color(0xFF241A12);
  static const muted = Color(0xFF8C7B6B);

  static const ok = Color(0xFF3E7C5A);
  static const okBg = Color(0xFFE4F0E7);
  static const warn = Color(0xFFB4892A);
  static const warnBg = Color(0xFFFBF0CF);
  static const danger = Color(0xFFB0483C);
  static const dangerBg = Color(0xFFF6E4E1);
  static const mutedBg = Color(0xFFEFE8D9);

  static const iconBgBrown = Color(0xFFF1E9D9);
  static const inputFill = Color(0xFFD1CFC9);
}

/// Espacements homogènes de l'application.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const page = 22.0;
}

/// Formatage des montants (Ariary) et dates (fr).
abstract final class AppFormat {
  static String ar(double amount) {
    final whole = amount.round();
    final digits = whole.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return '$digits Ar';
  }

  static String date(DateTime? d, {bool full = false}) {
    if (d == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    if (full) {
      const months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    }
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  static String duree(int heures) =>
      heures >= 60 ? '${(heures / 60).toStringAsFixed(1)} mois' : '$heures h';
}

/// Thème premium de l'application : brun / crème / or.
abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brown900,
      onPrimary: AppColors.cream,
      secondary: AppColors.gold,
      onSecondary: AppColors.brown950,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.brown900,
        titleTextStyle: TextStyle(
          fontFamily: 'Cormorant Garamond',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.brown900,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brown900,
          foregroundColor: AppColors.cream,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brown900,
          side: const BorderSide(color: AppColors.brown900, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.gold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        errorStyle: const TextStyle(height: 0.8, fontSize: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF9E9E9E), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.brown900, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brown950,
        contentTextStyle: TextStyle(color: AppColors.cream, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
        elevation: 6,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.okBg,
        labelStyle: const TextStyle(
          color: AppColors.ok,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    final serif = GoogleFonts.cormorantGaramondTextTheme(base);
    final sans = GoogleFonts.manropeTextTheme(base);
    return base.copyWith(
      displaySmall: serif.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.brown900,
      ),
      headlineSmall: serif.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.brown900,
      ),
      titleLarge: sans.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.brown900,
      ),
      titleMedium: sans.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.brown900,
      ),
      titleSmall: sans.titleSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.brown900,
      ),
      bodyLarge: sans.bodyLarge?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: AppColors.ink,
      ),
      bodyMedium: sans.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.45,
        color: AppColors.ink,
      ),
      bodySmall: sans.bodySmall?.copyWith(
        fontSize: 11.5,
        color: AppColors.muted,
      ),
      labelLarge: sans.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}