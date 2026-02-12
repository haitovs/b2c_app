import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable gray info box used across auth pages (verification, forgot password, reset password).
class AuthInfoBox extends StatelessWidget {
  final String text;

  const AuthInfoBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
    );
  }
}
