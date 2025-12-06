import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EventMenuPage extends StatelessWidget {
  final int eventId;

  const EventMenuPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    // Menu Items Data
    final menuItems = [
      {
        'icon': Icons.calendar_today,
        'label': 'Agenda',
        'route': '/events/$eventId/agenda',
      },
      {
        'icon': Icons.mic,
        'label': 'Speakers',
        'route': '/events/$eventId/speakers',
      },
      {
        'icon': Icons.groups,
        'label': 'Participants',
        'route': '/events/$eventId/participants',
      },
      {
        'icon': Icons.handshake,
        'label': 'Meetings',
        'route': '/events/$eventId/meetings',
      },
      {
        'icon': Icons.newspaper,
        'label': 'News',
        'route': '/events/$eventId/news',
      },
      {
        'icon': Icons.app_registration,
        'label': 'Registration',
        'route': '/events/$eventId/registration',
      }, // Maybe different flow
      {
        'icon': Icons.flight,
        'label': 'Flights',
        'route': '/events/$eventId/flights',
      },
      {
        'icon': Icons.hotel,
        'label': 'Accommodation',
        'route': '/events/$eventId/accommodation',
      },
      {
        'icon': Icons.directions_car,
        'label': 'Transfer',
        'route': '/events/$eventId/transfer',
      },
      {
        'icon': Icons.support_agent,
        'label': 'Hotline',
        'route': '/events/$eventId/hotline',
      },
      {
        'icon': Icons.feedback,
        'label': 'Feedback',
        'route': '/events/$eventId/feedback',
      },
      {
        'icon': Icons.help_outline,
        'label': 'FAQ',
        'route': '/events/$eventId/faq',
      },
      {
        'icon': Icons.contact_mail,
        'label': 'Contact Us',
        'route': '/events/$eventId/contact',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F6),
      appBar: AppBar(
        title: Text(
          'Event Menu',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Sponsors Carousel (Placeholder)
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 20),
              child: PageView(
                children: [
                  _buildSponsorSlide("Sponsor 1"),
                  _buildSponsorSlide("Sponsor 2"),
                  _buildSponsorSlide("Sponsor 3"),
                ],
              ),
            ),

            // 2. Grid Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.0,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (item['route'] != null) {
                          context.push(item['route'] as String);
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 40,
                            color: const Color(0xFF3C4494),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['label'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorSlide(String text) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
