import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;

class RoadOverlayService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<void> loadRoadsForBounds(
    NaverMapController controller,
    NLatLngBounds bounds,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/roads').replace(
        queryParameters: {
          'min_lat': bounds.southLatitude.toString(),
          'max_lat': bounds.northLatitude.toString(),
          'min_lng': bounds.westLongitude.toString(),
          'max_lng': bounds.eastLongitude.toString(),
          'limit': '5000',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('Road statusCode: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('Road body: ${response.body}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        debugPrint('Road load failed: ${data['message']}');
        return;
      }

      final roads = List<Map<String, dynamic>>.from(data['roads']);

      await controller.clearOverlays(type: NOverlayType.polylineOverlay);

      if (roads.isEmpty) return;

      final overlays = roads.map((road) {
        final coords = List<Map<String, dynamic>>.from(road['coords'])
            .map(
              (coord) => NLatLng(
                (coord['lat'] as num).toDouble(),
                (coord['lng'] as num).toDouble(),
              ),
            )
            .toList();

        return NPolylineOverlay(
          id: 'road_${road['road_id']}',
          coords: coords,
          width: 4,
          color: _colorForSafetyScore(road['safety_score'] as num?),
        );
      }).toSet();

      debugPrint('Road overlay count: ${overlays.length}');
      await controller.addOverlayAll(overlays);
    } catch (e) {
      debugPrint('Road load error: $e');
    }
  }

  static Color _colorForSafetyScore(num? score) {
    final value = score?.toDouble() ?? 0;

    if (value < 40) {
      return const Color(0xFFE53935);
    }
    if (value < 60) {
      return const Color(0xFFFF9800);
    }
    if (value < 80) {
      return const Color(0xFFFFD600);
    }
    return const Color(0xFF2E7D32);
  }
}
