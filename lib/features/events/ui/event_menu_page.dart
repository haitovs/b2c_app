import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../notifications/ui/notification_drawer.dart';
import '../../profile/ui/profile_dialog.dart';

class EventMenuPage extends StatelessWidget {
  final String id;
  const EventMenuPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: Stack(
        children: [
          // Header (Logo, Notifications, User) - Reused structure
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
                    color: Colors.white.withOpacity(0.2),
                    child: const Center(
                      child: Text(
                        "Logo",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  // Icons
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

          // Event Info
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Event Title
                Text(
                  "Annual Expo CMR forum for international guests", // Mock title based on design
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w500,
                    fontSize: 40, // Adjusted for fit
                    color: const Color(0xFFF1F1F6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Event Image
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(child: Text("Image")),
                ),
              ],
            ),
          ),

          // Sponsors
          Positioned(
            top: 351,
            left: 50,
            right: 50,
            child: SizedBox(
              height: 139,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                separatorBuilder: (context, index) => const SizedBox(width: 28),
                itemBuilder: (context, index) => _buildSponsorCard(context),
              ),
            ),
          ),

          // Menu Grid
          Positioned(
            top: 560,
            left: 128,
            right: 128,
            bottom: 0,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Row 1
                  _buildMenuRow(context, [
                    _MenuItem(
                      label: AppLocalizations.of(context)!.agenda,
                      icon: Icons.calendar_month,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.speakers,
                      icon: Icons.mic,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.participants,
                      icon: Icons.groups,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.meetings,
                      icon: Icons.handshake,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.news,
                      icon: Icons.newspaper,
                    ),
                  ]),
                  const SizedBox(height: 40),
                  const Divider(color: Color(0xFFF1F1F6), thickness: 2),
                  const SizedBox(height: 40),

                  // Row 2
                  _buildMenuRow(context, [
                    _MenuItem(
                      label: AppLocalizations.of(context)!.registration,
                      icon: Icons.app_registration,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.myParticipants,
                      icon: Icons.person_add,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.flights,
                      icon: Icons.flight,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.accommodation,
                      icon: Icons.hotel,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.transfer,
                      icon: Icons.directions_car,
                    ),
                  ]),
                  const SizedBox(height: 40),
                  const Divider(color: Color(0xFFF1F1F6), thickness: 2),
                  const SizedBox(height: 40),

                  // Row 3
                  _buildMenuRow(context, [
                    _MenuItem(
                      label: AppLocalizations.of(context)!.hotline,
                      icon: Icons.headset_mic,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.feedback,
                      icon: Icons.feedback,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.faq,
                      icon: Icons.help_outline,
                    ),
                    _MenuItem(
                      label: AppLocalizations.of(context)!.contactUs,
                      icon: Icons.contact_support,
                    ),
                  ]),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorCard(BuildContext context) {
    return Container(
      width: 200,
      height: 139,
      decoration: BoxDecoration(
        color: const Color(0xFF262B60),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo placeholder
          Container(
            width: 100,
            height: 50,
            color: Colors.white.withOpacity(0.1),
            child: const Center(
              child: Text("Logo", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.goldSponsor,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: const Color(0xFFDDAC17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(BuildContext context, List<_MenuItem> items) {
    return Wrap(
      spacing: 115,
      runSpacing: 40,
      alignment: WrapAlignment.start,
      children: items.map((item) => _buildMenuItem(context, item)).toList(),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return GestureDetector(
      onTap: () {
        if (item.label == AppLocalizations.of(context)!.agenda) {
          context.push('/events/$id/agenda');
        }
      },
      child: SizedBox(
        width: 140,
        height: 187,
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), // Placeholder for image
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              item.label,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                fontSize: 20,
                color: const Color(0xFFF1F1F6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;

  _MenuItem({required this.label, required this.icon});
}
