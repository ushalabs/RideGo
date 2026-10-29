import 'package:flutter/material.dart';

/// Design tokens extracted directly from Figma reference designs for RideGo.
class AppColors {
  // Brand Primary & Backgrounds
  static const Color background = Color(
    0xFF8FB8DE,
  ); // Light Sky Blue background
  static const Color headerNavy = Color(0xFF1E3A5F); // Dark Navy header
  static const Color headerDarker = Color(
    0xFF152A45,
  ); // Deeper navy for bottom nav / dark bars
  static const Color buttonTeal = Color(0xFF126E82); // Dark Teal CTA buttons
  static const Color buttonTealPressed = Color(0xFF0D5363);
  static const Color accentCyan = Color(0xFF48CAE4); // Bright cyan accents

  // Surface & Cards
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardSubtle = Color(0xFFF6F9FD);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFC8DCF0);
  static const Color divider = Color(0xFFD6E4F0);

  // Text colors
  static const Color textPrimary = Color(
    0xFF1B2D45,
  ); // Dark text on light surfaces
  static const Color textSecondary = Color(0xFF5A7184);
  static const Color textMuted = Color(0xFF8C9BA5);
  static const Color textOnNavy = Color(0xFFFFFFFF); // White text on dark navy
  static const Color textOnNavySubtle = Color(0xFFADC6E0);

  // Status Colors
  static const Color statusConfirmed = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusCompleted = Color(0xFF3B82F6);

  // Star Rating
  static const Color starGold = Color(0xFFFBBF24);

  // Category Icon Backgrounds
  static const Color categoryPillActive = Color(0xFF126E82);
  static const Color categoryPillInactive = Color(0xFFFFFFFF);
}
