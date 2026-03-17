import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth - 40 : 406.0;

    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: EdgeInsets.only(
        top: 120,
        right: isMobile ? 20 : 65,
        left: isMobile ? 20 : 0,
      ), // Position based on design
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
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
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Info Card
            Container(
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
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 11),
                  // Name
                  Expanded(
                    child: Text(
                      "Name Surname", // Placeholder
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: const Color(0xFF1C1C1C),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 13),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Language Selection
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 34),
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
            const SizedBox(height: 15),

            // Log Out Button
            GestureDetector(
              onTap: () {
                context.go('/login'); // Logout logic
              },
              child: Container(
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
