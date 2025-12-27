import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../auth/services/auth_service.dart';
import '../services/feedback_service.dart';

class FeedbackPage extends StatefulWidget {
  final String eventId;

  const FeedbackPage({super.key, required this.eventId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late final FeedbackService _service;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  List<FeedbackItem> _feedbacks = [];
  List<FeedbackItem> _filteredFeedbacks = [];
  bool _isLoading = true;
  bool _isOpen = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authService = legacy_provider.Provider.of<AuthService>(
      context,
      listen: false,
    );
    _service = FeedbackService(authService);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final eventId = int.tryParse(widget.eventId) ?? 0;

    // Check status first
    final isOpen = await _service.getFeedbackStatus(eventId);

    // Then load feedbacks
    final feedbacks = await _service.getFeedbacks(eventId);

    if (mounted) {
      setState(() {
        _isOpen = isOpen;
        _feedbacks = feedbacks;
        _filteredFeedbacks = feedbacks;
        _isLoading = false;
      });
    }
  }

  void _filterFeedbacks(String query) {
    if (query.isEmpty) {
      setState(() => _filteredFeedbacks = _feedbacks);
    } else {
      final filtered = _feedbacks
          .where(
            (fb) =>
                fb.content.toLowerCase().contains(query.toLowerCase()) ||
                fb.userName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
      setState(() => _filteredFeedbacks = filtered);
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback must be at least 10 characters'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final eventId = int.tryParse(widget.eventId) ?? 0;
    final success = await _service.submitFeedback(
      eventId,
      _feedbackController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        _feedbackController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload feedbacks
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit feedback'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return isoDate;
    }
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
                    'Feedback',
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
                  color: const Color(0xFFF1F1F6).withValues(alpha: 0.3),
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
                        onChanged: _filterFeedbacks,
                        style: GoogleFonts.roboto(
                          color: const Color(0xFFF1F1F6),
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search feedback...',
                          hintStyle: GoogleFonts.roboto(
                            color: const Color(
                              0xFFF1F1F6,
                            ).withValues(alpha: 0.6),
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
                    : !_isOpen
                    ? _buildLockedState(isMobile)
                    : _buildOpenState(isMobile),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build locked state UI
  Widget _buildLockedState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFFDFE1ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: isMobile ? 60 : 80,
                  color: const Color(0xFF3C4494),
                ),
                const SizedBox(height: 20),
                Text(
                  'LOCKED',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 36 : 50,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Feedback is currently closed for this event',
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 14 : 18,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build open state UI with feedback list and submit form
  Widget _buildOpenState(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFDFE1ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  'Share Your Feedback',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 24 : 36,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your feedback helps us improve future events',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w400,
                    fontSize: isMobile ? 14 : 18,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Submit feedback form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB7B7B7)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write your feedback:',
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF151938),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts about the event...',
                    hintStyle: GoogleFonts.roboto(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFB7B7B7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF3C4494),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C4494),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit Feedback',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Feedback list header
          Text(
            'What others are saying',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 20 : 24,
              color: const Color(0xFF151938),
            ),
          ),

          const SizedBox(height: 15),

          // Feedback list
          if (_filteredFeedbacks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No feedback yet. Be the first to share!',
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ..._filteredFeedbacks.map((fb) => _buildFeedbackCard(fb, isMobile)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Build a single feedback card
  Widget _buildFeedbackCard(FeedbackItem feedback, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDEEB).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 18 : 22,
                backgroundColor: const Color(0xFF3C4494),
                child: Text(
                  feedback.userName.isNotEmpty
                      ? feedback.userName[0].toUpperCase()
                      : 'A',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.userName,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 14 : 16,
                        color: const Color(0xFF151938),
                      ),
                    ),
                    Text(
                      _formatDate(feedback.createdAt),
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback.content,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 14 : 16,
              height: 1.5,
              color: const Color(0xFF151938),
            ),
          ),
        ],
      ),
    );
  }
}
