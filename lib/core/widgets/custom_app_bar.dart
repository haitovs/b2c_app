import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final bool isMobile;

  const CustomAppBar({
    super.key,
    required this.onProfileTap,
    required this.onNotificationTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
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
              // Bell
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
              SizedBox(width: isMobile ? 15 : 25),
              // User
              Material(
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
    );
  }
}
