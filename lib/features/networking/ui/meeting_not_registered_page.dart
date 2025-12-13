import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../events/ui/widgets/profile_dropdown.dart';
import '../../notifications/ui/notification_drawer.dart';

/// Page shown when user tries to access Meetings without being registered
class MeetingNotRegisteredPage extends StatefulWidget {
  final String eventId;

  const MeetingNotRegisteredPage({super.key, required this.eventId});

  @override
  State<MeetingNotRegisteredPage> createState() =>
      _MeetingNotRegisteredPageState();
}

class _MeetingNotRegisteredPageState extends State<MeetingNotRegisteredPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: GestureDetector(
        onTap: _closeProfile,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  // Content - centered message
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: _buildMessageCard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Profile dropdown overlay
            if (_isProfileOpen)
              Positioned(
                top: 100,
                right: 20,
                child: ProfileDropdown(onClose: _closeProfile),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Menu button
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          // Title
          Text(
            'Meeting',
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Notification & Profile icons
          CustomAppBar(
            onNotificationTap: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            onProfileTap: _toggleProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message text
          Text(
            'If you are not yet registered, please complete your registration first.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF333333),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Optional: Button to go to registration
          OutlinedButton(
            onPressed: () {
              // Navigate to registration page
              context.push('/events/${widget.eventId}/registration');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3C4494),
              side: const BorderSide(color: Color(0xFF3C4494), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            ),
            child: Text(
              'Go to Registration',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
