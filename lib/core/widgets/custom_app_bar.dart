import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final bool isMobile;
  final bool showLogo;
  final int unreadNotificationCount;

  const CustomAppBar({
    super.key,
    required this.onProfileTap,
    required this.onNotificationTap,
    this.isMobile = false,
    this.showLogo = true,
    this.unreadNotificationCount = 0,
  });

  Widget _buildNotificationBell() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onNotificationTap,
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
        // Notification badge
        if (unreadNotificationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4757),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadNotificationCount > 99
                    ? '99+'
                    : unreadNotificationCount.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserIcon() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onProfileTap,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: SvgPicture.asset(
            'assets/event_calendar/user.svg',
            width: isMobile ? 24 : 28,
            height: isMobile ? 24 : 28,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If no logo, just return the icons
    if (!showLogo) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNotificationBell(),
          SizedBox(width: isMobile ? 15 : 25),
          _buildUserIcon(),
        ],
      );
    }

    final double navbarHeight = isMobile ? 60.0 : 70.0;

    return SizedBox(
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
              _buildNotificationBell(),
              SizedBox(width: isMobile ? 15 : 25),
              _buildUserIcon(),
            ],
          ),
        ],
      ),
    );
  }
}
