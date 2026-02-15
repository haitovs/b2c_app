import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../core/app_theme.dart';
import '../../core/services/legal_service.dart';
import '../../features/auth/services/auth_service.dart';

/// Full-page legal document viewer used from auth pages (login/registration footer).
/// Displays legal documents with a gradient header and white card body.
class LegalDocumentPage extends StatefulWidget {
  final String docType;

  const LegalDocumentPage({super.key, required this.docType});

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  LegalDocument? _document;
  bool _isLoading = true;
  String? _error;
  late final LegalService _legalService;

  @override
  void initState() {
    super.initState();
    final authService = legacy_provider.Provider.of<AuthService>(
      context,
      listen: false,
    );
    _legalService = LegalService(authService);
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final doc = await _legalService.getDocument(widget.docType);
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
      case 'COOKIES':
        return 'Cookies Policy';
      default:
        return 'Legal Document';
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _goBack,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getTitle(),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content area
          Expanded(
            child: Container(
              color: AppColors.gradientEnd,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
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
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  _document!.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.buttonBackground,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                MarkdownBody(
                                  data: _document!.content,
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
                                    p: GoogleFonts.roboto(
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                    listBullet: GoogleFonts.roboto(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
