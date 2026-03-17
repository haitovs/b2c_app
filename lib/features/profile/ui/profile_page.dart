import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/reference_data_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/phone_input_field.dart';
import '../../../core/widgets/website_input_field.dart';
import '../../../shared/widgets/country_city_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/social_network.dart';
import '../providers/profile_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? returnTo;

  const ProfilePage({
    super.key,
    this.returnTo,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isEditing = false;
  bool _hasPopulatedControllers = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _profilePhotoUrl;
  String _mobileE164 = '';

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;

  String _selectedGender = '';
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedNationality;

  late TextEditingController _companyNameController;
  late TextEditingController _websiteController;
  late TextEditingController _positionController;

  List<SocialLinkEntry> _socialLinks = [];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _emailController = TextEditingController();

    _companyNameController = TextEditingController();
    _websiteController = TextEditingController();
    _positionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _websiteController.dispose();
    _positionController.dispose();
    for (final entry in _socialLinks) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasPopulatedControllers) return;
    final user = ref.read(authNotifierProvider).currentUser;
    if (user != null) {
      _hasPopulatedControllers = true;
      _nameController.text = user['first_name'] ?? '';
      _surnameController.text = user['last_name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _profilePhotoUrl = user['photo_url'];
      if (mounted) setState(() {});

      _mobileE164 = user['mobile'] ?? '';

      _selectedGender = user['gender'] ?? '';
      _selectedNationality =
          (user['nationality'] ?? '').toString().isNotEmpty ? user['nationality'] : null;
      _selectedCountry =
          (user['country'] ?? '').toString().isNotEmpty ? user['country'] : null;
      _selectedCity =
          (user['city'] ?? '').toString().isNotEmpty ? user['city'] : null;

      _companyNameController.text = user['company_name'] ?? '';
      _websiteController.text = user['website'] ?? '';
      _positionController.text = user['position'] ?? '';

      // Load social links
      if (user['social_links'] != null) {
        for (final entry in _socialLinks) {
          entry.dispose();
        }
        _socialLinks = [];
        for (var link in user['social_links']) {
          final network = SocialNetwork.fromKey(link['network'] ?? '');
          if (network != null) {
            _socialLinks.add(SocialLinkEntry(
              network: network,
              initialValue: link['handle'] ?? '',
            ));
          }
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadProfilePhoto() async {
    if (_selectedImageBytes == null) return null;

    try {
      final profileService = ref.read(profileServiceProvider);
      return await profileService.uploadProfilePhoto(_selectedImageBytes!);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Photo upload failed: $e');
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    // Upload photo if selected
    String? photoUrl;
    if (_selectedImageBytes != null) {
      photoUrl = await _uploadProfilePhoto();
    }

    final updates = {
      'first_name': _nameController.text,
      'last_name': _surnameController.text,
      'mobile': _mobileE164,
      'gender': _selectedGender.isNotEmpty ? _selectedGender : null,
      'nationality': _selectedNationality,
      'country': _selectedCountry,
      'city': _selectedCity,
      'company_name': _companyNameController.text,
      'website': _websiteController.text,
      'position': _positionController.text,
      if (photoUrl != null) 'photo_url': photoUrl,
      'social_links': _socialLinks
          .where((e) => e.controller.text.isNotEmpty)
          .map((e) => e.toJson())
          .toList(),
    };

    final error = await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(updates);
    if (!mounted) return;
    if (error != null) {
      AppSnackBar.showInfo(context, error);
      return;
    }
    setState(() => _isEditing = false);
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                "Change Password",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: "New Password (min 8 characters)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureNew = !obscureNew,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: "Confirm New Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (currentPasswordController.text.isEmpty) {
                      AppSnackBar.showError(
                          this.context, 'Current password is required');
                      return;
                    }
                    if (newPasswordController.text.length < 8) {
                      AppSnackBar.showError(this.context,
                          'New password must be at least 8 characters');
                      return;
                    }
                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      AppSnackBar.showError(
                          this.context, 'Passwords do not match');
                      return;
                    }

                    try {
                      final profileService =
                          ref.read(profileServiceProvider);
                      final error = await profileService.changePassword(
                        currentPassword: currentPasswordController.text,
                        newPassword: newPasswordController.text,
                      );

                      if (!this.context.mounted) return;
                      if (error == null) {
                        Navigator.pop(dialogContext);
                        AppSnackBar.showSuccess(
                            this.context, 'Password changed successfully!');
                      } else {
                        AppSnackBar.showError(this.context, error);
                      }
                    } catch (e) {
                      if (!this.context.mounted) return;
                      AppSnackBar.showError(this.context, 'Error: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                  ),
                  child: Text(
                    "Change Password",
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gradientStart,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 1000;

          return Column(
            children: [
              _buildHeader(isMobile),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 20 : 50),
                    child: isMobile
                        ? _buildMobileLayout()
                        : _buildDesktopLayout(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 12 : 16,
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: isMobile ? 24 : 28,
              ),
              onPressed: () {
                if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
                  context.go(widget.returnTo!);
                } else if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            const SizedBox(width: 12),
            Text(
              "Profile",
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: isMobile ? 22 : 32,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== Layouts ==============

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfilePhoto(),
        const SizedBox(width: 50),
        Expanded(child: _buildFormContainer()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildProfilePhoto(),
        const SizedBox(height: 32),
        _buildFormContainer(),
      ],
    );
  }

  Widget _buildProfilePhoto() {
    return Column(
      children: [
        Container(
          width: 300,
          height: 351,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          clipBehavior: Clip.hardEdge,
          child: _selectedImage != null
              ? (kIsWeb
                  ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                  : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
              : (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
                  ? Image.network(
                      _profilePhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person,
                            size: 80, color: Color(0xFF979797));
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gradientStart,
                          ),
                        );
                      },
                    )
                  : const Icon(Icons.person, size: 80, color: Color(0xFF979797)),
        ),
        if (_isEditing) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload, size: 18),
            label: const Text("Upload Photo (5:6)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============== Form Container ==============

  Widget _buildFormContainer() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 890),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Profile Information",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildEditSaveButton(),
              ],
            ),

            const SizedBox(height: 24),

            // Name / Surname
            _buildTwoColumnRow(
              _buildTextField("Name:", _nameController),
              _buildTextField("Surname:", _surnameController),
            ),
            const SizedBox(height: 16),

            // Email / Mobile
            _buildTwoColumnRow(
              _buildTextField("E-mail address:", _emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildMobilePhoneField(),
            ),
            const SizedBox(height: 16),

            // Gender / Nationality
            _buildTwoColumnRow(
              _buildGenderField(),
              _buildNationalityField(),
            ),
            const SizedBox(height: 16),

            // Country / City
            _buildCountryCitySection(),
            const SizedBox(height: 16),

            // Company Name / Website
            _buildTwoColumnRow(
              _buildTextField("Company Name:", _companyNameController),
              _buildWebsiteField(),
            ),
            const SizedBox(height: 16),

            // Position (single column)
            SizedBox(
              width: 394,
              child: _buildTextField("Position:", _positionController),
            ),

            const SizedBox(height: 32),

            // Social links
            Text(
              "Follow Me:",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            _buildSocialLinksSection(),

            const SizedBox(height: 32),

            // Security
            Text(
              "Security:",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 394,
              child: ElevatedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock_outline, color: Colors.white),
                label: Text(
                  "Change Password",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientStart,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== Edit/Save Button ==============

  Widget _buildEditSaveButton() {
    return InkWell(
      onTap: () async {
        if (_isEditing) {
          await _saveProfile();
        } else {
          setState(() => _isEditing = true);
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 85,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isEditing
                ? const Color(0xFF008000)
                : AppColors.inputBorder,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isEditing ? "Save" : "Edit",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: _isEditing
                    ? const Color(0xFF008000)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _isEditing ? Icons.check : Icons.edit,
              size: 14,
              color: _isEditing
                  ? const Color(0xFF008000)
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ============== Two-Column Row Helper ==============

  Widget _buildTwoColumnRow(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              left,
              const SizedBox(height: 16),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  // ============== Text Field (using AppTextField) ==============

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    if (_isEditing) {
      return AppTextField(
        labelText: label,
        controller: controller,
        keyboardType: keyboardType,
      );
    }

    return _buildReadOnlyField(label, controller.text);
  }

  // ============== Mobile Phone Field ==============

  Widget _buildMobilePhoneField() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text("Mobile number:", style: AppTextStyles.label),
          ),
          PhoneInputField(
            initialPhone: _mobileE164,
            onChanged: (e164Phone) {
              _mobileE164 = e164Phone;
            },
            hintText: "61444555",
          ),
        ],
      );
    }

    return _buildReadOnlyField('Mobile number:', _mobileE164);
  }

  // ============== Gender Field ==============

  Widget _buildGenderField() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text("Gender:", style: AppTextStyles.label),
          ),
          SizedBox(
            height: 48,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedGender.isNotEmpty ? _selectedGender : null,
              hint: Text('Select gender', style: AppTextStyles.placeholder),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: AppTextStyles.inputText.copyWith(color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.inputBorder, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.inputBorder, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.buttonBackground, width: 2),
                ),
              ),
              items: ['Male', 'Female'].map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Text(g),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedGender = value);
              },
            ),
          ),
        ],
      );
    }

    return _buildReadOnlyField(
      'Gender:',
      _selectedGender.isNotEmpty ? _selectedGender : '',
    );
  }

  // ============== Nationality Field (using countriesProvider) ==============

  Widget _buildNationalityField() {
    if (!_isEditing) {
      return _buildReadOnlyField(
        'Nationality:',
        _selectedNationality ?? '',
      );
    }

    final countriesAsync = ref.watch(countriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text("Nationality:", style: AppTextStyles.label),
        ),
        countriesAsync.when(
          loading: () => _buildLoadingBox(),
          error: (_, __) => _buildErrorBox('Failed to load'),
          data: (countries) => Autocomplete<String>(
            initialValue:
                TextEditingValue(text: _selectedNationality ?? ''),
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) return countries;
              final query = textEditingValue.text.toLowerCase();
              return countries
                  .where((c) => c.toLowerCase().contains(query))
                  .toList();
            },
            onSelected: (selection) {
              setState(() => _selectedNationality = selection);
            },
            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
              return SizedBox(
                height: 48,
                child: TextFormField(
                  controller: textController,
                  focusNode: focusNode,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'Search nationality...',
                    hintStyle: AppTextStyles.placeholder,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    suffixIcon: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.inputBorder, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.inputBorder, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.buttonBackground, width: 2),
                    ),
                  ),
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                  onChanged: (val) {
                    if (val.isEmpty) {
                      setState(() => _selectedNationality = null);
                    }
                  },
                ),
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
        ),
      ],
    );
  }

  // ============== Country / City (using CountryCityPicker) ==============

  Widget _buildCountryCitySection() {
    if (_isEditing) {
      return CountryCityPicker(
        selectedCountry: _selectedCountry,
        selectedCity: _selectedCity,
        onCountryChanged: (country) {
          setState(() {
            _selectedCountry = country;
            _selectedCity = null;
          });
        },
        onCityChanged: (city) {
          setState(() => _selectedCity = city);
        },
      );
    }

    return _buildTwoColumnRow(
      _buildReadOnlyField('Country:', _selectedCountry ?? ''),
      _buildReadOnlyField('City:', _selectedCity ?? ''),
    );
  }

  // ============== Website Field (using WebsiteInputField) ==============

  Widget _buildWebsiteField() {
    if (_isEditing) {
      return WebsiteInputField(
        labelText: 'Company Website:',
        controller: _websiteController,
        hintText: 'example.com',
      );
    }

    return _buildReadOnlyField('Company Website:', _websiteController.text);
  }

  // ============== Read-only field (view mode) ==============

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text(label, style: AppTextStyles.label),
        ),
        Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============== Social Links ==============

  Widget _buildSocialLinksSection() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._socialLinks.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: 394,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(entry.network.icon,
                            size: 20, color: AppColors.gradientStart),
                        const SizedBox(width: 8),
                        Text(entry.network.label,
                            style: AppTextStyles.label),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _socialLinks.removeAt(index).dispose();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppTextField(
                      controller: entry.controller,
                      hintText: entry.network.hintText,
                    ),
                  ],
                ),
              ),
            );
          }),

          // "+ Add New" button
          if (_availableNetworks.isNotEmpty)
            PopupMenuButton<SocialNetwork>(
              onSelected: (network) {
                setState(() {
                  _socialLinks.add(SocialLinkEntry(network: network));
                });
              },
              itemBuilder: (context) => _availableNetworks
                  .map((network) => PopupMenuItem(
                        value: network,
                        child: Row(
                          children: [
                            Icon(network.icon,
                                size: 20, color: AppColors.gradientStart),
                            const SizedBox(width: 10),
                            Text(network.label),
                          ],
                        ),
                      ))
                  .toList(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gradientStart),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add,
                        size: 18, color: AppColors.gradientStart),
                    const SizedBox(width: 6),
                    Text(
                      "Add New",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.gradientStart,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // View mode
    final filledLinks =
        _socialLinks.where((e) => e.controller.text.isNotEmpty).toList();
    if (filledLinks.isEmpty) {
      return Text(
        'No social links added.',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: filledLinks.map((entry) {
        return SizedBox(
          width: 394,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(entry.network.icon,
                      size: 20, color: AppColors.gradientStart),
                  const SizedBox(width: 8),
                  Text(entry.network.label, style: AppTextStyles.label),
                ],
              ),
              const SizedBox(height: 6),
              _buildReadOnlyField('', entry.controller.text),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<SocialNetwork> get _availableNetworks {
    final usedKeys = _socialLinks.map((e) => e.network).toSet();
    return SocialNetwork.values
        .where((n) => !usedKeys.contains(n))
        .toList();
  }

  // ============== Helpers ==============

  Widget _buildLoadingBox() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.gradientStart,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
        ),
      ),
    );
  }
}
