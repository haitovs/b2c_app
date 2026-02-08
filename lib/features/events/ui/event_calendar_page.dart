import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_app_bar.dart';
import '../../auth/services/auth_service.dart';
import '../../events/services/event_service.dart';
import '../../notifications/ui/notification_drawer.dart';
import 'widgets/event_card.dart';
import 'widgets/profile_dropdown.dart';

class EventCalendarPage extends StatefulWidget {
  const EventCalendarPage({super.key});

  @override
  State<EventCalendarPage> createState() => _EventCalendarPageState();
}

class _EventCalendarPageState extends State<EventCalendarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Search Controller
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isProfileOpen = false;

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

  void _logout() async {
    await context.read<AuthService>().logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800; // Mobile breakpoint

    // Configurable dimensions
    final double navbarHeight = isMobile ? 60.0 : 70.0;
    final double navbarTopPadding = isMobile ? 10.0 : 20.0;

    final double searchBarTop = navbarHeight + navbarTopPadding + 20;
    final double searchBarHeight = isMobile ? 45.0 : 50.0;

    final double listTop =
        searchBarTop + searchBarHeight + (isMobile ? 20 : 40);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      // Wrap Stack in GestureDetector to handle clicks outside profile
      body: GestureDetector(
        onTap: _closeProfile,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // 1. Navigation Header
            Positioned(
              top: navbarTopPadding,
              left: isMobile ? 20 : 40,
              right: isMobile ? 20 : 40,
              child: CustomAppBar(
                onProfileTap: _toggleProfile,
                onNotificationTap: () {
                  _closeProfile();
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                isMobile: isMobile,
              ),
            ),

            // 2. Search Bar
            Positioned(
              top: searchBarTop,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 1310,
                  height: searchBarHeight,
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.92),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _searchController,
                    onTap: _closeProfile, // accessing search closes profile
                    cursorColor: const Color(0xFFF1F1F6),
                    style: GoogleFonts.roboto(
                      fontSize: isMobile ? 16 : 18,
                      color: const Color(0xFFF1F1F6),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlignVertical:
                        TextAlignVertical.center, // Vertically center text
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      prefixIcon: Icon(
                        Icons.search,
                        color: const Color(0xFFF1F1F6),
                        size: isMobile ? 24 : 28,
                      ),
                      hintText: "Search by event name",
                      hintStyle: GoogleFonts.roboto(
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 16 : 18,
                        color: const Color(
                          0xFFF1F1F6,
                        ), // Same color as text for hint
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding:
                          EdgeInsets.zero, // Important for fitting in height
                    ),
                  ),
                ),
              ),
            ),

            // 3. Scrollable Event List
            Positioned.fill(
              top: listTop,
              child: GestureDetector(
                onTap: _closeProfile,
                child: FutureBuilder<List<dynamic>>(
                  future: context.read<EventService>().fetchEvents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "No events found",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final events = snapshot.data!;

                    // We need a ScrollController for the Scrollbar to work
                    // Create a ScrollController (make sure to dispose if stateful, or use PrimaryScrollController)
                    // Since specific styling is needed, we should provide an explicit controller.
                    // However, creating it inside buider causes re-creation.
                    // Ideally, we move `_scrollController` to State class.
                    // For now, let's use PrimaryScrollController if possible or just use a local one for structure,
                    // BUT: The bug states "Scrollbar attempted to use PrimaryScrollController...".
                    // Best fix: Add 'controller' to State, pass it to both Scrollbar and SingleChildScrollView.

                    return Theme(
                      data: ThemeData(
                        scrollbarTheme: ScrollbarThemeData(
                          thumbColor: WidgetStateProperty.all(
                            const Color(0xFFF1F1F6).withValues(alpha: 0.2),
                          ),
                          trackColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          radius: const Radius.circular(12),
                          thickness: WidgetStateProperty.all(isMobile ? 4 : 8),
                        ),
                      ),
                      child: Scrollbar(
                        controller: _scrollController, // <--- ASSIGNED HERE
                        thumbVisibility: true,
                        thickness: isMobile ? 4 : 8,
                        radius: const Radius.circular(12),
                        child: SingleChildScrollView(
                          controller: _scrollController, // <--- ASSIGNED HERE
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 50, right: 10),
                          child: Column(
                            children: events.map((event) {
                              return Column(
                                children: [
                                  EventCard(
                                    title: event['title'] ?? 'No Title',
                                    date: event['date_str'] ?? '',
                                    location: event['location'] ?? '',
                                    imageUrl:
                                        event['image_url'] ??
                                        "assets/event_calendar/event1.png",
                                    logoUrl: event['logo_url'],
                                    eventStartTime:
                                        DateTime.tryParse(
                                          event['start_time'] ?? '',
                                        ) ??
                                        DateTime.now(),
                                    onTap: () {
                                      final id = event['id'];
                                      if (id != null) {
                                        context.go('/events/$id');
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Event ID missing"),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 25),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 4. Profile Dropdown Overlay
            if (_isProfileOpen)
              Positioned(
                top: navbarTopPadding + navbarHeight + 5,
                right: isMobile ? 20 : 65,
                left: isMobile ? 20 : null,
                child: ProfileDropdown(onLogout: _logout),
              ),
          ],
        ),
      ),
    );
  }
}
