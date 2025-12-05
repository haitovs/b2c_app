import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/event_service.dart';

class EventDetailsPage extends StatefulWidget {
  final String id;
  const EventDetailsPage({super.key, required this.id});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final _eventService = EventService();
  Map<String, dynamic>? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    // Mock data for now
    setState(() {
      _event = {
        "id": widget.id,
        "name": "Turkmenistan–China Innovation Forum",
        "description":
            "Strengthening bilateral cooperation in trade, innovation, and education; Annual exhibitions showcasing cutting-edge technologies and industry developments; Expert-led lectures, panel discussions, and networking sessions; Investment opportunities for international businesses and entrepreneurs; Advancing scientific research and academic collaborationions; Cultural exchange and diplomatic dialogue between nations; Sustainable development, infrastructure, and green energy initiatives.",
        "start_date": "2025-05-20",
        "end_date": "2025-05-25",
        "location": "Ashgabat, TKM",
      };
      _isLoading = false;
    });
    // final event = await _eventService.getEvent(int.parse(widget.id));
    // setState(() {
    //   _event = event;
    //   _isLoading = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_event == null) {
      return const Scaffold(body: Center(child: Text("Event not found")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Back Button
            Padding(
              padding: const EdgeInsets.all(50),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFF1F1F6),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Assuming rounded rect based on vector
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFFF1F1F6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Event Title & Image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Flexible(
                    child: Text(
                      _event!['name'],
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 55,
                        color: const Color(0xFFF1F1F6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // Main Content Area
            Container(
              width: 1310, // Max width
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Stack(
                children: [
                  // Info Card
                  Container(
                    width: 929,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Speakers Dropdown (Mock)
                        Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.speakersLabel,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                color: const Color(0xFF616161),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF616161),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Key Themes Title
                        Center(
                          child: Text(
                            AppLocalizations.of(context)!.keyThemesLabel,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                              fontSize: 30,
                              color: const Color(0xFF231C1C),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Description
                        Text(
                          _event!['description'],
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                            height: 1.75,
                            color: const Color(0xD9474551),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Dear Participants
                        Center(
                          child: Text(
                            AppLocalizations.of(context)!.dearParticipants,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                              fontSize: 25,
                              color: const Color(0xFF231C1C),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer Text
                        Text(
                          "To access the mobile application, please click the button below. If you do not find yourself in the list of participants, please complete your registration on the official website. Your personal ID will be sent to the email address you provided.",
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                            height: 1.75,
                            color: const Color(0xD9474551),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Side Image & Button (Desktop Layout)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Column(
                      children: [
                        Container(
                          width: 381,
                          height: 497,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(child: Text("Image")),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () =>
                              context.push('/events/${widget.id}/menu'),
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
                                fontWeight: FontWeight.w500,
                                fontSize: 45,
                                color: const Color(0xFFF1F1F6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
