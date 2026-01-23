import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/visa_service.dart';

/// Visa Application Form Page matching Figma design
class VisaApplicationFormPage extends StatefulWidget {
  final int eventId;
  final String participantId;

  const VisaApplicationFormPage({
    super.key,
    required this.eventId,
    required this.participantId,
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
  final _placeOfBirthController = TextEditingController();
  final _citizenshipController = TextEditingController();
  final _passportSeriesController = TextEditingController();
  final _passportDateIssueController = TextEditingController();
  final _educationController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _placeOfStudyController = TextEditingController();
  final _jobTitleController = TextEditingController();

  // NEW: Missing backend fields
  final _homeCityController = TextEditingController();
  final _homeCountryController = TextEditingController();
  final _homePostalCodeController = TextEditingController();
  final _passportIssuingCountryController = TextEditingController();
  final _employerNameController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _passportDateIssue;
  DateTime? _passportExpiry; // Changed from text to date
  File? _photoFile;
  Uint8List? _photoBytes; // For web support

  // Submission state
  bool _isSubmitting = false;

  // Marital Status
  String _maritalStatus = 'single'; // 'single' or 'married'
  final _spouseFullNameController = TextEditingController();
  String _spouseRelationship = 'Wife';
  final _spousePlaceOfBirthController = TextEditingController();
  DateTime? _spouseDateOfBirth;
  final _spouseCitizenshipController = TextEditingController();

  // Children
  final List<Map<String, dynamic>> _children = [];

  bool _confirmationChecked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _placeOfBirthController.dispose();
    _citizenshipController.dispose();
    _passportSeriesController.dispose();
    _passportDateIssueController.dispose();
    _educationController.dispose();
    _specialtyController.dispose();
    _homeAddressController.dispose();
    _phoneNumberController.dispose();
    _passportNumberController.dispose();
    _passportDateIssueController.dispose();
    _placeOfStudyController.dispose();
    _jobTitleController.dispose();
    _homeCityController.dispose();
    _homeCountryController.dispose();
    _homePostalCodeController.dispose();
    _passportIssuingCountryController.dispose();
    _employerNameController.dispose();
    _spouseFullNameController.dispose();
    _spousePlaceOfBirthController.dispose();
    _spouseCitizenshipController.dispose();
    _spouseCitizenshipController.dispose();
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

      final visaService = context.read<VisaService>();
      final visa = await visaService.getMyVisa(widget.participantId);

      if (!mounted) return;

      // Check status immediately
      final status = visa['status'] as String? ?? 'NOT_STARTED';

      // If status is not FILL_OUT or NOT_STARTED or DECLINED, we should not be here
      // Redirect to status or details page
      if (status == 'PENDING') {
        if (mounted) {
          context.replace(
            '/events/${widget.eventId}/visa/status/${widget.participantId}',
          );
        }
        return;
      }

      if (status == 'APPROVED' ||
          status == 'DECLINED' && visa['decline_reason'] == null) {
        // Note: DECLINED usually allows retry, but if we treat it as read-only for now:
        // For now, allow DECLINED to be edited.
        if (status == 'APPROVED') {
          if (mounted) {
            context.replace(
              '/events/${widget.eventId}/visa/details/${widget.participantId}',
            );
          }
          return;
        }
      }

      // Pre-fill form data
      _citizenshipController.text = visa['citizenship'] ?? '';
      _placeOfBirthController.text = visa['place_of_birth'] ?? '';
      if (visa['date_of_birth'] != null) {
        _dateOfBirth = DateTime.parse(visa['date_of_birth']);
      }
      _phoneNumberController.text = visa['phone_number'] ?? '';

      _passportSeriesController.text = visa['passport_series'] ?? '';
      _passportNumberController.text = visa['passport_number'] ?? '';
      if (visa['passport_date_of_issue'] != null) {
        _passportDateIssue = DateTime.parse(visa['passport_date_of_issue']);
      }
      if (visa['passport_expiry'] != null) {
        _passportExpiry = DateTime.parse(visa['passport_expiry']);
      }
      _passportIssuingCountryController.text =
          visa['passport_issuing_country'] ?? '';

      _educationController.text = visa['education_level'] ?? '';
      _placeOfStudyController.text = visa['place_of_study'] ?? '';
      _specialtyController.text = visa['specialty'] ?? '';
      _jobTitleController.text = visa['job_title'] ?? '';
      _employerNameController.text = visa['employer_name'] ?? '';

      _homeAddressController.text = visa['home_address'] ?? '';
      _homeCityController.text = visa['home_city'] ?? '';
      _homeCountryController.text = visa['home_country'] ?? '';
      _homePostalCodeController.text = visa['home_postal_code'] ?? '';

      // Marital Status
      if (visa['marital_status'] != null) {
        _maritalStatus = (visa['marital_status'] as String).toLowerCase();
      }

      if (_maritalStatus == 'married') {
        _spouseFullNameController.text =
            '${visa['spouse_first_name'] ?? ''} ${visa['spouse_last_name'] ?? ''}'
                .trim();
        _spouseRelationship = visa['spouse_relationship'] ?? 'Wife';
        _spousePlaceOfBirthController.text =
            visa['spouse_place_of_birth'] ?? '';
        if (visa['spouse_date_of_birth'] != null) {
          _spouseDateOfBirth = DateTime.parse(visa['spouse_date_of_birth']);
        }
        _spouseCitizenshipController.text = visa['spouse_citizenship'] ?? '';
      }

      // Children
      final childrenList = visa['children'] as List<dynamic>?;
      if (childrenList != null) {
        for (var child in childrenList) {
          _children.add({
            'fullName': TextEditingController(
              text: '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}'
                  .trim(),
            ),
            'placeOfBirth': TextEditingController(
              text: child['place_of_birth'] ?? '',
            ),
            'citizenship': TextEditingController(
              text: child['citizenship'] ?? '',
            ),
            'dateOfBirth': child['date_of_birth'] != null
                ? DateTime.parse(child['date_of_birth'])
                : null,
          });
        }
      }

      // Photo
      // Note: We don't display the photo URL in the file picker, but we could show a preview if exists?
      // Currently the UI doesn't clearly support showing existing remote photo, but we can add that later.

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

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      if (kIsWeb) {
        // For web, read as bytes
        final bytes = await image.readAsBytes();
        setState(() {
          _photoBytes = bytes;
        });
      } else {
        // For mobile, use file
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

  void addChild() {
    setState(() {
      _children.add({
        'fullName': TextEditingController(),
        'relationship': 'Son',
        'placeOfBirth': TextEditingController(),
        'dateOfBirth': null,
        'citizenship': TextEditingController(),
      });
    });
  }

  void removeChild(int index) {
    setState(() {
      _children[index]['fullName'].dispose();
      _children[index]['placeOfBirth'].dispose();
      _children[index]['citizenship'].dispose();
      _children.removeAt(index);
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

      // 2. Prepare data for backend
      if (!mounted) return;

      // Split spouse name
      final spouseFullName = _spouseFullNameController.text.trim();
      final spouseNameParts = spouseFullName.split(' ');
      final spouseFirstName = spouseNameParts.isNotEmpty
          ? spouseNameParts.first
          : '';
      final spouseLastName = spouseNameParts.length > 1
          ? spouseNameParts.sublist(1).join(' ')
          : '';

      final formData = <String, dynamic>{
        // Personal Information
        'place_of_birth': _placeOfBirthController.text.trim(),
        if (_dateOfBirth != null)
          'date_of_birth': _dateOfBirth!.toIso8601String().split('T')[0],
        'citizenship': _citizenshipController.text.trim(),
        'phone_number': _phoneNumberController.text.trim(),

        // Passport Details
        'passport_series': _passportSeriesController.text.trim(),
        'passport_number': _passportNumberController.text.trim(),
        if (_passportDateIssue != null)
          'passport_date_of_issue': _passportDateIssue!.toIso8601String().split(
            'T',
          )[0],
        if (_passportExpiry != null)
          'passport_expiry': _passportExpiry!.toIso8601String().split('T')[0],
        'passport_issuing_country': _passportIssuingCountryController.text
            .trim(),

        // Professional/Academic
        'education_level': _educationController.text.trim(),
        'place_of_study': _placeOfStudyController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'job_title': _jobTitleController.text.trim(),
        'employer_name': _employerNameController.text.trim(),

        // Residential
        'home_address': _homeAddressController.text.trim(),
        'home_city': _homeCityController.text.trim(),
        'home_country': _homeCountryController.text.trim(),
        'home_postal_code': _homePostalCodeController.text.trim(),

        // Photo
        if (photoUrl != null) 'photo_url': photoUrl,

        // Marital Status (capitalize)
        'marital_status': _maritalStatus == 'single' ? 'Single' : 'Married',

        if (_maritalStatus == 'married') ...{
          'spouse_first_name': spouseFirstName,
          'spouse_last_name': spouseLastName,
          'spouse_relationship': _spouseRelationship,
          'spouse_place_of_birth': _spousePlaceOfBirthController.text.trim(),
          if (_spouseDateOfBirth != null)
            'spouse_date_of_birth': _spouseDateOfBirth!.toIso8601String().split(
              'T',
            )[0],
          'spouse_citizenship': _spouseCitizenshipController.text.trim(),
        },

        // Children
        'children': _children.map((child) {
          final childFullName = child['fullName'].text.trim();
          final childNameParts = childFullName.split(' ');
          return {
            'first_name': childNameParts.isNotEmpty ? childNameParts.first : '',
            'last_name': childNameParts.length > 1
                ? childNameParts.sublist(1).join(' ')
                : '',
            'place_of_birth': child['placeOfBirth'].text.trim(),
            if (child['dateOfBirth'] != null)
              'date_of_birth': child['dateOfBirth'].toIso8601String().split(
                'T',
              )[0],
            'citizenship': child['citizenship'].text.trim(),
          };
        }).toList(),
      };

      // 3. Update visa application
      if (!mounted) return;
      final visaService = context.read<VisaService>();
      await visaService.updateMyVisa(
        participantId: widget.participantId,
        data: formData,
      );

      // 4. Submit for review
      if (!mounted) return;
      await visaService.submitMyVisa(widget.participantId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visa application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
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
    // Show loading indicator while fetching visa data
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF3C4494),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Show error screen if loading failed
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

    // Main form UI
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

                  // Personal Information Section
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      if (isWide) {
                        return buildTwoColumnLayout();
                      } else {
                        return buildSingleColumnLayout();
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

                  // Marital Status Selector
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              setState(() => _maritalStatus = 'single'),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'single',
                                groupValue: _maritalStatus,
                                onChanged: (value) {
                                  setState(() => _maritalStatus = value!);
                                },
                              ),
                              const Text('Single'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              setState(() => _maritalStatus = 'married'),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'married',
                                groupValue: _maritalStatus,
                                onChanged: (value) {
                                  setState(() => _maritalStatus = value!);
                                },
                              ),
                              const Text('Married'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Show spouse fields only if married
                  if (_maritalStatus == 'married') buildMaritalStatusSection(),

                  const SizedBox(height: 32),

                  // Children Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Children:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_box_outlined),
                        onPressed: addChild,
                        color: const Color(0xFF3C4494),
                      ),
                    ],
                  ),
                  ..._children.asMap().entries.map((entry) {
                    return buildChildSection(entry.key, entry.value);
                  }),

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

  Widget buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: Column(
            children: [
              buildTextField('Name:', _nameController),
              buildTextField('Surname:', _surnameController),
              buildTextField('Place of birth:', _placeOfBirthController),
              buildTextField('Citizenship:', _citizenshipController),
              buildTextField('Passport series:', _passportSeriesController),
              buildDateField(
                'Passport date issue:',
                _passportDateIssueController,
                null,
              ),
              buildTextField('Education:', _educationController),
              buildTextField('Speciality:', _specialtyController),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column
        Expanded(
          child: Column(
            children: [
              // Photo Upload (compact, aligned with Name + Surname)
              buildPhotoUpload(),
              buildDateField('Date of birth:', null, _dateOfBirth, (date) {
                setState(() => _dateOfBirth = date);
              }),
              buildTextField('Phone number:', _phoneNumberController),
              buildTextField('Passport number:', _passportNumberController),
              buildDateField(
                'Passport validity period:',
                null,
                _passportExpiry,
                (date) {
                  setState(() => _passportExpiry = date);
                },
              ),
              buildTextField('Place of study:', _placeOfStudyController),
              buildTextField('Job title:', _jobTitleController),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSingleColumnLayout() {
    return Column(
      children: [
        buildPhotoUpload(),
        buildTextField('Name:', _nameController),
        buildTextField('Surname:', _surnameController),
        buildTextField('Place of Birth:', _placeOfBirthController),
        buildDateField('Date of birth:', null, _dateOfBirth, (date) {
          setState(() => _dateOfBirth = date);
        }),
        buildTextField('Citizenship:', _citizenshipController),
        buildTextField('Phone number:', _phoneNumberController),
        buildTextField('Passport series:', _passportSeriesController),
        buildTextField('Passport number:', _passportNumberController),
        buildDateField(
          'Passport date issue:',
          _passportDateIssueController,
          null,
        ),
        buildTextField('Citizenship:', _citizenshipController),
        buildTextField('Phone number:', _phoneNumberController),
        buildTextField('Passport series:', _passportSeriesController),
        buildTextField('Passport number:', _passportNumberController),
        buildDateField('Passport date issue:', null, _passportDateIssue, (
          date,
        ) {
          setState(() => _passportDateIssue = date);
        }),
        buildDateField('Passport expiry:', null, _passportExpiry, (date) {
          setState(() => _passportExpiry = date);
        }),
        buildTextField(
          'Passport issuing country:',
          _passportIssuingCountryController,
        ),
        buildTextField('Education:', _educationController),
        buildTextField('Place of study:', _placeOfStudyController),
        buildTextField('Specialty:', _specialtyController),
        buildTextField('Job title:', _jobTitleController),
        buildTextField('Employer name:', _employerNameController),
        buildTextField('Home address:', _homeAddressController),
        buildTextField('Home city:', _homeCityController),
        buildTextField('Home country:', _homeCountryController),
        buildTextField('Home postal code:', _homePostalCodeController),
      ],
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
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
          ),
        ],
      ),
    );
  }

  Widget buildDateField(
    String label,
    TextEditingController? controller,
    DateTime? selectedDate, [
    Function(DateTime)? onDateSelected,
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
              hintText: selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(selectedDate)
                  : '',
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhotoUpload() {
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
              // Compact square photo preview with blue border
              Container(
                width: 120,
                height: 144, // 5:6 aspect ratio
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
              // Upload button
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

  Widget buildMaritalStatusSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildTextField('Full name:', _spouseFullNameController),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                        value: _spouseRelationship,
                        isExpanded: true,
                        items: ['Wife', 'Husband'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _spouseRelationship = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: buildTextField(
                'Place of birth:',
                _spousePlaceOfBirthController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildDateField(
                'Date of birth:',
                null,
                _spouseDateOfBirth,
                (date) {
                  setState(() => _spouseDateOfBirth = date);
                },
              ),
            ),
          ],
        ),
        buildTextField('Citizenship:', _spouseCitizenshipController),
      ],
    );
  }

  Widget buildChildSection(int index, Map<String, dynamic> child) {
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
                'Child ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => removeChild(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: buildTextField('Full name:', child['fullName'])),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Relationship:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
                          value: child['relationship'],
                          isExpanded: true,
                          items: ['Son', 'Daughter'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              child['relationship'] = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: buildTextField('Place of birth:', child['placeOfBirth']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildDateField(
                  'Date of birth:',
                  null,
                  child['dateOfBirth'],
                  (date) {
                    setState(() => child['dateOfBirth'] = date);
                  },
                ),
              ),
            ],
          ),
          buildTextField('Citizenship:', child['citizenship']),
        ],
      ),
    );
  }
}
