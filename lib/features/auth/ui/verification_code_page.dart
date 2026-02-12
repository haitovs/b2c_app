import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_theme.dart';
import '../services/auth_service.dart';
import 'widgets/auth_info_box.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_button.dart';
import 'widgets/hover_text.dart';

/// Page shown after registration where user enters the verification code
/// sent to their email.
class VerificationCodePage extends StatefulWidget {
  final String email;

  const VerificationCodePage({super.key, required this.email});

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isVerifying = false;
  bool _isResending = false;

  /// Mask email: "test@gmail.com" -> "te******il.com"
  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;

    final local = parts[0];
    final domain = parts[1];

    final maskedLocal = local.length <= 4
        ? '${local[0]}${'*' * (local.length - 1)}'
        : '${local.substring(0, 2)}${'*' * (local.length - 2)}';

    return '$maskedLocal@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      desktopCardHeight: 620,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          "Enter your\nverification code",
          textAlign: TextAlign.left,
          style: AppTextStyles.titleLargeDesktop.copyWith(
            height: 1.3,
          ),
        ),
        const SizedBox(height: 25),

        SizedBox(
          width: 320,
          child: Column(
            children: [
              // Info box with masked email
              AuthInfoBox(
                text: "Please enter the code we sent to\n$_maskedEmail",
              ),
              const SizedBox(height: 20),

              // Code input field
              SizedBox(
                height: 48,
                child: TextFormField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.buttonBackground,
                        width: 2,
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) => _verify(),
                ),
              ),
              const SizedBox(height: 20),

              // Verify button
              AuthButton(
                text: "Verify",
                isLoading: _isVerifying,
                onTap: _verify,
              ),
              const SizedBox(height: 20),

              // Didn't get the code? Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't get the code? ",
                    style: AppTextStyles.dontHaveAccount,
                  ),
                  MouseRegion(
                    cursor: _isResending
                        ? SystemMouseCursors.wait
                        : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isResending ? null : _resendCode,
                      child: _isResending
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : HoverText(
                              text: "Resent Code",
                              baseStyle:
                                  AppTextStyles.dontHaveAccount.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                              hoverColor: AppColors.buttonBackground,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Go back & edit email
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/signup');
                    }
                  },
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Go back",
                          style: AppTextStyles.dontHaveAccount.copyWith(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: " & edit email",
                          style: AppTextStyles.dontHaveAccount,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _verify() async {
    if (_isVerifying) return;

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showError("Please enter the verification code");
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final error = await _authService.verifyCode(widget.email, code);

      if (!mounted) return;

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email verified successfully! Please login."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/login');
      } else {
        _showError(error);
      }
    } catch (e) {
      if (mounted) {
        _showError("An unexpected error occurred. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    try {
      final error = await _authService.resendCode(widget.email);

      if (!mounted) return;

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification code sent! Check your email."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        _showError(error);
      }
    } catch (e) {
      if (mounted) {
        _showError("Failed to resend code. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
