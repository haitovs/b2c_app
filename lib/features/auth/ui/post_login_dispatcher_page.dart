import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/event_context_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../events/providers/event_providers.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _dispatch());
  }

  Future<void> _dispatch() async {
    try {
      // 0. Check for a stored redirect URL (user was trying to reach a page before login)
      final redirectUrl = postLoginRedirectUrl;
      if (redirectUrl != null) {
        postLoginRedirectUrl = null;
        if (!mounted) return;
        context.go(redirectUrl);
        return;
      }

      // 1. Check for a persisted last-visited event (survives logout)
      final lastEventId = ref.read(eventContextProvider).eventId;
      if (lastEventId != null) {
        if (!mounted) return;
        context.go('/events/$lastEventId/dashboard');
        return;
      }

      // 2. No stored event — fetch events and pick first one
      final eventService = ref.read(eventServiceProvider);
      final events = await eventService.fetchEvents();

      if (!mounted) return;

      if (events.isEmpty) {
        context.go('/');
        return;
      }

      if (events.length == 1) {
        final eventId = events.first['id'];
        context.go('/events/$eventId/dashboard');
        return;
      }

      // Multiple events — go to event calendar to pick
      context.go('/');
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
