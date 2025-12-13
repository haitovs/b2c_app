import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/faq_service.dart';

class FAQPage extends StatefulWidget {
  final String eventId;

  const FAQPage({super.key, required this.eventId});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final FAQService _service = FAQService();
  final TextEditingController _searchController = TextEditingController();

  List<FAQItem> _faqs = [];
  List<FAQItem> _filteredFaqs = [];
  bool _isLoading = true;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFAQs() async {
    setState(() => _isLoading = true);

    final eventId = int.tryParse(widget.eventId);
    final faqs = await _service.getFAQs(eventId: eventId);

    if (mounted) {
      setState(() {
        _faqs = faqs;
        _filteredFaqs = faqs;
        _isLoading = false;
      });
    }
  }

  void _filterFAQs(String query) {
    if (query.isEmpty) {
      setState(() => _filteredFaqs = _faqs);
    } else {
      final filtered = _faqs
          .where(
            (faq) =>
                faq.question.toLowerCase().contains(query.toLowerCase()) ||
                faq.answer.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
      setState(() => _filteredFaqs = filtered);
    }
  }

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile ? 20.0 : 50.0;

    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () {
                      // Navigate back to menu
                      context.go('/events/${widget.eventId}/menu');
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFF1F1F6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Title
                  Text(
                    'FAQ',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 28 : 40,
                      color: const Color(0xFFF1F1F6),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F6).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    const Icon(
                      Icons.search,
                      color: Color(0xFFF1F1F6),
                      size: 28,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterFAQs,
                        style: GoogleFonts.roboto(
                          color: const Color(0xFFF1F1F6),
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search questions...',
                          hintStyle: GoogleFonts.roboto(
                            color: const Color(0xFFF1F1F6).withOpacity(0.6),
                            fontSize: 18,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Content area
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3C4494),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Header section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 40,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDFE1ED),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Have any questions?',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w500,
                                      fontSize: isMobile ? 32 : 50,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'Let us answer the questions for you.',
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w400,
                                      fontSize: isMobile ? 18 : 25,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // FAQ items
                            if (_filteredFaqs.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(40),
                                child: Text(
                                  'No FAQs found',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            else
                              ..._filteredFaqs.asMap().entries.map((entry) {
                                final index = entry.key;
                                final faq = entry.value;
                                final isExpanded = _expandedIndex == index;

                                return _buildFAQItem(
                                  faq,
                                  index,
                                  isExpanded,
                                  isMobile,
                                );
                              }),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, int index, bool isExpanded, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isExpanded
              ? [
                  const BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // Question header
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _toggleExpanded(index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 30,
                    vertical: isMobile ? 20 : 25,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCDEEB).withOpacity(0.85),
                    borderRadius: isExpanded
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          )
                        : BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          faq.question,
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w400,
                            fontSize: isMobile ? 18 : 28,
                            color: const Color(0xFF151938),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: isMobile ? 28 : 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Answer (expandable)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 20 : 30),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: MarkdownBody(
                        data: faq.answer,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.roboto(
                            fontSize: isMobile ? 16 : 20,
                            height: 1.6,
                            color: const Color(0xFF151938).withOpacity(0.85),
                          ),
                          listBullet: GoogleFonts.roboto(
                            fontSize: isMobile ? 16 : 20,
                            color: const Color(0xFF151938).withOpacity(0.85),
                          ),
                          a: GoogleFonts.roboto(
                            fontSize: isMobile ? 16 : 20,
                            color: const Color(0xFF3C4494),
                            decoration: TextDecoration.underline,
                          ),
                          strong: GoogleFonts.roboto(
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF151938).withOpacity(0.85),
                          ),
                          em: GoogleFonts.roboto(
                            fontSize: isMobile ? 16 : 20,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF151938).withOpacity(0.85),
                          ),
                        ),
                        onTapLink: (text, href, title) async {
                          if (href != null) {
                            final uri = Uri.parse(href);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          }
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
