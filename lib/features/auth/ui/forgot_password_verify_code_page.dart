import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_theme.dart';
import '../services/auth_service.dart';
import 'reset_password_page.dart';
import 'widgets/auth_info_box.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_button.dart';
import 'widgets/send_me_back_link.dart';

class ForgotPasswordVerifyCodePage extends StatefulWidget {
  final String email;

  const ForgotPasswordVerifyCodePage({super.key, required this.email});

  @override
  State<ForgotPasswordVerifyCodePage> createState() =>
      _ForgotPasswordVerifyCodePageState();
}

class _ForgotPasswordVerifyCodePageState
    extends State<ForgotPasswordVerifyCodePage> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

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
        Text(
          "Forgot Your Password?",
          style: AppTextStyles.titleLargeDesktop,
        ),
        const SizedBox(height: 25),

        SizedBox(
          width: 320,
          child: Column(
            children: [
              const AuthInfoBox(
                text:
                    "A verification code has been successfully sent to your email address. Please check your inbox (and spam folder) to proceed.",
              ),
              const SizedBox(height: 25),

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
                  onFieldSubmitted: (_) => _verifyCode(),
                ),
              ),
              const SizedBox(height: 25),

              // Verify Code button
              AuthButton(
                text: "Verify Code",
                isLoading: _isLoading,
                onTap: _verifyCode,
              ),
              const SizedBox(height: 20),

              // FORGET IT, SEND ME BACK TO THE SIGN IN
              const SendMeBackLink(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showError("Please enter the verification code.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await _authService.verifyResetCode(widget.email, code);

      if (!mounted) return;

      if (error == null) {
        // Success - navigate to reset password page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(
              email: widget.email,
              code: code,
            ),
          ),
        );
      } else {
        _showError(error);
      }
    } catch (e) {
      if (mounted) {
        _showError("An unexpected error occurred. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
