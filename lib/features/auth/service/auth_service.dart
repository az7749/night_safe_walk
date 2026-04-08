import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  static Future<Map<String, dynamic>> checkUserId({
    required String userid,
  }) async {
    final url = Uri.parse('$baseUrl/check-userid');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_id': userid}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> signUp({
    required String userid,
    required String name,
    required String phone,
    required String birth,
    required String gender,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/signup');

    final response = await http.post(
      url,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'login_id': userid,
        'name': name,
        'phone': phone,
        'birth_date': birth,
        'gender': gender,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String userid,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'login_id': userid, 'password': password}),
    );
    return jsonDecode(response.body);
  }
}
