import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFFF6F6F4);
  static const card = Color(0xFFFFFFFF);
  static const primaryText = Color(0xFF111111);
  static const secondaryText = Color(0xFF8A8A8A);
  static const accent = Color(0xFF8B7EF6);
  static const accentLight = Color(0xFFE8E5FF);
  static const shadow = Color(0x26000000);
  static const reading = Color(0xFF4CAF50);
  static const onHold = Color(0xFFFFA726);
  static const completed = Color(0xFF42A5F5);
  static const planned = Color(0xFFAB47BC);
  static const dropped = Color(0xFFEF5350);
  static const caughtUp = Color(0xFF66BB6A);
  static const newChapter = Color(0xFFFF7043);
  static const progressBg = Color(0xFFE0E0E0);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        surface: AppColors.card,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
          height: 1.3,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryText,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryText,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryText,
          height: 1.3,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class AppRadius {
  static const double card = 32;
  static const double image = 20;
  static const double pill = 100;
  static const double button = 30;
}

class AppShadows {
  static List<BoxShadow> get card {
    return [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> get subtle {
    return [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 12,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
