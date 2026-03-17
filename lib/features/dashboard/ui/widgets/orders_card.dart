import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import 'card_helpers.dart';

/// Dashboard card showing purchased services count with view button.
class DashboardOrdersCard extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final AsyncValue<List<dynamic>> orders;

  const DashboardOrdersCard({
    super.key,
    required this.eventId,
    required this.isMobile,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      child: orders.when(
        loading: () => const DashboardCardLoading(),
        error: (_, __) => const DashboardCardError(message: 'Failed to load'),
        data: (list) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: Color(0xFF66BB6A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Services & Orders',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${list.length} Service${list.length == 1 ? '' : 's'} Purchased',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/events/$eventId/services'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
