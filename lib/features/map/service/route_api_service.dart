import 'dart:convert';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;

class RouteApiService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<List<NLatLng>> loadRoute({
    required NLatLng start,
    required NLatLng destination,
    required String mode,
  }) async {
    final uri = Uri.parse('$_baseUrl/route').replace(
      queryParameters: {
        's_lat': start.latitude.toString(),
        's_lng': start.longitude.toString(),
        'e_lat': destination.latitude.toString(),
        'e_lng': destination.longitude.toString(),
        'mode': mode,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '경로를 찾을 수 없습니다.');
    }

    final path = List<Map<String, dynamic>>.from(data['path']);

    return path
        .map(
          (point) => NLatLng(
            (point['lat'] as num).toDouble(),
            (point['lng'] as num).toDouble(),
          ),
        )
        .toList();
  }
}
