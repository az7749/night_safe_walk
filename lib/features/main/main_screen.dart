import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import '../../components/bottom_navbar.dart';
import '../../components/bottom_sheets/favorite_bottom_sheet.dart';
import '../../components/bottom_sheets/guide_bottom_sheet.dart';
import '../../components/bottom_sheets/more_bottom_sheet.dart';
import '../../components/bottom_sheets/place_action_bottom_sheet.dart';
import '../../components/map_search_bar.dart';
import '../alarm/screen/alarm_log_screen.dart';
import '../alarm/screen/alarm_setting_screen.dart';
import '../alarm/service/alarm_setting_service.dart';
import '../alarm/service/background_risk_monitor_service.dart';
import '../auth/screen/login_screen.dart';
import '../auth/screen/profile_edit_screen.dart';
import '../emergency_contact/screen/emergency_contact_screen.dart';
import '../favorite/service/favorite_service.dart';
import '../map/map_screen.dart';
import '../map/service/place_search_service.dart';
import '../map/service/risk_zone_alert_service.dart';
import '../map/service/route_api_service.dart';
import '../map/widgets/search_panel.dart';
import '../report/screen/report_history_screen.dart';
import '../sos/service/emergency_sos_service.dart';

class MainScreen extends StatefulWidget {
  final int? userId;

  const MainScreen({super.key, this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  int selectedIndex = 0;
  bool showSheet = false;
  bool showSearchPanel = false;
  bool hasSearched = false;
  NLatLng? startPoint;
  NLatLng? destinationPoint;
  String? startPointName;
  String? destinationPointName;
  NLatLng? cameraTarget;
  List<NLatLng> routePath = [];
  bool isRouteLoading = false;
  bool isSearchLoading = false;
  bool isSosLoading = false;
  bool isInRiskZone = false;
  bool riskZoneAlertEnabled = true;
  int favoriteRefreshToken = 0;
  StreamSubscription<bool>? riskZoneStateSubscription;
  List<Map<String, dynamic>> searchResults = [];

  final double navBarHeight = 80;
  final double guideSheetHeight = 300;
  final double favoriteSheetHeight = 320;
  final double moreSheetHeight = 476;

  double get currentSheetHeight => switch (selectedIndex) {
    0 => guideSheetHeight,
    1 => favoriteSheetHeight,
    _ => moreSheetHeight,
  };

  bool get isRiskAlertVisible => isInRiskZone && riskZoneAlertEnabled;

  double get riskAlertControlLift => isRiskAlertVisible ? 92 : 0;

  @override
  void initState() {
    super.initState();
    riskZoneStateSubscription = BackgroundRiskMonitorService.riskZoneStates
        .listen(onRiskZoneChanged);
    loadAlarmSettings();
  }


  Future<void> loadAlarmSettings() async {
    final userId = widget.userId;
    if (userId == null) return;

    try {
      final settings = await AlarmSettingService.loadSettings(userId);
      if (!mounted) return;
      setState(() {
        riskZoneAlertEnabled = settings.riskZoneAlert;
      });
      await BackgroundRiskMonitorService.startOrUpdate(
        userId: userId,
        settings: settings,
      );
      await syncCurrentRiskZoneState();
    } catch (e) {
      debugPrint('Alarm settings load error: $e');
    }
  }

  Future<void> syncCurrentRiskZoneState() async {
    if (!riskZoneAlertEnabled) {
      onRiskZoneChanged(false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final riskRoad =
          await RiskZoneAlertService.findNearestRiskRoadByCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      final isRisky = riskRoad != null;
      await BackgroundRiskMonitorService.syncRiskZoneState(isRisky);
      onRiskZoneChanged(isRisky);
    } catch (e) {
      debugPrint('Initial risk zone check error: $e');
    }
  }

  void onTapBottomNav(int index) {
    setState(() {
      if (selectedIndex == index && showSheet) {
        showSheet = false;
      } else {
        selectedIndex = index;
        showSheet = true;
      }
    });
  }

  void onRiskZoneChanged(bool value) {
    if (!mounted || isInRiskZone == value) return;

    setState(() {
      isInRiskZone = value;
    });
  }

  Widget buildRiskZoneOverlay() {
    final alertBottom = showSheet
        ? navBarHeight + currentSheetHeight + 4
        : navBarHeight + 12;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isInRiskZone && riskZoneAlertEnabled ? 1 : 0,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: alertBottom,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.65),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE53935),
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '위험구역입니다',
                          style: TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getCurrentBottomSheet() {
    if (selectedIndex == 0) {
      return GuideBottomSheet(
        startPoint: startPoint,
        destinationPoint: destinationPoint,
        startPointName: startPointName,
        destinationPointName: destinationPointName,
        isRouteLoading: isRouteLoading,
        onReset: resetRoutePoints,
        onRouteSelected: loadRoute,
      );
    } else if (selectedIndex == 1) {
      final selectedPlace = destinationPoint ?? startPoint;
      return FavoriteBottomSheet(
        userId: widget.userId,
        selectedLatitude: selectedPlace?.latitude,
        selectedLongitude: selectedPlace?.longitude,
        suggestedAlias: searchController.text,
        refreshToken: favoriteRefreshToken,
        onSelected: selectFavoritePlace,
      );
    } else {
      return MoreBottomSheet(
        onProfileTap: openProfileEdit,
        onEmergencyContactsTap: openEmergencyContacts,
        onAlarmSettingsTap: openAlarmSettings,
        onAlarmLogsTap: openAlarmLogs,
        onReportHistoryTap: openReportHistory,
        onLogoutTap: logout,
      );
    }
  }

  void openProfileEdit() {
    final userId = widget.userId;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다.')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(userId: userId),
      ),
    );
  }

  void openReportHistory() {
    final userId = widget.userId;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다.')));
      return;
    }

    setState(() {
      showSheet = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportHistoryScreen(userId: userId),
      ),
    );
  }

  void openEmergencyContacts() {
    final userId = widget.userId;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다.')));
      return;
    }

    setState(() {
      showSheet = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyContactScreen(userId: userId),
      ),
    );
  }

  Future<void> openAlarmSettings() async {
    final userId = widget.userId;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다.')));
      return;
    }

    setState(() {
      showSheet = false;
    });

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmSettingScreen(userId: userId),
      ),
    );

    if (changed == true && mounted) {
      await loadAlarmSettings();
    }
  }

  void openAlarmLogs() {
    final userId = widget.userId;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다.')));
      return;
    }

    setState(() {
      showSheet = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlarmLogScreen(userId: userId)),
    );
  }

  Future<void> logout() async {
    await BackgroundRiskMonitorService.stop();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> requestEmergencySos() async {
    final userId = widget.userId;
    if (userId == null || isSosLoading) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.sos_rounded, color: Color(0xFFDC2626), size: 44),
              const SizedBox(height: 14),
              const Text(
                '긴급 SOS를 요청할까요?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '현재 위치와 지도 링크가 등록된 회원인 비상 연락처의 앱 알림으로 전송됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                      child: const Text('SOS 요청'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => isSosLoading = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('휴대폰 위치 서비스를 켜주세요.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('SOS 요청을 위해 위치 권한을 허용해주세요.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final request = await EmergencySosService.createRequest(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      final unmatchedMessage = request.unmatchedContactCount > 0
          ? ' (${request.unmatchedContactCount}명은 앱 미가입)'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '비상 연락처 ${request.recipientCount}명에게 SOS 알림을 보냈습니다.$unmatchedMessage',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => isSosLoading = false);
    }
  }

  void selectRoutePoint(NLatLng point, {String? name}) {
    final isStartSelection = startPoint == null || destinationPoint != null;

    setState(() {
      selectedIndex = 0;
      showSheet = true;
      showSearchPanel = false;

      if (startPoint == null || destinationPoint != null) {
        startPoint = point;
        startPointName = name;
        destinationPoint = null;
        destinationPointName = null;
        routePath = [];
      } else {
        destinationPoint = point;
        destinationPointName = name;
        routePath = [];
      }
    });

    if (name == null || name.trim().isEmpty) {
      unawaited(
        loadRoutePointAddress(point, isStartSelection: isStartSelection),
      );
    }

  }

  void openPlaceActions(NLatLng point, String? name) {
    FocusScope.of(context).unfocus();
    setState(() {
      showSearchPanel = false;
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => PlaceActionBottomSheet(
        point: point,
        placeName: name,
        userId: widget.userId,
        onFavoriteChanged: () {
          if (!mounted) return;
          setState(() => favoriteRefreshToken++);
        },
        onSelectStart: (displayName) {
          Navigator.pop(sheetContext);
          setPlaceAsStart(point, displayName);
        },
        onSelectDestination: (displayName) {
          Navigator.pop(sheetContext);
          setPlaceAsDestination(point, displayName);
        },
      ),
    );
  }

  void setPlaceAsStart(NLatLng point, String displayName) {
    setState(() {
      selectedIndex = 0;
      showSheet = true;
      startPoint = point;
      startPointName = displayName;
      destinationPoint = null;
      destinationPointName = null;
      cameraTarget = point;
      routePath = [];
    });
  }

  Future<void> setPlaceAsDestination(NLatLng point, String displayName) async {
    NLatLng? currentStart;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('휴대폰 위치 서비스를 켜주세요.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('현재 위치를 사용하려면 위치 권한을 허용해주세요.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      currentStart = NLatLng(position.latitude, position.longitude);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (!mounted) return;
    setState(() {
      selectedIndex = 0;
      showSheet = true;
      startPoint = currentStart;
      startPointName = '현재 위치';
      destinationPoint = point;
      destinationPointName = displayName;
      cameraTarget = point;
      routePath = [];
    });
  }

  Future<void> loadRoutePointAddress(
    NLatLng point, {
    required bool isStartSelection,
  }) async {
    try {
      final address = await PlaceSearchService.reverseGeocode(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted || address.isEmpty) return;

      final selectedPoint = isStartSelection ? startPoint : destinationPoint;
      if (selectedPoint == null ||
          selectedPoint.latitude != point.latitude ||
          selectedPoint.longitude != point.longitude) {
        return;
      }

      setState(() {
        if (isStartSelection) {
          startPointName = address;
        } else {
          destinationPointName = address;
        }
      });
    } catch (error) {
      debugPrint('Reverse geocoding error: $error');
    }
  }

  Future<void> searchPlaces() async {
    final query = searchController.text.trim();

    if (query.isEmpty || isSearchLoading) return;

    setState(() {
      isSearchLoading = true;
      showSearchPanel = true;
      hasSearched = true;
      searchResults = [];
    });

    try {
      final places = await PlaceSearchService.searchPlaces(query);

      if (!mounted) return;

      setState(() {
        searchResults = places;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (!mounted) return;

      setState(() {
        isSearchLoading = false;
      });
    }
  }

  void selectSearchResult(Map<String, dynamic> place) {
    final lat = place['lat'];
    final lng = place['lng'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('좌표가 없는 검색 결과입니다.')));
      return;
    }

    final point = NLatLng((lat as num).toDouble(), (lng as num).toDouble());

    setState(() {
      cameraTarget = point;
      searchController.text = place['title']?.toString() ?? '';
      showSearchPanel = false;
      hasSearched = false;
    });

    searchFocusNode.unfocus();
    selectRoutePoint(point, name: place['title']?.toString());
  }

  Future<void> selectFavoritePlace(FavoritePlace favorite) async {
    final destination = NLatLng(favorite.latitude, favorite.longitude);
    NLatLng? currentStart;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      currentStart = NLatLng(position.latitude, position.longitude);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 위치를 가져오지 못해 목적지만 설정했습니다.')),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      selectedIndex = 0;
      showSheet = true;
      showSearchPanel = false;
      startPoint = currentStart;
      startPointName = currentStart == null ? null : '현재 위치';
      destinationPoint = destination;
      destinationPointName = favorite.alias;
      cameraTarget = destination;
      routePath = [];
      searchController.text = favorite.alias;
    });
  }

  void resetRoutePoints() {
    setState(() {
      startPoint = null;
      destinationPoint = null;
      startPointName = null;
      destinationPointName = null;
      routePath = [];
    });
  }

  Future<void> loadRoute(String mode) async {
    final start = startPoint;
    final destination = destinationPoint;

    if (start == null || destination == null || isRouteLoading) return;

    setState(() {
      isRouteLoading = true;
    });

    try {
      final path = await RouteApiService.loadRoute(
        start: start,
        destination: destination,
        mode: mode,
      );

      if (!mounted) return;

      setState(() {
        routePath = path;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (!mounted) return;

      setState(() {
        isRouteLoading = false;
      });
    }
  }

  @override
  void dispose() {
    riskZoneStateSubscription?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: navBarHeight,
            child: MapScreen(
              buttonBottom: showSheet
                  ? currentSheetHeight +
                        navBarHeight -
                        70 +
                        riskAlertControlLift
                  : navBarHeight - 70 + riskAlertControlLift,
              userId: widget.userId,
              startPoint: startPoint,
              destinationPoint: destinationPoint,
              routePath: routePath,
              cameraTarget: cameraTarget,
              onPlaceSelected: openPlaceActions,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MapSearchBar(
              controller: searchController,
              focusNode: searchFocusNode,
              onTap: () {
                setState(() {
                  showSearchPanel = true;
                });
              },
              onSearch: searchPlaces,
              onSubmitted: (_) => searchPlaces(),
            ),
          ),

          if (showSearchPanel && (isSearchLoading || hasSearched))
            Positioned(
              top: 88,
              left: 16,
              right: 16,
              child: SearchPanel(
                isLoading: isSearchLoading,
                results: searchResults,
                onSelect: selectSearchResult,
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: showSheet ? navBarHeight - 10 : -currentSheetHeight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: currentSheetHeight,
              child: getCurrentBottomSheet(),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 18,
            bottom: showSheet
                ? navBarHeight + currentSheetHeight + 8 + riskAlertControlLift
                : navBarHeight + 18 + riskAlertControlLift,
            child: Material(
              color: const Color(0xFFDC2626),
              shape: const CircleBorder(),
              elevation: 5,
              child: InkWell(
                onTap: isSosLoading ? null : requestEmergencySos,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Center(
                    child: isSosLoading
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavbar(
              selectedIndex: selectedIndex,
              showSheet: showSheet,
              onTap: onTapBottomNav,
              height: navBarHeight,
            ),
          ),
          buildRiskZoneOverlay(),
        ],
      ),
    );
  }
}
