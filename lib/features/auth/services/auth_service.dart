import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // TODO: Replace with actual backend URL
  final String baseUrl = 'http://localhost:8000/api/v1';

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // TODO: Save token
        print("Login success: ${data['access_token']}");
        return true;
      } else {
        print("Login failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }
}
