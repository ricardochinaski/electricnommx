import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignTokens {
  // Dark Mode Palette (WCAG 2.1 AA)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Light Mode Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Accent (same in both themes)
  static const Color accent = Color(0xFF38BDF8);

  /// Get dynamic colors based on brightness
  static Color getBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkBackground : lightBackground;
  }

  static Color getSurface(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurface : lightSurface;
  }

  static Color getTextPrimary(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  }

  static Color getTextSecondary(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static Color getCardBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(13)
        : const Color(0xFFE2E8F0);
  }

  static Color getBorderColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(20)
        : const Color(0xFFCBD5E1);
  }

  static Color getShadowColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? Colors.black.withAlpha(100)
        : Colors.black.withAlpha(30);
  }

  /// Get typography with dynamic colors
  static TextStyle getDisplay(
    Brightness brightness, {
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: getTextPrimary(brightness),
    );
  }

  static TextStyle getBody(
    Brightness brightness, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: getTextPrimary(brightness),
    );
  }

  static TextStyle getCaption(
    Brightness brightness, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: getTextSecondary(brightness),
    );
  }
}

