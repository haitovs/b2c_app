import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';

/// Shared full-width rounded button for auth pages with loading state.
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;

  const AuthButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: isLoading ? SystemMouseCursors.wait : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: isLoading
                ? AppColors.buttonBackground.withValues(alpha: 0.6)
                : AppColors.buttonBackground,
            borderRadius: BorderRadius.circular(45),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(text, style: AppTextStyles.buttonTextLarge),
        ),
      ),
    );
  }
}
