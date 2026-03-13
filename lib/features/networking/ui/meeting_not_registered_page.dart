import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// Page shown when user tries to access Meetings without a purchased service.
/// Renders inside EventShellLayout (no Scaffold needed).
class MeetingNotRegisteredPage extends StatelessWidget {
  final String eventId;

  const MeetingNotRegisteredPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 20),
              Text(
                'Purchase Required',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You need to purchase a service package for this event to access the Meetings section.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/events/$eventId/services');
                },
                style: AppTheme.primaryButtonStyle,
                child: const Text('Browse Services'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
