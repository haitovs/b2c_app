import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/phone_input_field.dart';
import '../../../shared/widgets/legal_bottom_sheet.dart';
import '../../auth/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final int initialTab;
  final String? returnTo;
  final bool highlightConfirmButton;

  const ProfilePage({
    super.key,
    this.initialTab = 1,
    this.returnTo,
    this.highlightConfirmButton = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late int _currentTab;
  bool _isEditing = false;
  bool _agreedToTerms = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes; // Store image bytes for upload
  String? _profilePhotoUrl; // Profile photo URL from user data
  String _mobileE164 = ''; // Store mobile in E.164 format (e.g., +99361444555)

  // Button highlight animation
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  bool _showHighlight = false;

  // Scroll controller for auto-scroll to button
  final ScrollController _scrollController = ScrollController();

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
    _currentTab = widget.initialTab.clamp(0, 2); // Ensure valid tab index

    // Setup highlight animation
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _highlightAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    // Start highlight animation if coming from agreement dialog
    if (widget.highlightConfirmButton && widget.initialTab == 0) {
      _showHighlight = true;
      // Start animation after widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        int cycles = 0;
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            cycles++;
            if (cycles >= 4) {
              // 2 full cycles (forward+reverse each)
              _highlightController.removeStatusListener(listener);
              _highlightController.stop();
              if (mounted) setState(() => _showHighlight = false);
            }
          }
        }

        _highlightController.addStatusListener(listener);
        _highlightController.repeat(reverse: true);

        // Auto-scroll to checkbox area
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }

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
    _highlightController.dispose();
    _scrollController.dispose();
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
      // Load profile photo URL and trigger rebuild
      _profilePhotoUrl = user['photo_url'];
      if (mounted) {
        setState(() {});
      }

      // Store mobile in E.164 format for PhoneInputField
      _mobileE164 = user['mobile'] ?? '';

      _countryController.text = user['country'] ?? '';
      _cityController.text = user['city'] ?? '';

      _companyNameController.text = user['company_name'] ?? '';
      _websiteController.text = user['website'] ?? '';

      // Set agreement checkbox from user's saved status
      if (user['has_agreed_terms'] == true) {
        _agreedToTerms = true;
      }

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
      final authService = context.read<AuthService>();
      final token = await authService.getToken();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text("Current password is required"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (newPasswordController.text.length < 8) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "New password must be at least 8 characters",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text("Passwords do not match"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Call API
                    try {
                      final authService = this.context.read<AuthService>();
                      final token = await authService.getToken();
                      final response = await http.patch(
                        Uri.parse(
                          '${AppConfig.b2cApiBaseUrl}/api/v1/users/me/password?current_password=${Uri.encodeComponent(currentPasswordController.text)}&new_password=${Uri.encodeComponent(newPasswordController.text)}',
                        ),
                        headers: {'Authorization': 'Bearer $token'},
                      );

                      if (response.statusCode == 200) {
                        if (!this.context.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text("Password changed successfully!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        final error = jsonDecode(response.body);
                        if (!this.context.mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error['detail'] ?? 'Failed to change password',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!this.context.mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
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

  /// Builds a ripple ring that expands and fades out
  Widget _buildRippleRing(double progress, Color color, double maxSize) {
    final size = 24.0 + (maxSize - 24.0) * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withValues(alpha: opacity * 0.6),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(size / 4),
      ),
    );
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
                    controller: _scrollController,
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
    final tabs = ["Agreement process", "My profile"];

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
              // Animated checkbox with ripple ring effect - fixed size to prevent layout shift
              SizedBox(
                width: 40,
                height: 40,
                child: AnimatedBuilder(
                  animation: _highlightAnimation,
                  builder: (context, _) {
                    // Elastic bounce effect
                    final bounce = _showHighlight
                        ? 1.0 +
                              0.1 *
                                  Curves.elasticOut.transform(
                                    (_highlightAnimation.value * 2).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                  )
                        : 1.0;

                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Ripple rings (expanding circles that fade)
                        if (_showHighlight) ...[
                          // First ring
                          _buildRippleRing(
                            _highlightAnimation.value,
                            const Color(0xFF3C4494),
                            32,
                          ),
                          // Second ring (delayed)
                          _buildRippleRing(
                            (_highlightAnimation.value - 0.3).clamp(0.0, 1.0),
                            const Color(0xFF3C4494),
                            32,
                          ),
                        ],
                        // The checkbox
                        Transform.scale(
                          scale: bounce,
                          child: GestureDetector(
                            onTap: () {
                              // Only allow toggling if user hasn't already confirmed
                              final hasConfirmed = context
                                  .read<AuthService>()
                                  .hasAgreedTerms;
                              if (!hasConfirmed) {
                                setState(
                                  () => _agreedToTerms = !_agreedToTerms,
                                );
                              }
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _showHighlight || _agreedToTerms
                                      ? const Color(0xFF3C4494)
                                      : const Color(0xFFB7B7B7),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                color: _agreedToTerms
                                    ? const Color(0xFF3C4494)
                                    : Colors.white,
                                boxShadow: _showHighlight
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF3C4494,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: _agreedToTerms
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
              // Only enable if checkbox is checked AND user hasn't already confirmed
              onPressed:
                  (_agreedToTerms &&
                      !context.read<AuthService>().hasAgreedTerms)
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

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Agreement confirmed! You now have full access.",
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );

                      // Redirect to returnTo URL if available, otherwise switch to My Profile tab
                      if (widget.returnTo != null &&
                          widget.returnTo!.isNotEmpty) {
                        context.go(widget.returnTo!);
                      } else {
                        // Stay on profile page but switch to My Profile tab
                        setState(() => _currentTab = 1);
                      }
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

  Widget _buildEditButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (_isEditing) {
            // Upload photo if selected
            String? photoUrl;
            if (_selectedImageBytes != null) {
              photoUrl = await _uploadProfilePhoto();
              // Don't abort if photo upload fails - still save other fields
            }

            final updates = {
              'first_name': _nameController.text,
              'last_name': _surnameController.text,
              'mobile': _mobileE164, // Use E.164 format from PhoneInputField
              'country': _countryController.text,
              'city': _cityController.text,
              'company_name': _companyNameController.text,
              'website': _websiteController.text,
              // Include photo URL if uploaded
              if (photoUrl != null) 'photo_url': photoUrl,
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
                      // Upload photo if selected
                      String? photoUrl;
                      if (_selectedImageBytes != null) {
                        photoUrl = await _uploadProfilePhoto();
                      }

                      final updates = {
                        'first_name': _nameController.text,
                        'last_name': _surnameController.text,
                        'mobile':
                            _mobileE164, // Use E.164 format from PhoneInputField
                        'country': _countryController.text,
                        'city': _cityController.text,
                        'company_name': _companyNameController.text,
                        'website': _websiteController.text,
                        // Include photo URL if uploaded
                        if (photoUrl != null) 'photo_url': photoUrl,
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
              _buildMobilePhoneField(),
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
}
