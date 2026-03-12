import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/providers/upload_provider.dart';

import '../../../shared/widgets/country_city_picker.dart';
import '../../../core/providers/reference_data_provider.dart';
import '../../company/models/user_limits.dart';
import '../../company/providers/company_providers.dart';
import '../models/team_member.dart';
import '../providers/team_providers.dart';
import 'widgets/team_role_dropdown.dart';

/// Social media platforms with their URL hints.
const _socialPlatforms = <String, String>{
  'LinkedIn': 'https://linkedin.com/in/username',
  'Twitter / X': 'https://x.com/username',
  'Facebook': 'https://facebook.com/username',
  'Instagram': 'https://instagram.com/username',
  'Telegram': 'https://t.me/username',
  'YouTube': 'https://youtube.com/@channel',
  'TikTok': 'https://tiktok.com/@username',
  'Website': 'https://example.com',
};

// ---------------------------------------------------------------------------
// Figma-accurate constants
// ---------------------------------------------------------------------------

const _kInputBorderRadius = 5.0;
const _kInputBorderColor = Color(0xFFB7B7B7);
const _kCardShadow = BoxShadow(
  color: Color.fromRGBO(0, 0, 0, 0.25),
  blurRadius: 10,
);
const _kLabelFontSize = 16.0;
const _kPhotoWidth = 145.0;
const _kPhotoHeight = 170.0;

/// Add Team Member page with a 2-step wizard.
///
/// **Step 1 — Personal Info:** profile photo, name, surname, email, mobile,
/// country/city, position, company, and social links ("Follow Me").
///
/// **Step 2 — Role in Event:** team members table with role assignment.
class AddTeamMemberPage extends ConsumerStatefulWidget {
  final String? memberId;
  const AddTeamMemberPage({super.key, this.memberId});

  @override
  ConsumerState<AddTeamMemberPage> createState() => _AddTeamMemberPageState();
}

class _AddTeamMemberPageState extends ConsumerState<AddTeamMemberPage> {
  bool _isSubmitting = false;
  bool _didPopulate = false;

  /// Index into member tabs: 0..N-1 = existing members, N = "new member"
  int _selectedMemberTabIndex = -1;

  final _step1Key = GlobalKey<FormState>();

  // --- Step 1: Personal Info ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedPosition;
  String? _selectedCompanyId;
  String? _profilePhotoUrl;

  // Social links
  final List<_SocialLinkEntry> _socialLinks = [];

  // --- Step 2: Role & Attendance ---
  String _selectedRole = 'USER';
  bool _willAttend = true;
  bool _allowMeetingRequests = false;
  bool _showContactDetails = false;

  /// ID of the member being edited (from tab selection or route param).
  String? _editingMemberId;

  bool get _isEditing => _editingMemberId != null;

  bool get _hasUnsavedChanges =>
      _firstNameController.text.trim().isNotEmpty ||
      _lastNameController.text.trim().isNotEmpty ||
      _emailController.text.trim().isNotEmpty ||
      _mobileController.text.trim().isNotEmpty ||
      _profilePhotoUrl != null ||
      _socialLinks.isNotEmpty;

  String get _memberTabLabel {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isNotEmpty || last.isNotEmpty) {
      return '${first.isNotEmpty ? first : '...'} ${last.isNotEmpty ? last : '...'}'
          .trim();
    }
    return 'New Member';
  }

  @override
  void initState() {
    super.initState();
    _editingMemberId = widget.memberId;
    _firstNameController.addListener(_onNameChanged);
    _lastNameController.addListener(_onNameChanged);
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _firstNameController.removeListener(_onNameChanged);
    _lastNameController.removeListener(_onNameChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    for (final link in _socialLinks) {
      link.urlController.dispose();
    }
    super.dispose();
  }

  void _populateFromMember(TeamMember member) {
    if (_didPopulate) return;
    _didPopulate = true;
    _firstNameController.text = member.firstName;
    _lastNameController.text = member.lastName;
    _emailController.text = member.email;
    _mobileController.text = member.mobile ?? '';
    _selectedCountry = member.country;
    _selectedCity = member.city;
    _selectedPosition = member.position;
    _selectedCompanyId = member.companyId;
    _selectedRole = member.role == TeamMemberRole.administrator
        ? 'ADMINISTRATOR'
        : 'USER';
    _willAttend = member.willAttend;
    _allowMeetingRequests = member.allowMeetingRequests;
    _showContactDetails = member.showContactDetails;
    _profilePhotoUrl = member.profilePhotoUrl;

    if (member.socialLinks != null && member.socialLinks!.isNotEmpty) {
      for (final entry in member.socialLinks!.entries) {
        final controller =
            TextEditingController(text: entry.value?.toString() ?? '');
        _socialLinks.add(_SocialLinkEntry(
          platform: entry.key,
          urlController: controller,
        ));
      }
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _mobileController.clear();
    _selectedCountry = null;
    _selectedCity = null;
    _selectedPosition = null;
    _profilePhotoUrl = null;
    _selectedRole = 'USER';
    _willAttend = true;
    _allowMeetingRequests = false;
    _showContactDetails = false;
    for (final link in _socialLinks) {
      link.urlController.dispose();
    }
    _socialLinks.clear();
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final eventId = int.tryParse(eventIdStr) ?? 0;

    // Dynamic limits
    final limitsAsync = ref.watch(userLimitsProvider(eventId));
    final limits = limitsAsync.when(
      data: (l) => l,
      loading: () => UserLimits.defaults,
      error: (_, __) => UserLimits.defaults,
    );
    final maxTeamMembers = limits.maxTeamMembersPerCompany;

    // Pre-populate form when editing via route param
    if (_editingMemberId != null && !_didPopulate) {
      final memberAsync = ref.watch(teamMemberProvider(_editingMemberId!));
      memberAsync.whenData((member) {
        _populateFromMember(member);
        _selectedCompanyId ??= member.companyId;
      });

      if (memberAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (memberAsync.hasError) {
        return Center(child: Text('Error: ${memberAsync.error}'));
      }
    }

    // Load existing team members for tabs
    final List<TeamMember> existingMembers;
    if (_selectedCompanyId != null && _selectedCompanyId!.isNotEmpty) {
      final membersAsync = ref.watch(teamMembersProvider(_selectedCompanyId!));
      existingMembers = membersAsync.when(
        data: (data) => data,
        loading: () => <TeamMember>[],
        error: (_, __) => <TeamMember>[],
      );
    } else {
      existingMembers = [];
    }

    // Auto-set tab index
    if (_selectedMemberTabIndex == -1) {
      if (_editingMemberId != null) {
        final idx =
            existingMembers.indexWhere((m) => m.id == _editingMemberId);
        _selectedMemberTabIndex = idx >= 0 ? idx : existingMembers.length;
      } else {
        _selectedMemberTabIndex = existingMembers.length;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Builder(builder: (context) {
            final isMobile = MediaQuery.of(context).size.width < 600;
            return Text(
              _isEditing ? 'Edit Team Member' : 'Add Team Member',
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            );
          }),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 20),

          // Hint banner
          _buildHintBanner(),
          const SizedBox(height: 16),

          // Member tabs
          _buildMemberTabs(existingMembers, maxTeamMembers),
          const SizedBox(height: 0),

          // Form card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: const [_kCardShadow],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildStep1(eventId),
            ),
          ),
          const SizedBox(height: 24),

          // Navigation buttons
          _buildSaveButtons(eventIdStr, eventId),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // Hint Banner
  // ===========================================================================

  Widget _buildHintBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: Color(0xFFE57373)),
                const SizedBox(width: 6),
                Text(
                  'Hint',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE57373),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: const Color(0xFFE57373).withValues(alpha: 0.4),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                'The provided information will be used for your ID badge and to enable communication with other participants. It will be displayed in the official attendee list.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFE57373),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Member Tabs
  // ===========================================================================

  Widget _buildMemberTabs(List<TeamMember> existingMembers, int maxTeamMembers) {
    final canAddNew = existingMembers.length < maxTeamMembers;
    final isNewTab = _selectedMemberTabIndex >= existingMembers.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < existingMembers.length; i++)
            _buildMemberPillTab(
              label: existingMembers[i].fullName,
              isSelected: _selectedMemberTabIndex == i,
              onTap: () => _onMemberTabTap(i, existingMembers),
            ),
          if (isNewTab)
            _buildMemberPillTab(
              label: _memberTabLabel,
              isSelected: true,
              onTap: null,
            ),
          if (canAddNew && !isNewTab)
            _buildMemberPillTab(
              label: '+ Add (${existingMembers.length}/$maxTeamMembers)',
              isSelected: false,
              onTap: () =>
                  _onMemberTabTap(existingMembers.length, existingMembers),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberPillTab({
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFFE8E8F0),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _onMemberTabTap(int index, List<TeamMember> existingMembers) {
    if (_selectedMemberTabIndex == index) return;

    setState(() {
      _selectedMemberTabIndex = index;
      _didPopulate = false;

      if (index < existingMembers.length) {
        final member = existingMembers[index];
        _editingMemberId = member.id;
        _clearForm();
        _populateFromMember(member);
      } else {
        _editingMemberId = null;
        _clearForm();
      }
    });
  }

  // ===========================================================================
  // Step 1 — Personal Info
  // ===========================================================================

  Widget _buildStep1(int eventId) {
    final positionsAsync = ref.watch(positionsProvider);
    final companiesAsync = ref.watch(myCompaniesProvider(eventId));

    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Basic Info'),
          const SizedBox(height: 24),

          // Name / Surname
          _ResponsiveRow(
            left: _buildLabeledField(
              label: 'Name:',
              required: true,
              child: TextFormField(
                controller: _firstNameController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: _inputDecoration(hintText: 'Enter name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            right: _buildLabeledField(
              label: 'Surname:',
              required: true,
              child: TextFormField(
                controller: _lastNameController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: _inputDecoration(hintText: 'Enter surname'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Email / Mobile
          _ResponsiveRow(
            left: _buildLabeledField(
              label: 'E-mail address:',
              required: true,
              child: TextFormField(
                controller: _emailController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration:
                    _inputDecoration(hintText: 'member@example.com'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
            ),
            right: _buildLabeledField(
              label: 'Mobile number:',
              child: TextFormField(
                controller: _mobileController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: _inputDecoration(hintText: '+1 234 567 8900'),
                keyboardType: TextInputType.phone,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Country / City
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
          const SizedBox(height: 20),

          // Company / Position
          _ResponsiveRow(
            left: companiesAsync.when(
              loading: () => _buildLabeledField(
                label: 'Choose Company:',
                required: true,
                child: _buildLoadingContainer(),
              ),
              error: (_, __) => _buildLabeledField(
                label: 'Choose Company:',
                required: true,
                child: _buildErrorContainer('Failed to load'),
              ),
              data: (companies) => _buildCompanyDropdown(companies),
            ),
            right: positionsAsync.when(
              loading: () => _buildLabeledField(
                label: 'Position:',
                child: _buildLoadingContainer(),
              ),
              error: (_, __) => _buildLabeledField(
                label: 'Position:',
                child: _buildErrorContainer('Failed to load'),
              ),
              data: (positions) => _buildPositionDropdown(positions),
            ),
          ),
          const SizedBox(height: 20),

          // Role & Attendance
          _buildSectionHeader('Role & Attendance'),
          const SizedBox(height: 16),

          // Role selection
          _ResponsiveRow(
            left: _buildLabeledField(
              label: 'Role:',
              required: true,
              child: TeamRoleDropdown(
                currentRole: _selectedRole,
                onRoleChanged: (role) =>
                    setState(() => _selectedRole = role),
              ),
            ),
            right: _buildLabeledField(
              label: 'Will Attend:',
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_kInputBorderRadius),
                  border: Border.all(color: _kInputBorderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _willAttend ? 'Yes — will attend' : 'No — remote only',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Switch(
                      value: _willAttend,
                      activeTrackColor: AppTheme.primaryColor,
                      onChanged: (v) => setState(() => _willAttend = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Follow Me — Social Links
          _buildFollowMeSection(),
          const SizedBox(height: 28),

          // Profile photo
          _buildSectionHeader('Profile Photo'),
          const SizedBox(height: 16),
          _buildProfilePhotoSection(),
          const SizedBox(height: 28),

          // Meeting Requests
          _buildMeetingRequestsSection(),
          const SizedBox(height: 24),

          // Contact Visibility
          _buildContactVisibilitySection(),
        ],
      ),
    );
  }

  // ===========================================================================
  // Profile Photo
  // ===========================================================================

  Widget _buildProfilePhotoSection() {
    final hasPhoto = _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: _kPhotoWidth,
            height: _kPhotoHeight,
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: hasPhoto
                ? Image.network(
                    _profilePhotoUrl!,
                    width: _kPhotoWidth,
                    height: _kPhotoHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: 56,
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 56,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _onPhotoUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kInputBorderRadius),
                ),
                textStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: const Text('Upload New Profile Picture'),
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => setState(() => _profilePhotoUrl = null),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade400),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kInputBorderRadius),
                  ),
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                child: const Text('Remove Profile Picture'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Company Dropdown
  // ===========================================================================

  Widget _buildCompanyDropdown(List<dynamic> companies) {
    if (companies.isEmpty) {
      return _buildLabeledField(
        label: 'Choose Company:',
        required: true,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(_kInputBorderRadius),
            border: Border.all(color: _kInputBorderColor),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            'No companies available',
            style:
                GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    // Auto-select first company if none selected or current is stale
    if (_selectedCompanyId == null ||
        !companies.any((c) => c.id == _selectedCompanyId)) {
      _selectedCompanyId = companies.first.id;
    }

    if (companies.length == 1) {
      return _buildLabeledField(
        label: 'Choose Company:',
        required: true,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kInputBorderRadius),
            border: Border.all(color: _kInputBorderColor),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            companies.first.name,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          ),
        ),
      );
    }

    final effectiveValue =
        (_selectedCompanyId != null &&
                companies.any((c) => c.id == _selectedCompanyId))
            ? _selectedCompanyId
            : null;

    return _buildLabeledField(
      label: 'Choose Company:',
      required: true,
      child: DropdownButtonFormField<String>(
        initialValue: effectiveValue,
        onChanged: (value) => setState(() => _selectedCompanyId = value),
        decoration: _inputDecoration(hintText: 'Select company'),
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            size: 20, color: Colors.grey.shade600),
        isExpanded: true,
        style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
        items: companies
            .map((c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
      ),
    );
  }

  // ===========================================================================
  // Position Dropdown (Autocomplete)
  // ===========================================================================

  Widget _buildPositionDropdown(List<String> positions) {
    final effectiveValue =
        (_selectedPosition != null && positions.contains(_selectedPosition))
            ? _selectedPosition
            : null;

    return _buildLabeledField(
      label: 'Position:',
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: effectiveValue ?? ''),
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) return positions;
          final query = textEditingValue.text.toLowerCase();
          return positions
              .where((p) => p.toLowerCase().contains(query))
              .toList();
        },
        onSelected: (selection) {
          setState(() => _selectedPosition = selection);
        },
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDecoration(
              hintText: 'Search or select position',
            ).copyWith(
              suffixIcon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade600),
            ),
            onFieldSubmitted: (_) => onFieldSubmitted(),
            onChanged: (value) {
              _selectedPosition =
                  value.trim().isNotEmpty ? value.trim() : null;
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 240, maxWidth: 500),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
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
    );
  }

  // ===========================================================================
  // Follow Me — Social Links
  // ===========================================================================

  Widget _buildFollowMeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow Me:',
          style: GoogleFonts.montserrat(
            fontSize: _kLabelFontSize,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        for (int i = 0; i < _socialLinks.length; i++) ...[
          const SizedBox(height: 8),
          _buildSocialLinkRow(i),
        ],

        // "Add New" button — after existing entries
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addSocialLink,
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'Add New',
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: BorderSide(color: Colors.grey.shade400),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kInputBorderRadius),
            ),
          ),
        ),
      ],
    );
  }

  void _addSocialLink() {
    setState(() {
      _socialLinks.add(_SocialLinkEntry(
        platform: null,
        urlController: TextEditingController(),
      ));
    });
  }

  Widget _buildSocialLinkRow(int index) {
    final entry = _socialLinks[index];
    final usedPlatforms = _socialLinks
        .asMap()
        .entries
        .where((e) => e.key != index && e.value.platform != null)
        .map((e) => e.value.platform!)
        .toSet();
    final available =
        _socialPlatforms.keys.where((p) => !usedPlatforms.contains(p)).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: DropdownButtonFormField<String>(
              initialValue: entry.platform,
              onChanged: (value) => setState(() => entry.platform = value),
              decoration: _inputDecoration(hintText: 'Platform').copyWith(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: Colors.grey.shade600),
              isExpanded: true,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              items: available
                  .map((platform) => DropdownMenuItem<String>(
                        value: platform,
                        child:
                            Text(platform, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: entry.urlController,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: _inputDecoration(
                hintText: entry.platform != null
                    ? _socialPlatforms[entry.platform] ?? 'Enter URL'
                    : 'Select a platform first',
              ).copyWith(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              enabled: entry.platform != null,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _socialLinks[index].urlController.dispose();
                  _socialLinks.removeAt(index);
                });
              },
              icon: const Icon(Icons.close, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                backgroundColor: AppTheme.errorColor.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size(36, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // Meeting Requests
  // ===========================================================================

  Widget _buildMeetingRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Requests',
          style: GoogleFonts.montserrat(
            fontSize: _kLabelFontSize,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            decoration: TextDecoration.underline,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Allow other participants to send meeting requests to this member.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _allowMeetingRequests,
                onChanged: (v) =>
                    setState(() => _allowMeetingRequests = v ?? false),
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Allow meeting requests',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Contact Visibility
  // ===========================================================================

  Widget _buildContactVisibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Visibility',
          style: GoogleFonts.montserrat(
            fontSize: _kLabelFontSize,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Allow other participants to view this member\'s contact information.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _showContactDetails,
                onChanged: (v) =>
                    setState(() => _showContactDetails = v ?? false),
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Show contact details to other participants',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Navigation Buttons — aligned right per Figma
  // ===========================================================================

  Widget _buildSaveButtons(String eventIdStr, int eventId) {
    final outlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.grey.shade700,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kInputBorderRadius),
      ),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    );

    final primaryStyle = ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor,
      disabledBackgroundColor:
          AppTheme.primaryColor.withValues(alpha: 0.5),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kInputBorderRadius),
      ),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => _confirmDiscard(eventIdStr),
          style: outlinedStyle,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _saveAndReturn(eventIdStr, eventId),
          style: primaryStyle,
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEditing ? 'Save Changes' : 'Add Member'),
        ),
      ],
    );
  }

  Future<void> _confirmDiscard(String eventIdStr) async {
    if (!_hasUnsavedChanges) {
      context.go('/events/$eventIdStr/team');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Discard changes?',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to leave?',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Discard',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.go('/events/$eventIdStr/team');
    }
  }

  // ===========================================================================
  // Save / Upload Actions
  // ===========================================================================

  Future<void> _saveAndReturn(String eventIdStr, int eventId) async {
    if (!(_step1Key.currentState?.validate() ?? false)) return;

    if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
      AppSnackBar.showError(context, 'Please select a company');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(teamServiceProvider);

      final data = <String, dynamic>{
        'company_id': _selectedCompanyId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'will_attend': _willAttend,
        'allow_meeting_requests': _allowMeetingRequests,
        'show_contact_details': _showContactDetails,
      };

      if (_mobileController.text.trim().isNotEmpty) {
        data['mobile'] = _mobileController.text.trim();
      }
      if (_selectedCountry != null) data['country'] = _selectedCountry;
      if (_selectedCity != null) data['city'] = _selectedCity;
      if (_selectedPosition != null && _selectedPosition!.isNotEmpty) {
        data['position'] = _selectedPosition;
      }
      if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
        data['profile_photo_url'] = _profilePhotoUrl;
      }

      final socialLinksMap = <String, String>{};
      for (final link in _socialLinks) {
        if (link.platform != null &&
            link.urlController.text.trim().isNotEmpty) {
          socialLinksMap[link.platform!] = link.urlController.text.trim();
        }
      }
      if (socialLinksMap.isNotEmpty) {
        data['social_links'] = socialLinksMap;
      }

      if (_editingMemberId != null) {
        await service.updateTeamMember(_editingMemberId!, data);
        ref.invalidate(teamMemberProvider(_editingMemberId!));
      } else {
        await service.createTeamMember(data);
      }

      ref.invalidate(teamMembersProvider(_selectedCompanyId!));
      ref.invalidate(allTeamMembersProvider(eventId));

      if (!mounted) return;

      AppSnackBar.showSuccess(context, _editingMemberId != null
          ? 'Team member updated!'
          : 'Team member added! Invitation email sent.');

      context.go('/events/$eventIdStr/team');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.showError(context, 'Failed to ${_editingMemberId != null ? 'update' : 'add'} team member: $e');
    }
  }

  Future<void> _onPhotoUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      final uploadService = ref.read(uploadServiceProvider);
      final url = await uploadService.uploadFile(
        fileData: bytes,
        folder: 'team-photos',
        filename: 'team_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (!mounted) return;
      setState(() => _profilePhotoUrl = url);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Upload failed: $e');
    }
  }

  // ===========================================================================
  // Shared Helpers
  // ===========================================================================

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.shade300, height: 1),
      ],
    );
  }

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
                fontSize: _kLabelFontSize,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: _kLabelFontSize,
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

  Widget _buildLoadingContainer() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kInputBorderRadius),
        border: Border.all(color: _kInputBorderColor),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kInputBorderRadius),
        border: Border.all(color: AppTheme.errorColor),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.errorColor),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kInputBorderRadius),
        borderSide: const BorderSide(color: _kInputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kInputBorderRadius),
        borderSide: const BorderSide(color: _kInputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kInputBorderRadius),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kInputBorderRadius),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kInputBorderRadius),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
      ),
    );
  }

}

// =============================================================================
// _ResponsiveRow — eliminates repetitive LayoutBuilder boilerplate
// =============================================================================

class _ResponsiveRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _ResponsiveRow({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            children: [
              left,
              const SizedBox(height: 20),
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
}


/// Internal helper class for social link entries.
class _SocialLinkEntry {
  String? platform;
  final TextEditingController urlController;

  _SocialLinkEntry({
    required this.platform,
    required this.urlController,
  });
}
