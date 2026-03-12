import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../models/faq_item.dart';
import '../providers/faq_providers.dart';
import '../services/faq_service.dart';

class FAQPage extends ConsumerStatefulWidget {
  final String eventId;

  const FAQPage({super.key, required this.eventId});

  @override
  ConsumerState<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends ConsumerState<FAQPage> {
  late final FAQService _service;
  final TextEditingController _searchController = TextEditingController();

  List<FAQItem> _faqs = [];
  List<FAQItem> _filteredFaqs = [];
  bool _isLoading = true;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _service = ref.read(faqServiceProvider);
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
      final lower = query.toLowerCase();
      final filtered = _faqs
          .where(
            (faq) =>
                faq.question.toLowerCase().contains(lower) ||
                faq.answer.toLowerCase().contains(lower),
          )
          .toList();
      setState(() => _filteredFaqs = filtered);
    }
  }

  void _toggleExpanded(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 32.0;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Search
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAQ',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: _filterFAQs,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search questions...',
                    hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FAQ list
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _filteredFaqs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No results for "${_searchController.text}"'
                                  : 'No FAQs available',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                            padding, 0, padding, padding),
                        itemCount: _filteredFaqs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final faq = _filteredFaqs[index];
                          final isExpanded = _expandedIndex == index;
                          return _FAQAccordionItem(
                            faq: faq,
                            isExpanded: isExpanded,
                            isMobile: isMobile,
                            onTap: () => _toggleExpanded(index),
                          );
                        },
                      ),
          ),
        ],
      );
  }
}

// =============================================================================
// FAQ Accordion Item
// =============================================================================

class _FAQAccordionItem extends StatelessWidget {
  final FAQItem faq;
  final bool isExpanded;
  final bool isMobile;
  final VoidCallback onTap;

  const _FAQAccordionItem({
    required this.faq,
    required this.isExpanded,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
              onTap: onTap,
              borderRadius: isExpanded
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    )
                  : BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 16 : 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E9F3),
                  borderRadius: isExpanded
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        )
                      : BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 15 : 16,
                          color: const Color(0xFF151938),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.primaryColor,
                        size: isMobile ? 26 : 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Answer (expandable)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: MarkdownBody(
                      data: faq.answer,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 15,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                        listBullet: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 15,
                          color: Colors.black87,
                        ),
                        a: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 15,
                          color: AppTheme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                        strong: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        em: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 15,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
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
    );
  }
}
