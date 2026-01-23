import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/services/auth_service.dart';

/// Terms & Conditions Compliance Modal
/// Mandatory modal shown on first login for participants
class TermsComplianceModal extends StatefulWidget {
  final VoidCallback onAccepted;

  const TermsComplianceModal({super.key, required this.onAccepted});

  @override
  State<TermsComplianceModal> createState() => _TermsComplianceModalState();
}

class _TermsComplianceModalState extends State<TermsComplianceModal> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isSubmitting = false;
  String? _error;

  bool get _canProceed => _termsAccepted && _privacyAccepted;

  Future<void> _acceptTerms() async {
    if (!_canProceed) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final token = await authService.getToken();
      // Get participant ID from auth service
      final participantId = authService.currentUser?['id']?.toString() ?? '';

      final response = await http.post(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/participant-auth/accept-terms?participant_id=$participantId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'accept_terms': true}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        widget.onAccepted();
      } else {
        setState(() {
          _error = 'Failed to accept terms. Please try again.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissal
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.policy_outlined,
                    color: const Color(0xFF3C4494),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3C4494),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Please review and accept the following to continue',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Terms Content (Scrollable)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          'Terms of Use',
                          'By using this platform, you agree to comply with all event rules and regulations. You understand that your participation is subject to approval by the event organizers...',
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'Privacy Policy',
                          'We collect and process your personal data in accordance with applicable data protection laws. Your information will be used solely for event management purposes...',
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'Data Usage',
                          'Your visa application data, including passport details and personal information, will be shared with relevant authorities for visa processing purposes only...',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Checkboxes
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() => _termsAccepted = value ?? false);
                      },
                title: const Text(
                  'I accept the Terms of Use',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _privacyAccepted,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() => _privacyAccepted = value ?? false);
                      },
                title: const Text(
                  'I accept the Privacy Policy',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed && !_isSubmitting
                      ? _acceptTerms
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C4494),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Accept and Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3C4494),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800]),
        ),
      ],
    );
  }
}
