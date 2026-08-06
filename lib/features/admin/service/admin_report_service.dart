import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../report/service/facility_report_service.dart';

class AdminReportService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<List<FacilityReportHistoryItem>> loadReports({
    required int adminUserId,
    required String statusGroup,
  }) async {
    final uri = Uri.parse('$_baseUrl/admin/reports').replace(
      queryParameters: {
        'admin_user_id': adminUserId.toString(),
        'status': statusGroup,
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '신고 목록 조회에 실패했습니다.');
    }

    final reports = List<Map<String, dynamic>>.from(
      data['reports'] as List? ?? const [],
    );
    return reports.map(FacilityReportHistoryItem.fromJson).toList();
  }

  static Future<void> updateStatus({
    required int adminUserId,
    required int reportId,
    required String action,
  }) async {
    final uri = Uri.parse('$_baseUrl/admin/reports/$reportId');
    final response = await http
        .patch(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'admin_user_id': adminUserId, 'action': action}),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '신고 상태 변경에 실패했습니다.');
    }
  }
}
