import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Gradients
  static const Color gradientStart = Color(0xFF3C4494);
  static const Color gradientEnd = Color(0xFF232859);

  // Backgrounds
  static const Color cardBackground = Color(0xFFF1F1F6);
  static const Color flagBackground = Color(0xFFE6E5E5);

  // Text Colors
  static const Color textPrimary = Color(0xFF231C1C);
  static const Color textSecondary = Color(0x80231C1C); // 50% opacity
  static const Color textPlaceholder = Color(0x80000000); // 50% black
  static const Color textFooter = Colors.black;

  // UI Elements
  static const Color buttonBackground = Color(0xFF4159CF);
  static const Color buttonText = Colors.white;
  static const Color inputBorder = Color(0xFFB7B7B7);
  static const Color checkboxBorder = Color(0xFF6D6A6A); // or 231C1C for active
  static const Color checkboxActive = Color(0xFF231C1C);
}

class AppTextStyles {
  // Titles
  static TextStyle get titleLargeMobile => GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 28,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleLargeDesktop => GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 32,
    color: AppColors.textPrimary,
  );

  // Form Labels & Inputs
  static TextStyle get label => GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: Colors.black,
  );

  static TextStyle get placeholder => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textPlaceholder,
  );

  static TextStyle get inputText => const TextStyle(fontSize: 14);

  // Buttons
  static TextStyle get buttonText => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: AppColors.buttonText,
  );

  static TextStyle get buttonTextLarge => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 22,
    color: AppColors.buttonText,
  );

  // Footer & Misc
  static TextStyle get rememberMe => GoogleFonts.roboto(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static TextStyle get dontHaveAccount => GoogleFonts.roboto(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static TextStyle get footer => GoogleFonts.nunitoSans(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: AppColors.textFooter,
  );
}

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

  // Animation Constants
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
  static const Curve animCurve = Curves.easeInOut;

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
    // Smooth page transitions on all platforms
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
