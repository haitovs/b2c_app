import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// A dashboard summary card with an icon, title, and value.
///
/// Designed to be placed inside a responsive grid. Features a coloured icon
/// circle, a descriptive title, and a prominent value. The entire card is
/// optionally tappable.
///
/// ```dart
/// SummaryCard(
///   icon: Icons.event,
///   title: 'Events',
///   value: '12',
///   iconColor: Colors.orange,
///   onTap: () => context.go('/events'),
/// )
/// ```
class SummaryCard extends StatelessWidget {
  /// Icon displayed inside the coloured circle.
  final IconData icon;

  /// Short descriptive title (e.g. "Total Orders").
  final String title;

  /// The prominent value displayed below the title (e.g. "128").
  final String value;

  /// Callback invoked when the card is tapped. When `null` the card has no
  /// ink-splash effect.
  final VoidCallback? onTap;

  /// Background colour for the icon circle. Defaults to [AppTheme.primaryColor].
  final Color? iconColor;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppTheme.primaryColor;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: effectiveIconColor, size: 24),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Value
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
