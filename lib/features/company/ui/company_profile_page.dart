import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/reference_data_provider.dart';
import '../../../core/providers/upload_provider.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';
import '../../../shared/widgets/multi_select_field.dart';
import '../../../shared/widgets/country_city_picker.dart';
import '../../../shared/widgets/image_uploader.dart';
import '../providers/company_providers.dart';
import '../models/company.dart';

/// Company Profile Page — form page for managing company profiles (max 5 per event).
///
/// Supports creating new companies and editing existing ones. When the user owns
/// multiple companies for an event, tabs are shown at the top (one per company
/// plus a "+" tab to create a new one).
class CompanyProfilePage extends ConsumerStatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  ConsumerState<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends ConsumerState<CompanyProfilePage> {
  static const int _maxCompanies = 5;

  int _selectedTabIndex = 0;
  bool _isSaving = false;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // --- Basic Info ---
  final _nameController = TextEditingController();
  List<String> _selectedCategories = [];
  final _websiteController = TextEditingController();
  final _aboutController = TextEditingController();

  // --- Contact ---
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  // --- Location ---
  String? _selectedCountry;
  String? _selectedCity;

  // --- Branding ---
  String? _brandIconUrl;
  String? _fullLogoUrl;
  String? _coverImageUrl;

  // --- Gallery ---
  List<String?> _galleryUrls = [null, null, null, null];

  // --- Social Links ---
  final _linkedInController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _facebookController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _weChatController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _aboutController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _linkedInController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _whatsAppController.dispose();
    _weChatController.dispose();
    super.dispose();
  }

  /// Populate form controllers from a [Company] model.
  void _populateFromCompany(Company company) {
    _nameController.text = company.name;
    _selectedCategories = List<String>.from(company.categories ?? []);
    _websiteController.text = company.website ?? '';
    _aboutController.text = company.about ?? '';
    _emailController.text = company.email ?? '';
    _mobileController.text = company.mobile ?? '';
    _selectedCountry = company.country;
    _selectedCity = company.city;
    _brandIconUrl = company.brandIconUrl;
    _fullLogoUrl = company.fullLogoUrl;
    _coverImageUrl = company.coverImageUrl;

    // Gallery
    final urls = company.galleryUrls ?? [];
    _galleryUrls = List.generate(4, (i) => i < urls.length ? urls[i] : null);

    // Social links
    final social = company.socialLinks ?? {};
    _linkedInController.text = social['linkedin'] as String? ?? '';
    _instagramController.text = social['instagram'] as String? ?? '';
    _twitterController.text = social['twitter'] as String? ?? '';
    _facebookController.text = social['facebook'] as String? ?? '';
    _whatsAppController.text = social['whatsapp'] as String? ?? '';
    _weChatController.text = social['wechat'] as String? ?? '';
  }

  /// Clear all form controllers for a fresh "new company" form.
  void _clearForm() {
    _nameController.clear();
    _selectedCategories = [];
    _websiteController.clear();
    _aboutController.clear();
    _emailController.clear();
    _mobileController.clear();
    _selectedCountry = null;
    _selectedCity = null;
    _brandIconUrl = null;
    _fullLogoUrl = null;
    _coverImageUrl = null;
    _galleryUrls = [null, null, null, null];
    _linkedInController.clear();
    _instagramController.clear();
    _twitterController.clear();
    _facebookController.clear();
    _whatsAppController.clear();
    _weChatController.clear();
  }

  /// Build the payload map for create/update.
  Map<String, dynamic> _buildPayload(int eventId) {
    final socialLinks = <String, dynamic>{};
    if (_linkedInController.text.isNotEmpty) {
      socialLinks['linkedin'] = _linkedInController.text.trim();
    }
    if (_instagramController.text.isNotEmpty) {
      socialLinks['instagram'] = _instagramController.text.trim();
    }
    if (_twitterController.text.isNotEmpty) {
      socialLinks['twitter'] = _twitterController.text.trim();
    }
    if (_facebookController.text.isNotEmpty) {
      socialLinks['facebook'] = _facebookController.text.trim();
    }
    if (_whatsAppController.text.isNotEmpty) {
      socialLinks['whatsapp'] = _whatsAppController.text.trim();
    }
    if (_weChatController.text.isNotEmpty) {
      socialLinks['wechat'] = _weChatController.text.trim();
    }

    return {
      'event_id': eventId,
      'name': _nameController.text.trim(),
      'categories': _selectedCategories,
      'website': _websiteController.text.trim(),
      'about': _aboutController.text.trim(),
      'email': _emailController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'country': _selectedCountry,
      'city': _selectedCity,
      'brand_icon_url': _brandIconUrl,
      'full_logo_url': _fullLogoUrl,
      'cover_image_url': _coverImageUrl,
      'gallery_urls':
          _galleryUrls.where((url) => url != null && url.isNotEmpty).toList(),
      'social_links': socialLinks,
    };
  }

  /// Save the current form (create or update).
  Future<void> _save(int eventId, List<Company> companies) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(companyServiceProvider);
      final isNewCompany = _selectedTabIndex >= companies.length;

      if (isNewCompany) {
        await service.createCompany(_buildPayload(eventId));
      } else {
        final companyId = companies[_selectedTabIndex].id;
        await service.updateCompany(companyId, _buildPayload(eventId));
      }

      // Invalidate the provider to refresh the list
      ref.invalidate(myCompaniesProvider(eventId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNewCompany
                ? 'Company created successfully!'
                : 'Company updated successfully!',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save company: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final eventId = int.tryParse(eventIdStr) ?? 0;

    final companiesAsync = ref.watch(myCompaniesProvider(eventId));

    return EventSidebarLayout(
      title: 'Company Profile',
      child: companiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, _) => _buildErrorView(error, eventId),
        data: (companies) => _buildContent(companies, eventId),
      ),
    );
  }

  Widget _buildErrorView(Object error, int eventId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load companies',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(myCompaniesProvider(eventId)),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Company> companies, int eventId) {
    // Clamp tab index if companies list changed
    final canAddNew = companies.length < _maxCompanies;
    final maxTab = canAddNew ? companies.length : companies.length - 1;
    if (_selectedTabIndex > maxTab) {
      _selectedTabIndex = maxTab;
    }

    // Determine if current tab is an existing company or "new"
    final isNewCompany = _selectedTabIndex >= companies.length;

    // When we have data and the form is empty, populate from current selection
    // We use a post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only auto-populate when switching tabs or on first load
      if (!isNewCompany && companies.isNotEmpty) {
        final company = companies[_selectedTabIndex];
        if (_nameController.text != company.name) {
          _populateFromCompany(company);
          setState(() {});
        }
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page header
              _buildPageHeader(companies.length),
              const SizedBox(height: 20),

              // Company tabs (if multiple companies or can add new)
              if (companies.isNotEmpty || canAddNew)
                _buildCompanyTabs(companies, canAddNew),
              const SizedBox(height: 24),

              // Form card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicInfoSection(eventId),
                        const SizedBox(height: 32),
                        _buildDivider(),
                        const SizedBox(height: 32),
                        _buildContactSection(),
                        const SizedBox(height: 32),
                        _buildDivider(),
                        const SizedBox(height: 32),
                        _buildLocationSection(),
                        const SizedBox(height: 32),
                        _buildDivider(),
                        const SizedBox(height: 32),
                        _buildBrandingSection(),
                        const SizedBox(height: 32),
                        _buildDivider(),
                        const SizedBox(height: 32),
                        _buildGallerySection(),
                        const SizedBox(height: 32),
                        _buildDivider(),
                        const SizedBox(height: 32),
                        _buildSocialLinksSection(),
                        const SizedBox(height: 40),
                        _buildSaveButton(companies, eventId),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page Header
  // ---------------------------------------------------------------------------

  Widget _buildPageHeader(int companyCount) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.business,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company Profile',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$companyCount of $_maxCompanies companies registered',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Company Tabs
  // ---------------------------------------------------------------------------

  Widget _buildCompanyTabs(List<Company> companies, bool canAddNew) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // One tab per existing company
          for (int i = 0; i < companies.length; i++)
            _buildTab(
              label: companies[i].name,
              index: i,
              icon: Icons.business,
            ),

          // "+" tab for adding new
          if (canAddNew)
            _buildTab(
              label: 'New Company',
              index: companies.length,
              icon: Icons.add,
            ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: isSelected ? 0 : 1,
        child: InkWell(
          onTap: () {
            if (_selectedTabIndex == index) return;
            setState(() {
              _selectedTabIndex = index;
              _clearForm();
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section Header Helper
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade200, height: 1);
  }

  // ---------------------------------------------------------------------------
  // 1. Basic Info Section
  // ---------------------------------------------------------------------------

  Widget _buildBasicInfoSection(int eventId) {
    final categoriesAsync = ref.watch(companyCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Basic Information', Icons.info_outline),
        const SizedBox(height: 20),

        // Company name (required)
        _buildLabeledField(
          label: 'Company Name',
          required: true,
          child: TextFormField(
            controller: _nameController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDecoration(hintText: 'Enter company name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Company name is required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),

        // Categories (multi-select)
        categoriesAsync.when(
          loading: () => _buildLabeledField(
            label: 'Categories',
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          error: (err, _) => _buildLabeledField(
            label: 'Categories',
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Failed to load categories',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ),
          data: (categories) => MultiSelectField(
            label: 'Categories',
            options: categories,
            selectedValues: _selectedCategories,
            onChanged: (values) {
              setState(() => _selectedCategories = values);
            },
            hintText: 'Select industry categories',
          ),
        ),
        const SizedBox(height: 20),

        // Website
        _buildLabeledField(
          label: 'Website',
          child: TextFormField(
            controller: _websiteController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDecoration(hintText: 'https://example.com'),
            keyboardType: TextInputType.url,
          ),
        ),
        const SizedBox(height: 20),

        // About (textarea)
        _buildLabeledField(
          label: 'About',
          child: TextFormField(
            controller: _aboutController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDecoration(
              hintText: 'Tell us about your company...',
            ),
            maxLines: 4,
            minLines: 3,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Contact Section
  // ---------------------------------------------------------------------------

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Contact Information', Icons.contact_mail_outlined),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 500) {
              return Column(
                children: [
                  _buildLabeledField(
                    label: 'Email',
                    child: TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration:
                          _inputDecoration(hintText: 'company@example.com'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabeledField(
                    label: 'Mobile',
                    child: TextFormField(
                      controller: _mobileController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration:
                          _inputDecoration(hintText: '+1 234 567 8900'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildLabeledField(
                    label: 'Email',
                    child: TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration:
                          _inputDecoration(hintText: 'company@example.com'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLabeledField(
                    label: 'Mobile',
                    child: TextFormField(
                      controller: _mobileController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration:
                          _inputDecoration(hintText: '+1 234 567 8900'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Location Section
  // ---------------------------------------------------------------------------

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Location', Icons.location_on_outlined),
        const SizedBox(height: 20),
        CountryCityPicker(
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
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Branding Section
  // ---------------------------------------------------------------------------

  Widget _buildBrandingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Branding', Icons.palette_outlined),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 500) {
              return Column(
                children: [
                  ImageUploader(
                    label: 'Brand Icon',
                    currentImageUrl: _brandIconUrl,
                    height: 120,
                    onUpload: () => _onImageUpload('brand_icon'),
                    onRemove: _brandIconUrl != null
                        ? () => setState(() => _brandIconUrl = null)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ImageUploader(
                    label: 'Full Logo',
                    currentImageUrl: _fullLogoUrl,
                    height: 120,
                    onUpload: () => _onImageUpload('full_logo'),
                    onRemove: _fullLogoUrl != null
                        ? () => setState(() => _fullLogoUrl = null)
                        : null,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ImageUploader(
                    label: 'Brand Icon',
                    currentImageUrl: _brandIconUrl,
                    height: 140,
                    onUpload: () => _onImageUpload('brand_icon'),
                    onRemove: _brandIconUrl != null
                        ? () => setState(() => _brandIconUrl = null)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ImageUploader(
                    label: 'Full Logo',
                    currentImageUrl: _fullLogoUrl,
                    height: 140,
                    onUpload: () => _onImageUpload('full_logo'),
                    onRemove: _fullLogoUrl != null
                        ? () => setState(() => _fullLogoUrl = null)
                        : null,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        ImageUploader(
          label: 'Cover Image',
          currentImageUrl: _coverImageUrl,
          height: 200,
          onUpload: () => _onImageUpload('cover'),
          onRemove: _coverImageUrl != null
              ? () => setState(() => _coverImageUrl = null)
              : null,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Gallery Section
  // ---------------------------------------------------------------------------

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Gallery', Icons.photo_library_outlined),
        const SizedBox(height: 8),
        Text(
          'Upload up to 4 images to showcase your company',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 500 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return ImageUploader(
                  label: 'Image ${index + 1}',
                  currentImageUrl: _galleryUrls[index],
                  height: 140,
                  onUpload: () => _onImageUpload('gallery_$index'),
                  onRemove: _galleryUrls[index] != null
                      ? () => setState(() => _galleryUrls[index] = null)
                      : null,
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Social Links Section
  // ---------------------------------------------------------------------------

  Widget _buildSocialLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Social Links', Icons.link),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 500) {
              return Column(
                children: [
                  _buildSocialField(
                    label: 'LinkedIn',
                    controller: _linkedInController,
                    icon: Icons.business_center,
                    hint: 'https://linkedin.com/company/...',
                  ),
                  const SizedBox(height: 16),
                  _buildSocialField(
                    label: 'Instagram',
                    controller: _instagramController,
                    icon: Icons.camera_alt_outlined,
                    hint: 'https://instagram.com/...',
                  ),
                  const SizedBox(height: 16),
                  _buildSocialField(
                    label: 'Twitter / X',
                    controller: _twitterController,
                    icon: Icons.alternate_email,
                    hint: 'https://x.com/...',
                  ),
                  const SizedBox(height: 16),
                  _buildSocialField(
                    label: 'Facebook',
                    controller: _facebookController,
                    icon: Icons.facebook,
                    hint: 'https://facebook.com/...',
                  ),
                  const SizedBox(height: 16),
                  _buildSocialField(
                    label: 'WhatsApp',
                    controller: _whatsAppController,
                    icon: Icons.chat_outlined,
                    hint: '+1234567890',
                  ),
                  const SizedBox(height: 16),
                  _buildSocialField(
                    label: 'WeChat',
                    controller: _weChatController,
                    icon: Icons.message_outlined,
                    hint: 'WeChat ID',
                  ),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSocialField(
                        label: 'LinkedIn',
                        controller: _linkedInController,
                        icon: Icons.business_center,
                        hint: 'https://linkedin.com/company/...',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialField(
                        label: 'Instagram',
                        controller: _instagramController,
                        icon: Icons.camera_alt_outlined,
                        hint: 'https://instagram.com/...',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSocialField(
                        label: 'Twitter / X',
                        controller: _twitterController,
                        icon: Icons.alternate_email,
                        hint: 'https://x.com/...',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialField(
                        label: 'Facebook',
                        controller: _facebookController,
                        icon: Icons.facebook,
                        hint: 'https://facebook.com/...',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSocialField(
                        label: 'WhatsApp',
                        controller: _whatsAppController,
                        icon: Icons.chat_outlined,
                        hint: '+1234567890',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialField(
                        label: 'WeChat',
                        controller: _weChatController,
                        icon: Icons.message_outlined,
                        hint: 'WeChat ID',
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSocialField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: _inputDecoration(hintText: hint),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Save Button
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton(List<Company> companies, int eventId) {
    final isNewCompany = _selectedTabIndex >= companies.length;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _save(eventId, companies),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isNewCompany ? 'Create Company' : 'Save Changes',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.errorColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
      ),
    );
  }

  Future<void> _onImageUpload(String imageType) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      final uploadService = ref.read(uploadServiceProvider);
      final url = await uploadService.uploadFile(
        fileData: bytes,
        folder: 'company-branding',
        filename: '${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (!mounted) return;
      setState(() {
        switch (imageType) {
          case 'brand_icon':
            _brandIconUrl = url;
          case 'full_logo':
            _fullLogoUrl = url;
          case 'cover':
            _coverImageUrl = url;
          default:
            // Gallery images: gallery_0, gallery_1, ...
            if (imageType.startsWith('gallery_')) {
              final idx = int.tryParse(imageType.replaceFirst('gallery_', ''));
              if (idx != null && idx < _galleryUrls.length) {
                _galleryUrls[idx] = url;
              }
            }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
