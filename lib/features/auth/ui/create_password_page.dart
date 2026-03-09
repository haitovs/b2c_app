import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_info_box.dart';
import 'widgets/auth_page_layout.dart';

/// Create Password page — shown to team members invited by an administrator.
/// Accessed via one-time token link (e.g. /create-password?token=xxx).
class CreatePasswordPage extends ConsumerStatefulWidget {
  final String token;
  final String? eventId;

  const CreatePasswordPage({super.key, required this.token, this.eventId});

  @override
  ConsumerState<CreatePasswordPage> createState() =>
      _CreatePasswordPageState();
}

class _CreatePasswordPageState extends ConsumerState<CreatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await ref.read(authNotifierProvider.notifier).createPassword(
          widget.token,
          _passwordController.text.trim(),
        );

    if (!mounted) return;

    if (error == null) {
      if (!mounted) return;
      // If we have an event ID, go directly to that event's dashboard
      if (widget.eventId != null && widget.eventId!.isNotEmpty) {
        context.go('/events/${widget.eventId}/dashboard');
      } else {
        context.go('/post-login');
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      scrollable: true,
      desktopCardHeight: 620,
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Create Password',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const AuthInfoBox(
            text:
                'You have been registered as a participant for the event. '
                'To access your personal account, please create a secure password below.',
          ),
          const SizedBox(height: 24),

          // Password field
          Text('New Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Enter your password',

              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Password is required';
              if (value.trim().length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm password field
          Text('Confirm Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Re-enter your password',

              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please confirm your password';
              if (value.trim() != _passwordController.text.trim()) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Password hints
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Password must be at least 8 characters',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: AuthButton(
              text: 'Create Password',
              onTap: _isLoading ? null : _handleSubmit,
              isLoading: _isLoading,
            ),
          ),

          if (widget.token.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Invalid or missing invitation token. Please use the link from your invitation email.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.orange.shade800),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
