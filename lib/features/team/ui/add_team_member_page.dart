import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/upload_provider.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';
import '../../../shared/widgets/step_wizard.dart';
import '../../../shared/widgets/country_city_picker.dart';
import '../../../core/providers/reference_data_provider.dart';
import '../../company/providers/company_providers.dart';
import '../models/team_member.dart';
import '../providers/team_providers.dart';

/// Add Team Member page with a 2-step wizard.
///
/// **Step 1 — Personal Info:** first name, last name, email, mobile,
/// country/city, and position.
///
/// **Step 2 — Role in Event:** company selector (if multiple), role
/// selector (USER / ADMINISTRATOR), and profile photo upload area.
class AddTeamMemberPage extends ConsumerStatefulWidget {
  final String? memberId;
  const AddTeamMemberPage({super.key, this.memberId});

  @override
  ConsumerState<AddTeamMemberPage> createState() => _AddTeamMemberPageState();
}

class _AddTeamMemberPageState extends ConsumerState<AddTeamMemberPage> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _didPopulate = false;

  // Step 1 form key
  final _step1Key = GlobalKey<FormState>();
  // Step 2 form key
  final _step2Key = GlobalKey<FormState>();

  // --- Step 1: Personal Info ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedPosition;

  // --- Step 2: Role in Event ---
  String? _selectedCompanyId;
  String _selectedRole = 'USER';
  String? _profilePhotoUrl;

  bool get _isEditing => widget.memberId != null;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
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
    _profilePhotoUrl = member.profilePhotoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final eventId = int.tryParse(eventIdStr) ?? 0;

    // Pre-populate form when editing an existing member
    if (_isEditing) {
      final memberAsync = ref.watch(teamMemberProvider(widget.memberId!));
      memberAsync.whenData((member) => _populateFromMember(member));

      if (memberAsync.isLoading && !_didPopulate) {
        return EventSidebarLayout(
          title: 'Edit Team Member',
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      if (memberAsync.hasError && !_didPopulate) {
        return EventSidebarLayout(
          title: 'Edit Team Member',
          child: Center(child: Text('Error: ${memberAsync.error}')),
        );
      }
    }

    return EventSidebarLayout(
      title: _isEditing ? 'Edit Team Member' : 'Add Team Member',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header
                _buildPageHeader(),
                const SizedBox(height: 28),

                // Step wizard
                StepWizard(
                  currentStep: _currentStep,
                  stepLabels: const ['Personal Info', 'Role in Event'],
                ),
                const SizedBox(height: 28),

                // Step content card
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
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _currentStep == 0
                          ? _buildStep1()
                          : _buildStep2(eventId),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Navigation buttons
                _buildNavigationButtons(eventIdStr, eventId),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page Header
  // ---------------------------------------------------------------------------

  Widget _buildPageHeader() {
    return Row(
      children: [
        // Back arrow
        IconButton(
          onPressed: () {
            final eventIdStr =
                GoRouterState.of(context).pathParameters['id'] ?? '';
            context.go('/events/$eventIdStr/team');
          },
          icon: const Icon(Icons.arrow_back, size: 22),
          tooltip: 'Back to team members',
          style: IconButton.styleFrom(
            foregroundColor: Colors.black87,
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _isEditing ? Icons.edit : Icons.person_add,
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
                _isEditing ? 'Edit Team Member' : 'Add Team Member',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Step ${_currentStep + 1} of 2',
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
  // Step 1 — Personal Info
  // ---------------------------------------------------------------------------

  Widget _buildStep1() {
    final positionsAsync = ref.watch(positionsProvider);

    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information', Icons.person_outline),
          const SizedBox(height: 24),

          // First Name & Last Name (side by side on wide screens)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 480) {
                return Column(
                  children: [
                    _buildLabeledField(
                      label: 'First Name',
                      required: true,
                      child: TextFormField(
                        controller: _firstNameController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration:
                            _inputDecoration(hintText: 'Enter first name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabeledField(
                      label: 'Last Name',
                      required: true,
                      child: TextFormField(
                        controller: _lastNameController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration:
                            _inputDecoration(hintText: 'Enter last name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
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
                      label: 'First Name',
                      required: true,
                      child: TextFormField(
                        controller: _firstNameController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration:
                            _inputDecoration(hintText: 'Enter first name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLabeledField(
                      label: 'Last Name',
                      required: true,
                      child: TextFormField(
                        controller: _lastNameController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration:
                            _inputDecoration(hintText: 'Enter last name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Email (required)
          _buildLabeledField(
            label: 'Email',
            required: true,
            child: TextFormField(
              controller: _emailController,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: _inputDecoration(hintText: 'member@example.com'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),

          // Mobile
          _buildLabeledField(
            label: 'Mobile',
            child: TextFormField(
              controller: _mobileController,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: _inputDecoration(hintText: '+1 234 567 8900'),
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 20),

          // Country & City
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

          // Position (searchable dropdown)
          positionsAsync.when(
            loading: () => _buildLabeledField(
              label: 'Position',
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
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
            ),
            error: (err, _) => _buildLabeledField(
              label: 'Position',
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Failed to load positions',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ),
            data: (positions) => _buildPositionDropdown(positions),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionDropdown(List<String> positions) {
    // Ensure value is valid
    final effectiveValue =
        (_selectedPosition != null && positions.contains(_selectedPosition))
            ? _selectedPosition
            : null;

    return _buildLabeledField(
      label: 'Position',
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: effectiveValue ?? ''),
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return positions;
          }
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
              suffixIcon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade600,
              ),
            ),
            onFieldSubmitted: (_) => onFieldSubmitted(),
            onChanged: (value) {
              // Allow free-text position
              _selectedPosition = value.trim().isNotEmpty ? value.trim() : null;
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
                constraints: const BoxConstraints(maxHeight: 240, maxWidth: 500),
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
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          option,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
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

  // ---------------------------------------------------------------------------
  // Step 2 — Role in Event
  // ---------------------------------------------------------------------------

  Widget _buildStep2(int eventId) {
    final companiesAsync = ref.watch(myCompaniesProvider(eventId));

    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Role & Assignment', Icons.assignment_ind),
          const SizedBox(height: 24),

          // Company selector
          companiesAsync.when(
            loading: () => _buildLabeledField(
              label: 'Company',
              required: true,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
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
            ),
            error: (err, _) => _buildLabeledField(
              label: 'Company',
              required: true,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Failed to load companies',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ),
            data: (companies) {
              if (companies.isEmpty) {
                return _buildLabeledField(
                  label: 'Company',
                  required: true,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No companies available',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                );
              }

              // Auto-select first company
              if (_selectedCompanyId == null ||
                  !companies.any((c) => c.id == _selectedCompanyId)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(
                        () => _selectedCompanyId = companies.first.id);
                  }
                });
                _selectedCompanyId ??= companies.first.id;
              }

              // If only one company, show it as a read-only field
              if (companies.length == 1) {
                return _buildLabeledField(
                  label: 'Company',
                  required: true,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.business,
                            size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            companies.first.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return _buildLabeledField(
                label: 'Company',
                required: true,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCompanyId,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCompanyId = value);
                    }
                  },
                  decoration: _inputDecoration(hintText: 'Select company'),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                  isExpanded: true,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                  items: companies.map((company) {
                    return DropdownMenuItem<String>(
                      value: company.id,
                      child: Text(
                        company.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a company';
                    }
                    return null;
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Role selector
          _buildLabeledField(
            label: 'Role',
            required: true,
            child: Column(
              children: [
                _buildRoleOption(
                  value: 'USER',
                  title: 'User',
                  description:
                      'Can view company profile, event details, and participate '
                      'in meetings and activities.',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 10),
                _buildRoleOption(
                  value: 'ADMINISTRATOR',
                  title: 'Administrator',
                  description:
                      'Full access to manage company profile, team members, '
                      'bookings, and all event features.',
                  icon: Icons.admin_panel_settings_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Profile photo upload
          _buildLabeledField(
            label: 'Profile Photo',
            child: _buildPhotoUploadArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == value;

    return Material(
      color: isSelected
          ? AppTheme.primaryColor.withValues(alpha: 0.06)
          : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _selectedRole = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadArea() {
    if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
      return Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: NetworkImage(_profilePhotoUrl!),
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _onPhotoUpload,
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Change'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _profilePhotoUrl = null),
                child: Text(
                  'Remove photo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      onTap: _onPhotoUpload,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Upload profile photo',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG, PNG up to 5MB',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation Buttons
  // ---------------------------------------------------------------------------

  Widget _buildNavigationButtons(String eventIdStr, int eventId) {
    return Row(
      children: [
        // Back / Cancel
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _currentStep = 0);
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.go('/events/$eventIdStr/team'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
        const SizedBox(width: 16),

        // Next / Submit
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_currentStep == 0) {
                      _goToStep2();
                    } else {
                      _submit(eventIdStr, eventId);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor:
                  AppTheme.primaryColor.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 0
                            ? 'Next'
                            : _isEditing
                                ? 'Save Changes'
                                : 'Add Team Member',
                      ),
                      if (_currentStep == 0) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _goToStep2() {
    if (_step1Key.currentState?.validate() ?? false) {
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _submit(String eventIdStr, int eventId) async {
    if (!(_step2Key.currentState?.validate() ?? true)) return;

    if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a company',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
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
      };

      if (_mobileController.text.trim().isNotEmpty) {
        data['mobile'] = _mobileController.text.trim();
      }
      if (_selectedCountry != null) {
        data['country'] = _selectedCountry;
      }
      if (_selectedCity != null) {
        data['city'] = _selectedCity;
      }
      if (_selectedPosition != null && _selectedPosition!.isNotEmpty) {
        data['position'] = _selectedPosition;
      }
      if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
        data['profile_photo_url'] = _profilePhotoUrl;
      }

      if (_isEditing) {
        await service.updateTeamMember(widget.memberId!, data);
      } else {
        await service.createTeamMember(data);
      }

      // Invalidate the team members list for this company
      ref.invalidate(teamMembersProvider(_selectedCompanyId!));
      if (_isEditing) {
        ref.invalidate(teamMemberProvider(widget.memberId!));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Team member updated successfully!'
                : 'Team member added successfully!',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );

      context.go('/events/$eventIdStr/team');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${_isEditing ? 'update' : 'add'} team member: $e',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      setState(() {
        _profilePhotoUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Shared Helpers
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
}
