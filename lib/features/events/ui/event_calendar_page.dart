import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

  void _logout() {
    // Implement logout logic
    print("Logout pressed");
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              child: SizedBox(
                height: navbarHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Container(
                      width: isMobile ? 120 : 160,
                      height: isMobile ? 40 : 50,
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error, color: Colors.white),
                      ),
                    ),

                    // Icons
                    Row(
                      children: [
                        // Bell
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              _closeProfile();
                              _scaffoldKey.currentState?.openEndDrawer();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: SvgPicture.asset(
                                'assets/event_calendar/bell.svg',
                                width: isMobile ? 24 : 28,
                                height: isMobile ? 24 : 28,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 15 : 25),
                        // User
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: _toggleProfile,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: SvgPicture.asset(
                                'assets/event_calendar/user.svg',
                                width: isMobile ? 24 : 28,
                                height: isMobile ? 24 : 28,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
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
                    color: const Color(0xFFF1F1F6).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
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
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 50),
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
                                eventStartTime:
                                    DateTime.tryParse(
                                      event['start_time'] ?? '',
                                    ) ??
                                    DateTime.now(),
                                onTap: () {
                                  // Navigate to Event Menu
                                  final id =
                                      event['id']; // Make sure backend sends 'id'
                                  if (id != null) {
                                    context.go('/events/$id/menu');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
