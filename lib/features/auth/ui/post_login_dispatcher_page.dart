import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/event_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../events/providers/event_providers.dart';
import '../../registration/providers/registration_providers.dart';
import 'widgets/event_picker_dialog.dart';

class PostLoginDispatcherPage extends ConsumerStatefulWidget {
  const PostLoginDispatcherPage({super.key});

  @override
  ConsumerState<PostLoginDispatcherPage> createState() =>
      _PostLoginDispatcherPageState();
}

class _PostLoginDispatcherPageState
    extends ConsumerState<PostLoginDispatcherPage> {
  @override
  void initState() {
    super.initState();
    _dispatch();
  }

  Future<void> _dispatch() async {
    try {
      // 1. Check for a persisted last-visited event (survives logout)
      final lastEventId = ref.read(eventContextProvider).eventId;
      if (lastEventId != null) {
        if (!mounted) return;
        context.go('/events/$lastEventId/menu');
        return;
      }

      // 2. No stored event — check registrations
      final registrationService = ref.read(registrationServiceProvider);
      final registrations = await registrationService.getMyRegistrations();

      // Filter to active registrations (APPROVED or SUBMITTED)
      final active = registrations.where((reg) {
        final status = reg['status']?.toString().toUpperCase() ?? '';
        return status == 'APPROVED' || status == 'SUBMITTED';
      }).toList();

      if (!mounted) return;

      if (active.isEmpty) {
        context.go('/');
        return;
      }

      if (active.length == 1) {
        final eventId = active.first['event_id'];
        context.go('/events/$eventId/menu');
        return;
      }

      // Multiple events — fetch details and show picker
      final eventService = ref.read(eventServiceProvider);
      final eventDetails = <Map<String, dynamic>>[];
      for (final reg in active) {
        final eventId = reg['event_id'] as int;
        final detail = await eventService.fetchEvent(eventId);
        if (detail != null) {
          detail['registration_status'] = reg['status'];
          eventDetails.add(detail);
        }
      }

      if (!mounted) return;

      if (eventDetails.isEmpty) {
        context.go('/');
        return;
      }

      if (eventDetails.length == 1) {
        context.go('/events/${eventDetails.first['id']}/menu');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => EventPickerDialog(
          events: eventDetails,
          onEventSelected: (eventId) {
            Navigator.of(context).pop();
            context.go('/events/$eventId/menu');
          },
          onViewAll: () {
            Navigator.of(context).pop();
            context.go('/');
          },
        ),
      );
    } catch (e) {
      debugPrint('[PostLoginDispatcher] Error: $e');
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 20),
            Text(
              'Loading your events...',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
