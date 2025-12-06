import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../auth/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;

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
    // Initialize with placeholders; will update in didChangeDependencies or build
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

      // Socials parsing if backend structure is known
      // Assuming 'social_links' is a list of objects {network, handle}
      if (user['social_links'] != null) {
        for (var link in user['social_links']) {
          if (link['network'] == 'INSTAGRAM')
            _instagramController.text = link['handle'];
          if (link['network'] == 'WHATSAPP')
            _whatsappController.text = link['handle'];
          if (link['network'] == 'FACEBOOK')
            _facebookController.text = link['handle'];
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Profile",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 1000;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                width: isMobile ? constraints.maxWidth * 0.95 : 1340,
                margin: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 10,
                ),
                padding: const EdgeInsets.only(
                  top: 70,
                  bottom: 50,
                  left: 50,
                  right: 50,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
              ),
            ),
          );
        },
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
    return Column(
      children: [
        Container(
          width: 300,
          height: 351,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[300],
            image: const DecorationImage(
              image: AssetImage('profile_placeholder.png'),
              fit: BoxFit.cover,
            ),
          ),
          // alignment: Alignment.center,
          // child: const Icon(Icons.person, size: 80, color: Colors.grey),
        ),
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
                      // Collect data
                      final updates = {
                        'first_name': _nameController.text,
                        'last_name': _surnameController.text,
                        // 'email': _emailController.text, // Usually email is not editable or requires special flow
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
                      if (error != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                        return; // Don't toggle edit mode if error
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
                child: const Icon(Icons.flag, size: 20),
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
