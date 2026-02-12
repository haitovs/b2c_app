import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import 'auth_header.dart';
import 'auth_footer.dart';

/// Shared layout for all auth pages:
/// - Dark blue/purple gradient background
/// - White rounded card with left image + right form
/// - Responsive: hides image on mobile
class AuthPageLayout extends StatelessWidget {
  /// The form content to display on the right side of the card.
  final Widget child;

  /// Whether the right-side form content should be scrollable.
  final bool scrollable;

  /// Fixed height for the card on desktop. If null, uses intrinsic height.
  final double? desktopCardHeight;

  /// Current language for the header.
  final String currentLanguage;

  /// Callback when language changes.
  final ValueChanged<String>? onLanguageChanged;

  /// Mobile breakpoint width.
  final double mobileBreakpoint;

  const AuthPageLayout({
    super.key,
    required this.child,
    this.scrollable = false,
    this.desktopCardHeight,
    this.currentLanguage = 'ENG',
    this.onLanguageChanged,
    this.mobileBreakpoint = 800,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < mobileBreakpoint;
            final cardWidth = isMobile
                ? constraints.maxWidth * 0.95
                : (constraints.maxWidth > 950
                    ? 950.0
                    : constraints.maxWidth * 0.95);

            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: isMobile
                      ? _buildMobileLayout()
                      : _buildDesktopLayout(cardWidth),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthHeader(
            currentLanguage: currentLanguage,
            onLanguageChanged: onLanguageChanged,
          ),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 30),
          const AuthFooter(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(double cardWidth) {
    final formContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthHeader(
            currentLanguage: currentLanguage,
            onLanguageChanged: onLanguageChanged,
          ),
          const SizedBox(height: 20),
          Flexible(
            child: scrollable
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: child,
                  )
                : Center(child: child),
          ),
          const SizedBox(height: 20),
          const AuthFooter(),
        ],
      ),
    );

    return SizedBox(
      height: desktopCardHeight ?? 620,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left image section
          Container(
            width: cardWidth * 0.42,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                bottomLeft: Radius.circular(35),
              ),
              image: DecorationImage(
                image: AssetImage('assets/login_signup/login_image.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Right form section
          Expanded(child: formContent),
        ],
      ),
    );
  }
}
