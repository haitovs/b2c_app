import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../auth/services/auth_service.dart';
import '../services/meeting_service.dart';

class MeetingListPage extends StatelessWidget {
  const MeetingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProxyProvider<AuthService, MeetingService>(
      update: (_, auth, __) => MeetingService(auth),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F6),
        appBar: AppBar(
          title: Text(
            "My Meetings",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/meetings/new'),
            ),
          ],
        ),
        body: Consumer<MeetingService>(
          builder: (context, meetingService, child) {
            return FutureBuilder<List<dynamic>>(
              future: meetingService.fetchMyMeetings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("No meetings scheduled."),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => context.push('/meetings/new'),
                          child: const Text("Request Meeting"),
                        ),
                      ],
                    ),
                  );
                }

                final meetings = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: meetings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    return _buildMeetingCard(meeting);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMeetingCard(dynamic meeting) {
    final subject = meeting['subject'] ?? 'No Subject';
    final status = meeting['status'] ?? 'PENDING';
    final startTime =
        DateTime.tryParse(meeting['start_time'] ?? '') ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildStatusChip(status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Start: ${startTime.toString().substring(0, 16)}",
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'CONFIRMED':
        color = Colors.green;
        break;
      case 'DECLINED':
        color = Colors.red;
        break;
      case 'CANCELLED':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
