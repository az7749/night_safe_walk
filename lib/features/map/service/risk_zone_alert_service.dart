import 'dart:convert';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;

class RiskRoadInfo {
  final int roadId;
  final double safetyScore;
  final double distanceM;
  final String riskLevel;

  const RiskRoadInfo({
    required this.roadId,
    required this.safetyScore,
    required this.distanceM,
    required this.riskLevel,
  });

  factory RiskRoadInfo.fromJson(Map<String, dynamic> json) {
    return RiskRoadInfo(
      roadId: (json['road_id'] as num).toInt(),
      safetyScore: (json['safety_score'] as num).toDouble(),
      distanceM: (json['distance_m'] as num).toDouble(),
      riskLevel: json['risk_level']?.toString() ?? 'low',
    );
  }
}

class RiskZoneAlertService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<RiskRoadInfo?> findNearestRiskRoad(NLatLng point) async {
    return findNearestRiskRoadByCoordinates(
      latitude: point.latitude,
      longitude: point.longitude,
    );
  }

  static Future<RiskRoadInfo?> findNearestRiskRoadByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$_baseUrl/roads/nearest-risk').replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius_m': '25',
        'threshold': '50',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '위험구역 조회 실패');
    }

    if (data['is_risky'] != true || data['road'] == null) {
      return null;
    }

    return RiskRoadInfo.fromJson(
      Map<String, dynamic>.from(data['road'] as Map),
    );
  }

  static Future<void> recordRiskZoneEntry({
    required int userId,
    required int roadId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/users/$userId/alarm-logs/risk-zone'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'road_id': roadId}),
        )
        .timeout(const Duration(seconds: 5));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message']?.toString() ?? '위험구역 알림 기록 실패');
    }

    if (data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '위험구역 알림 기록 실패');
    }
  }
}
