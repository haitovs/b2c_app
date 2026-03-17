import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/phone_input_field.dart';
import '../../../core/providers/reference_data_provider.dart';
import '../../../core/providers/upload_provider.dart';
import '../../../shared/widgets/multi_select_field.dart';
import '../../../shared/widgets/country_city_picker.dart';
import '../providers/company_providers.dart';
import '../models/company.dart';

/// Form page for adding or editing a single company profile.
/// When [companyId] is null, we're creating a new company.
class CompanyProfilePage extends ConsumerStatefulWidget {
  final String? companyId;

  const CompanyProfilePage({super.key, this.companyId});

  @override
  ConsumerState<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends ConsumerState<CompanyProfilePage> {
  bool _isSaving = false;
  bool _didPopulate = false;

  final _formKey = GlobalKey<FormState>();

  // --- Basic Info ---
  final _nameController = TextEditingController();
  List<String> _selectedCategories = [];
  final _websiteController = TextEditingController();
  late quill.QuillController _aboutController;

  // --- Contact ---
  final _emailController = TextEditingController();
  String _mobile = '';

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
  List<_SocialLinkEntry> _socialLinks = [];

  @override
  void initState() {
    super.initState();
    _aboutController = quill.QuillController.basic();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _aboutController.dispose();
    _emailController.dispose();
    for (final entry in _socialLinks) {
      entry.dispose();
    }
    super.dispose();
  }

  bool get _isEditing => widget.companyId != null;

  void _populateFromCompany(Company company) {
    if (_didPopulate) return;
    _didPopulate = true;

    _nameController.text = company.name;
    _selectedCategories = List<String>.from(company.categories ?? []);
    _websiteController.text = company.website ?? '';

    final aboutText = company.about ?? '';
    if (aboutText.isNotEmpty) {
      _aboutController = quill.QuillController(
        document: quill.Document()..insert(0, aboutText),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    _emailController.text = company.email ?? '';
    _mobile = company.mobile ?? '';
    _selectedCountry = company.country;
    _selectedCity = company.city;
    _brandIconUrl = company.brandIconUrl;
    _fullLogoUrl = company.fullLogoUrl;
    _coverImageUrl = company.coverImageUrl;

    final urls = company.galleryUrls ?? [];
    _galleryUrls = List.generate(4, (i) => i < urls.length ? urls[i] : null);

    for (final entry in _socialLinks) {
      entry.dispose();
    }
    _socialLinks = [];
    final social = company.socialLinks ?? {};
    social.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        _socialLinks.add(
          _SocialLinkEntry(platform: key.toString(), url: value.toString()),
        );
      }
    });
  }

  Map<String, dynamic> _buildPayload(int eventId) {
    final socialLinks = <String, dynamic>{};
    for (final entry in _socialLinks) {
      final platform = entry.platformController.text.trim().toLowerCase();
      final url = entry.urlController.text.trim();
      if (platform.isNotEmpty && url.isNotEmpty) {
        socialLinks[platform] = url;
      }
    }

    final aboutPlainText = _aboutController.document.toPlainText().trim();

    return {
      'event_id': eventId,
      'name': _nameController.text.trim(),
      'categories': _selectedCategories,
      'website': _websiteController.text.trim(),
      'about': aboutPlainText,
      'email': _emailController.text.trim(),
      'mobile': _mobile.trim(),
      'country': _selectedCountry,
      'city': _selectedCity,
      'brand_icon_url': _brandIconUrl,
      'full_logo_url': _fullLogoUrl,
      'cover_image_url': _coverImageUrl,
      'gallery_urls': _galleryUrls
          .where((url) => url != null && url.isNotEmpty)
          .toList(),
      'social_links': socialLinks,
    };
  }

  Future<void> _save(int eventId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(companyServiceProvider);

      if (_isEditing) {
        await service.updateCompany(widget.companyId!, _buildPayload(eventId));
      } else {
        await service.createCompany(_buildPayload(eventId));
      }

      ref.invalidate(myCompaniesProvider(eventId));

      if (!mounted) return;
      AppSnackBar.showSuccess(context, _isEditing
          ? 'Company updated successfully!'
          : 'Company created successfully!');

      final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
      context.go('/events/$eventIdStr/company-profile');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Failed to save company: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final eventId = int.tryParse(eventIdStr) ?? 0;

    if (_isEditing) {
      final companyAsync = ref.watch(companyDetailProvider(widget.companyId!));
      companyAsync.whenData((company) => _populateFromCompany(company));

      if (companyAsync.isLoading && !_didPopulate) {
        return const Center(child: CircularProgressIndicator());
      }
      if (companyAsync.hasError && !_didPopulate) {
        return Center(child: Text('Error: ${companyAsync.error}'));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            Text(
              'Complete Company Profile',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 32, thickness: 1),

            // 1. Basic Info Card
            _buildSectionCard(
              title: 'Basic Info',
              svgAsset: 'assets/company/basic_info.svg',
              child: _buildBasicInfoContent(eventId),
            ),
            const SizedBox(height: 24),

            // 2. Contact & Address Card
            _buildSectionCard(
              title: 'Contact & Address',
              svgAsset: 'assets/company/contact.svg',
              child: _buildContactAddressContent(),
            ),
            const SizedBox(height: 24),

            // 3. Branding Card
            _buildSectionCard(
              title: 'Branding',
              svgAsset: 'assets/company/branding.svg',
              child: _buildBrandingContent(),
            ),
            const SizedBox(height: 24),

            // 4. Gallery Card
            _buildSectionCard(
              title: 'Gallery',
              svgAsset: 'assets/company/gallery.svg',
              child: _buildGalleryContent(),
            ),
            const SizedBox(height: 24),

            _buildBottomButtons(eventId),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Section Card — individual card with shadow and blue header bar
  // ===========================================================================

  Widget _buildSectionCard({
    required String title,
    required String svgAsset,
    required Widget child,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(60, 68, 148, 0.5),
            blurRadius: 7.6,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE9ECF9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(svgAsset, width: 20, height: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: child,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. Basic Info Content
  // ===========================================================================

  Widget _buildBasicInfoContent(int eventId) {
    final categoriesAsync = ref.watch(companyCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company Name + Category
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 500) {
              return Column(
                children: [
                  _buildLabeledField(
                    label: 'Company Name:',
                    child: TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: _inputDecoration(),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryField(categoriesAsync),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildLabeledField(
                    label: 'Company Name:',
                    child: TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: _inputDecoration(),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildCategoryField(categoriesAsync)),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Website
        _buildLabeledField(
          label: 'Company Website:',
          child: TextFormField(
            controller: _websiteController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDecoration(),
            keyboardType: TextInputType.url,
          ),
        ),
        const SizedBox(height: 20),

        // About Company (Quill editor)
        Text(
          'About Company (Maximum 2000 characters):',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              quill.QuillSimpleToolbar(
                controller: _aboutController,
                config: const quill.QuillSimpleToolbarConfig(
                  showAlignmentButtons: true,
                  showBackgroundColorButton: false,
                  showClearFormat: false,
                  showFontFamily: false,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showInlineCode: false,
                  multiRowsDisplay: true,
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 180,
                child: quill.QuillEditor(
                  controller: _aboutController,
                  scrollController: ScrollController(),
                  focusNode: FocusNode(),
                  config: quill.QuillEditorConfig(
                    padding: const EdgeInsets.all(12),
                    placeholder: 'Title...',
                    customStyles: quill.DefaultStyles(
                      paragraph: quill.DefaultTextBlockStyle(
                        GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                        const quill.HorizontalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        null,
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

  Widget _buildCategoryField(AsyncValue<List<String>> categoriesAsync) {
    return categoriesAsync.when(
      loading: () => _buildLabeledField(
        label: 'Company category:',
        child: Container(
          height: 48,
          decoration: BoxDecoration(
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
      error: (_, __) => _buildLabeledField(
        label: 'Company category:',
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.errorColor),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Failed to load',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.errorColor),
          ),
        ),
      ),
      data: (categories) => MultiSelectField(
        label: 'Company category:',
        options: categories,
        selectedValues: _selectedCategories,
        onChanged: (v) => setState(() => _selectedCategories = v),
        hintText: 'Select category',
      ),
    );
  }

  // ===========================================================================
  // 2. Contact & Address Content
  // ===========================================================================

  Widget _buildContactAddressContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country + City
        CountryCityPicker(
          selectedCountry: _selectedCountry,
          selectedCity: _selectedCity,
          onCountryChanged: (c) => setState(() {
            _selectedCountry = c;
            _selectedCity = null;
          }),
          onCityChanged: (c) => setState(() => _selectedCity = c),
        ),
        const SizedBox(height: 20),

        // Email + Mobile
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 500) {
              return Column(
                children: [
                  _buildLabeledField(
                    label: 'E-mail address:',
                    child: TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: _inputDecoration(),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PhoneInputField(
                    labelText: 'Mobile number',
                    initialPhone: _mobile,
                    onChanged: (e164) => _mobile = e164,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildLabeledField(
                    label: 'E-mail address:',
                    child: TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: _inputDecoration(),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PhoneInputField(
                    labelText: 'Mobile number',
                    initialPhone: _mobile,
                    onChanged: (e164) => _mobile = e164,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Social Medias
        _buildSocialMediasSection(),
      ],
    );
  }

  Widget _buildSocialMediasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Medias:',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _socialLinks.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSocialLinkRow(i),
          ),
        InkWell(
          onTap: () => setState(() => _socialLinks.add(_SocialLinkEntry())),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Add New',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinkRow(int index) {
    final entry = _socialLinks[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue:
                _platformOptions.contains(entry.platformController.text)
                ? entry.platformController.text
                : null,
            decoration: _inputDecoration(hintText: 'Platform'),
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            items: _platformOptions
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) {
              if (v != null) entry.platformController.text = v;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: entry.urlController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDecoration(
              hintText: _platformUrlHints[entry.platformController.text] ??
                  'URL or handle',
            ),
            keyboardType: TextInputType.url,
          ),
        ),
        IconButton(
          onPressed: () => setState(() {
            _socialLinks[index].dispose();
            _socialLinks.removeAt(index);
          }),
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          splashRadius: 20,
        ),
      ],
    );
  }

  static const _platformOptions = [
    'LinkedIn',
    'Instagram',
    'Twitter',
    'Facebook',
    'WhatsApp',
    'WeChat',
    'YouTube',
    'TikTok',
    'Telegram',
  ];

  static const _platformUrlHints = <String, String>{
    'LinkedIn': 'https://linkedin.com/company/name',
    'Instagram': 'https://instagram.com/username',
    'Twitter': 'https://x.com/username',
    'Facebook': 'https://facebook.com/pagename',
    'WhatsApp': 'https://wa.me/phonenumber',
    'WeChat': 'WeChat ID',
    'YouTube': 'https://youtube.com/@channel',
    'TikTok': 'https://tiktok.com/@username',
    'Telegram': 'https://t.me/username',
  };

  // ===========================================================================
  // 3. Branding Content
  // ===========================================================================

  Widget _buildBrandingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Icon
        _buildBrandingUploadItem(
          title: 'Brand Icon',
          description: 'Used in listings and small previews',
          recommendation:
              'Recommended: 512×512px, SVG or PNG, transparent background.',
          currentImageUrl: _brandIconUrl,
          uploadWidth: 108,
          uploadHeight: 108,
          onUpload: () => _onImageUpload('brand_icon'),
          onRemove: _brandIconUrl != null
              ? () => setState(() => _brandIconUrl = null)
              : null,
        ),
        const SizedBox(height: 24),

        // Full Logo
        _buildBrandingUploadItem(
          title: 'Full Logo',
          description: 'Used on your public company profile.',
          recommendation:
              'Recommended: 1200×400px, SVG preferred. Horizontal layout.',
          currentImageUrl: _fullLogoUrl,
          uploadWidth: 225,
          uploadHeight: 108,
          onUpload: () => _onImageUpload('full_logo'),
          onRemove: _fullLogoUrl != null
              ? () => setState(() => _fullLogoUrl = null)
              : null,
        ),
        const SizedBox(height: 24),

        // Cover Image
        _buildBrandingUploadItem(
          title: 'Cover Image',
          description: 'Displayed as a banner on your profile page.',
          recommendation:
              'Recommended: 1200×400px, SVG preferred. Horizontal layout.',
          currentImageUrl: _coverImageUrl,
          uploadWidth: 225,
          uploadHeight: 108,
          onUpload: () => _onImageUpload('cover'),
          onRemove: _coverImageUrl != null
              ? () => setState(() => _coverImageUrl = null)
              : null,
        ),
      ],
    );
  }

  Widget _buildBrandingUploadItem({
    required String title,
    required String description,
    required String recommendation,
    required String? currentImageUrl,
    required double uploadWidth,
    required double uploadHeight,
    required VoidCallback onUpload,
    VoidCallback? onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (bold) + Description (light)
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$title  ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextSpan(
                text: '($description)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          recommendation,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Upload box with button
        if (currentImageUrl != null && currentImageUrl.isNotEmpty)
          _buildBrandingPreview(
            imageUrl: currentImageUrl,
            width: uploadWidth,
            height: uploadHeight,
            onRemove: onRemove,
            onUpload: onUpload,
          )
        else
          _buildDashedUploadBox(
            width: uploadWidth,
            height: uploadHeight,
            onUpload: onUpload,
          ),
      ],
    );
  }

  Widget _buildDashedUploadBox({
    required double width,
    required double height,
    required VoidCallback onUpload,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onUpload,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: const Color(0xFF3C4494),
              strokeWidth: 1.5,
              dashWidth: 6,
              dashSpace: 4,
              borderRadius: 8,
            ),
            child: SizedBox(
              width: width,
              height: height,
              child: Center(
                child: Icon(Icons.add, size: 32, color: Colors.grey.shade400),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: width,
          child: ElevatedButton(
            onPressed: onUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Upload',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingPreview({
    required String imageUrl,
    required double width,
    required double height,
    VoidCallback? onRemove,
    required VoidCallback onUpload,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: width < 200 ? 200 : width,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Replace',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRemove,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. Gallery Content
  // ===========================================================================

  Widget _buildGalleryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload up to 4 images that accurately represent your company, its facilities, staff, or completed projects.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(4, (index) {
            final url = _galleryUrls[index];
            if (url != null && url.isNotEmpty) {
              return _buildGalleryPreview(index, url);
            }
            return _buildGalleryUploadBox(index);
          }),
        ),
      ],
    );
  }

  Widget _buildGalleryUploadBox(int index) {
    return GestureDetector(
      onTap: () => _onImageUpload('gallery_$index'),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: Colors.grey.shade400,
          strokeWidth: 1.5,
          dashWidth: 6,
          dashSpace: 4,
          borderRadius: 8,
        ),
        child: SizedBox(
          width: 170,
          height: 170,
          child: Center(
            child: Icon(Icons.add, size: 48, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryPreview(int index, String url) {
    return Stack(
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => setState(() => _galleryUrls[index] = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Bottom Buttons
  // ===========================================================================

  Widget _buildBottomButtons(int eventId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSaving
              ? null
              : () {
                  final eventIdStr =
                      GoRouterState.of(context).pathParameters['id'] ?? '';
                  context.go('/events/$eventIdStr/company-profile');
                },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _save(eventId),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            disabledBackgroundColor: AppTheme.primaryColor.withValues(
              alpha: 0.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Shared helpers
  // ===========================================================================

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
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
      AppSnackBar.showError(context, 'Upload failed: $e');
    }
  }
}

// =============================================================================
// Dashed border painter for upload boxes
// =============================================================================

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.borderRadius = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace;
}

// =============================================================================
// Social link entry model
// =============================================================================

class _SocialLinkEntry {
  final TextEditingController platformController;
  final TextEditingController urlController;

  _SocialLinkEntry({String? platform, String? url})
    : platformController = TextEditingController(text: platform ?? ''),
      urlController = TextEditingController(text: url ?? '');

  void dispose() {
    platformController.dispose();
    urlController.dispose();
  }
}
