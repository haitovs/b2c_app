import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../services/auth_service.dart';
import 'forgot_password_verify_code_page.dart';
import 'widgets/auth_info_box.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_button.dart';
import 'widgets/send_me_back_link.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthInfoBox(
                text: "Enter your Email and instructions will be sent to you!",
              ),
              const SizedBox(height: 20),

              // Email field
              AppTextField(
                labelText: "Email address:",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendRecoveryEmail(),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF4444),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFFF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Send recovery Email button
              AuthButton(
                text: "Send recovery Email",
                isLoading: _isLoading,
                onTap: _sendRecoveryEmail,
              ),
              const SizedBox(height: 20),

              // FORGET IT, SEND ME BACK TO THE SIGN IN
              const Center(child: SendMeBackLink()),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendRecoveryEmail() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = "Please enter your email address.");
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = "Please enter a valid email address.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final error = await _authService.forgotPassword(email);

      if (!mounted) return;

      if (error == null) {
        // Success - navigate to verify code page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ForgotPasswordVerifyCodePage(email: email),
          ),
        );
      } else {
        setState(
          () => _errorMessage = "Your email is incorrect. Please try again!",
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = "An unexpected error occurred. Please try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
