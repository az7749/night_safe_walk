import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminManagementService {
  static const _baseUrl = 'http://10.0.2.2:5000';

  static Future<Map<String, dynamic>> load(
    String resource,
    int adminId, {
    String query = '',
    int page = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/admin/$resource').replace(
      queryParameters: {
        'admin_user_id': '$adminId',
        'query': query,
        'page': '$page',
      },
    );
    return _decode(await http.get(uri).timeout(const Duration(seconds: 15)));
  }

  static Future<void> save(
    String resource,
    int adminId,
    int id,
    Map<String, dynamic> fields,
  ) async {
    _decode(
      await http
          .patch(
            Uri.parse('$_baseUrl/admin/$resource/$id'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({...fields, 'admin_user_id': adminId}),
          )
          .timeout(const Duration(seconds: 15)),
    );
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? '요청을 처리하지 못했습니다.');
    }
    return data;
  }
}
