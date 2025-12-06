import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../auth/services/auth_service.dart';
import '../../events/services/agenda_service.dart';

class AgendaPage extends StatelessWidget {
  final String id;

  int get eventId => int.tryParse(id) ?? 0;

  const AgendaPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ProxyProvider<AuthService, AgendaService>(
      update: (_, auth, __) => AgendaService(auth),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F6),
        appBar: AppBar(
          title: Text(
            "Agenda",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Consumer<AgendaService>(
          builder: (context, agendaService, child) {
            return FutureBuilder<List<dynamic>>(
              future: agendaService
                  .fetchAgenda(), // In real app, might filter by eventId
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No agenda items found."));
                }

                final items = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildAgendaItem(item);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAgendaItem(dynamic item) {
    // Adapter for Tourism Agenda Model
    final title = item['title'] ?? 'Untitled Session';
    final startTime = item['start_time'] ?? 'TBD';
    final endTime = item['end_time'] ?? 'TBD';
    final location = item['room'] ?? 'Main Hall';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          Column(
            children: [
              Text(
                startTime.toString().substring(11, 16), // Naive parsing HH:MM
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text("|", style: GoogleFonts.inter(color: Colors.grey)),
              const SizedBox(height: 5),
              Text(
                endTime.toString().substring(11, 16),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      location,
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
