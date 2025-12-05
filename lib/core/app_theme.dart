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
    fontSize: 32, // Reduced from 36 per previous refinements
    color: AppColors.textPrimary,
  );

  // Form Labels & Inputs
  static TextStyle get label => GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: Colors.black, // or AppColors.textPrimary
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
