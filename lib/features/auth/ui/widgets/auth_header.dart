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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentLanguage;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
    setState(() {});
  }

  OverlayEntry _createOverlayEntry() {
    final options = widget.languages.where((lang) => lang != _selected).toList();

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible backdrop to close dropdown on outside tap
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _removeOverlay();
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          // Dropdown positioned directly below the button
          Positioned(
            width: 60,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 24),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: options
                      .map(
                        (lang) => InkWell(
                          onTap: () {
                            setState(() => _selected = lang);
                            _removeOverlay();
                            widget.onChanged?.call(lang);
                          },
                          child: Container(
                            width: 60,
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
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggleDropdown,
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
    );
  }
}
