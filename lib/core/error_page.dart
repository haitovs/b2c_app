import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/event_context_service.dart';

/// Styled error page for routing errors (404, invalid routes)
class ErrorPage extends StatelessWidget {
  final String? error;
  final String? path;

  const ErrorPage({super.key, this.error, this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3C4494), Color(0xFF5B6BC0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error icon with animated gradient
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error code
                  Text(
                    "404",
                    style: GoogleFonts.roboto(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3C4494),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    "Page Not Found",
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    "The page you're looking for doesn't exist or has been moved.",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Path display (if available)
                  if (path != null && path!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        path!,
                        style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Go Home button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to event menu if in event context, otherwise home
                        if (eventContextService.hasEventContext) {
                          context.go(eventContextService.eventMenuPath);
                        } else {
                          context.go('/');
                        }
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: Text(
                        eventContextService.hasEventContext
                            ? "Go to Event Menu"
                            : "Go to Home",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C4494),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(
                          0xFF3C4494,
                        ).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Go Back button
                  TextButton.icon(
                    onPressed: () {
                      // If in event context, go to event menu
                      if (eventContextService.hasEventContext) {
                        context.go(eventContextService.eventMenuPath);
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: const Text("Go Back"),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
