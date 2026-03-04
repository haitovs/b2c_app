import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/event_context_provider.dart';
import '../../../../shared/layouts/event_sidebar_layout.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/event_providers.dart';

class EventDetailsPage extends ConsumerStatefulWidget {
  final String id;
  const EventDetailsPage({super.key, required this.id});

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
  Map<String, dynamic>? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvent();
    });
  }

  Future<void> _loadEvent() async {
    try {
      final eventId = int.tryParse(widget.id);
      if (eventId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final eventService = ref.read(eventServiceProvider);
      final eventData = await eventService.fetchEvent(eventId);

      if (!mounted) return;

      if (eventData != null) {
        setState(() {
          _event = {
            "id": eventData['id'],
            "name": eventData['title'] ?? 'Untitled Event',
            "description": eventData['description'] ?? '',
            "start_date": eventData['date_str'] ?? '',
            "location": eventData['location'] ?? '',
            "tourism_site_id": eventData['tourism_site_id'],
            "image_url": eventData['image_url'],
            "logo_url": eventData['logo_url'],
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading event: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onOpenTap() {
    final eventId = int.tryParse(widget.id);
    if (eventId != null && _event != null) {
      final tourismSiteId = _event!['tourism_site_id'] as int?;
      ref.read(eventContextProvider.notifier).setEventContext(
        eventId: eventId,
        tourismSiteId: tourismSiteId,
      );
    }
    context.go('/events/${widget.id}/menu');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF3C4494),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF3C4494),
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.eventNotFound,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return EventSidebarLayout(
      title: 'Event Details',
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: isMobile ? 20 : 30),

            // Title Row: Logo + Event Name
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 50,
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _event!['logo_url'] != null
                                ? Image.network(
                                    _event!['logo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.event,
                                      size: 40,
                                      color: Colors.white70,
                                    ),
                                  )
                                : const Icon(
                                    Icons.event,
                                    size: 40,
                                    color: Colors.white70,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _event!['name'],
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            height: 1.2,
                            color: const Color(0xFFF1F1F6),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _event!['logo_url'] != null
                                ? Image.network(
                                    _event!['logo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.event,
                                      size: 50,
                                      color: Colors.white70,
                                    ),
                                  )
                                : const Icon(
                                    Icons.event,
                                    size: 50,
                                    color: Colors.white70,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          child: Text(
                            _event!['name'],
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                              fontSize: 45,
                              height: 67 / 55,
                              color: const Color(0xFFF1F1F6),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: isMobile ? 25 : 50),

            // Content Area: Text Box + Image/Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 50,
              ),
              child: isMobile
                  ? Column(
                      children: [
                        _buildDescriptionBox(isMobile: true),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _onOpenTap,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9CA4CC),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context)!.openButton,
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFF1F1F6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDescriptionBox(isMobile: false),
                          ),
                          const SizedBox(width: 30),
                          Column(
                            children: [
                              Container(
                                width: 381,
                                height: 497,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/event_detail/event_photo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: Colors.grey,
                                      child: const Icon(
                                        Icons.image,
                                        size: 100,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 27),
                              GestureDetector(
                                onTap: _onOpenTap,
                                child: Container(
                                  width: 381,
                                  height: 121,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9CA4CC),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppLocalizations.of(context)!.openButton,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 45,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFF1F1F6),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),

            SizedBox(height: isMobile ? 30 : 50),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionBox({required bool isMobile}) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F6),
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(isMobile ? 15 : 20),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.keyThemesTurkmenistanChina,
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 18 : 30,
                fontWeight: FontWeight.w500,
                height: isMobile ? null : 37 / 30,
                color: const Color(0xFF231C1C),
              ),
            ),
            const SizedBox(height: 15),
            ...(_event!['description'] as String)
                .split(';')
                .where((item) => item.trim().isNotEmpty)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: GoogleFonts.roboto(
                            fontSize: isMobile ? 14 : 20,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xD9474551),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.trim(),
                            style: GoogleFonts.roboto(
                              fontSize: isMobile ? 14 : 20,
                              fontWeight: FontWeight.w400,
                              height: isMobile ? 1.4 : 35 / 20,
                              color: const Color(0xD9474551),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            SizedBox(height: isMobile ? 15 : 20),
            Text(
              l10n.dearParticipants,
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 16 : 25,
                fontWeight: FontWeight.w500,
                height: isMobile ? null : 37 / 25,
                color: const Color(0xFF231C1C),
              ),
            ),
            SizedBox(height: isMobile ? 10 : 12),
            Text(
              l10n.participantInstructions,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 14 : 20,
                fontWeight: FontWeight.w400,
                height: isMobile ? 1.4 : 35 / 20,
                color: const Color(0xD9474551),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
