import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// "FORGET IT, SEND ME BACK TO THE SIGN IN" link used on forgot/reset password pages.
class SendMeBackLink extends StatelessWidget {
  const SendMeBackLink({super.key});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/login'),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
            children: [
              const TextSpan(text: 'FORGET IT, '),
              TextSpan(
                text: 'SEND ME BACK',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const TextSpan(text: ' TO THE SIGN IN'),
            ],
          ),
        ),
      ),
    );
  }
}
