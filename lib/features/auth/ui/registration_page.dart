import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../services/auth_service.dart';
import 'verification_pending_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _websiteController = TextEditingController();
  final _companyNameController = TextEditingController();
  bool _rememberMe = false;

  String _countryCode = "+993"; // Default code

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
            final isMobile = constraints.maxWidth < 1000;
            // Centralized card, fitting screen
            final cardWidth = isMobile ? constraints.maxWidth * 0.95 : 1050.0;

            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), // Smooth scrolling
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
      padding: const EdgeInsets.all(30),
      child: _buildFormContent(isMobile: true),
    );
  }

  Widget _buildDesktopLayout(double cardWidth) {
    return SizedBox(
      height: 750, // Fixed height for desktop layout
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          Container(
            width: cardWidth * 0.40,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                bottomLeft: Radius.circular(35),
              ),
              image: DecorationImage(
                image: AssetImage('registration_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Form Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Center(
                // Center vertically
                child: _buildFormContent(isMobile: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(context)!.registrationTitle,
          style: isMobile
              ? AppTextStyles.titleLargeMobile
              : AppTextStyles.titleLargeDesktop,
        ),
        const SizedBox(height: 25),

        SizedBox(
          // Constrain form width so 2-columns look robust
          width: isMobile ? double.infinity : 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name & Surname row
              _buildDualField(
                context,
                field1: _buildFieldData(
                  label: AppLocalizations.of(context)!.nameLabel,
                  placeholder: AppLocalizations.of(context)!.namePlaceholder,
                  controller: _nameController,
                ),
                field2: _buildFieldData(
                  label: AppLocalizations.of(context)!.surnameLabel,
                  placeholder: AppLocalizations.of(context)!.surnamePlaceholder,
                  controller: _surnameController,
                ),
              ),
              const SizedBox(height: 15),

              // Email (Full width)
              _buildField(
                context,
                label: AppLocalizations.of(context)!.emailLabel,
                placeholder: AppLocalizations.of(context)!.emailPlaceholder,
                controller: _emailController,
              ),
              const SizedBox(height: 15),

              // Password & Confirm row
              _buildDualField(
                context,
                field1: _buildFieldData(
                  label: AppLocalizations.of(context)!.passwordLabel,
                  placeholder: AppLocalizations.of(
                    context,
                  )!.passwordPlaceholder,
                  controller: _passwordController,
                  isPassword: true,
                ),
                field2: _buildFieldData(
                  label: AppLocalizations.of(context)!.confirmPasswordLabel,
                  placeholder: AppLocalizations.of(
                    context,
                  )!.confirmPasswordPlaceholder,
                  controller: _confirmPasswordController,
                  isPassword: true,
                ),
              ),
              const SizedBox(height: 15),

              // Mobile Number (Full width)
              _buildField(
                context,
                label: AppLocalizations.of(context)!.mobileLabel,
                placeholder: AppLocalizations.of(context)!.mobilePlaceholder,
                controller: _mobileController,
                hasFlag: true, // Triggers Country Code Picker
              ),
              const SizedBox(height: 15),

              // Company Name (Full width)
              _buildField(
                context,
                label: AppLocalizations.of(context)!.companyNameLabel,
                placeholder: AppLocalizations.of(
                  context,
                )!.companyNamePlaceholder,
                controller: _companyNameController,
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
                    style: AppTextStyles.rememberMe,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Back to Login with Hover Effect
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: _HoverText(
                    text: AppLocalizations.of(context)!.alreadyHaveAccount,
                    baseStyle: AppTextStyles.dontHaveAccount,
                    hoverColor: AppColors.buttonBackground,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Registration Button with Hover Effect
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _register,
                  child: _HoverContainer(
                    child: Text(
                      AppLocalizations.of(context)!.registrationButton,
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

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

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    // Combine country code with mobile
    final fullMobile = "$_countryCode${_mobileController.text}";

    final errorMessage = await _authService.register(
      email: _emailController.text,
      password: _passwordController.text,
      firstName: _nameController.text,
      lastName: _surnameController.text,
      mobile: fullMobile,
      companyName: _companyNameController.text,
      website: _websiteController.text,
    );

    if (!mounted) return;

    if (errorMessage == null) {
      // Registration successful - redirect to verification page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Successful! Please check your email."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerificationPendingPage(email: _emailController.text),
        ),
      );
    } else {
      // Show detailed error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  _FieldData _buildFieldData({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    bool hasFlag = false,
    bool isPassword = false,
    bool isRequired = true,
  }) {
    return _FieldData(
      label: label,
      placeholder: placeholder,
      controller: controller,
      hasFlag: hasFlag,
      isPassword: isPassword,
      isRequired: isRequired,
    );
  }

  Widget _buildDualField(
    BuildContext context, {
    required _FieldData field1,
    required _FieldData field2,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildField(
            context,
            label: field1.label,
            placeholder: field1.placeholder,
            controller: field1.controller,
            hasFlag: field1.hasFlag,
            isPassword: field1.isPassword,
            isRequired: field1.isRequired,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildField(
            context,
            label: field2.label,
            placeholder: field2.placeholder,
            controller: field2.controller,
            hasFlag: field2.hasFlag,
            isPassword: field2.isPassword,
            isRequired: field2.isRequired,
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required String placeholder,
    required TextEditingController controller,
    bool hasFlag = false,
    bool isPassword = false,
    bool isRequired = true,
  }) {
    // For password fields, use AppPasswordField with visibility toggle
    if (isPassword) {
      return AppPasswordField(
        labelText: label,
        hintText: placeholder,
        controller: controller,
        required: isRequired,
      );
    }

    // For phone number field with country code picker, use special layout
    if (hasFlag) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: label,
                style: AppTextStyles.label,
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 48, // Match AppTextField height
            child: Row(
              children: [
                Container(
                  width: 110, // Width to show flag + dial code properly
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    // make border only for left top bottom
                    border: Border(
                      top: BorderSide(color: AppColors.inputBorder),
                      left: BorderSide(color: AppColors.inputBorder),
                      bottom: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                  height: 48,
                  alignment: Alignment.center,
                  child: CountryCodePicker(
                    onChanged: (country) {
                      setState(() {
                        _countryCode = country.dialCode ?? "+993";
                      });
                    },
                    initialSelection: 'TM',
                    favorite: const ['TM', 'CN'],
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    alignLeft: false,
                    padding: EdgeInsets.zero,
                    textStyle: AppTextStyles.inputText,
                    showFlagMain: true,
                    showDropDownButton: false,
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextFormField(
                      controller: controller,
                      style: AppTextStyles.inputText,
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: placeholder,
                        hintStyle: AppTextStyles.placeholder,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.only(
                          left: 8,
                          right: 12,
                          top: 12,
                          bottom: 12,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: AppColors.inputBorder),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: AppColors.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          borderSide: BorderSide(
                            color: AppColors.buttonBackground,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // For regular fields, use AppTextField
    return AppTextField(
      labelText: label,
      hintText: placeholder,
      controller: controller,
      required: isRequired,
    );
  }
}

class _FieldData {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool hasFlag;
  final bool isPassword;
  final bool isRequired;

  _FieldData({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.hasFlag = false,
    this.isPassword = false,
    this.isRequired = true,
  });
}

// Simple Hover Text Widget
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
        height: 48,
        decoration: BoxDecoration(
          // Darken slightly on hover or use specific color if requested
          color: _isHovering
              ? AppColors.buttonBackground.withValues(alpha: 0.9)
              : AppColors.buttonBackground,
          borderRadius: BorderRadius.circular(45),
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
