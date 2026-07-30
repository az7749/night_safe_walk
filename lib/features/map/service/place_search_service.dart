import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceSearchService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final uri = Uri.parse('$_baseUrl/search/places').replace(
      queryParameters: {
        'query': query,
        'display': '7',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '검색 결과가 없습니다.');
    }

    return List<Map<String, dynamic>>.from(data['places']);
  }
}
