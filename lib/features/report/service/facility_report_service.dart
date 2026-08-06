import 'dart:convert';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;

class ReportedFacility {
  final int reportId;
  final int facilityId;
  final String facilityType;
  final String reportType;
  final String description;
  final String status;
  final DateTime? createdAt;
  final NLatLng position;
  final String? imageUrl;

  const ReportedFacility({
    required this.reportId,
    required this.facilityId,
    required this.facilityType,
    required this.reportType,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.position,
    required this.imageUrl,
  });

  factory ReportedFacility.fromJson(Map<String, dynamic> json) {
    final imagePath = json['image_url']?.toString();

    return ReportedFacility(
      reportId: (json['report_id'] as num).toInt(),
      facilityId: (json['facility_id'] as num).toInt(),
      facilityType: json['facility_type']?.toString() ?? 'unknown',
      reportType: json['report_type']?.toString() ?? 'other',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'received',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      position: NLatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      imageUrl: imagePath == null || imagePath.isEmpty
          ? null
          : FacilityReportService.absoluteUrl(imagePath),
    );
  }
}

class FacilityReportHistoryItem {
  final int reportId;
  final int? facilityId;
  final String facilityType;
  final String reportType;
  final String description;
  final String status;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? imageUrl;

  const FacilityReportHistoryItem({
    required this.reportId,
    required this.facilityId,
    required this.facilityType,
    required this.reportType,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.completedAt,
    required this.imageUrl,
  });

  factory FacilityReportHistoryItem.fromJson(Map<String, dynamic> json) {
    final imagePath = json['image_url']?.toString();

    return FacilityReportHistoryItem(
      reportId: (json['report_id'] as num).toInt(),
      facilityId: (json['facility_id'] as num?)?.toInt(),
      facilityType: json['facility_type']?.toString() ?? 'unknown',
      reportType: json['report_type']?.toString() ?? 'other',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'received',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
      imageUrl: imagePath == null || imagePath.isEmpty
          ? null
          : FacilityReportService.absoluteUrl(imagePath),
    );
  }
}

class FacilityReportService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static String absoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$_baseUrl${path.startsWith('/') ? path : '/$path'}';
  }

  static Future<int> createReport({
    required int userId,
    required int facilityId,
    required String reportType,
    required String description,
    required String imagePath,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/reports'))
          ..fields['user_id'] = userId.toString()
          ..fields['facility_id'] = facilityId.toString()
          ..fields['report_type'] = reportType
          ..fields['description'] = description
          ..files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 20),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '고장 신고 등록에 실패했습니다.');
    }

    return (data['report']['report_id'] as num).toInt();
  }

  static Future<List<ReportedFacility>> loadMapReports(
    NLatLngBounds bounds,
  ) async {
    final uri = Uri.parse('$_baseUrl/reports/map').replace(
      queryParameters: {
        'min_lat': bounds.southLatitude.toString(),
        'max_lat': bounds.northLatitude.toString(),
        'min_lng': bounds.westLongitude.toString(),
        'max_lng': bounds.eastLongitude.toString(),
        'limit': '300',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '신고 시설물 조회에 실패했습니다.');
    }

    final reports = List<Map<String, dynamic>>.from(
      data['reports'] as List? ?? const [],
    );
    return reports.map(ReportedFacility.fromJson).toList();
  }

  static Future<List<FacilityReportHistoryItem>> loadUserReports(
    int userId,
  ) async {
    final uri = Uri.parse('$_baseUrl/users/$userId/reports');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '신고 내역 조회에 실패했습니다.');
    }

    final reports = List<Map<String, dynamic>>.from(
      data['reports'] as List? ?? const [],
    );
    return reports.map(FacilityReportHistoryItem.fromJson).toList();
  }
}
