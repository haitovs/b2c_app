import 'dart:convert';

import 'package:http/http.dart' as http;

class NotificationService {
  final String baseUrl = 'http://localhost:8000/api/v1';

  Future<List<dynamic>> getNotifications() async {
    // TODO: Add auth token header
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching notifications: $e");
      return [];
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await http.patch(Uri.parse('$baseUrl/notifications/$id/read'));
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }
}
