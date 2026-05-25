import 'package:flutter/material.dart';

class AppColors {
  // Theme Color System
  static const Color primaryMaroon = Color(0xFF6B1C2A); // Maroon
  static const Color secondaryGold = Color(0xFFD4AF37); // Gold
  static const Color warmBrown = Color(0xFF4A2E2B); // Accent dark brown
  static const Color creamBg = Color(0xFFFDFBF7); // Soft background
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color textLight = Color(0xFFFDFBF7);
  static const Color textMuted = Color(0xFF757575);

  // Status Alerts
  static const Color pending = Color(0xFFF2A654); // Soft Orange
  static const Color preparing = Color(0xFF5C93C4); // Blue
  static const Color ready = Color(0xFF68B77D); // Soft Green
  static const Color outOfStock = Color(0xFFD9534F); // Soft Red
  static const Color lowStock = Color(0xFFF2A654); // Warning Orange
  static const Color inStock = Color(0xFF68B77D); // Success green

  // Dark Mode Adjustments
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 12.0;
}

class AppBreakpoints {
  static const double tablet = 640.0;
  static const double desktop = 1024.0;
}

class AppTextStyles {
  static const TextStyle brandHeader = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryMaroon,
    fontFamily: 'serif',
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle currencyLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryMaroon,
  );
}
