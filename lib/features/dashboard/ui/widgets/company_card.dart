import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'card_helpers.dart';

/// Dashboard card showing company info with edit button.
class DashboardCompanyCard extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> companies;

  const DashboardCompanyCard({
    super.key,
    required this.eventId,
    required this.isMobile,
    required this.hasPurchased,
    required this.companies,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      child: companies.when(
        loading: () => const DashboardCardLoading(),
        error: (_, __) => const DashboardCardError(message: 'Failed to load'),
        data: (list) {
          final company = list.isNotEmpty ? list.first : null;
          final logoUrl = company?.brandIconUrl;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: logoUrl != null
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.business_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          )
                        : Icon(
                            Icons.business_outlined,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'My Company',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                company?.name ?? 'Not set up yet',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                    context.go('/events/$eventId/company-profile');
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
                    'Edit',
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
