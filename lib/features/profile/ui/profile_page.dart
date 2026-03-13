import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/phone_input_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/social_network.dart';

const List<String> _nationalities = [
  'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola',
  'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria',
  'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados',
  'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan',
  'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei',
  'Bulgaria', 'Burkina Faso', 'Burundi', 'Cabo Verde', 'Cambodia',
  'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile',
  'China', 'Colombia', 'Comoros', 'Congo', 'Costa Rica',
  'Croatia', 'Cuba', 'Cyprus', 'Czech Republic', 'Denmark',
  'Djibouti', 'Dominica', 'Dominican Republic', 'Ecuador', 'Egypt',
  'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini',
  'Ethiopia', 'Fiji', 'Finland', 'France', 'Gabon',
  'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece',
  'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana',
  'Haiti', 'Honduras', 'Hungary', 'Iceland', 'India',
  'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel',
  'Italy', 'Jamaica', 'Japan', 'Jordan', 'Kazakhstan',
  'Kenya', 'Kiribati', 'Kosovo', 'Kuwait', 'Kyrgyzstan',
  'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia',
  'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg', 'Madagascar',
  'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta',
  'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 'Micronesia',
  'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco',
  'Mozambique', 'Myanmar', 'Namibia', 'Nauru', 'Nepal',
  'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria',
  'North Korea', 'North Macedonia', 'Norway', 'Oman', 'Pakistan',
  'Palau', 'Palestine', 'Panama', 'Papua New Guinea', 'Paraguay',
  'Peru', 'Philippines', 'Poland', 'Portugal', 'Qatar',
  'Romania', 'Russia', 'Rwanda', 'Saint Kitts and Nevis', 'Saint Lucia',
  'Saint Vincent and the Grenadines', 'Samoa', 'San Marino',
  'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia',
  'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia',
  'Solomon Islands', 'Somalia', 'South Africa', 'South Korea', 'South Sudan',
  'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden',
  'Switzerland', 'Syria', 'Taiwan', 'Tajikistan', 'Tanzania',
  'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 'Trinidad and Tobago',
  'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu', 'Uganda',
  'Ukraine', 'United Arab Emirates', 'United Kingdom', 'United States',
  'Uruguay', 'Uzbekistan', 'Vanuatu', 'Vatican City', 'Venezuela',
  'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe',
];

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
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _profilePhotoUrl;
  String _mobileE164 = '';

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;

  String _selectedGender = '';
  String _selectedNationality = '';
  String _selectedCountry = '';
  String _selectedCity = '';

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
    _mobileController = TextEditingController();

    _companyNameController = TextEditingController();
    _websiteController = TextEditingController();
    _positionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
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
    final user = ref.read(authNotifierProvider).currentUser;
    if (user != null) {
      _nameController.text = user['first_name'] ?? '';
      _surnameController.text = user['last_name'] ?? '';
      _emailController.text = user['email'] ?? '';
      // Load profile photo URL and trigger rebuild
      _profilePhotoUrl = user['photo_url'];
      if (mounted) {
        setState(() {});
      }

      // Store mobile in E.164 format for PhoneInputField
      _mobileE164 = user['mobile'] ?? '';

      _selectedGender = user['gender'] ?? '';
      _selectedNationality = user['nationality'] ?? '';
      _selectedCountry = user['country'] ?? '';
      _selectedCity = user['city'] ?? '';

      _companyNameController.text = user['company_name'] ?? '';
      _websiteController.text = user['website'] ?? '';
      _positionController.text = user['position'] ?? '';

      // Load social links
      if (user['social_links'] != null) {
        // Dispose old entries first
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

  /// Upload profile photo to server and return URL
  Future<String?> _uploadProfilePhoto() async {
    if (_selectedImageBytes == null) return null;

    try {
      final token = await ref.read(authNotifierProvider.notifier).getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/files/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedImageBytes!,
          filename:
              'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return data['url'] ?? data['file_url'];
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Photo upload failed: $e');
      }
      return null;
    }
  }

  /// Show password change dialog
  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    // Current Password
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => obscureCurrentPassword =
                                !obscureCurrentPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // New Password
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: "New Password (min 8 characters)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => obscureNewPassword = !obscureNewPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Confirm Password
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirm New Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => obscureConfirmPassword =
                                !obscureConfirmPassword,
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
                    // Validation
                    if (currentPasswordController.text.isEmpty) {
                      AppSnackBar.showError(this.context, 'Current password is required');
                      return;
                    }
                    if (newPasswordController.text.length < 8) {
                      AppSnackBar.showError(this.context, 'New password must be at least 8 characters');
                      return;
                    }
                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      AppSnackBar.showError(this.context, 'Passwords do not match');
                      return;
                    }

                    // Call API
                    try {
                      final token = await ref.read(authNotifierProvider.notifier).getToken();
                      final response = await http.patch(
                        Uri.parse(
                          '${AppConfig.b2cApiBaseUrl}/api/v1/users/me/password?current_password=${Uri.encodeComponent(currentPasswordController.text)}&new_password=${Uri.encodeComponent(newPasswordController.text)}',
                        ),
                        headers: {'Authorization': 'Bearer $token'},
                      );

                      if (response.statusCode == 200) {
                        if (!this.context.mounted) return;
                        Navigator.pop(dialogContext);
                        AppSnackBar.showSuccess(this.context, 'Password changed successfully!');
                      } else {
                        final error = jsonDecode(response.body);
                        if (!this.context.mounted) return;
                        AppSnackBar.showError(this.context, error['message'] ?? error['detail'] ?? 'Failed to change password');
                      }
                    } catch (e) {
                      if (!this.context.mounted) return;
                      AppSnackBar.showError(this.context, 'Error: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C4494),
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
      color: const Color(0xFF3C4494),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 1000;

          return Column(
            children: [
              // Header
              _buildHeader(isMobile),
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F1F6),
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
            // Back button
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: isMobile ? 24 : 28,
              ),
              onPressed: () {
                // Use returnTo if available, otherwise go to home
                if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
                  context.go(widget.returnTo!);
                } else if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/'); // Go to home (event calendar)
                }
              },
            ),
            const SizedBox(width: 12),
            // Title
            Text(
              "Profile",
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: isMobile ? 22 : 32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== Profile Content Layouts ==============

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
        const SizedBox(height: 30),
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
            borderRadius: BorderRadius.circular(10),
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
                    // Fallback to placeholder if image fails to load
                    return const Icon(
                      Icons.person,
                      size: 80,
                      color: Color(0xFF979797),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3C4494),
                      ),
                    );
                  },
                )
              : const Icon(Icons.person, size: 80, color: Color(0xFF979797)),
        ),
        // Upload photo button - only visible in edit mode
        if (_isEditing) ...[
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload, size: 18),
            label: const Text("Upload Photo (5:6)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C4494),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormContainer() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 890),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Profile Information",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (_isEditing) {
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
                        'nationality': _selectedNationality.isNotEmpty ? _selectedNationality : null,
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
                    }
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 85,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isEditing
                            ? const Color(0xFF008000)
                            : const Color(0xFFD9D9D9),
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
                                : const Color.fromRGBO(0, 0, 0, 0.5),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          _isEditing ? Icons.check : Icons.edit,
                          size: 14,
                          color: _isEditing
                              ? const Color(0xFF008000)
                              : const Color.fromRGBO(0, 0, 0, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Personal info fields
          Wrap(
            spacing: 20,
            runSpacing: 30,
            children: [
              _buildField("Name", _nameController),
              _buildField("Surname", _surnameController),
              _buildField("E-mail address", _emailController),
              _buildMobilePhoneField(),
            ],
          ),

          const SizedBox(height: 30),

          // Gender & Nationality
          Wrap(
            spacing: 20,
            runSpacing: 30,
            children: [
              _buildGenderField(),
              _buildNationalityField(),
            ],
          ),

          const SizedBox(height: 30),

          // Country / City (city depends on selected country)
          _buildCountryCitySection(),

          const SizedBox(height: 30),

          // Company info fields
          Wrap(
            spacing: 20,
            runSpacing: 30,
            children: [
              _buildField("Company Name", _companyNameController),
              _buildField("Company Website", _websiteController),
              _buildField("Position", _positionController),
            ],
          ),

          const SizedBox(height: 50),

          Text(
            "Follow Me:",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
          ),

          const SizedBox(height: 30),

          _buildSocialLinksSection(),

          const SizedBox(height: 50),

          // Security Section
          Text(
            "Security:",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
          ),

          const SizedBox(height: 20),

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
                backgroundColor: const Color(0xFF3C4494),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return SizedBox(
      width: 394,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB7B7B7)),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: _isEditing
                ? TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.inter(fontSize: 16),
                  )
                : Text(
                    controller.text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  // Custom mobile phone field that supports edit/view modes
  Widget _buildMobilePhoneField() {
    return SizedBox(
      width: 394,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mobile number:",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          if (_isEditing)
            // Editable mode: Use PhoneInputField
            PhoneInputField(
              initialPhone: _mobileE164,
              onChanged: (e164Phone) {
                _mobileE164 = e164Phone;
              },
              hintText: "61444555",
            )
          else
            // View mode: Display formatted phone number
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB7B7B7)),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                _mobileE164.isNotEmpty ? _mobileE164 : '',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // ============== Gender Field ==============

  Widget _buildGenderField() {
    return SizedBox(
      width: 394,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gender:",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          if (_isEditing)
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB7B7B7)),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGender.isNotEmpty ? _selectedGender : null,
                  hint: Text(
                    'Select gender',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color.fromRGBO(0, 0, 0, 0.4),
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: ['Male', 'Female'].map((g) {
                    return DropdownMenuItem(
                      value: g,
                      child: Text(g, style: GoogleFonts.inter(fontSize: 16)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGender = value);
                    }
                  },
                ),
              ),
            )
          else
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB7B7B7)),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedGender.isNotEmpty ? _selectedGender : '',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============== Nationality Field ==============

  Widget _buildNationalityField() {
    return SizedBox(
      width: 394,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nationality:",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          if (_isEditing)
            GestureDetector(
              onTap: () => _showNationalityPickerDialog(),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB7B7B7)),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedNationality.isNotEmpty
                            ? _selectedNationality
                            : 'Select nationality',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: _selectedNationality.isNotEmpty
                              ? Colors.black87
                              : const Color.fromRGBO(0, 0, 0, 0.4),
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB7B7B7)),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedNationality.isNotEmpty ? _selectedNationality : '',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNationalityPickerDialog() {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = searchQuery.isEmpty
                ? _nationalities
                : _nationalities
                    .where((c) =>
                        c.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();
            return AlertDialog(
              title: const Text('Select Nationality'),
              content: SizedBox(
                width: 340,
                height: 450,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search country...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() => searchQuery = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No countries found'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (ctx, index) {
                                final country = filtered[index];
                                final isSelected =
                                    _selectedNationality == country;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    country,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFF3C4494)
                                          : null,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check,
                                          color: Color(0xFF3C4494), size: 20)
                                      : null,
                                  onTap: () {
                                    setState(
                                        () => _selectedNationality = country);
                                    Navigator.of(ctx).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============== Country / City Section ==============

  Widget _buildCountryCitySection() {
    if (_isEditing) {
      return CSCPickerPlus(
        showStates: false,
        showCities: true,
        currentCountry: _selectedCountry.isNotEmpty ? _selectedCountry : null,
        currentCity: _selectedCity.isNotEmpty ? _selectedCity : null,
        countryDropdownLabel: _selectedCountry.isNotEmpty
            ? _selectedCountry
            : 'Select Country',
        cityDropdownLabel:
            _selectedCity.isNotEmpty ? _selectedCity : 'Select City',
        dropdownDecoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFB7B7B7)),
          borderRadius: BorderRadius.circular(5),
        ),
        disabledDropdownDecoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(5),
          color: const Color(0xFFF5F5F5),
        ),
        selectedItemStyle: GoogleFonts.inter(fontSize: 16),
        dropdownHeadingStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: Colors.black,
        ),
        onCountryChanged: (country) {
          setState(() {
            _selectedCountry = country;
            _selectedCity = '';
          });
        },
        onStateChanged: (_) {},
        onCityChanged: (city) {
          setState(() {
            _selectedCity = city ?? '';
          });
        },
      );
    }

    // View mode: show as read-only text fields
    return Wrap(
      spacing: 20,
      runSpacing: 30,
      children: [
        _buildReadOnlyField('Country', _selectedCountry),
        _buildReadOnlyField('City', _selectedCity),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return SizedBox(
      width: 394,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB7B7B7)),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color.fromRGBO(0, 0, 0, 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============== Dynamic Social Links Section ==============

  Widget _buildSocialLinksSection() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Existing social link entries
          ..._socialLinks.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: 394,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(entry.network.icon,
                            size: 20, color: const Color(0xFF3C4494)),
                        const SizedBox(width: 8),
                        Text(
                          entry.network.label,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
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
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFB7B7B7)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: entry.controller,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: entry.network.hintText,
                          hintStyle: GoogleFonts.inter(
                            fontSize: 16,
                            color: const Color.fromRGBO(0, 0, 0, 0.25),
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
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
                                size: 20, color: const Color(0xFF3C4494)),
                            const SizedBox(width: 10),
                            Text(network.label),
                          ],
                        ),
                      ))
                  .toList(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3C4494)),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add,
                        size: 18, color: Color(0xFF3C4494)),
                    const SizedBox(width: 6),
                    Text(
                      "Add New",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF3C4494),
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

    // View mode: only show social links that have values
    final filledLinks =
        _socialLinks.where((e) => e.controller.text.isNotEmpty).toList();
    if (filledLinks.isEmpty) {
      return Text(
        'No social links added.',
        style: GoogleFonts.inter(
          fontSize: 16,
          color: const Color.fromRGBO(0, 0, 0, 0.5),
        ),
      );
    }

    return Wrap(
      spacing: 20,
      runSpacing: 30,
      children: filledLinks.map((entry) {
        return SizedBox(
          width: 394,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(entry.network.icon,
                      size: 20, color: const Color(0xFF3C4494)),
                  const SizedBox(width: 8),
                  Text(
                    entry.network.label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB7B7B7)),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  entry.controller.text,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color.fromRGBO(0, 0, 0, 0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Networks not yet added to the social links list
  List<SocialNetwork> get _availableNetworks {
    final usedKeys = _socialLinks.map((e) => e.network).toSet();
    return SocialNetwork.values
        .where((n) => !usedKeys.contains(n))
        .toList();
  }
}
