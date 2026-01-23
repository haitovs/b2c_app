import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized app theme and styling
class AppTheme {
  // Brand Colors
  static const primaryColor = Color(0xFF3C4494);
  static const backgroundColor = Color(0xFFF1F1F6);
  static const cardColor = Colors.white;
  static const errorColor = Color(0xFFE74C3C);
  static const successColor = Color(0xFF3BAC3B);

  // Input Decoration Theme
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
    hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
  );

  // Text Styles
  static TextStyle get heading1 => GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static TextStyle get heading2 => GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static TextStyle get bodyText =>
      GoogleFonts.inter(fontSize: 16, color: Colors.black87);

  static TextStyle get labelText => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
  );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
  );

  // Full Theme
  static ThemeData get theme => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    inputDecorationTheme: inputDecorationTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
    textTheme: TextTheme(
      displayLarge: heading1,
      displayMedium: heading2,
      bodyLarge: bodyText,
      labelLarge: labelText,
    ),
  );
}
