import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/legal_service.dart';

/// A bottom sheet widget that displays legal documents (Terms, Privacy, Refund)
/// with markdown rendering.
class LegalBottomSheet extends StatefulWidget {
  final String docType; // TERMS, PRIVACY, or REFUND

  const LegalBottomSheet({super.key, required this.docType});

  /// Show the legal bottom sheet
  static Future<void> show(BuildContext context, String docType) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LegalBottomSheet(docType: docType),
    );
  }

  @override
  State<LegalBottomSheet> createState() => _LegalBottomSheetState();
}

class _LegalBottomSheetState extends State<LegalBottomSheet> {
  LegalDocument? _document;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final doc = await legalService.getDocument(widget.docType);
      if (mounted) {
        setState(() {
          _document = doc;
          _isLoading = false;
          if (doc == null) {
            _error = 'Document not found. Please contact support.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load document. Please try again.';
        });
      }
    }
  }

  String _getTitle() {
    switch (widget.docType.toUpperCase()) {
      case 'TERMS':
        return 'Terms and Conditions';
      case 'PRIVACY':
        return 'Privacy Policy';
      case 'REFUND':
        return 'Refund Policy';
      default:
        return 'Legal Document';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _document?.title ?? _getTitle(),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : Markdown(
                    data: _document!.content,
                    padding: const EdgeInsets.all(20),
                    styleSheet: MarkdownStyleSheet(
                      h1: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      h3: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      p: GoogleFonts.roboto(fontSize: 16, height: 1.6),
                      listBullet: GoogleFonts.roboto(fontSize: 16),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
