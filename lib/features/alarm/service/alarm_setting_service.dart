import 'dart:convert';

import 'package:http/http.dart' as http;

class AlarmSettings {
  final bool riskZoneAlert;
  final bool pushAlert;
  final bool vibrationAlert;

  const AlarmSettings({
    required this.riskZoneAlert,
    required this.pushAlert,
    required this.vibrationAlert,
  });

  factory AlarmSettings.fromJson(Map<String, dynamic> json) {
    return AlarmSettings(
      riskZoneAlert: json['risk_zone_alert'] == true,
      pushAlert: json['push_alert'] == true,
      vibrationAlert: json['vibration_alert'] == true,
    );
  }
}

class AlarmSettingService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<AlarmSettings> loadSettings(int userId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/users/$userId/alarm-settings'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '알림 설정 조회에 실패했습니다.');
    }

    return AlarmSettings.fromJson(
      data['settings'] as Map<String, dynamic>? ?? const {},
    );
  }

  static Future<void> saveSettings({
    required int userId,
    required AlarmSettings settings,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/users/$userId/alarm-settings'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'risk_zone_alert': settings.riskZoneAlert,
            'push_alert': settings.pushAlert,
            'vibration_alert': settings.vibrationAlert,
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '알림 설정 저장에 실패했습니다.');
    }
  }
}
