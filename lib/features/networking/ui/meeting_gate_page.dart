import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../auth/services/auth_service.dart';
import '../../registration/services/registration_service.dart';
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
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      final registrationService = RegistrationService(authService);
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
      return Scaffold(
        backgroundColor: const Color(0xFF3C4494),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (!_isRegistered) {
      return MeetingNotRegisteredPage(eventId: widget.eventId);
    }

    return MeetingsPage(eventId: widget.eventId);
  }
}
