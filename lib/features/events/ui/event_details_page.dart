import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as p;

import '../../../../core/services/event_context_service.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../notifications/ui/notification_drawer.dart';
import '../services/event_service.dart';
import 'widgets/profile_dropdown.dart';

class EventDetailsPage extends ConsumerStatefulWidget {
  final String id;
  const EventDetailsPage({super.key, required this.id});

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

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

      final eventService = p.Provider.of<EventService>(context, listen: false);
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

  void _toggleProfile() {
    setState(() {
      _isProfileOpen = !_isProfileOpen;
    });
  }

  void _closeProfile() {
    if (_isProfileOpen) {
      setState(() {
        _isProfileOpen = false;
      });
    }
  }

  void _onOpenTap() {
    // Save event context using EventContextService
    final eventId = int.tryParse(widget.id);
    if (eventId != null && _event != null) {
      final tourismSiteId = _event!['tourism_site_id'] as int?;
      eventContextService.setEventContext(
        eventId: eventId,
        tourismSiteId: tourismSiteId,
      );
    }

    // Use go() for proper URL update on web
    context.go('/events/${widget.id}/menu');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Show mobile layout on medium screens too (up to 900px)
    final isMobile = screenWidth < 900;
    final horizontalPadding = isMobile ? 20.0 : 50.0;

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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: GestureDetector(
        onTap: _closeProfile,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Main Content
            SingleChildScrollView(
              child: Column(
                children: [
                  // Top Bar Area
                  Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding - 10,
                      top: isMobile ? 15 : 20,
                    ),
                    child: Row(
                      children: [
                        // Back Arrow
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            },
                            child: Container(
                              width: isMobile ? 40 : 50,
                              height: isMobile ? 40 : 50,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFFF1F1F6),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // App Bar Icons
                        CustomAppBar(
                          onProfileTap: _toggleProfile,
                          onNotificationTap: () {
                            _closeProfile();
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 20 : 30),

                  // Title Row: Logo + Event Name
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/event_detail/logo_mini.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.image, size: 40),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              // Event Name
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
                              // Logo
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/event_detail/logo_mini.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.image, size: 50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 30),
                              // Event Name
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
                      horizontal: horizontalPadding,
                    ),
                    child: isMobile
                        ? Column(
                            children: [
                              // Text Box - Mobile
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F1F6),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Key Themes Title
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.keyThemesTurkmenistanChina,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF231C1C),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    // Description as bullet list
                                    ...(_event!['description'] as String)
                                        .split(';')
                                        .where((item) => item.trim().isNotEmpty)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '• ',
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: const Color(
                                                      0xD9474551,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    item.trim(),
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      height: 1.4,
                                                      color: const Color(
                                                        0xD9474551,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    const SizedBox(height: 15),
                                    // Dear Participants
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.dearParticipants,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF231C1C),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Instructions
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.participantInstructions,
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 1.4,
                                        color: const Color(0xD9474551),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Open Button - Mobile (smaller)
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
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text Box
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F1F6),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Breadcrumbs
                                        Row(
                                          children: [
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.speakersLabel,
                                              style: GoogleFonts.roboto(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF616161),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF616161),
                                              size: 20,
                                            ),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.speakerBreadcrumb,
                                              style: GoogleFonts.roboto(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF616161),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        // Key Themes Title
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.keyThemesTurkmenistanChina,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500,
                                            height: 37 / 30,
                                            color: const Color(0xFF231C1C),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Description as bullet list
                                        ...(_event!['description'] as String)
                                            .split(';')
                                            .where(
                                              (item) => item.trim().isNotEmpty,
                                            )
                                            .map(
                                              (item) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '• ',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: const Color(
                                                          0xD9474551,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        item.trim(),
                                                        style:
                                                            GoogleFonts.roboto(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              height: 35 / 20,
                                                              color:
                                                                  const Color(
                                                                    0xD9474551,
                                                                  ),
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        const SizedBox(height: 30),
                                        // Dear Participants
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.dearParticipants,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w500,
                                            height: 37 / 25,
                                            color: const Color(0xFF231C1C),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Instructions
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.participantInstructions,
                                          style: GoogleFonts.roboto(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w400,
                                            height: 35 / 20,
                                            color: const Color(0xD9474551),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 30),
                              // Image + Button Column
                              Column(
                                children: [
                                  // Event Photo
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
                                  // Open Button
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
                                        AppLocalizations.of(
                                          context,
                                        )!.openButton,
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

                  SizedBox(height: isMobile ? 30 : 50),
                ],
              ),
            ),

            // Profile Dropdown Overlay
            if (_isProfileOpen)
              Positioned(
                top: isMobile ? 60 : 80,
                right: isMobile ? 20 : 65,
                left: isMobile ? 20 : null,
                child: ProfileDropdown(
                  onLogout: () {
                    context.go('/login');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
