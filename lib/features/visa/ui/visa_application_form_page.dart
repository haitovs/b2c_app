import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/phone_input_field.dart';
import '../../auth/services/auth_service.dart';

import 'package:flutter/services.dart' show rootBundle;

import '../services/visa_service.dart';

const List<String> _countries = [
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
  // Historical countries (for place of birth)
  'USSR (Soviet Union)', 'Yugoslavia', 'Czechoslovakia',
  'East Germany (GDR)', 'West Germany (FRG)',
];

const List<String> _passportTypes = [
  'Ordinary',
  'Diplomatic',
  'Service (Official)',
  'Special',
  'Emergency (Temporary)',
];

/// Visa Application Form Page matching Figma design
class VisaApplicationFormPage extends StatefulWidget {
  final int eventId;
  final String? participantId;

  const VisaApplicationFormPage({
    super.key,
    required this.eventId,
    this.participantId,
  });

  @override
  State<VisaApplicationFormPage> createState() =>
      _VisaApplicationFormPageState();
}

class _VisaApplicationFormPageState extends State<VisaApplicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Loading state
  bool _isLoading = true;
  String? _errorMessage;

  // Personal Information Controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _surnameAtBirthController = TextEditingController();
  final _fatherNameController = TextEditingController();
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

  // Passport scan photo
  File? _passportScanFile;
  Uint8List? _passportScanBytes;

  // Submission state
  bool _isSubmitting = false;

  // Marital Status & Relatives
  String _maritalStatus = 'single'; // 'single' or 'married'
  final List<Map<String, dynamic>> _relatives = [];

  bool _confirmationChecked = false;

  // City data loaded from csc_picker_plus asset
  static Map<String, List<String>>? _cityCache;
  List<String> _availableCities = [];

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
    _surnameAtBirthController.dispose();
    _fatherNameController.dispose();
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
    await _loadCityCache();
    setState(() {
      _availableCities = _cityCache?[country] ?? [];
    });
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

      final visaService = context.read<VisaService>();
      Map<String, dynamic> visa;
      try {
        visa = await visaService.getMyVisa(
          participantId: widget.participantId,
          eventId: widget.eventId,
        );
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      final status = visa['status'] as String? ?? 'NOT_STARTED';

      if (status == 'PENDING') {
        if (mounted) {
          final pid = widget.participantId ?? 'me';
          context.replace(
            '/events/${widget.eventId}/visa/status/$pid',
          );
        }
        return;
      }

      if (status == 'APPROVED') {
        if (mounted) {
          final pid = widget.participantId ?? 'me';
          context.replace(
            '/events/${widget.eventId}/visa/details/$pid',
          );
        }
        return;
      }

      // Pre-fill form data
      _nameController.text = visa['first_name'] ?? '';
      _surnameController.text = visa['last_name'] ?? '';
      _surnameAtBirthController.text = visa['surname_at_birth'] ?? '';
      _fatherNameController.text = visa['father_name'] ?? '';
      _gender = visa['gender'];
      _placeOfBirthController.text = visa['place_of_birth'] ?? '';
      _countryOfBirthController.text = visa['country_of_birth'] ?? '';
      if (_countryOfBirthController.text.isNotEmpty) {
        _loadCitiesForCountry(_countryOfBirthController.text);
      }
      _citizenshipController.text = visa['citizenship'] ?? '';
      _emailController.text = visa['email'] ?? '';
      _phoneNumberE164 = visa['phone_number'] ?? '';
      if (visa['date_of_birth'] != null) {
        _dateOfBirth = DateTime.parse(visa['date_of_birth']);
      }

      // Passport
      _typeOfPassport = visa['type_of_passport'];
      _passportNumberController.text = visa['passport_number'] ?? '';
      if (visa['passport_date_of_issue'] != null) {
        _passportDateIssue = DateTime.parse(visa['passport_date_of_issue']);
      }
      if (visa['passport_expiry'] != null) {
        _passportExpiry = DateTime.parse(visa['passport_expiry']);
      }
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
      }

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
      } else if (_maritalStatus == 'married') {
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

      // Pre-fill from participant data if visa fields are empty
      if (_nameController.text.isEmpty && _surnameController.text.isEmpty) {
        await _prefillFromParticipant();
      }

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
    if (widget.participantId == null) return;
    try {
      final authService = context.read<AuthService>();
      final token = await authService.getToken();

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
      debugPrint('Error pre-filling from participant data: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _photoBytes = bytes;
        });
      } else {
        setState(() {
          _photoFile = File(image.path);
        });
      }
    }
  }

  void _deletePhoto() {
    setState(() {
      _photoFile = null;
      _photoBytes = null;
    });
  }

  Future<void> _pickPassportScan() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _passportScanBytes = bytes;
        });
      } else {
        setState(() {
          _passportScanFile = File(image.path);
        });
      }
    }
  }

  void _deletePassportScan() {
    setState(() {
      _passportScanFile = null;
      _passportScanBytes = null;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_confirmationChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm the accuracy of the information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload photo if exists
      String? photoUrl;
      if (_photoFile != null || _photoBytes != null) {
        if (!mounted) return;
        final visaService = context.read<VisaService>();
        photoUrl = await visaService.uploadPhoto(
          participantId: widget.participantId,
          photoData: kIsWeb ? _photoBytes : _photoFile,
        );
      }

      // 2. Upload passport scan if exists
      String? passportScanUrl;
      if (_passportScanFile != null || _passportScanBytes != null) {
        if (!mounted) return;
        final visaService = context.read<VisaService>();
        passportScanUrl = await visaService.uploadPhoto(
          participantId: widget.participantId,
          photoData: kIsWeb ? _passportScanBytes : _passportScanFile,
        );
      }

      // 3. Prepare data
      if (!mounted) return;

      final formData = <String, dynamic>{
        // Personal Information
        'first_name': _nameController.text.trim(),
        'last_name': _surnameController.text.trim(),
        'surname_at_birth': _surnameAtBirthController.text.trim(),
        'gender': _gender,
        'place_of_birth': _placeOfBirthController.text.trim(),
        'country_of_birth': _countryOfBirthController.text.trim(),
        if (_dateOfBirth != null)
          'date_of_birth': _dateOfBirth!.toIso8601String().split('T')[0],
        'citizenship': _citizenshipController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneNumberE164,

        // Passport Details
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

        // Professional/Academic
        'education_level': _educationController.text.trim(),
        'place_of_study': _placeOfStudyController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'job_title': _jobTitleController.text.trim(),
        'employer_name': _employerNameController.text.trim(),

        // Residential
        'home_address': _homeAddressController.text.trim(),
        'planned_residential_address':
            _plannedResidentialAddressController.text.trim(),

        // Photo
        if (photoUrl != null) 'photo_url': photoUrl,
        if (passportScanUrl != null) 'passport_scan_url': passportScanUrl,

        // Marital Status
        'marital_status': _maritalStatus == 'single' ? 'Single' : 'Married',

        // Unified relatives array
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

      // 4. Update visa application
      if (!mounted) return;
      final visaService = context.read<VisaService>();
      await visaService.updateMyVisa(
        participantId: widget.participantId,
        eventId: widget.eventId,
        data: formData,
      );

      // 5. Submit for review
      if (!mounted) return;
      await visaService.submitMyVisa(
        participantId: widget.participantId,
        eventId: widget.eventId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visa application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/events/${widget.eventId}/menu');
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg.contains('Participant profile not found')
                  ? 'Please register as a participant before submitting a visa application.'
                  : msg,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _primaryColor),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
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
                padding: const EdgeInsets.symmetric(horizontal: 32),
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Visa',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageTitle(),
                const SizedBox(height: 12),
                _buildSeparatorLine(),
                const SizedBox(height: 20),
                _buildAlertBanner(),
                const SizedBox(height: 24),
                _buildMainFormCard(),
                const SizedBox(height: 24),
                _buildMaritalStatusCard(),
                const SizedBox(height: 24),
                _buildConfirmationCheckbox(),
                const SizedBox(height: 24),
                _buildButtonRow(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP-LEVEL WIDGET BUILDERS
  // ---------------------------------------------------------------------------

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
    return Container(height: 0.5, color: const Color(0xFFCACACA));
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
              style: TextStyle(color: _alertTextColor, fontSize: 14, height: 1.4),
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
          BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset.zero),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildTwoColumnLayout();
          } else {
            return _buildSingleColumnLayout();
          }
        },
      ),
    );
  }

  Widget _buildMaritalStatusCard() {
    final isMarried = _maritalStatus == 'married';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset.zero),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Marital status: Are you married?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 16),
          // Yes / No toggle
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 38,
                child: ElevatedButton(
                  onPressed: () => setState(() => _maritalStatus = 'married'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMarried ? _greenColor : Colors.white,
                    foregroundColor: isMarried ? Colors.white : _greenColor,
                    side: BorderSide(color: _greenColor, width: isMarried ? 0 : 1.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Yes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 80,
                height: 38,
                child: ElevatedButton(
                  onPressed: () => setState(() => _maritalStatus = 'single'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isMarried ? Colors.white : Colors.white,
                    foregroundColor: !isMarried ? _redColor : Colors.grey,
                    side: BorderSide(color: !isMarried ? _redColor : _borderColor, width: 1.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('No', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
          if (isMarried) ...[
            const SizedBox(height: 16),
            // + Add button with relationship popup
            _buildAddRelativeButton(),
            const SizedBox(height: 16),
            ..._relatives.asMap().entries.map((entry) {
              return _buildRelativeSection(entry.key, entry.value);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAddRelativeButton() {
    return OutlinedButton.icon(
      onPressed: () => _showAddRelativePopup(),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Add'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: _borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showAddRelativePopup() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Wife', 'Husband', 'Daughter', 'Son'].map((type) {
                return ListTile(
                  dense: true,
                  title: Text(type, style: const TextStyle(fontSize: 14)),
                  trailing: Checkbox(
                    value: _relatives.any((r) => r['relationship'] == type),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _relatives.add(_createRelativeEntry(relationship: type));
                        } else {
                          final idx = _relatives.indexWhere((r) => r['relationship'] == type);
                          if (idx >= 0) _removeRelative(idx);
                        }
                      });
                      Navigator.of(ctx).pop();
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _relatives.add(_createRelativeEntry(relationship: type));
                    });
                    Navigator.of(ctx).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmationCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _confirmationChecked = !_confirmationChecked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SvgPicture.asset(
              _confirmationChecked
                  ? 'assets/visa_application/icons/check-square.svg'
                  : 'assets/visa_application/icons/square-unchecked.svg',
              width: 22,
              height: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'I confirm that all information provided is true and complete, and I understand that any incorrect information may result in my visa being denied',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 183,
          height: 43,
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 183,
          height: 43,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primaryColor.withAlpha(153),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
        if (_gender == 'Female')
          _buildFieldRow(
            left: _buildTextField('Surname at birth:', _surnameAtBirthController, 'Maiden name (if different)'),
            right: _buildCountryPickerField('Citizenship:', _citizenshipController, true),
          ),
        if (_gender != 'Female')
          _buildFieldRow(
            left: _buildCountryPickerField('Citizenship:', _citizenshipController, true),
            right: const SizedBox.shrink(),
          ),
        _buildBirthLocationPicker(),

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
            onChanged: (e164) => setState(() => _phoneNumberE164 = e164),
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
        _buildGenderDropdown(),
        if (_gender == 'Female')
          _buildTextField('Surname at birth:', _surnameAtBirthController, 'Maiden name (if different)'),
        _buildCountryPickerField('Citizenship:', _citizenshipController, true),
        _buildBirthLocationPicker(),
        _buildDateField('Date of birth:', null, _dateOfBirth, (date) {
          setState(() => _dateOfBirth = date);
        }, '1990-05-20'),
        _buildTextField('Email:', _emailController, 'john@example.com', true),
        PhoneInputField(
          initialPhone: _phoneNumberE164,
          labelText: 'Personal mobile number:',
          hintText: '61444555',
          onChanged: (e164) => setState(() => _phoneNumberE164 = e164),
        ),
        _buildPassportTypeDropdown(),
        _buildTextField('Passport number:', _passportNumberController, 'AB1234567', true),
        _buildDateField('Passport date issue:', null, _passportDateIssue, (date) {
          setState(() => _passportDateIssue = date);
        }, '2020-01-15'),
        _buildDateField('Passport validity period:', null, _passportExpiry, (date) {
          setState(() => _passportExpiry = date);
        }, '2030-01-15'),
        _buildCountryPickerField('Place of issue (country):', _passportIssuingCountryController),
        _buildTextField('Personal Address:', _homeAddressController, 'Street, Building, Apt', true),
        _buildTextField('Education:', _educationController, "Bachelor's Degree", true),
        _buildTextField('Speciality:', _specialtyController, 'Computer Science', true),
        _buildTextField('Place of work (Company name):', _employerNameController, 'Tech Corp'),
        _buildTextField('Position:', _jobTitleController, 'Software Engineer', true),
        _buildTextField('Place of education:', _placeOfStudyController, 'Harvard University', true),
        _buildTextField('Planned residential address:', _plannedResidentialAddressController, 'Address during stay'),
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
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
              validator: isRequired
                  ? (value) {
                      if (value == null || value.trim().isEmpty) return 'This field is required';
                      return null;
                    }
                  : null,
              decoration: _inputDecoration(hintText: hintText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Inter', color: Color(0xFF1E1E1E))),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: DropdownButtonFormField<String>(
              initialValue: _gender,
              isExpanded: true,
              icon: SvgPicture.asset('assets/visa_application/icons/chevron-down.svg', width: 18, height: 18),
              decoration: _inputDecoration(),
              hint: Text('Select gender', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              items: ['Male', 'Female'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => (v == null || v.isEmpty) ? 'This field is required' : null,
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
          const Text('Type of passport:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Inter', color: Color(0xFF1E1E1E))),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: DropdownButtonFormField<String>(
              initialValue: _typeOfPassport,
              isExpanded: true,
              icon: SvgPicture.asset('assets/visa_application/icons/chevron-down.svg', width: 18, height: 18),
              decoration: _inputDecoration(),
              hint: Text('Select passport type', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              items: _passportTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _typeOfPassport = v),
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
    final displayController = controller ?? TextEditingController();
    if (selectedDate != null && controller == null) {
      displayController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Inter', color: Color(0xFF1E1E1E))),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: TextFormField(
              controller: displayController,
              readOnly: true,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              onTap: () {
                selectDate(context, selectedDate, onDateSelected ?? (date) {
                  controller?.text = DateFormat('yyyy-MM-dd').format(date);
                });
              },
              decoration: _inputDecoration(
                hintText: hintText,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset('assets/visa_application/icons/calendar.svg', width: 18, height: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPickerDialog(TextEditingController controller, [VoidCallback? onSelected]) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = searchQuery.isEmpty
                ? _countries
                : _countries.where((c) => c.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            return AlertDialog(
              title: const Text('Select Country'),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (value) => setDialogState(() => searchQuery = value),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No countries found'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (ctx, index) {
                                final country = filtered[index];
                                final isSelected = controller.text == country;
                                return ListTile(
                                  dense: true,
                                  title: Text(country, style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? _primaryColor : null,
                                  )),
                                  trailing: isSelected ? const Icon(Icons.check, color: _primaryColor, size: 20) : null,
                                  onTap: () {
                                    controller.text = country;
                                    Navigator.of(ctx).pop();
                                    setState(() {});
                                    onSelected?.call();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel'))],
            );
          },
        );
      },
    );
  }

  Widget _buildCountryPickerField(String label, TextEditingController controller, [bool isRequired = false, VoidCallback? onSelected]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Inter', color: Color(0xFF1E1E1E))),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: TextFormField(
              controller: controller,
              readOnly: true,
              onTap: () => _showCountryPickerDialog(controller, onSelected),
              validator: isRequired ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null : null,
              decoration: _inputDecoration(
                hintText: 'Select country',
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset('assets/visa_application/icons/chevron-down.svg', width: 18, height: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCityPickerDialog() {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = searchQuery.isEmpty
                ? _availableCities
                : _availableCities.where((c) => c.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            return AlertDialog(
              title: const Text('Select City'),
              content: SizedBox(
                width: 340,
                height: 450,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search city...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (value) => setDialogState(() => searchQuery = value),
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
                                        _placeOfBirthController.text = searchQuery;
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
                                final isSelected = _placeOfBirthController.text == city;
                                return ListTile(
                                  dense: true,
                                  title: Text(city, style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? _primaryColor : null,
                                  )),
                                  trailing: isSelected ? const Icon(Icons.check, color: _primaryColor, size: 20) : null,
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
              actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel'))],
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
          const Text('Place of birth (City) *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Inter', color: Color(0xFF1E1E1E))),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: TextFormField(
              controller: _placeOfBirthController,
              readOnly: hasCities,
              onTap: hasCities ? () => _showCityPickerDialog() : null,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              decoration: _inputDecoration(
                hintText: hasCities ? 'Select city' : 'Enter city',
                suffixIcon: hasCities
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: SvgPicture.asset('assets/visa_application/icons/chevron-down.svg', width: 18, height: 18),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthLocationPicker() {
    return _buildFieldRow(
      left: _buildCountryPickerField('Country of birth *', _countryOfBirthController, true, () {
        _placeOfBirthController.clear();
        _loadCitiesForCountry(_countryOfBirthController.text);
      }),
      right: _buildCityPickerField(),
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
            hasImage: kIsWeb ? _photoBytes != null : _photoFile != null,
            imageWidget: _buildPortraitImage(),
            previewAsset: 'assets/visa_application/profile_preview.jpg',
            onUpload: _pickImage, onDelete: _deletePhoto,
          ),
          const SizedBox(width: 16),
          _buildPhotoBox(
            width: 216, height: 154, label: 'Passport scan',
            hasImage: kIsWeb ? _passportScanBytes != null : _passportScanFile != null,
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
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: SvgPicture.asset('assets/visa_application/icons/x-close.svg', width: 14, height: 14),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: width, height: 32,
          child: ElevatedButton(
            onPressed: onUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor, foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: Text(hasImage ? 'Change' : 'Upload', style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitImage() {
    if (kIsWeb && _photoBytes != null) return Image.memory(_photoBytes!, fit: BoxFit.cover);
    if (!kIsWeb && _photoFile != null) return Image.file(_photoFile!, fit: BoxFit.cover);
    return const SizedBox.shrink();
  }

  Widget _buildPassportScanImage() {
    if (kIsWeb && _passportScanBytes != null) return Image.memory(_passportScanBytes!, fit: BoxFit.cover);
    if (!kIsWeb && _passportScanFile != null) return Image.file(_passportScanFile!, fit: BoxFit.cover);
    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // RELATIVE SECTION
  // ---------------------------------------------------------------------------

  Widget _buildRelativeSection(int index, Map<String, dynamic> rel) {
    final relationship = rel['relationship'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: _borderColor), borderRadius: BorderRadius.circular(5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(relationship, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.close, color: _redColor, size: 20),
                onPressed: () => _removeRelative(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldRow(
            left: _buildTextField('Name:', rel['firstName'] as TextEditingController),
            right: _buildTextField('Surname:', rel['lastName'] as TextEditingController),
          ),
          _buildFieldRow(
            left: _buildTextField('Middle name:', rel['middleName'] as TextEditingController),
            right: _buildDateField('Date of birth:', null, rel['dateOfBirth'] as DateTime?, (date) {
              setState(() => rel['dateOfBirth'] = date);
            }),
          ),
          _buildFieldRow(
            left: _buildTextField('Surname at birth:', rel['surnameAtBirth'] as TextEditingController),
            right: _buildCountryPickerField('Citizenship:', rel['citizenship'] as TextEditingController),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED INPUT DECORATION (Figma style)
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: _borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: _borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      suffixIcon: suffixIcon,
    );
  }
}
