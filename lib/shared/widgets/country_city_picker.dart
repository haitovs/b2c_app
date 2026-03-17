import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/reference_data_provider.dart';
import '../../core/theme/app_theme.dart';

/// A pair of searchable dropdowns for selecting a country and its associated city.
///
/// Uses [Autocomplete] for type-ahead search. The city dropdown remains
/// disabled until a country is selected.
class CountryCityPicker extends ConsumerStatefulWidget {
  final String? selectedCountry;
  final String? selectedCity;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onCityChanged;

  const CountryCityPicker({
    super.key,
    this.selectedCountry,
    this.selectedCity,
    required this.onCountryChanged,
    required this.onCityChanged,
  });

  @override
  ConsumerState<CountryCityPicker> createState() => _CountryCityPickerState();
}

class _CountryCityPickerState extends ConsumerState<CountryCityPicker> {
  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(countriesProvider);
    final citiesAsync = widget.selectedCountry != null
        ? ref.watch(citiesProvider(widget.selectedCountry!))
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country
        Expanded(
          child: countriesAsync.when(
            loading: () => _buildLoadingField(label: 'Country:'),
            error: (err, _) => _buildErrorField(label: 'Country:'),
            data: (countries) => _buildSearchableField(
              label: 'Country:',
              hint: 'Search country...',
              value: widget.selectedCountry,
              items: countries,
              onSelected: (value) {
                widget.onCountryChanged(value);
                widget.onCityChanged(null);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // City
        Expanded(
          child: citiesAsync == null
              ? _buildSearchableField(
                  label: 'City:',
                  hint: 'Select country first',
                  value: null,
                  items: const [],
                  onSelected: null,
                  enabled: false,
                )
              : citiesAsync.when(
                  loading: () => _buildLoadingField(label: 'City:'),
                  error: (err, _) => _buildErrorField(label: 'City:'),
                  data: (cities) => _buildSearchableField(
                    label: 'City:',
                    hint: 'Search city...',
                    value: widget.selectedCity,
                    items: cities,
                    onSelected: widget.onCityChanged,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchableField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onSelected,
    bool enabled = true,
  }) {
    final effectiveValue =
        (value != null && items.contains(value)) ? value : null;

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
        if (!enabled || items.isEmpty)
          TextFormField(
            enabled: false,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDeco(hint).copyWith(
              fillColor: Colors.grey.shade100,
              suffixIcon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade400),
            ),
          )
        else
          Autocomplete<String>(
            initialValue: TextEditingValue(text: effectiveValue ?? ''),
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) return items;
              final query = textEditingValue.text.toLowerCase();
              return items
                  .where((item) => item.toLowerCase().contains(query))
                  .toList();
            },
            onSelected: (selection) => onSelected?.call(selection),
            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: textController,
                focusNode: focusNode,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: _inputDeco(hint).copyWith(
                  suffixIcon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade600),
                ),
                onFieldSubmitted: (_) => onFieldSubmitted(),
                onChanged: (val) {
                  if (val.isEmpty) onSelected?.call(null);
                },
              );
            },
            optionsViewBuilder: (context, onSel, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 240, maxWidth: 400),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSel(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              option,
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
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

  Widget _buildErrorField({required String label}) {
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
