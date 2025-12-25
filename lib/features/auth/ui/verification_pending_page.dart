import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'login_page.dart';

/// Page shown after registration, prompting user to verify their email
class VerificationPendingPage extends StatefulWidget {
  final String email;

  const VerificationPendingPage({super.key, required this.email});

  @override
  State<VerificationPendingPage> createState() =>
      _VerificationPendingPageState();
}

class _VerificationPendingPageState extends State<VerificationPendingPage> {
  bool _isResending = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _message = null;
    });

    final error = await context.read<AuthService>().resendVerificationEmail(
      widget.email,
    );

    if (!mounted) return;

    setState(() {
      _isResending = false;
      if (error == null) {
        _message = "Verification email sent! Check your inbox.";
        _isSuccess = true;
      } else {
        _message = error;
        _isSuccess = false;
      }
    });
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3C4494), Color(0xFF5B6BC0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Email icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C4494).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_rounded,
                        size: 50,
                        color: Color(0xFF3C4494),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      "Verify Your Email",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      "We've sent a verification link to:",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Email address
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3C4494),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Instructions
                    Text(
                      "Click the link in the email to verify your account. "
                      "Once verified, you can log in to access B2C Events.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Message (success/error)
                    if (_message != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSuccess ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: _isSuccess ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _message!,
                                style: TextStyle(
                                  color: _isSuccess ? Colors.green : Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Resend button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isResending ? null : _resendEmail,
                        icon: _isResending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF3C4494),
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(
                          _isResending ? "Sending..." : "Resend Email",
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3C4494),
                          side: const BorderSide(color: Color(0xFF3C4494)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Back to login button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C4494),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Back to Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Help text
                    Text(
                      "Didn't receive the email? Check your spam folder or try resending.",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
