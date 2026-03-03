import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/phone_input_field.dart';
import '../../auth/services/auth_service.dart';
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

  // Photo
  File? _photoFile;
  Uint8List? _photoBytes;

  // Submission state
  bool _isSubmitting = false;

  // Marital Status & Relatives
  String _maritalStatus = 'single'; // 'single' or 'married'
  final List<Map<String, dynamic>> _relatives = [];

  bool _confirmationChecked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
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
      (rel['fatherName'] as TextEditingController).dispose();
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

      if (widget.participantId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final visaService = context.read<VisaService>();
      Map<String, dynamic> visa;
      try {
        visa = await visaService.getMyVisa(widget.participantId!);
      } catch (_) {
        // No existing visa — show empty form
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      final status = visa['status'] as String? ?? 'NOT_STARTED';

      if (status == 'PENDING') {
        if (mounted) {
          context.replace(
            '/events/${widget.eventId}/visa/status/${widget.participantId!}',
          );
        }
        return;
      }

      if (status == 'APPROVED') {
        if (mounted) {
          context.replace(
            '/events/${widget.eventId}/visa/details/${widget.participantId!}',
          );
        }
        return;
      }

      // Pre-fill form data
      _nameController.text = visa['first_name'] ?? '';
      _surnameController.text = visa['last_name'] ?? '';
      _surnameAtBirthController.text = visa['surname_at_birth'] ?? '';
      _gender = visa['gender'];
      _placeOfBirthController.text = visa['place_of_birth'] ?? '';
      _countryOfBirthController.text = visa['country_of_birth'] ?? '';
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
            fatherName: rel['father_name'] ?? '',
            middleName: rel['middle_name'] ?? '',
            surnameAtBirth: rel['surname_at_birth'] ?? '',
            citizenship: rel['citizenship'] ?? '',
            dateOfBirth: rel['date_of_birth'] != null
                ? DateTime.parse(rel['date_of_birth'])
                : null,
          ));
        }
      } else if (_maritalStatus == 'married') {
        // Fallback: construct from legacy spouse fields
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
        // Fallback: construct from legacy children
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
    String fatherName = '',
    String middleName = '',
    String surnameAtBirth = '',
    String citizenship = '',
    DateTime? dateOfBirth,
  }) {
    return {
      'relationship': relationship,
      'firstName': TextEditingController(text: firstName),
      'lastName': TextEditingController(text: lastName),
      'fatherName': TextEditingController(text: fatherName),
      'middleName': TextEditingController(text: middleName),
      'surnameAtBirth': TextEditingController(text: surnameAtBirth),
      'citizenship': TextEditingController(text: citizenship),
      'dateOfBirth': dateOfBirth,
    };
  }

  Future<void> _prefillFromParticipant() async {
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
    setState(() {
      _relatives.add(_createRelativeEntry());
    });
  }

  void _removeRelative(int index) {
    setState(() {
      final rel = _relatives[index];
      (rel['firstName'] as TextEditingController).dispose();
      (rel['lastName'] as TextEditingController).dispose();
      (rel['fatherName'] as TextEditingController).dispose();
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
          participantId: widget.participantId ?? 'self',
          photoData: kIsWeb ? _photoBytes : _photoFile,
        );
      }

      // 2. Prepare data
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

        // Marital Status
        'marital_status': _maritalStatus == 'single' ? 'Single' : 'Married',

        // Unified relatives array
        'relatives': _relatives.map((rel) {
          return {
            'relationship': rel['relationship'],
            'first_name': (rel['firstName'] as TextEditingController).text.trim(),
            'last_name': (rel['lastName'] as TextEditingController).text.trim(),
            'father_name':
                (rel['fatherName'] as TextEditingController).text.trim(),
            'middle_name':
                (rel['middleName'] as TextEditingController).text.trim(),
            'surname_at_birth':
                (rel['surnameAtBirth'] as TextEditingController).text.trim(),
            'citizenship':
                (rel['citizenship'] as TextEditingController).text.trim(),
            if (rel['dateOfBirth'] != null)
              'date_of_birth':
                  (rel['dateOfBirth'] as DateTime).toIso8601String().split('T')[0],
          };
        }).toList(),
      };

      // 3. Update visa application
      if (!mounted) return;
      final visaService = context.read<VisaService>();
      await visaService.updateMyVisa(
        participantId: widget.participantId ?? 'self',
        data: formData,
      );

      // 4. Submit for review
      if (!mounted) return;
      await visaService.submitMyVisa(widget.participantId ?? 'self');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visa application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF3C4494),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF3C4494),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3C4494),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white70),
              const SizedBox(height: 16),
              const Text(
                'Error loading visa application',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadVisaData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C4494),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => context.go('/events/${widget.eventId}/menu'),
        ),
        title: const Text(
          'Visa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  Text(
                    'My participants > Visa',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'VISA APPLICATION FORM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alert Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFEF5350)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Color(0xFFD32F2F),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'If the application form is not completed correctly or required information is missing, there is a risk that the visa may be denied.',
                            style: TextStyle(
                              color: Colors.red[900],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      if (isWide) {
                        return _buildTwoColumnLayout();
                      } else {
                        return _buildSingleColumnLayout();
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // Marital Status Section
                  const Text(
                    'MARITAL STATUS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Yes/No Toggle
                  RadioGroup<String>(
                    groupValue: _maritalStatus,
                    onChanged: (value) {
                      setState(() => _maritalStatus = value!);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _maritalStatus = 'single'),
                            child: const Row(
                              children: [
                                Radio<String>(value: 'single'),
                                Text('No'),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _maritalStatus = 'married'),
                            child: const Row(
                              children: [
                                Radio<String>(value: 'married'),
                                Text('Yes'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Relatives section (shown when married)
                  if (_maritalStatus == 'married') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Relatives:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addRelative,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3C4494),
                          ),
                        ),
                      ],
                    ),
                    ..._relatives.asMap().entries.map((entry) {
                      return _buildRelativeSection(entry.key, entry.value);
                    }),
                  ],

                  const SizedBox(height: 32),

                  // Confirmation Checkbox
                  CheckboxListTile(
                    value: _confirmationChecked,
                    onChanged: (value) {
                      setState(() {
                        _confirmationChecked = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I confirm that all information provided is true and complete, and I understand that any incorrect information may result in my visa being denied',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9FA8DA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return Column(
      children: [
        // Section 1: Personal Information
        _buildSectionHeader('Şahsy maglumatlar / Personal Information'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildTextField('Name:', _nameController, 'John', true),
                  _buildTextField('Surname:', _surnameController, 'Smith', true),
                  _buildGenderDropdown(),
                  _buildTextField(
                    'Surname at birth:',
                    _surnameAtBirthController,
                    'Maiden name (if different)',
                  ),
                  _buildCountryPickerField(
                    'Country of birth:',
                    _countryOfBirthController,
                    true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildPhotoUpload(),
                  _buildDateField('Date of birth:', null, _dateOfBirth, (date) {
                    setState(() => _dateOfBirth = date);
                  }, '1990-05-20'),
                  _buildCountryPickerField(
                    'Citizenship:',
                    _citizenshipController,
                    true,
                  ),
                  _buildTextField(
                    'Place of birth (City):',
                    _placeOfBirthController,
                    'New York',
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Section 2: Passport Details
        _buildSectionHeader('Passport maglumatlary / Passport Details'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildPassportTypeDropdown(),
                  _buildDateField(
                    'Passport date issue:',
                    null,
                    _passportDateIssue,
                    (date) {
                      setState(() => _passportDateIssue = date);
                    },
                    '2020-01-15',
                  ),
                  _buildCountryPickerField(
                    'Place of issue (country):',
                    _passportIssuingCountryController,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildTextField(
                    'Passport number:',
                    _passportNumberController,
                    'AB1234567',
                    true,
                  ),
                  _buildDateField(
                    'Passport validity period:',
                    null,
                    _passportExpiry,
                    (date) {
                      setState(() => _passportExpiry = date);
                    },
                    '2030-01-15',
                  ),
                  _buildTextField(
                    'Personal Address:',
                    _homeAddressController,
                    'Street, Building, Apt',
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Email (full width)
        _buildTextField('Email:', _emailController, 'john@example.com', true),

        // Section 3: Professional & Academic
        _buildSectionHeader('Hünär we bilim / Professional & Academic'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildTextField(
                    'Education:',
                    _educationController,
                    "Bachelor's Degree",
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
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildTextField(
                    'Speciality:',
                    _specialtyController,
                    'Computer Science',
                    true,
                  ),
                  PhoneInputField(
                    initialPhone: _phoneNumberE164,
                    labelText: 'Personal mobile number:',
                    hintText: '61444555',
                    onChanged: (e164) {
                      setState(() => _phoneNumberE164 = e164);
                    },
                  ),
                  _buildTextField(
                    'Place of education:',
                    _placeOfStudyController,
                    'Harvard University',
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Planned residential address (full width)
        _buildTextField(
          'Planned residential address:',
          _plannedResidentialAddressController,
          'Address during stay',
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    return Column(
      children: [
        _buildPhotoUpload(),
        _buildSectionHeader('Şahsy maglumatlar / Personal Information'),
        _buildTextField('Name:', _nameController, 'John', true),
        _buildTextField('Surname:', _surnameController, 'Smith', true),
        _buildGenderDropdown(),
        _buildTextField(
          'Surname at birth:',
          _surnameAtBirthController,
          'Maiden name (if different)',
        ),
        _buildCountryPickerField(
          'Country of birth:',
          _countryOfBirthController,
          true,
        ),
        _buildTextField(
          'Place of birth (City):',
          _placeOfBirthController,
          'New York',
          true,
        ),
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
        _buildSectionHeader('Passport maglumatlary / Passport Details'),
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
        _buildSectionHeader('Hünär we bilim / Professional & Academic'),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E1E1E),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, [
    String? hintText,
    bool isRequired = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  }
                : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
          const Text(
            'Gender:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
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
        ],
      ),
    );
  }

  void _showCountryPickerDialog(TextEditingController controller) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = searchQuery.isEmpty
                ? _countries
                : _countries
                    .where((c) =>
                        c.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();
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
                                          ? const Color(0xFF3C4494)
                                          : null,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check,
                                          color: Color(0xFF3C4494), size: 20)
                                      : null,
                                  onTap: () {
                                    controller.text = country;
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

  Widget _buildCountryPickerField(
    String label,
    TextEditingController controller, [
    bool isRequired = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: () => _showCountryPickerDialog(controller),
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  }
                : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              hintText: 'Select country',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              suffixIcon: const Icon(Icons.arrow_drop_down),
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _typeOfPassport,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: displayController,
            readOnly: true,
            style: const TextStyle(color: Colors.black, fontSize: 14),
            onTap: () {
              selectDate(
                context,
                selectedDate,
                onDateSelected ??
                    (date) {
                      controller?.text = DateFormat('yyyy-MM-dd').format(date);
                    },
              );
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
              hintText: hintText ?? '',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUpload() {
    final hasImage = kIsWeb ? _photoBytes != null : _photoFile != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Picture (5:6):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 144,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasImage
                        ? const Color(0xFF3C4494)
                        : Colors.grey[300]!,
                    width: hasImage ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey[50],
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: kIsWeb
                            ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                            : Image.file(_photoFile!, fit: BoxFit.cover),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'visa_application/visa_example.jpg',
                            fit: BoxFit.cover,
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: Colors.red,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: const Text(
                                'EXAMPLE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: _pickImage,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Upload files',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3C4494),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or drag a files here',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelativeSection(int index, Map<String, dynamic> rel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Relative ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFE8EAF6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: rel['relationship'] as String,
                      isExpanded: true,
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

          // Father's name & Middle name row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "Father's name:",
                  rel['fatherName'] as TextEditingController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Middle name:',
                  rel['middleName'] as TextEditingController,
                ),
              ),
            ],
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
          _buildTextField(
            'Citizenship:',
            rel['citizenship'] as TextEditingController,
          ),
        ],
      ),
    );
  }
}
