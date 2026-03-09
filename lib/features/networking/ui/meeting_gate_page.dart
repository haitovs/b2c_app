import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../registration/providers/registration_providers.dart';
import 'meeting_not_registered_page.dart';
import 'meetings_page.dart';

/// Gate that checks if user is registered before showing meetings
/// If not registered, shows the registration required page
class MeetingGatePage extends ConsumerStatefulWidget {
  final String eventId;

  const MeetingGatePage({super.key, required this.eventId});

  @override
  ConsumerState<MeetingGatePage> createState() => _MeetingGatePageState();
}

class _MeetingGatePageState extends ConsumerState<MeetingGatePage> {
  bool _isLoading = true;
  bool _isRegistered = false;

  // For testing: Set this to true to bypass registration check
  static const bool _bypassRegistrationCheck = true;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    if (_bypassRegistrationCheck) {
      // Skip check for testing
      setState(() {
        _isRegistered = true;
        _isLoading = false;
      });
      return;
    }

    try {
      final registrationService = ref.read(registrationServiceProvider);
      final eventId = int.tryParse(widget.eventId) ?? 0;
      final isRegistered = await registrationService.hasApprovedRegistration(
        eventId,
      );

      if (mounted) {
        setState(() {
          _isRegistered = isRegistered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking registration: $e');
      // On error, allow access for now (for testing)
      if (mounted) {
        setState(() {
          _isRegistered = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    if (!_isRegistered) {
      return MeetingNotRegisteredPage(eventId: widget.eventId);
    }

    return MeetingsPage(eventId: widget.eventId);
  }
}
