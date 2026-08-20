import 'dart:convert';

import 'package:http/http.dart' as http;

class FavoritePlace {
  final int favoriteId;
  final String alias;
  final double latitude;
  final double longitude;

  const FavoritePlace({
    required this.favoriteId,
    required this.alias,
    required this.latitude,
    required this.longitude,
  });

  factory FavoritePlace.fromJson(Map<String, dynamic> json) {
    return FavoritePlace(
      favoriteId: (json['favorite_id'] as num).toInt(),
      alias: json['alias']?.toString() ?? '',
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }
}

class FavoriteService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<List<FavoritePlace>> loadFavorites(int userId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/users/$userId/favorites'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureSuccess(response, data);

    final rows = List<Map<String, dynamic>>.from(
      data['favorites'] as List? ?? const [],
    );
    return rows.map(FavoritePlace.fromJson).toList();
  }

  static Future<void> createFavorite({
    required int userId,
    required String alias,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/users/$userId/favorites'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'alias': alias, 'lat': latitude, 'lng': longitude}),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureSuccess(response, data, expectedStatus: 201);
  }

  static Future<void> deleteFavorite({
    required int userId,
    required int favoriteId,
  }) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/users/$userId/favorites/$favoriteId'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureSuccess(response, data);
  }

  static void _ensureSuccess(
    http.Response response,
    Map<String, dynamic> data, {
    int expectedStatus = 200,
  }) {
    if (response.statusCode != expectedStatus || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '즐겨찾기 처리에 실패했습니다.');
    }
  }
}
