import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/phone_input_field.dart';
import '../../../core/widgets/website_input_field.dart';
import '../../auth/services/auth_service.dart';

/// Add Participant Form Page (Figma Design)
/// Left: Photo upload (5:6 ratio) with preview
/// Right: Profile fields (all required)
class AddParticipantFormPage extends StatefulWidget {
  final int eventId;

  const AddParticipantFormPage({super.key, required this.eventId});

  @override
  State<AddParticipantFormPage> createState() => _AddParticipantFormPageState();
}

class _AddParticipantFormPageState extends State<AddParticipantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  String _mobileE164 = ''; // Store phone in E.164 format
  final String _websiteUrl = ''; // Store website in https:// format
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    // _mobileE164 is a String, no need to dispose
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1440, // 5:6 ratio
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return null;

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
          _imageBytes!,
          filename: _imageName ?? 'participant_photo.jpg',
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
            content: Text('Image upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload image first if selected
      String? photoUrl;
      if (_imageBytes != null) {
        photoUrl = await _uploadImage();
        if (photoUrl == null) {
          // Upload failed, abort submission
          setState(() => _isSubmitting = false);
          return;
        }
      }

      if (!mounted) return;

      final authService = context.read<AuthService>();
      final token = await authService.getToken();

      final body = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'company_name': _companyController.text.trim(),
        'mobile': _mobileE164, // E.164 format: +99362436999
        if (photoUrl != null)
          'profile_photo_url': photoUrl, // ✅ Include photo URL
      };

      final response = await http.post(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/participants/?event_id=${widget.eventId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          AppSnackBar.showSuccess(context, 'Participant added successfully!');
          context.go('/events/${widget.eventId}/my-participants');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Failed to add participant';

        // Log full error for debugging
        // Log full error for debugging
        // debugPrint('Participant creation error: ${response.statusCode}');
        // debugPrint('Error body: ${response.body}');

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
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
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFF1F1F6),
                      size: 32,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Participant',
                    style: TextStyle(
                      color: Color(0xFFF1F1F6),
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(50, 20, 50, 50),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Side - Photo Upload
                        Column(
                          children: [
                            // Photo preview/placeholder (5:6 ratio = 300x351)
                            Container(
                              width: 300,
                              height: 351,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9CA4CC),
                                borderRadius: BorderRadius.circular(10),
                                image: _imageBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(_imageBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _imageBytes == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 120,
                                      color: Color(0xFFF1F1F6),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 15),
                            // Upload button
                            SizedBox(
                              width: 300,
                              height: 69,
                              child: ElevatedButton(
                                onPressed: _pickImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9CA4CC),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  _imageBytes == null
                                      ? 'Upload Photo (5:6)'
                                      : 'Change Photo',
                                  style: const TextStyle(
                                    color: Color(0xFFF1F1F6),
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 45),

                        // Right Side - Form
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with Save button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Profile Information',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      OutlinedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : _submitForm,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF008000,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF008000),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF008000),
                                                    ),
                                              )
                                            : const Text(
                                                'Save',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),

                                  // Row 1: First Name & Last Name
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _firstNameController,
                                          label: 'Name: *',
                                          validator: (v) =>
                                              v?.trim().isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 22),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _lastNameController,
                                          label: 'Surname: *',
                                          validator: (v) =>
                                              v?.trim().isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),

                                  // Row 2: Email (full width)
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email: *',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v?.trim().isEmpty ?? true) {
                                        return 'Required';
                                      }
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(v!)) {
                                        return 'Invalid email';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 30),

                                  // Row 3: Company Name & Mobile Number
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _companyController,
                                          label: 'Company Name: *',
                                          validator: (v) =>
                                              v?.trim().isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 22),
                                      Expanded(
                                        child: PhoneInputField(
                                          labelText: 'Mobile Number: *',
                                          hintText: '62436999',
                                          required: true,
                                          onChanged: (e164) {
                                            setState(() => _mobileE164 = e164);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),
                                ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Color(0xFFB7B7B7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Color(0xFFB7B7B7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Color(0xFF3C4494), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
