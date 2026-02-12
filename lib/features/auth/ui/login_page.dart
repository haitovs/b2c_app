import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../services/auth_service.dart';
import 'verification_pending_page.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_button.dart';
import 'widgets/hover_text.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      desktopCardHeight: 620,
      child: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Login Title
        Text(
          AppLocalizations.of(context)!.loginTitle,
          style: AppTextStyles.titleLargeDesktop,
        ),
        const SizedBox(height: 25),

        SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username Field
              AppTextField(
                labelText: "Name, phone number or email address",
                controller: _usernameController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

              // Password Field
              AppPasswordField(
                labelText: AppLocalizations.of(context)!.passwordPlaceholder,
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 20),

              // Remember Me + Forgot Password row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Remember me
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 17,
                        height: 18,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) =>
                              setState(() => _rememberMe = val!),
                          activeColor: AppColors.checkboxActive,
                          side: const BorderSide(
                            color: AppColors.checkboxActive,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.rememberMe,
                        style: AppTextStyles.rememberMe.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  // Forgot Password
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                      child: HoverText(
                        text: "Forgot Password?",
                        baseStyle: AppTextStyles.rememberMe.copyWith(
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                        hoverColor: AppColors.buttonBackground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Don't have account
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.push('/signup'),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: AppTextStyles.dontHaveAccount,
                        children: [
                          TextSpan(
                            text: "Sign up",
                            style: AppTextStyles.dontHaveAccount.copyWith(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Login Button
              AuthButton(
                text: AppLocalizations.of(context)!.loginButton,
                isLoading: _isLoading,
                onTap: _login,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _login() async {
    if (_isLoading) return;

    if (_usernameController.text.trim().isEmpty) {
      _showError("Please enter your email or mobile number");
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError("Please enter your password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final errorMessage = await context.read<AuthService>().login(
        _usernameController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/');
      } else if (errorMessage == 'EMAIL_NOT_VERIFIED') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationPendingPage(
              email: _usernameController.text.trim(),
            ),
          ),
        );
      } else {
        _showError(errorMessage);
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
