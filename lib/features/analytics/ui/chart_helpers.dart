import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';

/// Color palette for chart segments — distinct, accessible colors.
const List<Color> chartPalette = [
  Color(0xFF3C4494), // primary
  Color(0xFF4CAF50), // green
  Color(0xFFF9A825), // amber
  Color(0xFFE74C3C), // red
  Color(0xFF26C6DA), // cyan
  Color(0xFFAB47BC), // purple
  Color(0xFFFF7043), // deep orange
  Color(0xFF5C6BC0), // indigo
  Color(0xFF66BB6A), // light green
  Color(0xFF8D6E63), // brown
];

Color chartColor(int index) => chartPalette[index % chartPalette.length];

/// Standard tooltip text style.
TextStyle tooltipStyle() => GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );

/// Standard axis label style.
TextStyle axisLabelStyle() => GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    );

/// Format a date for x-axis labels (e.g., "Mar 14").
String formatAxisDate(DateTime d) => DateFormat('MMM d').format(d);

/// Format number with comma separator (e.g., 1,234).
String formatNumber(num n) => NumberFormat('#,##0').format(n);

/// Format USD amount (e.g., \$1,234.50).
String formatUsd(double n) => NumberFormat.currency(symbol: '\$').format(n);
