import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/phone_input_field.dart';
import '../../../shared/widgets/app_checkbox.dart';
import '../../../core/providers/reference_data_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/visa_providers.dart';

const List<String> _passportTypes = [
  'P - Milli Pasport (National)',
  'Diplomatic',
  'Service (Official)',
  'Special',
  'Emergency (Temporary)',
];

/// Visa Application Form Page matching Figma design
class VisaApplicationFormPage extends ConsumerStatefulWidget {
  final int eventId;
  final String? participantId;
  final String? visaId;

  const VisaApplicationFormPage({
    super.key,
    required this.eventId,
    this.participantId,
    this.visaId,
  });

  @override
  ConsumerState<VisaApplicationFormPage> createState() =>
      _VisaApplicationFormPageState();
}

class _VisaApplicationFormPageState
    extends ConsumerState<VisaApplicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Loading state
  bool _isLoading = true;
  String? _errorMessage;

  // Multi-visa tab management
  List<Map<String, dynamic>> _allVisas = [];
  int _selectedVisaIndex = 0;
  String? _visaId;
  String _currentVisaStatus = 'FILL_OUT';
  bool _isSwitchingTab = false;
  bool _isCreatingVisa = false;
  bool _isLoadingCities = false;

  // City data loaded from csc_picker_plus asset
  static Map<String, List<String>>? _cityCache;
  List<String> _availableCities = [];

  // Personal Information Controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _surnameAtBirthController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _countryOfBirthController = TextEditingController();
  final _citizenshipController = TextEditingController();
  final _emailController = TextEditingController();
  String _phoneNumberE164 = '';
  String? _gender;

  // Passport Controllers
  String? _typeOfPassport;
  final _passportNumberController = TextEditingController();
  final _passportIssuingCountryController = TextEditingController();

  // Professional/Academic Controllers
  final _educationController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _placeOfStudyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _employerNameController = TextEditingController();

  // Residential Controllers
  final _homeAddressController = TextEditingController();
  final _plannedResidentialAddressController = TextEditingController();

  // Date fields
  DateTime? _dateOfBirth;
  DateTime? _passportDateIssue;
  DateTime? _passportExpiry;

  // Portrait photo
  File? _photoFile;
  Uint8List? _photoBytes;
  String? _existingPhotoUrl;

  // Passport scan photo
  File? _passportScanFile;
  Uint8List? _passportScanBytes;
  String? _existingPassportScanUrl;

  // Submission state
  bool _isSubmitting = false;

  // Marital Status & Relatives
  String _maritalStatus = ''; // '', 'single', 'married', 'divorced', 'widowed'
  final List<Map<String, dynamic>> _relatives = [];

  bool _confirmationChecked = false;

  // -- Figma design constants --
  static const _primaryColor = Color(0xFF3C4494);
  static const _borderColor = Color(0xFFB7B7B7);
  static const _optionalLabelColor = Color(0xFFD4D4D4);
  static const _alertBgColor = Color(0xFFFFE0E0);
  static const _alertBorderColor = Color(0xFFF67373);
  static const _alertTextColor = Color(0xFFCA0000);
  static const _greenColor = Color(0xFF008000);
  static const _redColor = Color(0xFFCA0000);

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _fatherNameController.dispose();
    _surnameAtBirthController.dispose();
    _placeOfBirthController.dispose();
    _countryOfBirthController.dispose();
    _citizenshipController.dispose();
    _emailController.dispose();
    _passportNumberController.dispose();
    _passportIssuingCountryController.dispose();
    _educationController.dispose();
    _specialtyController.dispose();
    _placeOfStudyController.dispose();
    _jobTitleController.dispose();
    _employerNameController.dispose();
    _homeAddressController.dispose();
    _plannedResidentialAddressController.dispose();
    for (final rel in _relatives) {
      (rel['firstName'] as TextEditingController).dispose();
      (rel['lastName'] as TextEditingController).dispose();
      (rel['middleName'] as TextEditingController).dispose();
      (rel['surnameAtBirth'] as TextEditingController).dispose();
      (rel['citizenship'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVisaData();
    });
  }

  Future<void> _loadVisaData() async {
    try {
      if (!mounted) return;

      if (widget.eventId <= 0) {
        setState(() {
          _errorMessage = 'Invalid event. Please go back and try again.';
          _isLoading = false;
        });
        return;
      }

      final visaService = ref.read(visaServiceProvider);

      // Load all visas for this event
      List<Map<String, dynamic>> visas;
      try {
        visas = await visaService.listMyVisas(eventId: widget.eventId);
      } catch (_) {
        visas = [];
      }

      // If no visas exist, create one automatically
      if (visas.isEmpty) {
        try {
          await visaService.createMyVisa(eventId: widget.eventId);
          visas = await visaService.listMyVisas(eventId: widget.eventId);
        } catch (_) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      if (!mounted) return;

      _allVisas = visas;

      // Determine which visa tab to select
      if (widget.visaId != null) {
        final idx = visas.indexWhere((v) => v['id'] == widget.visaId);
        _selectedVisaIndex = idx >= 0 ? idx : 0;
      } else {
        _selectedVisaIndex = 0;
      }

      // Load selected visa into form controllers
      await _loadVisaIntoForm(_allVisas[_selectedVisaIndex]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Load a single visa's data into all form controllers.
  Future<void> _loadVisaIntoForm(Map<String, dynamic> visa) async {
    _visaId = visa['id'] as String?;
    _currentVisaStatus = visa['status'] as String? ?? 'FILL_OUT';

    // Pre-fill form data
    _nameController.text = visa['first_name'] ?? '';
    _surnameController.text = visa['last_name'] ?? '';
    _surnameAtBirthController.text = visa['surname_at_birth'] ?? '';
    _fatherNameController.text = visa['father_name'] ?? '';
    _gender = visa['gender'];
    _placeOfBirthController.text = visa['place_of_birth'] ?? '';
    _countryOfBirthController.text = visa['country_of_birth'] ?? '';
    _citizenshipController.text = visa['citizenship'] ?? '';
    _emailController.text = visa['email'] ?? '';
    _phoneNumberE164 = visa['phone_number'] ?? '';
    _dateOfBirth = visa['date_of_birth'] != null
        ? DateTime.parse(visa['date_of_birth'])
        : null;

    // Passport (migrate legacy 'Ordinary' value)
    final rawPassportType = visa['type_of_passport'] as String?;
    if (rawPassportType == 'Ordinary') {
      _typeOfPassport = 'P - Milli Pasport (National)';
    } else {
      _typeOfPassport = rawPassportType;
    }
    _passportNumberController.text = visa['passport_number'] ?? '';
    _passportDateIssue = visa['passport_date_of_issue'] != null
        ? DateTime.parse(visa['passport_date_of_issue'])
        : null;
    _passportExpiry = visa['passport_expiry'] != null
        ? DateTime.parse(visa['passport_expiry'])
        : null;
    _passportIssuingCountryController.text =
        visa['passport_issuing_country'] ?? '';

    // Professional
    _educationController.text = visa['education_level'] ?? '';
    _placeOfStudyController.text = visa['place_of_study'] ?? '';
    _specialtyController.text = visa['specialty'] ?? '';
    _jobTitleController.text = visa['job_title'] ?? '';
    _employerNameController.text = visa['employer_name'] ?? '';

    // Residential
    _homeAddressController.text = visa['home_address'] ?? '';
    _plannedResidentialAddressController.text =
        visa['planned_residential_address'] ?? '';

    // Marital Status
    if (visa['marital_status'] != null) {
      _maritalStatus = (visa['marital_status'] as String).toLowerCase();
    } else {
      _maritalStatus = '';
    }

    // Clear existing relatives
    for (final rel in _relatives) {
      (rel['firstName'] as TextEditingController).dispose();
      (rel['lastName'] as TextEditingController).dispose();
      (rel['middleName'] as TextEditingController).dispose();
      (rel['surnameAtBirth'] as TextEditingController).dispose();
      (rel['citizenship'] as TextEditingController).dispose();
    }
    _relatives.clear();

    // Load relatives from unified array (with fallback to legacy)
    final relativesList = visa['relatives'] as List<dynamic>?;
    if (relativesList != null && relativesList.isNotEmpty) {
      for (var rel in relativesList) {
        _relatives.add(_createRelativeEntry(
          relationship: rel['relationship'] ?? 'Wife',
          firstName: rel['first_name'] ?? '',
          lastName: rel['last_name'] ?? '',
          middleName: rel['middle_name'] ?? '',
          surnameAtBirth: rel['surname_at_birth'] ?? '',
          citizenship: rel['citizenship'] ?? '',
          dateOfBirth: rel['date_of_birth'] != null
              ? DateTime.parse(rel['date_of_birth'])
              : null,
        ));
      }
    } else {
      // Legacy fallback: load spouse fields only if married
      if (_maritalStatus == 'married') {
        final spouseFirst = visa['spouse_first_name'] ?? '';
        final spouseLast = visa['spouse_last_name'] ?? '';
        if (spouseFirst.isNotEmpty || spouseLast.isNotEmpty) {
          _relatives.add(_createRelativeEntry(
            relationship: visa['spouse_relationship'] ?? 'Wife',
            firstName: spouseFirst,
            lastName: spouseLast,
            citizenship: visa['spouse_citizenship'] ?? '',
            dateOfBirth: visa['spouse_date_of_birth'] != null
                ? DateTime.parse(visa['spouse_date_of_birth'])
                : null,
          ));
        }
      }
      // Legacy children load for any marital status
      final childrenList = visa['children'] as List<dynamic>?;
      if (childrenList != null) {
        for (var child in childrenList) {
          _relatives.add(_createRelativeEntry(
            relationship: 'Son',
            firstName: child['first_name'] ?? '',
            lastName: child['last_name'] ?? '',
            citizenship: child['citizenship'] ?? '',
            dateOfBirth: child['date_of_birth'] != null
                ? DateTime.parse(child['date_of_birth'])
                : null,
          ));
        }
      }
    }

    // Load cities for the country of birth
    if (_countryOfBirthController.text.isNotEmpty) {
      _loadCitiesForCountry(_countryOfBirthController.text);
    } else {
      _availableCities = [];
    }

    // Reset photo/scan state for new visa and load existing URLs
    _photoFile = null;
    _photoBytes = null;
    _existingPhotoUrl = visa['photo_url'] as String?;
    _passportScanFile = null;
    _passportScanBytes = null;
    _existingPassportScanUrl = visa['passport_scan_url'] as String?;
    _confirmationChecked = false;

    // Pre-fill from participant data if visa fields are empty
    if (_nameController.text.isEmpty && _surnameController.text.isEmpty) {
      await _prefillFromParticipant();
    }
  }

  /// Build form data map from current controller state.
  Map<String, dynamic> _buildFormData({String? photoUrl, String? passportScanUrl}) {
    return {
      'first_name': _nameController.text.trim(),
      'last_name': _surnameController.text.trim(),
      'surname_at_birth': _surnameAtBirthController.text.trim(),
      'father_name': _fatherNameController.text.trim(),
      'gender': _gender,
      'place_of_birth': _placeOfBirthController.text.trim(),
      'country_of_birth': _countryOfBirthController.text.trim(),
      if (_dateOfBirth != null)
        'date_of_birth': _dateOfBirth!.toIso8601String().split('T')[0],
      'citizenship': _citizenshipController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_number': _phoneNumberE164,
      'type_of_passport': _typeOfPassport ?? '',
      'passport_number': _passportNumberController.text.trim(),
      if (_passportDateIssue != null)
        'passport_date_of_issue':
            _passportDateIssue!.toIso8601String().split('T')[0],
      if (_passportExpiry != null)
        'passport_expiry':
            _passportExpiry!.toIso8601String().split('T')[0],
      'passport_issuing_country':
          _passportIssuingCountryController.text.trim(),
      'education_level': _educationController.text.trim(),
      'place_of_study': _placeOfStudyController.text.trim(),
      'specialty': _specialtyController.text.trim(),
      'job_title': _jobTitleController.text.trim(),
      'employer_name': _employerNameController.text.trim(),
      'home_address': _homeAddressController.text.trim(),
      'planned_residential_address':
          _plannedResidentialAddressController.text.trim(),
      if (photoUrl != null) 'photo_url': photoUrl,
      if (passportScanUrl != null) 'passport_scan_url': passportScanUrl,
      if (_maritalStatus.isNotEmpty)
        'marital_status': _maritalStatus[0].toUpperCase() + _maritalStatus.substring(1),
      'relatives': _relatives.map((rel) {
        return {
          'relationship': rel['relationship'],
          'first_name':
              (rel['firstName'] as TextEditingController).text.trim(),
          'last_name':
              (rel['lastName'] as TextEditingController).text.trim(),
          'middle_name':
              (rel['middleName'] as TextEditingController).text.trim(),
          'surname_at_birth':
              (rel['surnameAtBirth'] as TextEditingController).text.trim(),
          'citizenship':
              (rel['citizenship'] as TextEditingController).text.trim(),
          if (rel['dateOfBirth'] != null)
            'date_of_birth': (rel['dateOfBirth'] as DateTime)
                .toIso8601String()
                .split('T')[0],
        };
      }).toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // STATUS & EDIT RESTRICTIONS
  // ---------------------------------------------------------------------------

  bool get _isVisaEditable =>
      _currentVisaStatus == 'FILL_OUT' ||
      _currentVisaStatus == 'NOT_STARTED' ||
      _currentVisaStatus == 'DECLINED';

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFE89B0C);
      case 'APPROVED':
        return _greenColor;
      case 'DECLINED':
        return _redColor;
      default:
        return _primaryColor;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Under Review';
      case 'APPROVED':
        return 'Approved';
      case 'DECLINED':
        return 'Declined';
      default:
        return 'Draft';
    }
  }

  // ---------------------------------------------------------------------------
  // CITY CACHE
  // ---------------------------------------------------------------------------

  Future<void> _loadCityCache() async {
    if (_cityCache != null) return;
    try {
      final jsonStr = await rootBundle.loadString(
        'packages/csc_picker_plus/lib/assets/countries.json',
      );
      final List<dynamic> data = json.decode(jsonStr);
      final map = <String, List<String>>{};
      for (final country in data) {
        final name = country['name'] as String;
        final cities = <String>{};
        for (final state in (country['state'] as List? ?? [])) {
          for (final city in (state['city'] as List? ?? [])) {
            cities.add(city['name'] as String);
          }
        }
        final sorted = cities.toList()..sort();
        map[name] = sorted;
      }
      _cityCache = map;
    } catch (_) {
      _cityCache = {};
    }
  }

  Future<void> _loadCitiesForCountry(String country) async {
    setState(() => _isLoadingCities = true);
    try {
      await _loadCityCache();
      if (mounted) {
        setState(() {
          _availableCities = _cityCache?[country] ?? [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  /// Silently save current visa form data without submitting.
  Future<void> _saveCurrentVisa() async {
    if (_visaId == null || !_isVisaEditable) return;
    try {
      final visaService = ref.read(visaServiceProvider);
      final formData = _buildFormData();
      await visaService.updateMyVisaById(visaId: _visaId!, data: formData);
    } catch (e) {
      if (kDebugMode) debugPrint('Auto-save failed: $e');
    }
  }

  /// Switch to a different visa tab.
  Future<void> _switchToVisa(int index) async {
    if (index == _selectedVisaIndex) return;

    setState(() => _isSwitchingTab = true);
    try {
      // Auto-save current form
      await _saveCurrentVisa();

      // Reload the target visa fresh from server
      final visaService = ref.read(visaServiceProvider);
      final visa = await visaService.getMyVisaById(
        _allVisas[index]['id'] as String,
      );
      if (!mounted) return;
      _selectedVisaIndex = index;
      await _loadVisaIntoForm(visa);
      setState(() {});
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to load visa: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isSwitchingTab = false);
    }
  }

  /// Add a new visa application and switch to it.
  Future<void> _addNewVisa() async {
    setState(() => _isCreatingVisa = true);
    try {
      // Save current visa first
      await _saveCurrentVisa();

      final visaService = ref.read(visaServiceProvider);
      await visaService.createMyVisa(eventId: widget.eventId);

      // Refresh list
      final visas = await visaService.listMyVisas(eventId: widget.eventId);
      if (!mounted) return;

      _allVisas = visas;
      // Switch to the newly created visa (last in list)
      final newIndex = visas.length - 1;
      _selectedVisaIndex = newIndex;
      await _loadVisaIntoForm(_allVisas[newIndex]);
      setState(() {});
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isCreatingVisa = false);
    }
  }

  /// Show confirmation dialog then delete the current visa.
  Future<void> _confirmDeleteVisa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Visa Application'),
        content: Text(
          'Are you sure you want to delete Visa ${_selectedVisaIndex + 1}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final visaId = _allVisas[_selectedVisaIndex]['id'] as String;
      final visaService = ref.read(visaServiceProvider);
      await visaService.deleteMyVisaById(visaId);

      // Refresh list
      final visas = await visaService.listMyVisas(eventId: widget.eventId);
      if (!mounted) return;

      _allVisas = visas;
      if (_selectedVisaIndex >= _allVisas.length) {
        _selectedVisaIndex = _allVisas.length - 1;
      }
      if (_allVisas.isNotEmpty) {
        await _loadVisaIntoForm(_allVisas[_selectedVisaIndex]);
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Map<String, dynamic> _createRelativeEntry({
    String relationship = 'Wife',
    String firstName = '',
    String lastName = '',
    String middleName = '',
    String surnameAtBirth = '',
    String citizenship = '',
    DateTime? dateOfBirth,
  }) {
    return {
      'relationship': relationship,
      'firstName': TextEditingController(text: firstName),
      'lastName': TextEditingController(text: lastName),
      'middleName': TextEditingController(text: middleName),
      'surnameAtBirth': TextEditingController(text: surnameAtBirth),
      'citizenship': TextEditingController(text: citizenship),
      'dateOfBirth': dateOfBirth,
    };
  }

  Future<void> _prefillFromParticipant() async {
    if (widget.participantId == null || widget.participantId!.isEmpty) return;

    try {
      final token = await ref.read(authNotifierProvider.notifier).getToken();

      final response = await http.get(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/participants/${widget.participantId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final participant = jsonDecode(response.body) as Map<String, dynamic>;

        if (_nameController.text.isEmpty) {
          _nameController.text = participant['first_name'] ?? '';
        }
        if (_surnameController.text.isEmpty) {
          _surnameController.text = participant['last_name'] ?? '';
        }
        if (_phoneNumberE164.isEmpty) {
          _phoneNumberE164 = participant['mobile'] ?? '';
        }
        if (_employerNameController.text.isEmpty) {
          _employerNameController.text = participant['company_name'] ?? '';
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error pre-filling from participant data: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (mounted) setState(() => _photoBytes = bytes);
        } else {
          setState(() => _photoFile = File(image.path));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Image picker error: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to pick image. Please try again.');
      }
    }
  }

  void _deletePhoto() {
    setState(() {
      _photoFile = null;
      _photoBytes = null;
      _existingPhotoUrl = null;
    });
  }

  Future<void> _pickPassportScan() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (mounted) setState(() => _passportScanBytes = bytes);
        } else {
          setState(() => _passportScanFile = File(image.path));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Passport scan picker error: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to pick image. Please try again.');
      }
    }
  }

  void _deletePassportScan() {
    setState(() {
      _passportScanFile = null;
      _passportScanBytes = null;
      _existingPassportScanUrl = null;
    });
  }

  Future<void> selectDate(
    BuildContext context,
    DateTime? currentDate,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _addRelative() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select relationship',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        borderRadius: BorderRadius.circular(4),
                        child: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...['Wife', 'Husband', 'Daughter', 'Son'].map((type) {
                    return InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _relatives.add(_createRelativeEntry(relationship: type));
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _removeRelative(int index) {
    setState(() {
      final rel = _relatives[index];
      (rel['firstName'] as TextEditingController).dispose();
      (rel['lastName'] as TextEditingController).dispose();
      (rel['middleName'] as TextEditingController).dispose();
      (rel['surnameAtBirth'] as TextEditingController).dispose();
      (rel['citizenship'] as TextEditingController).dispose();
      _relatives.removeAt(index);
    });
  }

  Future<void> submitForm() async {
    if (!_isVisaEditable) {
      AppSnackBar.showError(
        context,
        _currentVisaStatus == 'PENDING'
            ? 'Your visa application is under review and cannot be edited.'
            : 'This visa application has been approved and cannot be modified.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_confirmationChecked) {
      AppSnackBar.showError(context, 'Please confirm the accuracy of the information');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload photo if exists
      String? photoUrl;
      if (_photoFile != null || _photoBytes != null) {
        if (!mounted) return;
        final visaService = ref.read(visaServiceProvider);
        photoUrl = await visaService.uploadPhoto(
          participantId: widget.participantId,
          photoData: kIsWeb ? _photoBytes : _photoFile,
        );
      }

      // 2. Upload passport scan if exists
      String? passportScanUrl;
      if (_passportScanFile != null || _passportScanBytes != null) {
        if (!mounted) return;
        final visaService = ref.read(visaServiceProvider);
        passportScanUrl = await visaService.uploadPhoto(
          participantId: widget.participantId,
          photoData: kIsWeb ? _passportScanBytes : _passportScanFile,
        );
      }

      // 3. Prepare data
      if (!mounted) return;

      final formData = _buildFormData(
        photoUrl: photoUrl,
        passportScanUrl: passportScanUrl,
      );

      // 4. Update visa application
      if (!mounted) return;
      final visaService = ref.read(visaServiceProvider);
      if (_visaId != null) {
        await visaService.updateMyVisaById(visaId: _visaId!, data: formData);
      } else {
        await visaService.updateMyVisa(
          participantId: widget.participantId,
          eventId: widget.eventId,
          data: formData,
        );
      }

      // 5. Submit for review
      if (!mounted) return;
      if (_visaId != null) {
        await visaService.submitMyVisaById(_visaId!);
      } else {
        await visaService.submitMyVisa(
          participantId: widget.participantId,
          eventId: widget.eventId,
        );
      }

      // 6. Refresh visa list to update tab status
      if (!mounted) return;
      try {
        _allVisas = await visaService.listMyVisas(eventId: widget.eventId);
        if (mounted && _allVisas.isNotEmpty && _selectedVisaIndex < _allVisas.length) {
          await _loadVisaIntoForm(_allVisas[_selectedVisaIndex]);
        }
      } catch (_) {}

      if (!mounted) return;
      ref.invalidate(visaListProvider(widget.eventId));
      AppSnackBar.showSuccess(context, 'Visa application submitted successfully');
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        AppSnackBar.showError(context, msg.contains('Participant profile not found')
            ? 'Please register as a participant before submitting a visa application.'
            : msg);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: _primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Error loading visa application',
              style: TextStyle(color: Color(0xFF333333), fontSize: 18),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF666666)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVisaData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _saveCurrentVisa();
        if (mounted) context.pop();
      },
      child: SafeArea(
        child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Page title
                      _buildPageTitle(),
                      const SizedBox(height: 12),

                      // 2. Separator line
                      _buildSeparatorLine(),
                      const SizedBox(height: 20),

                      // 3. Alert banner
                      _buildAlertBanner(),
                      const SizedBox(height: 16),

                      // 4. Visa tabs
                      _buildVisaTabs(),
                      const SizedBox(height: 16),

                      // 5. Status banner (when not editable)
                      if (!_isVisaEditable) ...[
                        _buildStatusBanner(),
                        const SizedBox(height: 16),
                      ],

                      // 6. Main form card + Marital status (disabled when not editable)
                      IgnorePointer(
                        ignoring: !_isVisaEditable,
                        child: Opacity(
                          opacity: _isVisaEditable ? 1.0 : 0.6,
                          child: Column(
                            children: [
                              _buildMainFormCard(),
                              const SizedBox(height: 24),
                              _buildMaritalStatusCard(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 7. Confirmation checkbox (only when editable)
                      if (_isVisaEditable) ...[
                        _buildConfirmationCheckbox(),
                        const SizedBox(height: 24),
                      ],

                      // 8. Conditional buttons
                      _buildButtonRow(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              if (_isSwitchingTab)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withAlpha(180),
                    child: const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    ),
                  ),
                ),
            ],
          ),
        ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP-LEVEL WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildVisaTabs() {
    final currentVisa = _allVisas.isNotEmpty ? _allVisas[_selectedVisaIndex] : null;
    final currentStatus = currentVisa?['status'] as String? ?? 'FILL_OUT';
    final canDelete = _allVisas.length > 1 &&
        currentStatus != 'PENDING' &&
        currentStatus != 'APPROVED';

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Visa tabs
                for (int i = 0; i < _allVisas.length; i++)
                  _buildVisaTab(i),
                // "+ Add" tab
                InkWell(
                  onTap: _isCreatingVisa ? null : _addNewVisa,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8E8F0),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isCreatingVisa)
                          const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                          )
                        else
                          const Icon(Icons.add, size: 16, color: _primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Add (${_allVisas.length})',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Delete current visa button
        if (canDelete) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: _confirmDeleteVisa,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withAlpha(100)),
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVisaTab(int index) {
    final isActive = index == _selectedVisaIndex;
    final visa = _allVisas[index];
    final status = visa['status'] as String? ?? 'FILL_OUT';
    final isEditable = status == 'FILL_OUT' || status == 'NOT_STARTED' || status == 'DECLINED';
    final isSubmitted = status == 'PENDING' || status == 'APPROVED';
    final statusCol = _statusColor(status);

    return Tooltip(
      message: _statusLabel(status),
      child: Padding(
        padding: const EdgeInsets.only(right: 2),
        child: InkWell(
          onTap: () => _switchToVisa(index),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive && !isEditable
                  ? statusCol.withAlpha(20)
                  : isActive
                      ? Colors.white
                      : const Color(0xFFE8E8F0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: isActive
                  ? Border.all(color: isEditable ? _primaryColor : statusCol, width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Visa ${index + 1}',
                  style: TextStyle(
                    color: isActive ? (isEditable ? _primaryColor : statusCol) : Colors.black87,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
                if (isSubmitted) ...[
                  const SizedBox(width: 6),
                  Icon(
                    status == 'APPROVED' ? Icons.check_circle : Icons.schedule,
                    size: 14,
                    color: status == 'APPROVED' ? _greenColor : const Color(0xFFB39656),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return const Text(
      'Visa & Travel Center',
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: _primaryColor,
      ),
    );
  }

  Widget _buildSeparatorLine() {
    return Container(
      height: 0.5,
      color: const Color(0xFFCACACA),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _alertBgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _alertBorderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SvgPicture.asset(
              'assets/visa_application/icons/alert-triangle.svg',
              width: 20,
              height: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'If the application form is not completed correctly or required information is missing, there is a risk that the visa may be denied.',
              style: TextStyle(
                color: _alertTextColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final isPending = _currentVisaStatus == 'PENDING';
    final isApproved = _currentVisaStatus == 'APPROVED';
    final statusCol = _statusColor(_currentVisaStatus);

    final String title;
    final String message;
    final IconData icon;

    if (isPending) {
      title = 'Application Under Review';
      message = 'This visa application has been submitted and is being reviewed. '
          'You cannot edit it. To apply for another person, tap "+ Add" above.';
      icon = Icons.schedule;
    } else if (isApproved) {
      title = 'Visa Approved';
      message = 'This visa application has been approved. '
          'To apply for another person, tap "+ Add" above.';
      icon = Icons.check_circle;
    } else {
      title = 'Visa Declined';
      message = 'This visa was declined. You can edit and resubmit it.';
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusCol.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusCol.withAlpha(80), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: statusCol, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: statusCol,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: statusCol.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            offset: Offset.zero,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          if (isWide) {
            return _buildTwoColumnLayout();
          } else {
            return _buildSingleColumnLayout();
          }
        },
      ),
    );
  }

  Widget _buildMaritalStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            offset: Offset.zero,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Marital Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 16),
          _buildMaritalStatusDropdown(),
          const SizedBox(height: 16),

          // Relatives section (always available — children possible for any status)
          Row(
            children: [
              const Text(
                'Relatives:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _addRelative,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  side: const BorderSide(color: _primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          ..._relatives.asMap().entries.map((entry) {
            return _buildRelativeSection(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildMaritalStatusDropdown() {
    const statuses = ['single', 'married', 'divorced', 'widowed'];
    const labels = {
      'single': 'Single',
      'married': 'Married',
      'divorced': 'Divorced',
      'widowed': 'Widowed',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {
        final isSelected = _maritalStatus == status;
        final Color bgColor;
        final Color borderColor;
        if (isSelected) {
          bgColor = _primaryColor;
          borderColor = _primaryColor;
        } else {
          bgColor = Colors.white;
          borderColor = _borderColor;
        }
        return SizedBox(
          height: 40,
          child: OutlinedButton(
            onPressed: () => setState(() => _maritalStatus = status),
            style: OutlinedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: isSelected ? Colors.white : const Color(0xFF333333),
              side: BorderSide(color: borderColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(
              labels[status]!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmationCheckbox() {
    return AppCheckbox(
      value: _confirmationChecked,
      onChanged: (v) => setState(() => _confirmationChecked = v),
      label:
          'I confirm that all information provided is true and complete, and I understand that any incorrect information may result in my visa being denied',
    );
  }

  Widget _buildButtonRow() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Non-editable: show "Back" + "Add New Visa"
    if (!_isVisaEditable) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: isMobile ? null : 183,
            height: 43,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF666666),
                side: const BorderSide(color: _borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 16),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 43,
            child: ElevatedButton.icon(
              onPressed: _isCreatingVisa ? null : _addNewVisa,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add New Visa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Editable: show "Cancel" + "Submit"
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: isMobile ? null : 183,
          height: 43,
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 16),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: isMobile ? null : 183,
          height: 43,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primaryColor.withAlpha(153),
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Submit',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TWO-COLUMN (desktop) LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildFieldRow({required Widget left, required Widget right}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 24),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name/Surname on the left, Photo uploads on the right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildTextField('Name:', _nameController, 'John', true),
                  _buildTextField('Surname:', _surnameController, 'Smith', true),
                  _buildTextField('Middle name:', _fatherNameController, 'Middle name', true),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(child: _buildPhotoUploadSection()),
          ],
        ),

        // Remaining personal info – paired rows
        _buildFieldRow(
          left: _buildGenderDropdown(),
          right: _buildDateField('Date of birth:', null, _dateOfBirth, (date) {
            setState(() => _dateOfBirth = date);
          }, '1990-05-20'),
        ),
        _buildFieldRow(
          left: _buildTextField('Surname at birth:', _surnameAtBirthController, 'Maiden name (if different)', false, true, _gender != null),
          right: _buildCountryPickerField('Citizenship:', _citizenshipController, true),
        ),
        _buildFieldRow(
          left: _buildCountryPickerField('Country of birth:', _countryOfBirthController, true, () {
            _placeOfBirthController.clear();
            _loadCitiesForCountry(_countryOfBirthController.text);
          }),
          right: _buildCityPickerField(),
        ),

        // Passport section – paired rows
        _buildFieldRow(
          left: _buildPassportTypeDropdown(),
          right: _buildTextField('Passport number:', _passportNumberController, 'AB1234567', true),
        ),
        _buildFieldRow(
          left: _buildDateField('Passport date issue:', null, _passportDateIssue, (date) {
            setState(() => _passportDateIssue = date);
          }, '2020-01-15'),
          right: _buildDateField('Passport validity period:', null, _passportExpiry, (date) {
            setState(() => _passportExpiry = date);
          }, '2030-01-15'),
        ),
        _buildFieldRow(
          left: _buildCountryPickerField('Place of issue (country):', _passportIssuingCountryController),
          right: _buildTextField('Personal Address:', _homeAddressController, 'Street, Building, Apt', true),
        ),

        // Email – full width
        _buildTextField('Email:', _emailController, 'john@example.com', true),

        // Professional section – paired rows
        _buildFieldRow(
          left: _buildTextField('Education:', _educationController, "Bachelor's Degree", true),
          right: _buildTextField('Speciality:', _specialtyController, 'Computer Science', true),
        ),
        _buildFieldRow(
          left: _buildTextField('Place of work (Company name):', _employerNameController, 'Tech Corp'),
          right: PhoneInputField(
            initialPhone: _phoneNumberE164,
            labelText: 'Personal mobile number:',
            hintText: '61444555',
            onChanged: (e164) {
              setState(() => _phoneNumberE164 = e164);
            },
          ),
        ),
        _buildFieldRow(
          left: _buildTextField('Position:', _jobTitleController, 'Software Engineer', true),
          right: _buildTextField('Place of education:', _placeOfStudyController, 'Harvard University', true),
        ),

        // Planned residential address – full width
        _buildTextField('Planned residential address:', _plannedResidentialAddressController, 'Address during stay'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SINGLE-COLUMN (mobile) LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildSingleColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoUploadSection(),
        _buildTextField('Name:', _nameController, 'John', true),
        _buildTextField('Surname:', _surnameController, 'Smith', true),
        _buildTextField('Middle name:', _fatherNameController, 'Middle name', true),
        _buildGenderDropdown(),
        _buildTextField(
          'Surname at birth:',
          _surnameAtBirthController,
          'Maiden name (if different)',
          false,
          true,
          _gender != null,
        ),
        _buildCountryPickerField(
          'Country of birth:',
          _countryOfBirthController,
          true,
          () {
            _placeOfBirthController.clear();
            _loadCitiesForCountry(_countryOfBirthController.text);
          },
        ),
        _buildCityPickerField(),
        _buildDateField('Date of birth:', null, _dateOfBirth, (date) {
          setState(() => _dateOfBirth = date);
        }, '1990-05-20'),
        _buildCountryPickerField(
          'Citizenship:',
          _citizenshipController,
          true,
        ),
        _buildTextField('Email:', _emailController, 'john@example.com', true),
        PhoneInputField(
          initialPhone: _phoneNumberE164,
          labelText: 'Personal mobile number:',
          hintText: '61444555',
          onChanged: (e164) {
            setState(() => _phoneNumberE164 = e164);
          },
        ),
        _buildPassportTypeDropdown(),
        _buildTextField(
          'Passport number:',
          _passportNumberController,
          'AB1234567',
          true,
        ),
        _buildDateField('Passport date issue:', null, _passportDateIssue,
            (date) {
          setState(() => _passportDateIssue = date);
        }, '2020-01-15'),
        _buildDateField(
          'Passport validity period:',
          null,
          _passportExpiry,
          (date) {
            setState(() => _passportExpiry = date);
          },
          '2030-01-15',
        ),
        _buildCountryPickerField(
          'Place of issue (country):',
          _passportIssuingCountryController,
        ),
        _buildTextField(
          'Personal Address:',
          _homeAddressController,
          'Street, Building, Apt',
          true,
        ),
        _buildTextField(
          'Education:',
          _educationController,
          "Bachelor's Degree",
          true,
        ),
        _buildTextField(
          'Speciality:',
          _specialtyController,
          'Computer Science',
          true,
        ),
        _buildTextField(
          'Place of work (Company name):',
          _employerNameController,
          'Tech Corp',
        ),
        _buildTextField(
          'Position:',
          _jobTitleController,
          'Software Engineer',
          true,
        ),
        _buildTextField(
          'Place of education:',
          _placeOfStudyController,
          'Harvard University',
          true,
        ),
        _buildTextField(
          'Planned residential address:',
          _plannedResidentialAddressController,
          'Address during stay',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD BUILDERS (Figma styling)
  // ---------------------------------------------------------------------------

  Widget _buildTextField(
    String label,
    TextEditingController controller, [
    String? hintText,
    bool isRequired = false,
    bool isOptional = false,
    bool enabled = true,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: isOptional ? _optionalLabelColor : const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 50,
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                validator: isRequired
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      }
                    : null,
                decoration: _inputDecoration(hintText: hintText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: DropdownButtonFormField<String>(
              initialValue: _gender,
              isExpanded: true,
              icon: SvgPicture.asset(
                'assets/visa_application/icons/chevron-down.svg',
                width: 18,
                height: 18,
              ),
              decoration: _inputDecoration(),
              hint: Text(
                'Select gender',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              items: ['Male', 'Female'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _gender = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type of passport:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: DropdownButtonFormField<String>(
              initialValue: _typeOfPassport,
              isExpanded: true,
              icon: SvgPicture.asset(
                'assets/visa_application/icons/chevron-down.svg',
                width: 18,
                height: 18,
              ),
              decoration: _inputDecoration(),
              hint: Text(
                'Select passport type',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              items: _passportTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _typeOfPassport = newValue;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController? controller,
    DateTime? selectedDate, [
    Function(DateTime)? onDateSelected,
    String? hintText,
  ]) {
    final TextEditingController displayController =
        controller ?? TextEditingController();

    if (selectedDate != null && controller == null) {
      displayController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: TextFormField(
              controller: displayController,
              readOnly: true,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              onTap: () {
                selectDate(
                  context,
                  selectedDate,
                  onDateSelected ??
                      (date) {
                        controller?.text =
                            DateFormat('yyyy-MM-dd').format(date);
                      },
                );
              },
              decoration: _inputDecoration(
                hintText: hintText,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    'assets/visa_application/icons/calendar.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPickerDialog(TextEditingController controller, [VoidCallback? onChanged]) {
    String searchQuery = '';
    final countries = ref.read(countriesProvider).value ?? [];
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = searchQuery.isEmpty
                ? countries
                : countries
                    .where((c) =>
                        c.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();
            return AlertDialog(
              title: const Text('Select Country'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width < 600 ? 280 : 340,
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
                                    controller.text == country;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    country,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? _primaryColor
                                          : null,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check,
                                          color: _primaryColor, size: 20)
                                      : null,
                                  onTap: () {
                                    controller.text = country;
                                    Navigator.of(ctx).pop();
                                    setState(() {});
                                    onChanged?.call();
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

  Widget _buildCountryPickerField(
    String label,
    TextEditingController controller, [
    bool isRequired = false,
    VoidCallback? onChanged,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: TextFormField(
              controller: controller,
              readOnly: true,
              onTap: () => _showCountryPickerDialog(controller, onChanged),
              validator: isRequired
                  ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    }
                  : null,
              decoration: _inputDecoration(
                hintText: 'Select country',
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    'assets/visa_application/icons/chevron-down.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CITY PICKER
  // ---------------------------------------------------------------------------

  void _showCityPickerDialog() {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = searchQuery.isEmpty
                ? _availableCities
                : _availableCities
                    .where((c) => c.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();
            return AlertDialog(
              title: const Text('Select City'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width < 600 ? 280 : 340,
                height: 450,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search city...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) =>
                          setDialogState(() => searchQuery = value),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('No cities found'),
                                  if (searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: () {
                                        _placeOfBirthController.text =
                                            searchQuery;
                                        Navigator.of(ctx).pop();
                                        setState(() {});
                                      },
                                      child: Text('Use "$searchQuery"'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (ctx, index) {
                                final city = filtered[index];
                                final isSelected =
                                    _placeOfBirthController.text == city;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    city,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color:
                                          isSelected ? _primaryColor : null,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check,
                                          color: _primaryColor, size: 20)
                                      : null,
                                  onTap: () {
                                    _placeOfBirthController.text = city;
                                    Navigator.of(ctx).pop();
                                    setState(() {});
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

  Widget _buildCityPickerField() {
    final hasCities = _availableCities.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Place of birth (City):',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: TextFormField(
              controller: _placeOfBirthController,
              readOnly: hasCities || _isLoadingCities,
              onTap: hasCities ? () => _showCityPickerDialog() : null,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              decoration: _inputDecoration(
                hintText: _isLoadingCities
                    ? 'Loading cities...'
                    : (hasCities ? 'Select city' : 'Enter city'),
                suffixIcon: _isLoadingCities
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _primaryColor,
                          ),
                        ),
                      )
                    : hasCities
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: SvgPicture.asset(
                              'assets/visa_application/icons/chevron-down.svg',
                              width: 18,
                              height: 18,
                            ),
                          )
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PHOTO UPLOAD SECTION (Two boxes: portrait + passport scan)
  // ---------------------------------------------------------------------------

  Widget _buildPhotoUploadSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotoBox(
            width: 123, height: 154, label: 'Portrait photo',
            hasImage: (kIsWeb ? _photoBytes != null : _photoFile != null) || _existingPhotoUrl != null,
            imageWidget: _buildPortraitImage(),
            previewAsset: 'assets/visa_application/profile_preview.jpg',
            onUpload: _pickImage, onDelete: _deletePhoto,
          ),
          const SizedBox(width: 16),
          _buildPhotoBox(
            width: 216, height: 154, label: 'Passport scan',
            hasImage: (kIsWeb ? _passportScanBytes != null : _passportScanFile != null) || _existingPassportScanUrl != null,
            imageWidget: _buildPassportScanImage(),
            previewAsset: 'assets/visa_application/visa_preview.png',
            onUpload: _pickPassportScan, onDelete: _deletePassportScan,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox({
    required double width, required double height, required String label,
    required bool hasImage, required Widget imageWidget,
    required String previewAsset,
    required VoidCallback onUpload, required VoidCallback onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E1E1E))),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              width: width, height: height,
              decoration: BoxDecoration(
                border: Border.all(color: hasImage ? _primaryColor : _borderColor, width: hasImage ? 2 : 1),
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey[50],
              ),
              child: hasImage
                  ? ClipRRect(borderRadius: BorderRadius.circular(4), child: imageWidget)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Opacity(
                        opacity: 0.4,
                        child: Image.asset(previewAsset, width: width, height: height, fit: BoxFit.cover),
                      ),
                    ),
            ),
            if (!hasImage)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Example', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            if (hasImage)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgPicture.asset(
                      'assets/visa_application/icons/x-close.svg',
                      width: 14,
                      height: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: width,
          height: 32,
          child: ElevatedButton(
            onPressed: onUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Text(
              hasImage ? 'Change' : 'Upload',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitImage() {
    if (kIsWeb && _photoBytes != null) {
      return Image.memory(_photoBytes!, fit: BoxFit.cover);
    }
    if (!kIsWeb && _photoFile != null) {
      return Image.file(_photoFile!, fit: BoxFit.cover);
    }
    if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      return Image.network(_existingPhotoUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    return const SizedBox.shrink();
  }

  Widget _buildPassportScanImage() {
    if (kIsWeb && _passportScanBytes != null) {
      return Image.memory(_passportScanBytes!, fit: BoxFit.cover);
    }
    if (!kIsWeb && _passportScanFile != null) {
      return Image.file(_passportScanFile!, fit: BoxFit.cover);
    }
    if (_existingPassportScanUrl != null && _existingPassportScanUrl!.isNotEmpty) {
      return Image.network(_existingPassportScanUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // RELATIVE SECTION
  // ---------------------------------------------------------------------------

  Widget _buildRelativeSection(int index, Map<String, dynamic> rel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Relative ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: _redColor),
                onPressed: () => _removeRelative(index),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Relationship dropdown
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Relationship:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 50,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderColor),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: rel['relationship'] as String,
                        isExpanded: true,
                        icon: SvgPicture.asset(
                          'assets/visa_application/icons/chevron-down.svg',
                          width: 18,
                          height: 18,
                        ),
                        items: ['Wife', 'Husband', 'Daughter', 'Son']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            rel['relationship'] = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Name row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Name:',
                  rel['firstName'] as TextEditingController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Surname:',
                  rel['lastName'] as TextEditingController,
                ),
              ),
            ],
          ),

          _buildTextField(
            'Middle name:',
            rel['middleName'] as TextEditingController,
          ),

          // Date of birth & Surname at birth
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Date of birth:',
                  null,
                  rel['dateOfBirth'] as DateTime?,
                  (date) {
                    setState(() => rel['dateOfBirth'] = date);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Surname at birth:',
                  rel['surnameAtBirth'] as TextEditingController,
                ),
              ),
            ],
          ),

          // Citizenship
          _buildCountryPickerField(
            'Citizenship:',
            rel['citizenship'] as TextEditingController,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED INPUT DECORATION (Figma style)
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      suffixIcon: suffixIcon,
    );
  }
}
