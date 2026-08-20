import 'dart:convert';

import 'package:http/http.dart' as http;

class AlarmLog {
  final int logId;
  final String alarmType;
  final String content;
  final bool isRead;
  final DateTime? createdAt;

  const AlarmLog({
    required this.logId,
    required this.alarmType,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory AlarmLog.fromJson(Map<String, dynamic> json) {
    return AlarmLog(
      logId: (json['log_id'] as num).toInt(),
      alarmType: json['alarm_type']?.toString() ?? 'unknown',
      content: json['content']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  AlarmLog copyWith({bool? isRead}) {
    return AlarmLog(
      logId: logId,
      alarmType: alarmType,
      content: content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class AlarmLogResult {
  final List<AlarmLog> logs;
  final int unreadCount;

  const AlarmLogResult({required this.logs, required this.unreadCount});
}

class AlarmLogService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<AlarmLogResult> loadLogs(int userId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/users/$userId/alarm-logs?limit=100'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureSuccess(response, data);

    final items = List<Map<String, dynamic>>.from(
      data['logs'] as List? ?? const [],
    );
    return AlarmLogResult(
      logs: items.map(AlarmLog.fromJson).toList(),
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<List<AlarmLog>> loadPendingSosAlerts({
    required int userId,
    required int afterLogId,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            '$_baseUrl/users/$userId/alarm-logs/sos/pending?after_log_id=$afterLogId',
          ),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureSuccess(response, data);

    final items = List<Map<String, dynamic>>.from(
      data['logs'] as List? ?? const [],
    );
    return items
        .map(
          (item) => AlarmLog.fromJson({
            ...item,
            'alarm_type': 'sos',
            'is_read': false,
          }),
        )
        .toList();
  }

  static Future<void> markAsRead({
    required int userId,
    required int logId,
  }) async {
    final response = await http
        .patch(Uri.parse('$_baseUrl/users/$userId/alarm-logs/$logId/read'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureSuccess(response, data);
  }

  static Future<void> markAllAsRead(int userId) async {
    final response = await http
        .patch(Uri.parse('$_baseUrl/users/$userId/alarm-logs/read-all'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureSuccess(response, data);
  }

  static Future<void> deleteLog({
    required int userId,
    required int logId,
  }) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/users/$userId/alarm-logs/$logId'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureSuccess(response, data);
  }

  static Future<void> deleteAll(int userId) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/users/$userId/alarm-logs'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureSuccess(response, data);
  }

  static void _ensureSuccess(
    http.Response response,
    Map<String, dynamic> data,
  ) {
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? '알림 요청 처리에 실패했습니다.');
    }
  }
}
