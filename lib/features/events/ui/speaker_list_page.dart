import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../auth/services/auth_service.dart';
import '../services/speaker_service.dart';

class SpeakerListPage extends StatelessWidget {
  final String eventId;

  const SpeakerListPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return ProxyProvider<AuthService, SpeakerService>(
      update: (_, auth, __) => SpeakerService(auth),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F6),
        appBar: AppBar(
          title: Text(
            "Speakers",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Consumer<SpeakerService>(
          builder: (context, speakerService, child) {
            return FutureBuilder<List<dynamic>>(
              future: speakerService.fetchSpeakers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No speakers found."));
                }

                final speakers = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: speakers.length,
                  itemBuilder: (context, index) {
                    final speaker = speakers[index];
                    return _buildSpeakerCard(speaker);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpeakerCard(dynamic speaker) {
    final name = speaker['name'] ?? 'Unknown';
    final title = speaker['title'] ?? '';
    final imageUrl =
        speaker['photo_url']; // e.g. http://localhost:8001/media/...

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (title.isNotEmpty)
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
