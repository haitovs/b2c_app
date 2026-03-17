import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_fade_in.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../providers/feedback_providers.dart';
import '../services/feedback_service.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  final String eventId;

  const FeedbackPage({super.key, required this.eventId});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
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
    _service = ref.read(feedbackServiceProvider);
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
      AppSnackBar.showWarning(context, 'Feedback must be at least 10 characters');
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
        AppSnackBar.showSuccess(context, 'Feedback submitted successfully!');
        // Reload feedbacks
        _loadData();
      } else {
        AppSnackBar.showError(context, 'Failed to submit feedback');
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return AnimatedFadeIn(
      child: Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Feedback',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // Search bar
          TextField(
            controller: _searchController,
            onChanged: _filterFeedbacks,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search feedback...',
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
          const SizedBox(height: 20),

          // Content
          Expanded(
            child: !_isOpen
                ? _buildLockedState(isMobile)
                : _buildOpenState(isMobile),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildLockedState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: isMobile ? 48 : 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Feedback Closed',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 18 : 22,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feedback is currently closed for this event',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOpenState(bool isMobile) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submit feedback form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your feedback',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your feedback helps us improve future events',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts about the event...',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: AppTheme.primaryButtonStyle,
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
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Feedback list header
          Text(
            'What others are saying',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // Feedback list
          if (_filteredFeedbacks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No feedback yet. Be the first to share!',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                ),
              ),
            )
          else
            ..._filteredFeedbacks.map((fb) => _buildFeedbackCard(fb, isMobile)),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackItem feedback, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  feedback.userName.isNotEmpty
                      ? feedback.userName[0].toUpperCase()
                      : 'A',
                  style: GoogleFonts.montserrat(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatDate(feedback.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
