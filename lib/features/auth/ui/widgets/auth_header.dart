import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared header for auth pages: logo on the left, language selector on the right.
class AuthHeader extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String>? onLanguageChanged;
  final List<String> languages;

  const AuthHeader({
    super.key,
    this.currentLanguage = 'ENG',
    this.onLanguageChanged,
    this.languages = const ['ENG', 'RUS', 'TKM'],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Image.asset(
          'assets/login_signup/login_logo.png',
          height: 50,
          fit: BoxFit.contain,
        ),
        // Language selector
        _LanguageSelector(
          currentLanguage: currentLanguage,
          languages: languages,
          onChanged: onLanguageChanged,
        ),
      ],
    );
  }
}

class _LanguageSelector extends StatefulWidget {
  final String currentLanguage;
  final List<String> languages;
  final ValueChanged<String>? onChanged;

  const _LanguageSelector({
    required this.currentLanguage,
    required this.languages,
    this.onChanged,
  });

  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
  bool _isOpen = false;
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Current language button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Text(
              _selected,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        // Dropdown options
        if (_isOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.languages
                  .where((lang) => lang != _selected)
                  .map(
                    (lang) => MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selected = lang;
                            _isOpen = false;
                          });
                          widget.onChanged?.call(lang);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            lang,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
