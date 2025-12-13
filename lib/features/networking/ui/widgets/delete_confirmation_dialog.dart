import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows a delete confirmation dialog matching the Figma design
/// Returns true if user confirms deletion, false otherwise
Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _DeleteConfirmationDialog(),
  );
  return result ?? false;
}

class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 481,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F8),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header section (white background)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFBCBCBC), width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Trash icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3C4796),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Delete title
                  Text(
                    'Delete',
                    style: GoogleFonts.roboto(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3C4796),
                    ),
                  ),
                ],
              ),
            ),
            // Content section (grey background)
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 35, 30, 35),
              child: Column(
                children: [
                  // Confirmation message
                  Text(
                    'Are you sure you want to delete this item?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel button
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Color(0xFFD8D8D8),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 53,
                            vertical: 17,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 57),
                      // Delete button
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC60404),
                          side: const BorderSide(
                            color: Color(0xFFC60404),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 53,
                            vertical: 17,
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
