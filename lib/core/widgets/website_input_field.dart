import 'package:flutter/material.dart';
import '../utils/url_util.dart';
import 'app_text_field.dart';

/// Website input field that accepts domain only and stores as HTTPS URL
///
/// User enters: example.com
/// Stored as: https://example.com
class WebsiteInputField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool required;
  final void Function(String)? onChanged;

  const WebsiteInputField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.validator,
    this.required = false,
    this.onChanged,
  });

  @override
  State<WebsiteInputField> createState() => _WebsiteInputFieldState();
}

class _WebsiteInputFieldState extends State<WebsiteInputField> {
  late TextEditingController _internalController;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _internalController = TextEditingController();
      _isInternalController = true;
    } else {
      _internalController = widget.controller!;
      // Extract domain if controller has https:// URL
      if (_internalController.text.isNotEmpty) {
        _internalController.text = UrlUtil.extractDomain(
          _internalController.text,
        );
      }
    }

    _internalController.addListener(_handleChange);
  }

  @override
  void dispose() {
    _internalController.removeListener(_handleChange);
    if (_isInternalController) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _handleChange() {
    if (widget.onChanged != null && _internalController.text.isNotEmpty) {
      // Convert domain to HTTPS URL before calling onChanged
      final httpsUrl = UrlUtil.toHttpsUrl(_internalController.text);
      widget.onChanged!(httpsUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      labelText: widget.labelText,
      hintText: widget.hintText ?? 'example.com',
      controller: _internalController,
      keyboardType: TextInputType.url,
      required: widget.required,
      validator:
          widget.validator ?? (widget.required ? _validateWebsite : null),
      suffix: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'https://',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  String? _validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Website is required';
    }

    // Extract domain if user entered full URL
    final domain = UrlUtil.extractDomain(value);

    // Validate domain format
    if (!UrlUtil.isValidDomain(domain)) {
      return 'Please enter a valid domain (e.g., example.com)';
    }

    return null;
  }
}
