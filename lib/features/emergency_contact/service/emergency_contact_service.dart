import 'dart:convert';

import 'package:http/http.dart' as http;

class EmergencyContact {
  final int contactId;
  final String name;
  final String phone;

  const EmergencyContact({
    required this.contactId,
    required this.name,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      contactId: (json['contact_id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class EmergencyContactService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<List<EmergencyContact>> loadContacts(int userId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/users/$userId/emergency-contacts'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '비상 연락처 조회에 실패했습니다.');
    }

    final contacts = List<Map<String, dynamic>>.from(
      data['contacts'] as List? ?? const [],
    );
    return contacts.map(EmergencyContact.fromJson).toList();
  }

  static Future<void> createContact({
    required int userId,
    required String name,
    required String phone,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/users/$userId/emergency-contacts'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'name': name, 'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));
    _ensureSuccess(response, expectedStatus: 201);
  }

  static Future<void> updateContact({
    required int userId,
    required int contactId,
    required String name,
    required String phone,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/users/$userId/emergency-contacts/$contactId'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'name': name, 'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));
    _ensureSuccess(response);
  }

  static Future<void> deleteContact({
    required int userId,
    required int contactId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/users/$userId/emergency-contacts/$contactId'),
        )
        .timeout(const Duration(seconds: 10));
    _ensureSuccess(response);
  }

  static void _ensureSuccess(
    http.Response response, {
    int expectedStatus = 200,
  }) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != expectedStatus || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '요청 처리에 실패했습니다.');
    }
  }
}
