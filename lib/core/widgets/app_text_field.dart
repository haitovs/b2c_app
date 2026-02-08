import 'package:flutter/material.dart';
import 'package:b2c_app/core/app_theme.dart';

/// Reusable text field widget with consistent styling
class AppTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool required;
  final int? maxLines;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final double borderRadius;
  final double height;
  final Color? fillColor;
  final bool showBorder;

  const AppTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.required = false,
    this.maxLines = 1,
    this.suffix,
    this.onChanged,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    this.borderRadius = 12,
    this.height = 50,
    this.fillColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: RichText(
              text: TextSpan(
                text: labelText,
                style: AppTextStyles.label,
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                ],
              ),
            ),
          ),
        SizedBox(
          height: height,
          child: TextFormField(
            controller: controller,
            validator: validator ?? (required ? _defaultValidator : null),
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            onChanged: onChanged,
            enabled: enabled,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            style: AppTextStyles.inputText,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.placeholder,
              suffixIcon: suffix,
              filled: true,
              fillColor: fillColor ?? Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: showBorder
                    ? BorderSide(color: AppColors.inputBorder, width: 1)
                    : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: showBorder
                    ? BorderSide(color: AppColors.inputBorder, width: 1)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: AppColors.buttonBackground,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '$labelText is required';
    }
    return null;
  }
}
