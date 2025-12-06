import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

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
            final isMobile = constraints.maxWidth < 800;
            // Ensure card fits within screen with limited max width
            final cardWidth = isMobile
                ? constraints.maxWidth * 0.95
                : (constraints.maxWidth > 900
                      ? 900.0
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
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: _buildFormContent(isMobile: true),
    );
  }

  Widget _buildDesktopLayout(double cardWidth) {
    // FIX: Using SizedBox with fixed height to prevent IntrinsicHeight crashes
    return SizedBox(
      height: 600, // Fixed height for Login Page (shorter than registration)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          Container(
            width: cardWidth * 0.45, // Proportional width
            decoration: const BoxDecoration(
              color: Colors.grey, // Placeholder for image
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                bottomLeft: Radius.circular(35),
              ),
              image: DecorationImage(
                image: AssetImage('assets/login_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Login Form Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30, // Reduced padding
                vertical: 40,
              ),
              child: Center(child: _buildFormContent(isMobile: false)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent({required bool isMobile}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Login Title
        Text(
          AppLocalizations.of(context)!.loginTitle,
          style: isMobile
              ? AppTextStyles.titleLargeMobile
              : AppTextStyles.titleLargeDesktop,
        ),
        const SizedBox(height: 25),

        SizedBox(
          width: 320, // Constrained width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username Field
              Text(
                AppLocalizations.of(context)!.usernamePlaceholder,
                style: AppTextStyles.placeholder.copyWith(
                  color: AppColors.textPlaceholder,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 45,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  style: AppTextStyles.inputText,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Password Field
              Text(
                AppLocalizations.of(context)!.passwordPlaceholder,
                style: AppTextStyles.placeholder.copyWith(
                  color: AppColors.textPlaceholder,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 45,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  style: AppTextStyles.inputText,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Remember Me
              Row(
                children: [
                  SizedBox(
                    width: 17,
                    height: 18,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (val) => setState(() => _rememberMe = val!),
                      activeColor: AppColors.checkboxActive,
                      side: const BorderSide(
                        color: AppColors.checkboxActive,
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.rememberMe,
                    style: AppTextStyles.rememberMe.copyWith(
                      fontSize: 16,
                    ), // Adjusted size
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Don't have account
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.push('/register'),
                    child: _HoverText(
                      text: AppLocalizations.of(context)!.dontHaveAccount,
                      baseStyle: AppTextStyles.dontHaveAccount,
                      hoverColor: AppColors.buttonBackground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Login Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _login,
                  child: _HoverContainer(
                    child: Text(
                      AppLocalizations.of(context)!.loginButton,
                      style: AppTextStyles.buttonTextLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Footer
        _buildFooter(),
      ],
    );
  }

  Widget _buildFooter() {
    return LayoutBuilder(
      builder: (context, footerConstraints) {
        return Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 5,
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text("All rights reserved", style: AppTextStyles.footer),
            Container(width: 1, height: 12, color: AppColors.textFooter),
            // Privacy Policy
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: _HoverText(
                  text: AppLocalizations.of(
                    context,
                  )!.privacyPolicy.split('|')[1].trim(), // "Privacy Policy"
                  baseStyle: AppTextStyles.footer,
                  hoverColor: AppColors.buttonBackground,
                ),
              ),
            ),
            Container(width: 1, height: 12, color: AppColors.textFooter),
            // Terms of Use
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: _HoverText(
                  text: AppLocalizations.of(context)!.terms,
                  baseStyle: AppTextStyles.footer,
                  hoverColor: AppColors.buttonBackground,
                ),
              ),
            ),
            Container(width: 1, height: 12, color: AppColors.textFooter),
            // Powered By
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HoverText(
                  text: "Powered by",
                  baseStyle: AppTextStyles.footer,
                  hoverColor: AppColors.buttonBackground,
                ),
                const SizedBox(width: 5),
                Image.asset("assets/rotating-logo.gif", width: 24, height: 24),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    final errorMessage = await context.read<AuthService>().login(
      _usernameController.text,
      _passwordController.text,
      rememberMe: _rememberMe,
    );
    if (!mounted) return;
    if (errorMessage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Successful")));
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage), // Show detailed error
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Simple Hover Text Widget (Duplicated to avoid extra file for now, ideally in widgets/common)
class _HoverText extends StatefulWidget {
  final String text;
  final TextStyle baseStyle;
  final Color hoverColor;

  const _HoverText({
    required this.text,
    required this.baseStyle,
    required this.hoverColor,
  });

  @override
  State<_HoverText> createState() => _HoverTextState();
}

class _HoverTextState extends State<_HoverText> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Text(
        widget.text,
        style: widget.baseStyle.copyWith(
          color: _isHovering ? widget.hoverColor : widget.baseStyle.color,
        ),
      ),
    );
  }
}

// Hover Container Widget for Button
class _HoverContainer extends StatefulWidget {
  final Widget child;

  const _HoverContainer({required this.child});

  @override
  State<_HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<_HoverContainer> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        width: double.infinity,
        height: 50, // 50 for login
        decoration: BoxDecoration(
          color: _isHovering
              ? AppColors.buttonBackground.withOpacity(0.9)
              : AppColors.buttonBackground,
          borderRadius: BorderRadius.circular(45),
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
