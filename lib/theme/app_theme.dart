import 'package:flutter/material.dart';

class AppColors {
  // Primary greens - vitality, fresh, clean
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySoft = Color(0xFFE8F5E9);
  static const Color primaryMuted = Color(0xFFA5D6A7);

  // Neutrals
  static const Color background = Color(0xFFF8FAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color(0xCCFFFFFF);
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFB0B0B0);
  static const Color border = Color(0xFFE8E8E8);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color shadow = Color(0x0A000000);

  // Accents
  static const Color accent = Color(0xFFFF6B35);
  static const Color error = Color(0xFFE53935);
  static const Color star = Color(0xFFFFB300);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          indicatorColor: AppColors.primarySoft,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              );
            }
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            );
          }),
        ),
      );
}

// Glassmorphism decoration
class GlassDecoration {
  static BoxDecoration card({double opacity = 0.8, double blur = 10}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration pill() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration header() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2E7D32),
          Color(0xFF388E3C),
          Color(0xFF43A047),
        ],
      ),
    );
  }
}
