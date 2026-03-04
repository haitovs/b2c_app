import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/reference_data_provider.dart';
import '../../core/theme/app_theme.dart';

/// A pair of dropdowns for selecting a country and its associated city.
///
/// The country list is loaded from [countriesProvider] and the city list from
/// [citiesProvider] (keyed by the selected country). The city dropdown remains
/// disabled until a country is selected.
///
/// Both dropdowns use the standard [InputDecoration] styling from [AppTheme].
///
/// ```dart
/// CountryCityPicker(
///   selectedCountry: _country,
///   selectedCity: _city,
///   onCountryChanged: (c) => setState(() { _country = c; _city = null; }),
///   onCityChanged: (c) => setState(() => _city = c),
/// )
/// ```
class CountryCityPicker extends ConsumerWidget {
  /// Currently selected country, or `null` when none is chosen.
  final String? selectedCountry;

  /// Currently selected city, or `null` when none is chosen.
  final String? selectedCity;

  /// Called when the user picks a different country (or clears the selection).
  final ValueChanged<String?> onCountryChanged;

  /// Called when the user picks a different city (or clears the selection).
  final ValueChanged<String?> onCityChanged;

  const CountryCityPicker({
    super.key,
    this.selectedCountry,
    this.selectedCity,
    required this.onCountryChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countriesAsync = ref.watch(countriesProvider);
    final citiesAsync = selectedCountry != null
        ? ref.watch(citiesProvider(selectedCountry!))
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country dropdown
        Expanded(
          child: countriesAsync.when(
            loading: () => _buildLoadingField(label: 'Country'),
            error: (err, _) => _buildErrorField(label: 'Country', error: err),
            data: (countries) => _buildDropdown(
              label: 'Country',
              hint: 'Select country',
              value: selectedCountry,
              items: countries,
              onChanged: (value) {
                onCountryChanged(value);
                // Reset city when country changes.
                onCityChanged(null);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // City dropdown
        Expanded(
          child: citiesAsync == null
              ? _buildDropdown(
                  label: 'City',
                  hint: 'Select city',
                  value: null,
                  items: const [],
                  onChanged: null,
                  enabled: false,
                )
              : citiesAsync.when(
                  loading: () => _buildLoadingField(label: 'City'),
                  error: (err, _) =>
                      _buildErrorField(label: 'City', error: err),
                  data: (cities) => _buildDropdown(
                    label: 'City',
                    hint: 'Select city',
                    value: selectedCity,
                    items: cities,
                    onChanged: onCityChanged,
                  ),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    bool enabled = true,
  }) {
    // Ensure the current value exists in the items list; otherwise drop it.
    final effectiveValue = (value != null && items.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: effectiveValue,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          isExpanded: true,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingField({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorField({required String label, required Object error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.errorColor),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Failed to load',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
