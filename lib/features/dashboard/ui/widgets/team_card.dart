import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'card_helpers.dart';

/// Dashboard card showing team member count with manage button.
class DashboardTeamCard extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> teamMembers;

  const DashboardTeamCard({
    super.key,
    required this.eventId,
    required this.isMobile,
    required this.hasPurchased,
    required this.teamMembers,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      child: teamMembers.when(
        loading: () => const DashboardCardLoading(),
        error: (_, __) => const DashboardCardError(message: 'Failed to load'),
        data: (members) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.groups_outlined,
                      color: Color(0xFF42A5F5), size: 22),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Team Members',
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
              '${members.length} Member${members.length == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!hasPurchased) {
                    AppSnackBar.showInfo(context,
                        'Purchase a service package to unlock this feature');
                    return;
                  }
                  context.go('/events/$eventId/team');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasPurchased ? AppTheme.successColor : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Manage',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
