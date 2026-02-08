import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../utils/phone_number_util.dart';

/// Reusable phone input field with country code picker
///
/// Stores and returns phone numbers in E.164 format (+[country][number])
/// Displays split view: Country picker + Local number input
class PhoneInputField extends StatefulWidget {
  /// Initial phone in E.164 format (e.g., "+99361444555")
  final String? initialPhone;

  /// Callback when phone changes (returns E.164 format)
  final ValueChanged<String> onChanged;

  /// Label text above the field
  final String? labelText;

  /// Hint text for local number input
  final String? hintText;

  /// Whether the field is required
  final bool required;

  const PhoneInputField({
    super.key,
    this.initialPhone,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.required = false,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late TextEditingController _localNumberController;
  late String _dialCode;

  @override
  void initState() {
    super.initState();

    // Parse initial phone if provided
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      final parsed = PhoneNumberUtil.fromE164(widget.initialPhone!);
      _dialCode = parsed['dialCode']!;
      _localNumberController = TextEditingController(
        text: parsed['localNumber'],
      );
    } else {
      _dialCode = '+993'; // Default to Turkmenistan
      _localNumberController = TextEditingController();
    }

    _localNumberController.addListener(_notifyChange);
  }

  @override
  void dispose() {
    _localNumberController.removeListener(_notifyChange);
    _localNumberController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final e164 = PhoneNumberUtil.toE164(_dialCode, _localNumberController.text);
    widget.onChanged(e164);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.labelText!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country Code Picker
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CountryCodePicker(
                onChanged: (country) {
                  setState(() {
                    _dialCode = country.dialCode ?? '+993';
                    _notifyChange();
                  });
                },
                initialSelection: PhoneNumberUtil.getCountryISO(_dialCode),
                favorite: const ['+993', '+1', '+44', '+7'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                flagWidth: 24,
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            // Local Number Input
            Expanded(
              child: TextFormField(
                controller: _localNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? '61444555',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: widget.required
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
