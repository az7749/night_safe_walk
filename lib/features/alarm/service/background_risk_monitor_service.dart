import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../map/service/risk_zone_alert_service.dart';
import 'alarm_log_service.dart';
import 'alarm_setting_service.dart';

const _monitorChannelId = 'risk_zone_monitor';
const _alertChannelId = 'risk_zone_alert';
const _silentAlertChannelId = 'risk_zone_alert_silent';
const _foregroundNotificationId = 8100;
const _riskNotificationId = 8101;
const _sosAlertChannelId = 'emergency_sos_alert';
const _sosSilentAlertChannelId = 'emergency_sos_alert_silent';
const _userIdKey = 'background_risk_user_id';
const _riskAlertKey = 'background_risk_alert_enabled';
const _pushAlertKey = 'background_push_alert_enabled';
const _vibrationAlertKey = 'background_vibration_alert_enabled';
const _currentRiskStateKey = 'background_current_risk_state';
const _lastSosLogIdKeyPrefix = 'background_last_sos_log_id';

class BackgroundRiskMonitorService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static bool _isInitialized = false;

  static Stream<bool> get riskZoneStates => _service
      .on('riskZoneState')
      .map((event) => event?['is_risky'] == true);

  static Future<void> syncRiskZoneState(bool isRisky) async {
    if (!Platform.isAndroid) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_currentRiskStateKey, isRisky);
    _service.invoke('syncRiskZoneState', {'is_risky': isRisky});
  }

  static Future<void> initialize() async {
    if (!Platform.isAndroid || _isInitialized) return;

    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_safe_walk'),
      ),
    );

    final androidNotifications = notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidNotifications?.createNotificationChannel(
      const AndroidNotificationChannel(
        _monitorChannelId,
        '위험구역 감지 서비스',
        description: '앱이 백그라운드일 때도 위험구역 진입을 감지합니다.',
        importance: Importance.low,
      ),
    );
    await androidNotifications?.createNotificationChannel(
      const AndroidNotificationChannel(
        _sosAlertChannelId,
        '긴급 SOS 알림',
        description: '등록된 비상 연락처가 보낸 긴급 SOS를 알립니다.',
        importance: Importance.max,
        enableVibration: true,
      ),
    );
    await androidNotifications?.createNotificationChannel(
      const AndroidNotificationChannel(
        _sosSilentAlertChannelId,
        '긴급 SOS 알림(무진동)',
        description: '등록된 비상 연락처가 보낸 긴급 SOS를 진동 없이 알립니다.',
        importance: Importance.max,
        enableVibration: false,
      ),
    );
    await androidNotifications?.createNotificationChannel(
      const AndroidNotificationChannel(
        _alertChannelId,
        '위험구역 진입 알림',
        description: '위험구역에 진입했을 때 알림과 진동을 제공합니다.',
        importance: Importance.max,
        enableVibration: true,
      ),
    );
    await androidNotifications?.createNotificationChannel(
      const AndroidNotificationChannel(
        _silentAlertChannelId,
        '위험구역 진입 알림(무진동)',
        description: '위험구역에 진입했을 때 진동 없이 알립니다.',
        importance: Importance.max,
        enableVibration: false,
      ),
    );

    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: backgroundRiskMonitorEntryPoint,
        onBackground: iosBackgroundEntryPoint,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundRiskMonitorEntryPoint,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: _monitorChannelId,
        initialNotificationTitle: '안심 보행 보호 실행 중',
        initialNotificationContent: '주변 위험구역을 확인하고 있습니다.',
        foregroundServiceNotificationId: _foregroundNotificationId,
        foregroundServiceTypes: const [AndroidForegroundType.location],
      ),
    );
    _isInitialized = true;
  }

  static Future<bool> startOrUpdate({
    required int userId,
    required AlarmSettings settings,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_userIdKey, userId);
    await preferences.setBool(_riskAlertKey, settings.riskZoneAlert);
    await preferences.setBool(_pushAlertKey, settings.pushAlert);
    await preferences.setBool(_vibrationAlertKey, settings.vibrationAlert);

    if (!Platform.isAndroid) return false;

    try {
      await initialize();
    } catch (error) {
      debugPrint('Background risk monitor initialization error: $error');
      return false;
    }

    if (!settings.riskZoneAlert && !settings.pushAlert) {
      await stop();
      return false;
    }

    if (!await _requestRequiredPermissions()) return false;

    if (!await _service.isRunning()) {
      await _service.startService();
    }
    _service.invoke('settingsUpdated');
    return true;
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (await _service.isRunning()) {
      _service.invoke('stopService');
    }
  }

  static Future<bool> _requestRequiredPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    final notifications = FlutterLocalNotificationsPlugin();
    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return true;
  }
}

@pragma('vm:entry-point')
Future<bool> iosBackgroundEntryPoint(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void backgroundRiskMonitorEntryPoint(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
    await service.setForegroundNotificationInfo(
      title: '안심 보행 보호 실행 중',
      content: '주변 위험구역을 확인하고 있습니다.',
    );
  }

  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_safe_walk'),
    ),
  );

  StreamSubscription<Position>? positionSubscription;
  Timer? sosPollTimer;
  Timer? safeExitTimer;
  var isChecking = false;
  var isPollingSos = false;
  final statePreferences = await SharedPreferences.getInstance();
  await statePreferences.reload();
  var isInRiskZone = statePreferences.getBool(_currentRiskStateKey) ?? false;

  service.on('stopService').listen((_) async {
    await positionSubscription?.cancel();
    sosPollTimer?.cancel();
    safeExitTimer?.cancel();
    await service.stopSelf();
  });

  service.on('syncRiskZoneState').listen((event) async {
    isInRiskZone = event?['is_risky'] == true;
    await statePreferences.setBool(_currentRiskStateKey, isInRiskZone);
    if (isInRiskZone) {
      safeExitTimer?.cancel();
      safeExitTimer = null;
    }
  });

  Future<void> pollSosAlerts() async {
    if (isPollingSos) return;
    isPollingSos = true;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final userId = preferences.getInt(_userIdKey);
      if (userId == null) return;

      final lastLogKey = '${_lastSosLogIdKeyPrefix}_$userId';
      final lastLogId = preferences.getInt(lastLogKey) ?? 0;
      final logs = await AlarmLogService.loadPendingSosAlerts(
        userId: userId,
        afterLogId: lastLogId,
      );
      if (logs.isEmpty) return;

      final pushAlertEnabled = preferences.getBool(_pushAlertKey) ?? true;
      final vibrationEnabled =
          preferences.getBool(_vibrationAlertKey) ?? true;

      for (final log in logs) {
        if (pushAlertEnabled) {
          final channelId = vibrationEnabled
              ? _sosAlertChannelId
              : _sosSilentAlertChannelId;
          await notifications.show(
            id: 8200 + (log.logId % 100000),
            title: '긴급 SOS 요청',
            body: log.content,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                vibrationEnabled ? '긴급 SOS 알림' : '긴급 SOS 알림(무진동)',
                channelDescription: '비상 연락처가 보낸 긴급 SOS 알림입니다.',
                importance: Importance.max,
                priority: Priority.high,
                enableVibration: vibrationEnabled,
                playSound: true,
                icon: 'ic_stat_safe_walk',
              ),
            ),
            payload: 'sos:${log.logId}',
          );
        }
        await preferences.setInt(lastLogKey, log.logId);
      }
    } catch (error) {
      debugPrint('Background SOS polling error: $error');
    } finally {
      isPollingSos = false;
    }
  }

  await pollSosAlerts();
  sosPollTimer = Timer.periodic(
    const Duration(seconds: 10),
    (_) => pollSosAlerts(),
  );

  positionSubscription = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 7,
    ),
  ).listen((position) async {
    if (isChecking) return;
    isChecking = true;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final userId = preferences.getInt(_userIdKey);
      final riskAlertEnabled = preferences.getBool(_riskAlertKey) ?? true;

      if (userId == null || !riskAlertEnabled) {
        service.invoke('riskZoneState', {'is_risky': false});
        return;
      }

      final riskRoad =
          await RiskZoneAlertService.findNearestRiskRoadByCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
          );

      if (riskRoad == null) {
        if (!isInRiskZone || safeExitTimer != null) return;

        safeExitTimer = Timer(const Duration(seconds: 5), () async {
          try {
            final currentPosition = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );
            final currentRiskRoad =
                await RiskZoneAlertService.findNearestRiskRoadByCoordinates(
                  latitude: currentPosition.latitude,
                  longitude: currentPosition.longitude,
                );
            if (currentRiskRoad == null && isInRiskZone) {
              isInRiskZone = false;
              await statePreferences.setBool(_currentRiskStateKey, false);
              service.invoke('riskZoneState', {'is_risky': false});
            }
          } catch (error) {
            debugPrint('Risk zone exit check error: $error');
          } finally {
            safeExitTimer = null;
          }
        });
        return;
      }

      safeExitTimer?.cancel();
      safeExitTimer = null;
      service.invoke('riskZoneState', {'is_risky': true});

      // 위험구역 안에서 인접 도로가 바뀌더라도 재알림하지 않는다.
      // 안전구역으로 완전히 나갔다가 다시 진입할 때만 새로 알린다.
      if (isInRiskZone) return;
      isInRiskZone = true;
      await statePreferences.setBool(_currentRiskStateKey, true);

      final pushAlertEnabled = preferences.getBool(_pushAlertKey) ?? true;
      final vibrationEnabled =
          preferences.getBool(_vibrationAlertKey) ?? true;

      if (pushAlertEnabled) {
        final channelId = vibrationEnabled
            ? _alertChannelId
            : _silentAlertChannelId;
        await notifications.show(
          id: _riskNotificationId,
          title: '위험구역 진입 알림',
          body: '위험구역에 진입했습니다. 주변을 살펴보고 안전에 유의해주세요.',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              vibrationEnabled ? '위험구역 진입 알림' : '위험구역 진입 알림(무진동)',
              channelDescription: '위험구역 진입 시 표시되는 안전 알림입니다.',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: vibrationEnabled,
              playSound: true,
              icon: 'ic_stat_safe_walk',
            ),
          ),
          payload: 'risk-road:${riskRoad.roadId}',
        );
      }

      await RiskZoneAlertService.recordRiskZoneEntry(
        userId: userId,
        roadId: riskRoad.roadId,
      );
    } catch (error) {
      debugPrint('Background risk monitor error: $error');
    } finally {
      isChecking = false;
    }
  });
}
