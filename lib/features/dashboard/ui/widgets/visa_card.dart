import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'card_helpers.dart';

/// Dashboard card showing visa application statuses in a 2x2 grid.
class DashboardVisaCard extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final bool hasPurchased;
  final AsyncValue<List<Map<String, dynamic>>> visas;

  const DashboardVisaCard({
    super.key,
    required this.eventId,
    required this.isMobile,
    required this.hasPurchased,
    required this.visas,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      child: visas.when(
        loading: () => const DashboardCardLoading(),
        error: (_, __) => const DashboardCardError(message: 'Failed to load'),
        data: (list) {
          final counts = _countStatuses(list);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: Color(0xFF5C6BC0), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Visa Status',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 2x2 status grid
              Row(
                children: [
                  _VisaStatusChip(
                      label: 'Pending', count: counts['pending']!),
                  const SizedBox(width: 12),
                  _VisaStatusChip(
                      label: 'Fill out', count: counts['fill_out']!),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _VisaStatusChip(
                      label: 'Confirmed', count: counts['confirmed']!),
                  const SizedBox(width: 12),
                  _VisaStatusChip(
                      label: 'Declined', count: counts['declined']!),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (!hasPurchased) {
                      AppSnackBar.showInfo(context,
                          'Purchase a service package to unlock this feature');
                      return;
                    }
                    context.go('/events/$eventId/visa-travel');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        hasPurchased ? AppTheme.primaryColor : Colors.grey,
                    side: BorderSide(
                        color: hasPurchased
                            ? AppTheme.primaryColor
                            : Colors.grey),
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

  Map<String, int> _countStatuses(List<Map<String, dynamic>> list) {
    int pending = 0, fillOut = 0, confirmed = 0, declined = 0;
    for (final v in list) {
      final s = (v['status'] ?? '').toString().toUpperCase();
      switch (s) {
        case 'PENDING':
        case 'SUBMITTED':
          pending++;
          break;
        case 'FILL_OUT':
        case 'DRAFT':
        case '':
          fillOut++;
          break;
        case 'CONFIRMED':
        case 'APPROVED':
          confirmed++;
          break;
        case 'DECLINED':
        case 'REJECTED':
          declined++;
          break;
      }
    }
    return {
      'pending': pending,
      'fill_out': fillOut,
      'confirmed': confirmed,
      'declined': declined,
    };
  }
}

class _VisaStatusChip extends StatelessWidget {
  final String label;
  final int count;

  const _VisaStatusChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
