import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(
        top: 120,
        right: 65,
      ), // Position based on design
      backgroundColor: Colors.transparent,
      child: Container(
        width: 406,
        height: 343,
        decoration: BoxDecoration(
          color: const Color(0xFF9CA4CC),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 10),
              spreadRadius: 6,
            ),
          ],
        ),
        child: Stack(
          children: [
            // User Info Card
            Positioned(
              left: 20,
              top: 25,
              child: Container(
                width: 366,
                height: 57,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 13),
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey, // Placeholder
                        borderRadius: BorderRadius.circular(25),
                        // image: DecorationImage(image: AssetImage('assets/avatar.jpg')),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 11),
                    // Name
                    Text(
                      "Leyli Ashyrberdiyeva", // Placeholder
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: const Color(0xFF1C1C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Language Selection
            Positioned(
              left: 20,
              top: 97,
              child: Container(
                width: 366,
                height: 157,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Stack(
                  children: [
                    // Header
                    Positioned(
                      left: 20,
                      top: 20,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.language,
                            size: 24,
                            color: Color(0xFF999999),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context)!.language,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: const Color(0xFF1C1C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Selected Language Highlight (RUS in design, but we default to EN/Active)
                    Positioned(
                      left: 53, // Adjusted
                      top: 53,
                      child: Container(
                        width: 298,
                        height: 31,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9CA4CC).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    // Languages
                    Positioned(
                      left: 64,
                      top: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LanguageItem(text: "RUS", isSelected: true),
                          const SizedBox(height: 12),
                          _LanguageItem(text: "EN", isSelected: false),
                          const SizedBox(height: 12),
                          _LanguageItem(text: "TKM", isSelected: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Log Out Button
            Positioned(
              left: 20,
              top: 269,
              child: GestureDetector(
                onTap: () {
                  context.go('/login'); // Logout logic
                },
                child: Container(
                  width: 366,
                  height: 57,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      const Icon(Icons.logout, size: 24, color: Colors.black54),
                      const SizedBox(width: 20),
                      Text(
                        AppLocalizations.of(context)!.logOut,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: const Color(0xFF1C1C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String text;
  final bool isSelected;

  const _LanguageItem({required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: const Color(0xFF1C1C1C),
        ),
      ),
    );
  }
}
