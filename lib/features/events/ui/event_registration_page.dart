import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../../../core/services/registration_data_service.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/ui/notification_drawer.dart';
import 'widgets/profile_dropdown.dart';

/// Event Registration Page - Phase 1: Contact Information
/// Based on Figma design with deep purple header, 3-tab navigation, and contact form.
class EventRegistrationPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventRegistrationPage({super.key, required this.eventId});

  @override
  ConsumerState<EventRegistrationPage> createState() =>
      _EventRegistrationPageState();
}

class _EventRegistrationPageState extends ConsumerState<EventRegistrationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  // Current tab: 0 = General Info, 1 = Forum, 2 = Expo
  int _currentTab = 0;

  // Form controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyWebsiteController = TextEditingController();

  // ignore: unused_field
  String _countryCode = "+993";

  // Package selection state (Forum tab)
  // Packages loaded from backend API
  List<Map<String, dynamic>> _packages = [];
  // ignore: unused_field
  bool _isLoadingPackages = true;

  // Track quantities for each package
  final Map<int, int> _packageQuantities = {};
  // Track which packages are expanded
  final Set<int> _expandedPackages = {};

  // Delegate details state
  bool _showDelegateDetails = false;
  int _currentDelegateIndex = 0;
  int _totalDelegates = 0;

  // Delegate form controllers (will be reset for each delegate)
  final _delegateNameController = TextEditingController();
  final _delegateSurnameController = TextEditingController();
  final _delegateEmailController = TextEditingController();
  final _delegateMobileController = TextEditingController();
  final _delegateCountryController = TextEditingController();
  final _delegateCityController = TextEditingController();
  final _delegateCompanyController = TextEditingController();
  final _delegateWebsiteController = TextEditingController();
  // Social media fields
  final _instagramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _facebookController = TextEditingController();

  // Delegate country code for mobile field
  // ignore: unused_field
  String _delegateCountryCode = '+993';

  // Store delegate data
  final List<Map<String, String>> _delegateData = [];

  // Expo products state (Phase 3)
  // Products loaded from backend API
  List<Map<String, dynamic>> _expoProducts = [];
  // ignore: unused_field
  bool _isLoadingProducts = true;

  // Track quantities for each expo product
  final Map<int, int> _expoQuantities = {};
  // Track which expo products are expanded
  final Set<int> _expandedExpoProducts = {};

  // Show confirmation screen after registration complete
  bool _showConfirmation = false;

  // Registration ID from backend (created when starting registration)
  // ignore: unused_field
  String? _registrationId;

  // Saving state for buttons
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _fetchPackagesAndProducts();
  }

  /// Fetch delegate packages and expo products from backend API
  Future<void> _fetchPackagesAndProducts() async {
    final authService = legacy_provider.Provider.of<AuthService>(
      context,
      listen: false,
    );
    final service = RegistrationDataService(authService);

    try {
      // Fetch packages
      final packages = await service.fetchDelegatePackages(widget.eventId);
      if (mounted) {
        setState(() {
          _packages = packages;
          _isLoadingPackages = false;
        });
      }

      // Fetch products
      final products = await service.fetchExpoProducts(widget.eventId);
      if (mounted) {
        setState(() {
          _expoProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching registration data: $e');
      if (mounted) {
        setState(() {
          _isLoadingPackages = false;
          _isLoadingProducts = false;
        });
      }
    }
  }

  /// Submit the full registration to backend
  Future<void> _submitFullRegistration() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final authService = legacy_provider.Provider.of<AuthService>(
      context,
      listen: false,
    );
    final service = RegistrationDataService(authService);

    try {
      // Step 1: Create registration (or get existing)
      final regData = await service.createRegistration(widget.eventId);
      if (regData == null) {
        _showError('Failed to create registration');
        return;
      }

      final regId = regData['id'] as String;
      final status = regData['status'] as String?;
      _registrationId = regId;

      // Step 2: Save Phase 1 - Contact info
      final phase1Success = await service.savePhase1Contact(
        registrationId: regId,
        firstName: _nameController.text,
        lastName: _surnameController.text,
        email: _emailController.text,
        mobile: '$_countryCode${_mobileController.text}',
        country: _countryController.text,
        city: _cityController.text,
        companyName: _companyNameController.text,
        companyWebsite: _companyWebsiteController.text.isEmpty
            ? null
            : _companyWebsiteController.text,
      );
      if (!phase1Success) {
        _showError('Failed to save contact information');
        return;
      }

      // Step 3: Save Phase 2 - Package selections
      final packageSelections = <Map<String, dynamic>>[];
      _packageQuantities.forEach((pkgId, qty) {
        if (qty > 0) {
          packageSelections.add({'package_id': pkgId, 'quantity': qty});
        }
      });

      if (packageSelections.isNotEmpty) {
        final phase2Success = await service.savePhase2Packages(
          registrationId: regId,
          packages: packageSelections,
        );
        if (!phase2Success) {
          _showError('Failed to save package selections');
          return;
        }
      }

      // Step 4: Save Phase 3 - Expo products
      final productSelections = <Map<String, dynamic>>[];
      _expoQuantities.forEach((prodId, qty) {
        if (qty > 0) {
          productSelections.add({'product_id': prodId, 'quantity': qty});
        }
      });

      if (productSelections.isNotEmpty) {
        final phase3Success = await service.savePhase3Products(
          registrationId: regId,
          products: productSelections,
        );
        if (!phase3Success) {
          _showError('Failed to save expo products');
          return;
        }
      }

      // Step 5: Submit registration (only if it's a draft)
      if (status == 'draft') {
        final submitSuccess = await service.submitRegistration(regId);
        if (!submitSuccess) {
          _showError('Failed to submit registration');
          return;
        }
      }

      // Success! Show confirmation
      if (mounted) {
        setState(() {
          _showConfirmation = true;
          _isSaving = false;
        });
      }
    } catch (e) {
      debugPrint('Error submitting registration: $e');
      _showError('An error occurred: $e');
    } finally {
      if (mounted && !_showConfirmation) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Pre-fill form with current user's profile data
  void _prefillUserData() {
    // Get current user from AuthService
    final authService = legacy_provider.Provider.of<AuthService>(
      context,
      listen: false,
    );
    final user = authService.currentUser;

    if (user != null) {
      _nameController.text = user['first_name'] ?? '';
      _surnameController.text = user['last_name'] ?? '';
      _emailController.text = user['email'] ?? '';

      // Parse phone number - extract country code if present
      final phone = user['mobile'] as String? ?? '';
      if (phone.startsWith('+')) {
        // Try to match known country code lengths (most common first)
        // +993 (Turkmenistan, 3 digits), +7 (Russia, 1 digit), etc.
        String? detectedCode;
        int codeLength = 0;

        // Try 3 digits first (most common for countries like Turkmenistan +993)
        if (phone.length > 3) {
          final code3 = phone.substring(0, 4); // +XXX
          if (RegExp(r'^\+\d{3}$').hasMatch(code3)) {
            detectedCode = code3;
            codeLength = 4;
          }
        }
        // If not found, try 2 digits
        if (detectedCode == null && phone.length > 2) {
          final code2 = phone.substring(0, 3); // +XX
          if (RegExp(r'^\+\d{2}$').hasMatch(code2)) {
            detectedCode = code2;
            codeLength = 3;
          }
        }
        // If not found, try 1 digit (like +7 for Russia)
        if (detectedCode == null && phone.length > 1) {
          final code1 = phone.substring(0, 2); // +X
          if (RegExp(r'^\+\d$').hasMatch(code1)) {
            detectedCode = code1;
            codeLength = 2;
          }
        }

        if (detectedCode != null) {
          _countryCode = detectedCode;
          _mobileController.text = phone
              .substring(codeLength)
              .replaceAll(RegExp(r'^[-\s]*'), '');
        } else {
          _mobileController.text = phone;
        }
      } else {
        _mobileController.text = phone;
      }

      _countryController.text = user['country'] ?? '';
      _cityController.text = user['city'] ?? '';
      _companyNameController.text = user['company_name'] ?? '';
      _companyWebsiteController.text = user['website'] ?? '';
    }
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
    _companyWebsiteController.dispose();
    super.dispose();
  }

  void _toggleProfile() {
    setState(() => _isProfileOpen = !_isProfileOpen);
  }

  void _closeProfile() {
    if (_isProfileOpen) setState(() => _isProfileOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: GestureDetector(
        onTap: _closeProfile,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Show confirmation screen or main content
            if (_showConfirmation)
              _buildConfirmationScreen(isMobile)
            else
              Column(
                children: [
                  // Header with hamburger menu, title, and icons
                  _buildHeader(isMobile),

                  // Tab navigation + Main content area
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 50,
                      ),
                      child: Column(
                        children: [
                          // Tab bar overlay on top of card
                          _buildTabBar(isMobile),

                          // Main card with form
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F1F6),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: _buildCurrentTabContent(isMobile),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Profile dropdown overlay
            if (_isProfileOpen)
              Positioned(
                top: isMobile ? 70 : 90,
                right: isMobile ? 20 : 50,
                child: ProfileDropdown(onClose: _closeProfile),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 10,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: isMobile ? 24 : 28,
            ),
            onPressed: () => context.go('/events/${widget.eventId}/menu'),
          ),
          const SizedBox(width: 8),
          // Title
          Text(
            'Registration',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 24 : 28,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Custom App Bar with notifications and profile
          CustomAppBar(
            onProfileTap: _toggleProfile,
            onNotificationTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  /// Confirmation screen shown after registration is complete
  Widget _buildConfirmationScreen(bool isMobile) {
    return Column(
      children: [
        // Header (simplified - just title and menu)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 50,
            vertical: 15,
          ),
          child: Row(
            children: [
              // Hamburger menu
              IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Color(0xFFF1F1F6),
                  size: 30,
                ),
                onPressed: () => context.go('/events/${widget.eventId}/menu'),
              ),
              const SizedBox(width: 15),

              // Title
              Text(
                'Registration',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 28 : 40,
                  color: const Color(0xFFF1F1F6),
                ),
              ),
            ],
          ),
        ),

        // Centered confirmation card
        Expanded(
          child: Center(
            child: Container(
              width: isMobile ? 340 : 732,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 50,
                  vertical: isMobile ? 40 : 60,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFE1ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Application Accepted!\nWe will be in touch soon.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 24 : 35,
                        height: 1.43,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () =>
                          context.go('/events/${widget.eventId}/menu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17154B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Go Home',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 16 : 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isMobile) {
    final tabs = ['General Information', 'Forum', 'Expo'];

    return Row(
      children: tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isActive = index == _currentTab;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 15 : 30,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF1F1F6) : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: isMobile
                  ? 16
                  : isActive
                  ? 30
                  : 25,
              color: isActive
                  ? const Color(0xFF3C4494)
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurrentTabContent(bool isMobile) {
    switch (_currentTab) {
      case 0:
        return _buildContactForm(isMobile);
      case 1:
        return _buildForumPackages(isMobile);
      case 2:
        return _buildExpoProducts(isMobile);
      default:
        return _buildContactForm(isMobile);
    }
  }

  /// Forum tab - Package selection with expandable cards
  Widget _buildForumPackages(bool isMobile) {
    // Show delegate details form if user clicked Next after selecting packages
    if (_showDelegateDetails && _totalDelegates > 0) {
      return _buildDelegateDetailsForm(isMobile);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 15 : 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package list
            ..._packages.map((pkg) => _buildPackageCard(pkg, isMobile)),

            const SizedBox(height: 40),

            // Back, Skip and Next buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _currentTab = 0);
                  },
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.black.withValues(alpha: 0.5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Skip to next tab (Expo)
                        setState(() => _currentTab = 2);
                      },
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: Colors.black.withValues(alpha: 0.5),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    TextButton(
                      onPressed: _onForumNextPressed,
                      child: Text(
                        'Next',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: Colors.black.withValues(alpha: 0.5),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handle Next button in Forum packages view
  void _onForumNextPressed() {
    // Calculate total delegates from selected packages
    int total = 0;
    _packageQuantities.forEach((pkgId, qty) {
      total += qty;
    });

    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one package')),
      );
      return;
    }

    // Initialize delegate data storage
    _delegateData.clear();
    for (int i = 0; i < total; i++) {
      _delegateData.add({});
    }

    setState(() {
      _totalDelegates = total;
      _currentDelegateIndex = 0;
      _showDelegateDetails = true;
      _clearDelegateForm();
    });
  }

  /// Clear delegate form fields
  void _clearDelegateForm() {
    _delegateNameController.clear();
    _delegateSurnameController.clear();
    _delegateEmailController.clear();
    _delegateMobileController.clear();
    _delegateCountryController.clear();
    _delegateCityController.clear();
    _delegateCompanyController.clear();
    _delegateWebsiteController.clear();
    _instagramController.clear();
    _whatsappController.clear();
    _facebookController.clear();
  }

  /// Save current delegate and go to next
  void _onDelegateNextPressed() {
    // Save current delegate data
    _delegateData[_currentDelegateIndex] = {
      'name': _delegateNameController.text,
      'surname': _delegateSurnameController.text,
      'email': _delegateEmailController.text,
      'mobile': _delegateMobileController.text,
      'country': _delegateCountryController.text,
      'city': _delegateCityController.text,
      'company': _delegateCompanyController.text,
      'website': _delegateWebsiteController.text,
      'instagram': _instagramController.text,
      'whatsapp': _whatsappController.text,
      'facebook': _facebookController.text,
    };

    if (_currentDelegateIndex < _totalDelegates - 1) {
      // Go to next delegate
      setState(() {
        _currentDelegateIndex++;
        _clearDelegateForm();
        // Pre-fill if data exists for this delegate
        final data = _delegateData[_currentDelegateIndex];
        if (data.isNotEmpty) {
          _delegateNameController.text = data['name'] ?? '';
          _delegateSurnameController.text = data['surname'] ?? '';
          _delegateEmailController.text = data['email'] ?? '';
          _delegateMobileController.text = data['mobile'] ?? '';
          _delegateCountryController.text = data['country'] ?? '';
          _delegateCityController.text = data['city'] ?? '';
          _delegateCompanyController.text = data['company'] ?? '';
          _delegateWebsiteController.text = data['website'] ?? '';
          _instagramController.text = data['instagram'] ?? '';
          _whatsappController.text = data['whatsapp'] ?? '';
          _facebookController.text = data['facebook'] ?? '';
        }
      });
    } else {
      // All delegates done, go to Expo tab
      setState(() {
        _showDelegateDetails = false;
        _currentTab = 2;
      });
    }
  }

  /// Delegate details form (2/3 etc.)
  Widget _buildDelegateDetailsForm(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 15 : 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title: Delegate Details (X/Y):
            Text(
              'Delegate Details (${_currentDelegateIndex + 1}/$_totalDelegates):',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),

            // Form fields
            if (isMobile)
              _buildDelegateMobileForm()
            else
              _buildDelegateDesktopForm(),

            const SizedBox(height: 30),

            // Follow Me section
            Text(
              'Follow Me:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Social media fields
            if (isMobile)
              _buildSocialMobileForm()
            else
              _buildSocialDesktopForm(),

            const SizedBox(height: 40),

            // Back and Next buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_currentDelegateIndex > 0) {
                        _currentDelegateIndex--;
                        _clearDelegateForm();
                        // Pre-fill if data exists for this delegate
                        final data = _delegateData[_currentDelegateIndex];
                        if (data.isNotEmpty) {
                          _delegateNameController.text = data['name'] ?? '';
                          _delegateSurnameController.text =
                              data['surname'] ?? '';
                          _delegateEmailController.text = data['email'] ?? '';
                          _delegateMobileController.text = data['mobile'] ?? '';
                          _delegateCountryController.text =
                              data['country'] ?? '';
                          _delegateCityController.text = data['city'] ?? '';
                          _delegateCompanyController.text =
                              data['company'] ?? '';
                          _delegateWebsiteController.text =
                              data['website'] ?? '';
                          _instagramController.text = data['instagram'] ?? '';
                          _whatsappController.text = data['whatsapp'] ?? '';
                          _facebookController.text = data['facebook'] ?? '';
                        }
                      } else {
                        // Back to package selection
                        _showDelegateDetails = false;
                      }
                    });
                  },
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.black.withValues(alpha: 0.5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _onDelegateNextPressed,
                  child: Text(
                    'Next',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.black.withValues(alpha: 0.5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDelegateDesktopForm() {
    return Column(
      children: [
        // Row 1: Name | Surname
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Name:',
                'Enter name',
                _delegateNameController,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: _buildTextField(
                'Surname:',
                'Enter surname',
                _delegateSurnameController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),

        // Row 2: Email | Mobile
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'E-mail address:',
                'emailaddress@gmail.com',
                _delegateEmailController,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(child: _buildDelegateMobileField()),
          ],
        ),
        const SizedBox(height: 25),

        // Row 3: Country | City
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Country:',
                'Country',
                _delegateCountryController,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: _buildTextField('City:', 'City', _delegateCityController),
            ),
          ],
        ),
        const SizedBox(height: 25),

        // Row 4: Company Name | Company Website
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Company Name:',
                'CompanyName',
                _delegateCompanyController,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: _buildTextField(
                'Company Website:',
                'companywebsite.com',
                _delegateWebsiteController,
                isOptional: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDelegateMobileForm() {
    return Column(
      children: [
        _buildTextField('Name:', 'Enter name', _delegateNameController),
        const SizedBox(height: 20),
        _buildTextField(
          'Surname:',
          'Enter surname',
          _delegateSurnameController,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'E-mail address:',
          'emailaddress@gmail.com',
          _delegateEmailController,
        ),
        const SizedBox(height: 20),
        _buildDelegateMobileField(),
        const SizedBox(height: 20),
        _buildTextField('Country:', 'Country', _delegateCountryController),
        const SizedBox(height: 20),
        _buildTextField('City:', 'City', _delegateCityController),
        const SizedBox(height: 20),
        _buildTextField(
          'Company Name:',
          'CompanyName',
          _delegateCompanyController,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Company Website:',
          'companywebsite.com',
          _delegateWebsiteController,
          isOptional: true,
        ),
      ],
    );
  }

  Widget _buildDelegateMobileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile number:',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country code picker
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E5E5),
                border: Border.all(color: const Color(0xFFADADAD)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
              ),
              child: CountryCodePicker(
                onChanged: (country) {
                  setState(
                    () => _delegateCountryCode = country.dialCode ?? '+993',
                  );
                },
                initialSelection: 'TM',
                favorite: const ['TM', 'RU', 'US'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                padding: EdgeInsets.zero,
                textStyle: GoogleFonts.inter(fontSize: 16),
                showFlagMain: true,
                showDropDownButton: false,
              ),
            ),
            // Phone number input
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB7B7B7)),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: TextField(
                  controller: _delegateMobileController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                    hintText: 'Enter your mobile number',
                    hintStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialDesktopForm() {
    return Column(
      children: [
        // Row 1: Instagram | WhatsApp
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Instagram:',
                'nickname',
                _instagramController,
                isOptional: true,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: _buildTextField(
                'WhatsApp:',
                'nickname',
                _whatsappController,
                isOptional: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        // Row 2: Facebook (left column only)
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Facebook:',
                'nickname',
                _facebookController,
                isOptional: true,
              ),
            ),
            const SizedBox(width: 50),
            const Expanded(child: SizedBox()), // Empty right column
          ],
        ),
      ],
    );
  }

  Widget _buildSocialMobileForm() {
    return Column(
      children: [
        _buildTextField(
          'Instagram:',
          'nickname',
          _instagramController,
          isOptional: true,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'WhatsApp:',
          'nickname',
          _whatsappController,
          isOptional: true,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Facebook:',
          'nickname',
          _facebookController,
          isOptional: true,
        ),
      ],
    );
  }

  /// Expo tab - Product list with expandable cards
  Widget _buildExpoProducts(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 15 : 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Product List:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 30,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Product list
            ..._expoProducts.map(
              (product) => _buildExpoProductCard(product, isMobile),
            ),

            const SizedBox(height: 40),

            // Back, Skip and Next buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _currentTab = 1);
                  },
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.black.withValues(alpha: 0.5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Skip - just show confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Registration skipped. You can complete it later.',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: Colors.black.withValues(alpha: 0.5),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    TextButton(
                      onPressed: _isSaving ? null : _submitFullRegistration,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Submit',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                color: Colors.black.withValues(alpha: 0.5),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Single expo product card with expand/collapse and quantity selector
  Widget _buildExpoProductCard(Map<String, dynamic> product, bool isMobile) {
    final int productId = product['id'];
    final bool isExpanded = _expandedExpoProducts.contains(productId);
    final int quantity = _expoQuantities[productId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDEEB).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 15 : 30,
              vertical: 20,
            ),
            child: Row(
              children: [
                // Product name
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          product['name'] ?? '',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w400,
                            fontSize: isMobile ? 18 : 30,
                            color: const Color(0xFF151938),
                          ),
                        ),
                      ),
                      if (product['price'] != null) ...[
                        const SizedBox(width: 15),
                        Text(
                          '${product['price']} ${product['currency'] ?? 'USD'}',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 18 : 28,
                            color: const Color(0xFF311370),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Quantity selector
                _buildExpoQuantitySelector(productId, quantity),

                const SizedBox(width: 20),

                // Expand/collapse chevron
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedExpoProducts.remove(productId);
                      } else {
                        _expandedExpoProducts.add(productId);
                      }
                    });
                  },
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Expanded description
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                isMobile ? 15 : 30,
                0,
                isMobile ? 15 : 30,
                20,
              ),
              child: Text(
                product['description'] ?? '',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w400,
                  fontSize: isMobile ? 16 : 25,
                  height: 1.6,
                  color: const Color(0xFF151938).withValues(alpha: 0.85),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Quantity selector for expo products
  Widget _buildExpoQuantitySelector(int productId, int quantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus button
        GestureDetector(
          onTap: () {
            if (quantity > 0) {
              setState(() {
                _expoQuantities[productId] = quantity - 1;
              });
            }
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3C4494), width: 1),
            ),
            child: const Icon(Icons.remove, size: 16, color: Color(0xFF3C4494)),
          ),
        ),

        // Count
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Text(
            quantity.toString(),
            style: GoogleFonts.encodeSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: const Color(0xFF292526),
            ),
          ),
        ),

        // Plus button
        GestureDetector(
          onTap: () {
            setState(() {
              _expoQuantities[productId] = quantity + 1;
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3C4494), width: 1),
            ),
            child: const Icon(Icons.add, size: 16, color: Color(0xFF3C4494)),
          ),
        ),
      ],
    );
  }

  /// Single package card with expand/collapse and quantity selector
  Widget _buildPackageCard(Map<String, dynamic> pkg, bool isMobile) {
    final int pkgId = pkg['id'];
    final bool isExpanded = _expandedPackages.contains(pkgId);
    final int quantity = _packageQuantities[pkgId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDEEB).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 15 : 30,
              vertical: 20,
            ),
            child: Row(
              children: [
                // Package name + price
                Expanded(
                  child: Text(
                    '${pkg['name']} - ${pkg['price']} ${pkg['currency']}',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w400,
                      fontSize: isMobile ? 18 : 30,
                      color: const Color(0xFF151938),
                    ),
                  ),
                ),

                // Expand/collapse chevron
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedPackages.remove(pkgId);
                      } else {
                        _expandedPackages.add(pkgId);
                      }
                    });
                  },
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 40,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(width: 20),

                // Quantity selector
                _buildQuantitySelector(pkgId, quantity),
              ],
            ),
          ),

          // Expanded description
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                isMobile ? 15 : 30,
                0,
                isMobile ? 15 : 30,
                20,
              ),
              child: Text(
                pkg['description'] ?? '',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w400,
                  fontSize: isMobile ? 16 : 25,
                  height: 1.6,
                  color: const Color(0xFF151938).withValues(alpha: 0.85),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Quantity selector with minus/count/plus buttons
  Widget _buildQuantitySelector(int pkgId, int quantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus button
        GestureDetector(
          onTap: () {
            if (quantity > 0) {
              setState(() {
                _packageQuantities[pkgId] = quantity - 1;
              });
            }
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3C4494), width: 1),
            ),
            child: const Icon(Icons.remove, size: 16, color: Color(0xFF3C4494)),
          ),
        ),

        // Count
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Text(
            quantity.toString(),
            style: GoogleFonts.encodeSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: const Color(0xFF292526),
            ),
          ),
        ),

        // Plus button
        GestureDetector(
          onTap: () {
            setState(() {
              _packageQuantities[pkgId] = quantity + 1;
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3C4494), width: 1),
            ),
            child: const Icon(Icons.add, size: 16, color: Color(0xFF3C4494)),
          ),
        ),
      ],
    );
  }

  Widget _buildContactForm(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 15 : 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Text(
              'Contact Person',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),

            // Form fields in grid
            if (isMobile) _buildMobileForm() else _buildDesktopForm(),

            const SizedBox(height: 40),

            // Next button - goes to Forum tab (tab 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Move to Forum tab (tab 1) from General Info
                  setState(() {
                    _currentTab = 1;
                  });
                },
                child: Text(
                  'Next',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Colors.black.withValues(alpha: 0.5),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopForm() {
    return Column(
      children: [
        // Row 1: Name | Surname
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Name:',
                'Enter your name',
                _nameController,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: _buildTextField(
                'Surname:',
                'Enter your surname',
                _surnameController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),

        // Row 2: Email | Mobile
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'E-mail address:',
                'emailaddress@gmail.com',
                _emailController,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(child: _buildMobileField()),
          ],
        ),
        const SizedBox(height: 25),

        // Row 3: Country | City
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Country:',
                'Select country',
                _countryController,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: _buildTextField('City:', 'Enter city', _cityController),
            ),
          ],
        ),
        const SizedBox(height: 25),

        // Row 4: Company Name | Company Website
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Company Name:',
                'Enter company name',
                _companyNameController,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: _buildTextField(
                'Company Website:',
                'companywebsite.com',
                _companyWebsiteController,
                isOptional: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileForm() {
    return Column(
      children: [
        _buildTextField('Name:', 'Enter your name', _nameController),
        const SizedBox(height: 20),
        _buildTextField('Surname:', 'Enter your surname', _surnameController),
        const SizedBox(height: 20),
        _buildTextField(
          'E-mail address:',
          'emailaddress@gmail.com',
          _emailController,
        ),
        const SizedBox(height: 20),
        _buildMobileField(),
        const SizedBox(height: 20),
        _buildTextField('Country:', 'Select country', _countryController),
        const SizedBox(height: 20),
        _buildTextField('City:', 'Enter city', _cityController),
        const SizedBox(height: 20),
        _buildTextField(
          'Company Name:',
          'Enter company name',
          _companyNameController,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Company Website:',
          'companywebsite.com',
          _companyWebsiteController,
          isOptional: true,
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String placeholder,
    TextEditingController controller, {
    bool isOptional = false,
  }) {
    return Column(
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
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB7B7B7)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 14,
              ),
              hintText: placeholder,
              hintStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile number:',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country code picker
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E5E5),
                border: Border.all(color: const Color(0xFFADADAD)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
              ),
              child: CountryCodePicker(
                onChanged: (country) {
                  setState(() => _countryCode = country.dialCode ?? "+993");
                },
                initialSelection: 'TM',
                favorite: const ['TM', 'RU', 'US'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                padding: EdgeInsets.zero,
                textStyle: GoogleFonts.inter(fontSize: 16),
                showFlagMain: true,
                showDropDownButton: false,
              ),
            ),

            // Phone number input
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB7B7B7)),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                    hintText: 'Enter your mobile number',
                    hintStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
