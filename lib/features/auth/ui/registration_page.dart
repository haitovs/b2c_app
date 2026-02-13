import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../services/auth_service.dart';
import 'verification_code_page.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_button.dart';

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
  final _companyNameController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = false;

  String _countryCode = "+993";

  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      scrollable: true,
      desktopCardHeight: 750,
      mobileBreakpoint: 1000,
      child: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(loc.registrationTitle, style: AppTextStyles.titleLargeDesktop),
        const SizedBox(height: 20),

        SizedBox(
          width: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name & Surname row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      labelText: loc.nameLabel,
                      hintText: "Name",
                      controller: _nameController,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: AppTextField(
                      labelText: loc.surnameLabel,
                      hintText: "Surname",
                      controller: _surnameController,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Email (full width)
              AppTextField(
                labelText: loc.emailLabel,
                hintText: "emailaddress@gmail.com",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                required: true,
              ),
              const SizedBox(height: 12),

              // Password & Confirm Password row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppPasswordField(
                      labelText: loc.passwordLabel,
                      hintText: "very secret password",
                      controller: _passwordController,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: AppPasswordField(
                      labelText: loc.confirmPasswordLabel,
                      hintText: "very secret password",
                      controller: _confirmPasswordController,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mobile Number with country picker
              _buildMobileField(loc),
              const SizedBox(height: 12),

              // Company Name (full width)
              AppTextField(
                labelText: loc.companyNameLabel,
                hintText: "company name",
                controller: _companyNameController,
              ),
              const SizedBox(height: 12),

              // Company Website (full width)
              AppTextField(
                labelText: loc.websiteLabel,
                hintText: "company.com",
                controller: _websiteController,
              ),
              const SizedBox(height: 25),

              // Registration Button
              AuthButton(
                text: loc.registrationButton,
                isLoading: _isLoading,
                onTap: _register,
                height: 48,
              ),
              const SizedBox(height: 16),

              // Return to login
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: AppTextStyles.dontHaveAccount,
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: AppTextStyles.dontHaveAccount.copyWith(
                            color: AppColors.buttonBackground,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
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

  Widget _buildMobileField(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: RichText(
            text: TextSpan(
              text: loc.mobileLabel,
              style: AppTextStyles.label,
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Container(
                width: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
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
                    controller: _mobileController,
                    style: AppTextStyles.inputText,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "xx-xx-xx-xx",
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

  Future<void> _register() async {
    if (_isLoading) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError("Please enter your first name");
      return;
    }
    if (_surnameController.text.trim().isEmpty) {
      _showError("Please enter your last name");
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError("Please enter your email");
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError("Please enter a password");
      return;
    }
    if (_passwordController.text.length < 8) {
      _showError("Password must be at least 8 characters long");
      return;
    }
    if (_mobileController.text.trim().isEmpty) {
      _showError("Please enter your mobile number");
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError("Please enter a valid email address");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullMobile = "$_countryCode${_mobileController.text.trim()}";

      final errorMessage = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _nameController.text.trim(),
        lastName: _surnameController.text.trim(),
        mobile: fullMobile,
        companyName: _companyNameController.text.trim().isNotEmpty
            ? _companyNameController.text.trim()
            : null,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Registration successful! Please check your email to verify your account.",
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                VerificationCodePage(email: _emailController.text.trim()),
          ),
        );
      } else {
        final cleanError = errorMessage.replaceFirst(
          RegExp(r'^(?:Error\s*)?\d+\s*:\s*'),
          '',
        );
        _showError(cleanError);
      }
    } catch (e) {
      if (mounted) {
        _showError("An unexpected error occurred. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
