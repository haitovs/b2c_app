import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'token_provider.dart';

/// Shared file upload service.
///
/// Sends files to `POST /api/v1/files/upload` as multipart form data.
/// Supports both web (Uint8List) and mobile (dart:io File) via [dynamic].
class UploadService {
  final TokenProvider _tokenProvider;

  UploadService(this._tokenProvider);

  /// Upload a file and return the URL assigned by the server.
  ///
  /// [fileData] — `Uint8List` on web, `File` on mobile.
  /// [folder]   — server-side folder hint (e.g. `company-branding`).
  /// [filename] — optional explicit filename; a timestamp-based default is used
  ///              when omitted.
  Future<String> uploadFile({
    required dynamic fileData,
    String folder = 'general',
    String? filename,
  }) async {
    final token = await _tokenProvider.getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/files/upload'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['folder'] = folder;

    final resolvedFilename =
        filename ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (kIsWeb && fileData is Uint8List) {
      request.files.add(
        http.MultipartFile.fromBytes('file', fileData, filename: resolvedFilename),
      );
    } else if (!kIsWeb) {
      // On mobile/desktop, fileData should be a dart:io File.
      // We avoid importing dart:io at the top level so the file compiles on web.
      final bytes = fileData is Uint8List
          ? fileData
          : await _readFileBytes(fileData);
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: resolvedFilename),
      );
    } else {
      throw Exception('Invalid file data type: ${fileData.runtimeType}');
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseData) as Map<String, dynamic>;
      return data['url'] as String;
    }

    throw Exception('Upload failed (${response.statusCode}): $responseData');
  }

  /// Read bytes from a dart:io File without a direct import.
  Future<Uint8List> _readFileBytes(dynamic file) async {
    // file is expected to be a dart:io File
    final bytes = await (file as dynamic).readAsBytes();
    return bytes as Uint8List;
  }
}
