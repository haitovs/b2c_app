import 'package:flutter/material.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                text: labelText,
                style: Theme.of(context).textTheme.labelLarge,
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          validator: validator ?? (required ? _defaultValidator : null),
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          enabled: enabled,
          decoration: InputDecoration(hintText: hintText, suffixIcon: suffix),
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
