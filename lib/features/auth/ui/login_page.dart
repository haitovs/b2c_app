import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final _authService = AuthService();

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
                        color: AppColors.checkboxBorder,
                        width: 1,
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
                child: GestureDetector(
                  onTap: () => context.push('/register'),
                  child: Text(
                    AppLocalizations.of(context)!.dontHaveAccount,
                    style: AppTextStyles.dontHaveAccount,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Login Button
              GestureDetector(
                onTap: _login,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.buttonBackground,
                    borderRadius: BorderRadius.circular(45),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.loginButton,
                    style: AppTextStyles.buttonTextLarge,
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
            GestureDetector(
              onTap: () {},
              child: Text(
                AppLocalizations.of(
                  context,
                )!.privacyPolicy.split('|')[1].trim(), // "Privacy Policy"
                style: AppTextStyles.footer,
              ),
            ),
            Container(width: 1, height: 12, color: AppColors.textFooter),
            // Terms of Use
            GestureDetector(
              onTap: () {},
              child: Text(
                AppLocalizations.of(context)!.terms,
                style: AppTextStyles.footer,
              ),
            ),

            Container(width: 1, height: 12, color: AppColors.textFooter),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Powered by", style: AppTextStyles.footer),
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
    final success = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Successful")));
      context.go('/');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Failed")));
    }
  }
}
