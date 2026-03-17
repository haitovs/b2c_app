import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shop/providers/shop_providers.dart';
import 'meeting_not_registered_page.dart';
import 'meetings_page.dart';

/// Gate that checks if user has purchased a service (order approved)
/// before showing meetings. If not, shows the purchase required page.
class MeetingGatePage extends ConsumerStatefulWidget {
  final String eventId;

  const MeetingGatePage({super.key, required this.eventId});

  @override
  ConsumerState<MeetingGatePage> createState() => _MeetingGatePageState();
}

class _MeetingGatePageState extends ConsumerState<MeetingGatePage> {
  @override
  Widget build(BuildContext context) {
    final eventId = int.tryParse(widget.eventId) ?? 0;
    final hasPurchased = ref.watch(hasPurchasedProvider(eventId));

    if (!hasPurchased) {
      return MeetingNotRegisteredPage(eventId: widget.eventId);
    }

    return MeetingsPage(eventId: widget.eventId);
  }
}
