import 'dart:convert';

import 'package:http/http.dart' as http;

class EmergencySosResult {
  final int sosId;
  final int recipientCount;
  final int unmatchedContactCount;

  const EmergencySosResult({
    required this.sosId,
    required this.recipientCount,
    required this.unmatchedContactCount,
  });
}

class EmergencySosService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<EmergencySosResult> createRequest({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/users/$userId/sos-requests'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'SOS 요청 생성에 실패했습니다.');
    }

    final sos = Map<String, dynamic>.from(data['sos'] as Map);
    return EmergencySosResult(
      sosId: (sos['sos_id'] as num).toInt(),
      recipientCount: (sos['recipient_count'] as num?)?.toInt() ?? 0,
      unmatchedContactCount:
          (sos['unmatched_contact_count'] as num?)?.toInt() ?? 0,
    );
  }
}
