import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/visa_service.dart';

/// Page showing all visa applications for the current user + event.
/// Users can create new applications and tap existing ones to edit/view.
class VisaListPage extends StatefulWidget {
  final int eventId;

  const VisaListPage({super.key, required this.eventId});

  @override
  State<VisaListPage> createState() => _VisaListPageState();
}

class _VisaListPageState extends State<VisaListPage> {
  static const _primaryColor = Color(0xFF3C4494);

  List<Map<String, dynamic>> _visas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVisas());
  }

  Future<void> _loadVisas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final visaService = context.read<VisaService>();
      final visas = await visaService.listMyVisas(eventId: widget.eventId);
      if (mounted) {
        setState(() {
          _visas = visas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewVisa() async {
    try {
      final visaService = context.read<VisaService>();
      final newVisa = await visaService.createMyVisa(eventId: widget.eventId);
      if (mounted) {
        final visaId = newVisa['id'] as String;
        context.push('/events/${widget.eventId}/visa-apply?visaId=$visaId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openVisa(Map<String, dynamic> visa) {
    final visaId = visa['id'] as String;
    final status = visa['status'] as String? ?? '';

    if (status == 'PENDING') {
      context.push('/events/${widget.eventId}/visa/status/me?visaId=$visaId');
    } else if (status == 'APPROVED') {
      context.push('/events/${widget.eventId}/visa/details/me?visaId=$visaId');
    } else {
      context.push('/events/${widget.eventId}/visa-apply?visaId=$visaId');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'FILL_OUT':
      case 'NOT_STARTED':
        return const Color(0xFFE8E84F);
      case 'PENDING':
        return const Color(0xFFB39656);
      case 'APPROVED':
        return const Color(0xFF4CAF50);
      case 'DECLINED':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'FILL_OUT':
      case 'NOT_STARTED':
        return 'Fill Out';
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'DECLINED':
        return 'Declined';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Visa Applications',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: _primaryColor),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF666666))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadVisas,
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadVisas,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Title section
          const Text(
            'Visa & Travel Center',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage visa applications for yourself and family members.',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),

          // Add new button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _createNewVisa,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add New Visa Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(color: _primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Visa cards
          if (_visas.isEmpty)
            _buildEmptyState()
          else
            ..._visas.map((visa) => _buildVisaCard(visa)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.flight_takeoff, size: 48, color: Color(0xFFBBBBBB)),
          const SizedBox(height: 16),
          const Text(
            'No visa applications yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button above to create your first application.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildVisaCard(Map<String, dynamic> visa) {
    final status = visa['status'] as String? ?? 'FILL_OUT';
    final firstName = visa['first_name'] as String? ?? '';
    final lastName = visa['last_name'] as String? ?? '';
    final applicantName = '$firstName $lastName'.trim();
    final createdAt = visa['created_at'] as String?;
    final statusColor = _statusColor(status);

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt);
        formattedDate = DateFormat('MMM d, yyyy').format(dt);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: () => _openVisa(visa),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Row(
              children: [
                // Left: person icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.person_outline, color: _primaryColor, size: 24),
                ),
                const SizedBox(width: 14),

                // Center: name + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicantName.isNotEmpty ? applicantName : 'New Application',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      if (formattedDate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Created $formattedDate',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                          ),
                        ),
                    ],
                  ),
                ),

                // Right: status badge + arrow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status == 'FILL_OUT' || status == 'NOT_STARTED'
                          ? Colors.black87
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
