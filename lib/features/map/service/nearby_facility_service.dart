import 'dart:convert';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;

class NearbyFacility {
  final int facilityId;
  final String type;
  final NLatLng position;
  final double distanceM;

  const NearbyFacility({
    required this.facilityId,
    required this.type,
    required this.position,
    required this.distanceM,
  });

  factory NearbyFacility.fromJson(Map<String, dynamic> json) {
    return NearbyFacility(
      facilityId: (json['facility_id'] as num).toInt(),
      type: json['type']?.toString() ?? 'unknown',
      position: NLatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      distanceM: (json['distance_m'] as num).toDouble(),
    );
  }
}

class NearbyFacilityService {
  static const String _baseUrl = 'http://10.0.2.2:5000';
  static const double reportRadiusM = 30;

  static Future<List<NearbyFacility>> loadReportCandidates(
    NLatLng currentPosition,
  ) async {
    final uri = Uri.parse('$_baseUrl/facilities/nearby').replace(
      queryParameters: {
        'lat': currentPosition.latitude.toString(),
        'lng': currentPosition.longitude.toString(),
        'radius_m': reportRadiusM.toString(),
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '주변 시설물 조회에 실패했습니다.');
    }

    final facilities = List<Map<String, dynamic>>.from(
      data['facilities'] as List? ?? const [],
    );

    return facilities.map(NearbyFacility.fromJson).toList();
  }
}
