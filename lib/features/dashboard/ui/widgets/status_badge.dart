import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

/// Registration status badge: Not Registered / Pending / Confirmed.
class DashboardStatusBadge extends StatelessWidget {
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> orders;

  const DashboardStatusBadge({
    super.key,
    required this.hasPurchased,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    // Not purchased -> Not Registered
    // Purchased + any order approved -> Confirmed
    // Purchased + no approved orders -> Pending
    final String label;
    final Color color;
    final IconData icon;

    if (!hasPurchased) {
      label = 'Not Registered';
      color = Colors.grey;
      icon = Icons.info_outline;
    } else {
      final hasApproved = orders.whenOrNull(
            data: (list) =>
                list.any((o) => o.status.toUpperCase() == 'APPROVED'),
          ) ??
          false;

      if (hasApproved) {
        label = 'Confirmed';
        color = AppTheme.successColor;
        icon = Icons.check_circle;
      } else {
        label = 'Pending';
        color = const Color(0xFFFF9800);
        icon = Icons.schedule;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            'Status: $label',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
