import 'package:shared_preferences/shared_preferences.dart';

class RoutePreferenceService {
  static const String fastMode = 'fast';
  static const String safeMode = 'safe';
  static const String _keyPrefix = 'default_route_mode_';

  static Future<String> loadDefaultMode(int userId) async {
    final preferences = await SharedPreferences.getInstance();
    final mode = preferences.getString('$_keyPrefix$userId');
    return mode == fastMode ? fastMode : safeMode;
  }

  static Future<void> saveDefaultMode(int userId, String mode) async {
    if (mode != fastMode && mode != safeMode) {
      throw ArgumentError('지원하지 않는 경로 유형입니다.');
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('$_keyPrefix$userId', mode);
  }
}
