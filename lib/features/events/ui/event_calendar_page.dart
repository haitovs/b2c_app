import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../notifications/ui/notification_drawer.dart';
import '../../profile/ui/profile_dialog.dart';

class EventCalendarPage extends StatelessWidget {
  const EventCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: Stack(
        children: [
          // Nav / Header
          Positioned(
            top: 20,
            left: 40,
            right: 40,
            child: SizedBox(
              height: 126,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo Placeholder
                  Container(
                    width: 218,
                    height: 68,
                    color: Colors.white.withOpacity(0.2), // Placeholder
                    child: const Center(
                      child: Text(
                        "Logo",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  // Icons (Notification, User)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Scaffold.of(context).openEndDrawer(),
                        child: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const ProfileDialog(),
                          );
                        },
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: 179,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 1310,
                height: 64,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F6).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search,
                      color: Color(0xFFF1F1F6),
                      size: 36,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      AppLocalizations.of(context)!.searchPlaceholder,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w500,
                        fontSize: 24,
                        color: const Color(0xFFF1F1F6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Event List (Scrollable)
          Positioned.fill(
            top: 273,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _EventCard(
                    title: "Turkmenistan–China Innovation Forum",
                    date: "20-25 may 2025",
                    location: "Ashgabat, TKM",
                    days: "35",
                    hours: "17",
                    minutes: "59",
                    seconds: "56",
                  ),
                  const SizedBox(height: 30),
                  _EventCard(
                    title: "Another Event Example",
                    date: "10-12 June 2025",
                    location: "Mary, TKM",
                    days: "50",
                    hours: "10",
                    minutes: "20",
                    seconds: "05",
                  ),
                  const SizedBox(height: 50), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final String days;
  final String hours;
  final String minutes;
  final String seconds;

  const _EventCard({
    required this.title,
    required this.date,
    required this.location,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Center(
      child: Container(
        width: 1310,
        constraints: BoxConstraints(maxWidth: width * 0.9),
        height: isMobile ? null : 302, // Auto height for mobile
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: isMobile
            ? Column(
                children: [
                  // Image
                  Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Text("Event Image")),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            fontSize: 25,
                            color: const Color(0xFF151938),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 10),
                            Text(date, style: GoogleFonts.roboto(fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              location,
                              style: GoogleFonts.roboto(fontSize: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Timer Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5460CD), Color(0xFF1C045F)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(5),
                        bottomRight: Radius.circular(5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.startingIn,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTimerRow(context),
                      ],
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  // Image
                  Positioned(
                    left: 455, // Approx 34%
                    right: 499, // Approx 38%
                    top: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.grey[300],
                      child: const Center(child: Text("Image")),
                    ),
                  ),

                  // Content (Left)
                  Positioned(
                    left: 30,
                    top: 30,
                    width: 400,
                    bottom: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo/Icon placeholder
                        Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            fontSize: 25,
                            color: const Color(0xFF151938),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 24),
                            const SizedBox(width: 10),
                            Text(date, style: GoogleFonts.roboto(fontSize: 25)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              location,
                              style: GoogleFonts.roboto(fontSize: 25),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Timer (Right)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 500, // Approx
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF5460CD), Color(0xFF1C045F)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 50,
                            left: 40,
                            child: Text(
                              AppLocalizations.of(context)!.startingIn,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: 35,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 113,
                            left: 40,
                            right: 40,
                            height: 68,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(child: _buildTimerRow(context)),
                            ),
                          ),
                          Positioned(
                            bottom: 25,
                            right: 50,
                            child: GestureDetector(
                              onTap: () => context.push(
                                '/events/1',
                              ), // Hardcoded ID for now
                              child: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.learnMore,
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTimerRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeUnit(days, AppLocalizations.of(context)!.days),
        _buildSeparator(),
        _buildTimeUnit(hours, AppLocalizations.of(context)!.hours),
        _buildSeparator(),
        _buildTimeUnit(minutes, AppLocalizations.of(context)!.minutes),
        _buildSeparator(),
        _buildTimeUnit(seconds, AppLocalizations.of(context)!.seconds),
      ],
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 30, // Slightly smaller for fit
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        ":",
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}
