import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:b2c_app/core/theme/app_theme.dart';

import '../providers/auth_provider.dart';

/// Page that handles email verification when user clicks the link in their email
class VerifyEmailPage extends ConsumerStatefulWidget {
  final String token;

  const VerifyEmailPage({super.key, required this.token});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _isVerifying = true;
  String? _errorMessage;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    final error = await ref.read(authNotifierProvider.notifier).verifyEmail(widget.token);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      if (error == null) {
        _success = true;
      } else {
        _errorMessage = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(40),
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(25),
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isVerifying) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Verifying your email...',
            style: AppTextStyles.titleLargeMobile,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_success) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          Text(
            'Email Verified!',
            style: AppTextStyles.titleLargeMobile,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your email has been successfully verified. You can now log in to your account.',
            style: AppTextStyles.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonBackground,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Go to Login', style: TextStyle(fontSize: 16)),
          ),
        ],
      );
    }

    // Error state
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 80),
        const SizedBox(height: 24),
        Text(
          'Verification Failed',
          style: AppTextStyles.titleLargeMobile,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Failed to verify email. The link may have expired.',
          style: AppTextStyles.label,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonBackground,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text('Go to Login', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
