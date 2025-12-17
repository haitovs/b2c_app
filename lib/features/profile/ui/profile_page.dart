import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/legal_bottom_sheet.dart';
import '../../auth/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentTab = 1; // 0 = Agreement, 1 = My Profile, 2 = Company
  bool _isEditing = false;
  bool _agreedToTerms = false;
  XFile? _selectedImage;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;

  late TextEditingController _countryController;
  late TextEditingController _cityController;

  late TextEditingController _companyNameController;
  late TextEditingController _websiteController;

  late TextEditingController _instagramController;
  late TextEditingController _whatsappController;
  late TextEditingController _facebookController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();

    _countryController = TextEditingController();
    _cityController = TextEditingController();

    _companyNameController = TextEditingController();
    _websiteController = TextEditingController();

    _instagramController = TextEditingController();
    _whatsappController = TextEditingController();
    _facebookController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _companyNameController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _whatsappController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _nameController.text = user['first_name'] ?? '';
      _surnameController.text = user['last_name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _mobileController.text = user['mobile'] ?? '';

      _countryController.text = user['country'] ?? '';
      _cityController.text = user['city'] ?? '';

      _companyNameController.text = user['company_name'] ?? '';
      _websiteController.text = user['website'] ?? '';

      if (user['social_links'] != null) {
        for (var link in user['social_links']) {
          if (link['network'] == 'INSTAGRAM') {
            _instagramController.text = link['handle'];
          }
          if (link['network'] == 'WHATSAPP') {
            _whatsappController.text = link['handle'];
          }
          if (link['network'] == 'FACEBOOK') {
            _facebookController.text = link['handle'];
          }
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 1000;

          return Column(
            children: [
              // Header
              _buildHeader(isMobile),
              // Tabs
              _buildTabBar(isMobile),
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
                    child: _buildCurrentTabContent(isMobile),
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
                // Check if we can pop, otherwise go to a default page
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/events');
                }
              },
            ),
            const SizedBox(width: 12),
            // Title
            Text(
              "My profile",
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: isMobile ? 22 : 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Icons
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: isMobile ? 22 : 24,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: Icon(
                Icons.person_outline,
                color: Colors.white,
                size: isMobile ? 22 : 24,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    final tabs = ["Agreement process", "My profile", "Company profile"];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 50),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isActive = _currentTab == index;
            return Padding(
              padding: EdgeInsets.only(right: isMobile ? 15 : 40),
              child: GestureDetector(
                onTap: () => setState(() => _currentTab = index),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 20,
                        vertical: isMobile ? 8 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFF1F1F6)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        tabs[index],
                        style: GoogleFonts.montserrat(
                          fontSize: isMobile ? 14 : 25,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF3C4494)
                              : const Color.fromRGBO(255, 255, 255, 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(bool isMobile) {
    switch (_currentTab) {
      case 0:
        return _buildAgreementProcess();
      case 1:
        return isMobile ? _buildMobileLayout() : _buildDesktopLayout();
      case 2:
        return isMobile
            ? _buildCompanyMobileLayout()
            : _buildCompanyDesktopLayout();
      default:
        return const SizedBox();
    }
  }

  // ============== Agreement Process Tab ==============

  Widget _buildAgreementProcess() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Participation Agreement Process",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          const SizedBox(height: 20),
          // Description
          Text(
            'You are at the final stage of registration. Please carefully review the terms and conditions for participating in the "Future of Tech 2026" Forum and confirm your agreement to gain full access.',
            style: GoogleFonts.roboto(
              fontSize: 18,
              height: 1.39,
              color: const Color.fromRGBO(21, 25, 56, 0.85),
            ),
          ),
          const SizedBox(height: 50),

          // Step 1: Document Review
          Text(
            "Step 1: Document Review",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              if (isMobile) {
                // Stack vertically on mobile
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "To proceed, please read the following documents:",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: const Color.fromRGBO(21, 25, 56, 0.85),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildDocumentLink("Terms and Conditions", "TERMS"),
                    const SizedBox(height: 10),
                    _buildDocumentLink("Privacy Policy", "PRIVACY"),
                    const SizedBox(height: 10),
                    _buildDocumentLink("Refund Policy", "REFUND"),
                  ],
                );
              } else {
                // Side by side on desktop
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "To proceed, please read the following documents:",
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: const Color.fromRGBO(21, 25, 56, 0.85),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDocumentLink(
                            "Terms and Conditions (ToS)",
                            "TERMS",
                          ),
                          const SizedBox(height: 15),
                          _buildDocumentLink("Privacy Policy", "PRIVACY"),
                          const SizedBox(height: 15),
                          _buildDocumentLink("Refund Policy", "REFUND"),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 50),

          // Divider
          const Divider(color: Color(0xFFD2D2D2), thickness: 1),
          const SizedBox(height: 40),

          // Step 2: Final Agreement
          Text(
            "Step 2: Final Agreement",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          const SizedBox(height: 20),
          // Checkbox row
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                child: Container(
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFB7B7B7)),
                    borderRadius: BorderRadius.circular(5),
                    color: _agreedToTerms
                        ? const Color(0xFF3C4494)
                        : Colors.white,
                  ),
                  child: _agreedToTerms
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 15),
              Flexible(
                child: Text(
                  "I have read and agree to the Terms and Conditions and the Privacy Policy.",
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: const Color.fromRGBO(21, 25, 56, 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _agreedToTerms
                  ? () async {
                      // Save agreement to API
                      final error = await context
                          .read<AuthService>()
                          .updateProfile({'has_agreed_terms': true});
                      if (!mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Agreement confirmed! You now have full access.",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C4494),
                disabledBackgroundColor: const Color(0xFFD9D9D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Confirm and Complete Registration",
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF1F1F6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentLink(String title, String docType) {
    return GestureDetector(
      onTap: () => LegalBottomSheet.show(context, docType),
      child: Wrap(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              color: const Color(0xFF3C4494),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "(View)",
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: const Color.fromRGBO(21, 25, 56, 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ============== Company Profile Tab ==============

  Widget _buildCompanyDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfilePhoto(),
        const SizedBox(width: 50),
        Expanded(child: _buildCompanyFormContainer()),
      ],
    );
  }

  Widget _buildCompanyMobileLayout() {
    return Column(
      children: [
        _buildProfilePhoto(),
        const SizedBox(height: 30),
        _buildCompanyFormContainer(),
      ],
    );
  }

  Widget _buildCompanyFormContainer() {
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
                  "Company Information",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildEditButton(),
            ],
          ),

          const SizedBox(height: 30),

          // Company fields
          Wrap(
            spacing: 20,
            runSpacing: 30,
            children: [
              _buildField("Company Name", _companyNameController),
              _buildField("Company Website", _websiteController),
              _buildField("E-mail address", _emailController),
              _buildMobileField(_mobileController),
              _buildField("Country", _countryController),
              _buildField("City", _cityController),
            ],
          ),

          const SizedBox(height: 50),

          Text(
            "Follow Me:",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
          ),

          const SizedBox(height: 30),

          Wrap(
            spacing: 20,
            runSpacing: 30,
            children: [
              _buildSocialField("Instagram", _instagramController),
              _buildSocialField("WhatsApp", _whatsappController),
              _buildSocialField("Facebook", _facebookController),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (_isEditing) {
            final updates = {
              'first_name': _nameController.text,
              'last_name': _surnameController.text,
              'mobile': _mobileController.text,
              'country': _countryController.text,
              'city': _cityController.text,
              'company_name': _companyNameController.text,
              'website': _websiteController.text,
              'social_links': [
                if (_instagramController.text.isNotEmpty)
                  {'network': 'INSTAGRAM', 'handle': _instagramController.text},
                if (_whatsappController.text.isNotEmpty)
                  {'network': 'WHATSAPP', 'handle': _whatsappController.text},
                if (_facebookController.text.isNotEmpty)
                  {'network': 'FACEBOOK', 'handle': _facebookController.text},
              ],
            };

            final error = await context.read<AuthService>().updateProfile(
              updates,
            );
            if (!mounted) return;
            if (error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error)));
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
    );
  }

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
    final user = context.read<AuthService>().currentUser;
    final photoUrl = user?['photo_url'];

    return Column(
      children: [
        Container(
          width: 300,
          height: 351,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[300],
            image: _selectedImage != null
                ? DecorationImage(
                    image: kIsWeb
                        ? NetworkImage(_selectedImage!.path)
                        : FileImage(File(_selectedImage!.path))
                              as ImageProvider,
                    fit: BoxFit.cover,
                  )
                : photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(photoUrl),
                    fit: BoxFit.cover,
                  )
                : const DecorationImage(
                    image: AssetImage('assets/profile_placeholder.png'),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        // Upload photo button - only visible in edit mode
        if (_isEditing) ...[
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload, size: 18),
            label: const Text("Upload Photo"),
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
                      final updates = {
                        'first_name': _nameController.text,
                        'last_name': _surnameController.text,
                        'mobile': _mobileController.text,
                        'country': _countryController.text,
                        'city': _cityController.text,
                        'company_name': _companyNameController.text,
                        'website': _websiteController.text,
                        'social_links': [
                          if (_instagramController.text.isNotEmpty)
                            {
                              'network': 'INSTAGRAM',
                              'handle': _instagramController.text,
                            },
                          if (_whatsappController.text.isNotEmpty)
                            {
                              'network': 'WHATSAPP',
                              'handle': _whatsappController.text,
                            },
                          if (_facebookController.text.isNotEmpty)
                            {
                              'network': 'FACEBOOK',
                              'handle': _facebookController.text,
                            },
                        ],
                      };

                      final error = await context
                          .read<AuthService>()
                          .updateProfile(updates);
                      if (!mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
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

          Wrap(
            spacing: 20,
            runSpacing: 30,
            children: [
              _buildField("Name", _nameController),
              _buildField("Surname", _surnameController),
              _buildField("E-mail address", _emailController),
              _buildMobileField(_mobileController),
              _buildField("Country", _countryController),
              _buildField("City", _cityController),
              _buildField("Company Name", _companyNameController),
              _buildField("Company Website", _websiteController),
            ],
          ),

          const SizedBox(height: 50),

          Text(
            "Follow Me:",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
          ),

          const SizedBox(height: 30),

          Wrap(
            spacing: 20,
            runSpacing: 30,
            children: [
              _buildSocialField("Instagram", _instagramController),
              _buildSocialField("WhatsApp", _whatsappController),
              _buildSocialField("Facebook", _facebookController),
            ],
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
                      isDense: true,
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

  Widget _buildMobileField(TextEditingController controller) {
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E5E5),
                  border: Border.all(color: const Color(0xFFADADAD)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.flag, size: 20, color: Colors.green),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFB7B7B7)),
                      right: BorderSide(color: Color(0xFFB7B7B7)),
                      bottom: BorderSide(color: Color(0xFFB7B7B7)),
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.centerLeft,
                  child: _isEditing
                      ? TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialField(String label, TextEditingController controller) {
    return SizedBox(
      width: 394,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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
                      isDense: true,
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
}
