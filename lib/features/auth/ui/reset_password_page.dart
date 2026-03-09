import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import 'widgets/auth_info_box.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_button.dart';
import 'widgets/send_me_back_link.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;
  final String code;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
          "Reset Password",
          style: AppTextStyles.titleLargeDesktop,
        ),
        const SizedBox(height: 25),

        SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthInfoBox(
                text:
                    "Please enter your new password below to complete the reset process.",
              ),
              const SizedBox(height: 20),

              // New Password
              AppPasswordField(
                labelText: "New Password",
                controller: _newPasswordController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

              // Confirm Password
              AppPasswordField(
                labelText: "Confirm Password",
                controller: _confirmPasswordController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _resetPassword(),
              ),
              const SizedBox(height: 25),

              // Reset Password button
              AuthButton(
                text: "Reset Password",
                isLoading: _isLoading,
                onTap: _resetPassword,
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

  Future<void> _resetPassword() async {
    if (_isLoading) return;

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      _showError("Please enter a new password.");
      return;
    }
    if (newPassword.length < 8) {
      _showError("Password must be at least 8 characters long.");
      return;
    }
    if (newPassword != confirmPassword) {
      _showError("Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await ref.read(authNotifierProvider.notifier).resetPassword(
        widget.email,
        widget.code,
        newPassword,
      );

      if (!mounted) return;

      if (error == null) {
        AppSnackBar.showSuccess(context, "Password reset successfully! Please login with your new password.");
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    AppSnackBar.showError(context, message);
  }
}
