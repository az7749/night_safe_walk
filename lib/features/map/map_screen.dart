import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

import 'service/nearby_facility_service.dart';
import 'service/road_overlay_service.dart';
import 'service/risk_zone_alert_service.dart';

class MapScreen extends StatefulWidget {
  final double buttonBottom;
  final NLatLng? startPoint;
  final NLatLng? destinationPoint;
  final List<NLatLng> routePath;
  final NLatLng? cameraTarget;
  final ValueChanged<NLatLng> onRoutePointSelected;
  final ValueChanged<bool> onRiskZoneChanged;

  const MapScreen({
    super.key,
    required this.buttonBottom,
    required this.startPoint,
    required this.destinationPoint,
    required this.routePath,
    required this.cameraTarget,
    required this.onRoutePointSelected,
    required this.onRiskZoneChanged,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;
  NOverlayImage? _startPointMarkerIcon;
  NOverlayImage? _destinationPointMarkerIcon;
  NOverlayImage? _streetLightMarkerIcon;
  NOverlayImage? _securityLightMarkerIcon;
  StreamSubscription<Position>? _positionSubscription;
  bool _isFetchingRoadOverlays = false;
  bool _isCheckingRiskRoad = false;
  bool _isInRiskZone = false;
  bool _isLoadingReportFacilities = false;
  bool _isShowingReportFacilities = false;
  String? _lastRoadBoundsRequestKey;
  int? _lastAlertedRiskRoadId;
  DateTime? _lastRiskAlertAt;
  final Set<String> _reportFacilityMarkerIds = {};

  static const NLatLng _defaultPosition = NLatLng(36.6424, 127.4890);
  static const double _roadVisibleZoomThreshold = 14;
  static const String _startPointMarkerId = 'route_start_point';
  static const String _destinationPointMarkerId = 'route_destination_point';
  static const String _routePathOverlayId = 'selected_route_path';

  Future<NOverlayImage> _buildRoutePointMarkerIcon({
    required String label,
    required Color color,
  }) {
    return NOverlayImage.fromWidget(
      context: context,
      size: const Size(34, 34),
      widget: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Future<NOverlayImage> _getStartPointMarkerIcon() async {
    return _startPointMarkerIcon ??= await _buildRoutePointMarkerIcon(
      label: '출',
      color: const Color(0xFF2563EB),
    );
  }

  Future<NOverlayImage> _getDestinationPointMarkerIcon() async {
    return _destinationPointMarkerIcon ??= await _buildRoutePointMarkerIcon(
      label: '도',
      color: const Color(0xFFEF4444),
    );
  }

  Future<NOverlayImage> _buildReportFacilityMarkerIcon({
    required Color color,
    required IconData icon,
  }) {
    return NOverlayImage.fromWidget(
      context: context,
      size: const Size(36, 36),
      widget: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 21,
        ),
      ),
    );
  }

  Future<NOverlayImage> _getReportFacilityMarkerIcon(String type) async {
    if (type == 'street_light') {
      return _streetLightMarkerIcon ??= await _buildReportFacilityMarkerIcon(
        color: const Color(0xFFF59E0B),
        icon: Icons.light_mode_outlined,
      );
    }

    return _securityLightMarkerIcon ??= await _buildReportFacilityMarkerIcon(
      color: const Color(0xFF2563EB),
      icon: Icons.shield_outlined,
    );
  }

  String _buildBoundsRequestKey(NLatLngBounds bounds, double zoom) {
    return [
      bounds.southLatitude.toStringAsFixed(5),
      bounds.westLongitude.toStringAsFixed(5),
      bounds.northLatitude.toStringAsFixed(5),
      bounds.eastLongitude.toStringAsFixed(5),
      zoom.toStringAsFixed(2),
    ].join('|');
  }

  Future<void> _clearRoadOverlays() async {
    if (_mapController == null) return;
    await _mapController!.clearOverlays(type: NOverlayType.polylineOverlay);
  }

  Future<void> _deleteRoutePathOverlay() async {
    if (_mapController == null) return;

    try {
      await _mapController!.deleteOverlay(
        NOverlayInfo(
          type: NOverlayType.polylineOverlay,
          id: _routePathOverlayId,
        ),
      );
    } catch (_) {
      // ?꾩쭅 異붽??섏? ?딆? 寃쎈줈?좎쓣 吏???뚮뒗 臾댁떆?⑸땲??
    }
  }

  Future<void> _deleteRoutePointMarker(String markerId) async {
    if (_mapController == null) return;

    try {
      await _mapController!.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: markerId),
      );
    } catch (_) {
      // ?꾩쭅 異붽??섏? ?딆? 留덉빱瑜?吏???뚮뒗 臾댁떆?⑸땲??
    }
  }

  Future<void> _renderRoutePointMarkers() async {
    if (_mapController == null) return;

    await _deleteRoutePointMarker(_startPointMarkerId);
    await _deleteRoutePointMarker(_destinationPointMarkerId);

    final markers = <NMarker>{};

    if (widget.startPoint != null) {
      markers.add(
        NMarker(
          id: _startPointMarkerId,
          position: widget.startPoint!,
          icon: await _getStartPointMarkerIcon(),
          size: const Size(34, 34),
          anchor: const NPoint(0.5, 0.5),
        ),
      );
    }

    if (widget.destinationPoint != null) {
      markers.add(
        NMarker(
          id: _destinationPointMarkerId,
          position: widget.destinationPoint!,
          icon: await _getDestinationPointMarkerIcon(),
          size: const Size(34, 34),
          anchor: const NPoint(0.5, 0.5),
        ),
      );
    }

    if (markers.isNotEmpty) {
      await _mapController!.addOverlayAll(markers);
    }
  }

  Future<void> _renderRoutePathOverlay() async {
    if (_mapController == null) return;

    await _deleteRoutePathOverlay();

    if (widget.routePath.length < 2) return;

    final routeOverlay = NPolylineOverlay(
      id: _routePathOverlayId,
      coords: widget.routePath,
      width: 8,
      color: const Color(0xFF6546FF),
      lineCap: NLineCap.round,
      lineJoin: NLineJoin.round,
    );

    await _mapController!.addOverlay(routeOverlay);
  }

  Future<void> _reloadRoadOverlaysForVisibleBounds() async {
    if (_mapController == null || _isFetchingRoadOverlays) return;

    _isFetchingRoadOverlays = true;

    try {
      final controller = _mapController!;
      final cameraPosition = await controller.getCameraPosition();
      final currentZoom = cameraPosition.zoom;

      if (currentZoom < _roadVisibleZoomThreshold) {
        _lastRoadBoundsRequestKey = null;
        await _clearRoadOverlays();
        await _renderRoutePathOverlay();
        debugPrint('Road overlay load skipped at zoom $currentZoom');
        return;
      }

      final bounds = await controller.getContentBounds();
      final requestKey = _buildBoundsRequestKey(bounds, currentZoom);

      if (_lastRoadBoundsRequestKey == requestKey) {
        debugPrint('Road overlay request skipped for same bounds');
        return;
      }

      _lastRoadBoundsRequestKey = requestKey;
      await RoadOverlayService.loadRoadsForBounds(controller, bounds);
      await _renderRoutePathOverlay();
    } catch (e) {
      debugPrint('Road overlay reload error: $e');
    } finally {
      _isFetchingRoadOverlays = false;
    }
  }

  Future<NLatLng?> _getCurrentLatLng() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('위치 서비스가 꺼져 있습니다.')));
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('위치 권한을 거부했습니다.')));
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해주세요.')),
      );
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return NLatLng(position.latitude, position.longitude);
  }

  Future<void> _moveToCurrentLocation() async {
    if (_mapController == null) return;

    final currentLatLng = await _getCurrentLatLng();
    if (currentLatLng == null) return;

    final cameraUpdate = NCameraUpdate.withParams(
      target: currentLatLng,
      zoom: 16,
    );

    await _mapController!.updateCamera(cameraUpdate);

    final locationOverlay = _mapController!.getLocationOverlay();
    locationOverlay.setIsVisible(true);
    locationOverlay.setPosition(currentLatLng);
  }

  Future<void> _clearReportFacilityMarkers() async {
    if (_mapController == null) return;

    for (final markerId in _reportFacilityMarkerIds.toList()) {
      try {
        await _mapController!.deleteOverlay(
          NOverlayInfo(type: NOverlayType.marker, id: markerId),
        );
      } catch (_) {
        // The marker may already have been removed by a map rebuild.
      }
    }

    _reportFacilityMarkerIds.clear();
  }

  String _facilityTypeLabel(String type) {
    switch (type) {
      case 'street_light':
        return '가로등';
      case 'security_light':
        return '보안등';
      default:
        return '안전 시설물';
    }
  }

  void _showFacilityReportSheet(NearbyFacility facility) {
    final facilityLabel = _facilityTypeLabel(facility.type);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFE53935),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facilityLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '현재 위치에서 ${facility.distanceM.toStringAsFixed(1)}m',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '이 $facilityLabel의 고장을 신고하시겠습니까?',
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4B5563),
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('신고 작성 화면은 다음 단계에서 연결됩니다.'),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.report_problem_outlined, size: 19),
                      label: const Text('고장 신고'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renderReportFacilityMarkers(
    List<NearbyFacility> facilities,
  ) async {
    if (_mapController == null || facilities.isEmpty) return;

    final markers = <NMarker>{};

    for (final facility in facilities) {
      final markerId = 'report_candidate_${facility.facilityId}';
      _reportFacilityMarkerIds.add(markerId);
      final markerIcon = await _getReportFacilityMarkerIcon(facility.type);

      final marker = NMarker(
        id: markerId,
        position: facility.position,
        icon: markerIcon,
        size: const Size(36, 36),
        anchor: const NPoint(0.5, 0.5),
      );

      marker.setOnTapListener((_) {
        _showFacilityReportSheet(facility);
      });

      markers.add(marker);
    }

    await _mapController!.addOverlayAll(markers);
  }

  Future<void> _toggleReportFacilities() async {
    if (_mapController == null || _isLoadingReportFacilities) return;

    if (_isShowingReportFacilities) {
      await _clearReportFacilityMarkers();
      if (!mounted) return;

      setState(() {
        _isShowingReportFacilities = false;
      });
      return;
    }

    setState(() {
      _isLoadingReportFacilities = true;
    });

    try {
      final currentPosition = await _getCurrentLatLng();
      if (currentPosition == null) return;

      await _clearReportFacilityMarkers();

      final facilities = await NearbyFacilityService.loadReportCandidates(
        currentPosition,
      );

      if (!mounted) return;

      await _mapController!.updateCamera(
        NCameraUpdate.withParams(target: currentPosition, zoom: 19),
      );

      final locationOverlay = _mapController!.getLocationOverlay();
      locationOverlay.setIsVisible(true);
      locationOverlay.setPosition(currentPosition);

      await _renderReportFacilityMarkers(facilities);

      if (!mounted) return;

      setState(() {
        _isShowingReportFacilities = facilities.isNotEmpty;
      });

      final message = facilities.isEmpty
          ? '반경 30m 이내에 신고 가능한 시설물이 없습니다.'
          : '반경 30m 이내 시설물 ${facilities.length}개를 표시했습니다.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주변 시설물을 불러오지 못했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReportFacilities = false;
        });
      }
    }
  }

  Future<void> _startRiskZoneMonitoring() async {
    if (_positionSubscription != null) return;

    final currentLatLng = await _getCurrentLatLng();
    if (currentLatLng == null) return;

    await _checkRiskZone(currentLatLng);

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
          ),
        ).listen((position) {
          final point = NLatLng(position.latitude, position.longitude);
          _checkRiskZone(point);
        });
  }

  Future<void> _checkRiskZone(NLatLng point) async {
    if (_isCheckingRiskRoad) return;

    _isCheckingRiskRoad = true;

    try {
      final riskRoad = await RiskZoneAlertService.findNearestRiskRoad(point);

      if (!mounted) return;

      final nextIsInRiskZone = riskRoad != null;

      if (_isInRiskZone != nextIsInRiskZone) {
        setState(() {
          _isInRiskZone = nextIsInRiskZone;
        });
        widget.onRiskZoneChanged(nextIsInRiskZone);
      }

      if (riskRoad == null) {
        _lastAlertedRiskRoadId = null;
        return;
      }

      final now = DateTime.now();
      final isSameRoad = _lastAlertedRiskRoadId == riskRoad.roadId;
      final isCooldown =
          _lastRiskAlertAt != null &&
          now.difference(_lastRiskAlertAt!) < const Duration(seconds: 45);

      if (isSameRoad && isCooldown) return;

      _lastAlertedRiskRoadId = riskRoad.roadId;
      _lastRiskAlertAt = now;
    } catch (e) {
      debugPrint('Risk zone check error: $e');
    } finally {
      _isCheckingRiskRoad = false;
    }
  }

  Future<void> _moveCameraTo(NLatLng target) async {
    if (_mapController == null) return;

    final cameraUpdate = NCameraUpdate.withParams(target: target, zoom: 16);

    await _mapController!.updateCamera(cameraUpdate);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.startPoint != widget.startPoint ||
        oldWidget.destinationPoint != widget.destinationPoint) {
      _renderRoutePointMarkers();
    }

    if (oldWidget.routePath != widget.routePath) {
      _renderRoutePathOverlay();
    }

    if (oldWidget.cameraTarget != widget.cameraTarget &&
        widget.cameraTarget != null) {
      _moveCameraTo(widget.cameraTarget!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NaverMap(
          options: const NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: _defaultPosition,
              zoom: 14,
            ),
          ),
          onMapReady: (controller) async {
            _mapController = controller;
            await _reloadRoadOverlaysForVisibleBounds();
            await _renderRoutePointMarkers();
            await _renderRoutePathOverlay();
            await _startRiskZoneMonitoring();
            if (widget.cameraTarget != null) {
              await _moveCameraTo(widget.cameraTarget!);
            }
          },
          onCameraIdle: () async {
            await _reloadRoadOverlaysForVisibleBounds();
          },
          onMapTapped: (_, latLng) {
            if (_isShowingReportFacilities) return;
            widget.onRoutePointSelected(latLng);
          },
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: 16,
          bottom: widget.buttonBottom + 52,
          child: FloatingActionButton(
            heroTag: 'facility_report_button',
            mini: true,
            onPressed: _toggleReportFacilities,
            tooltip: '시설물 신고',
            backgroundColor: _isShowingReportFacilities
                ? const Color(0xFFE53935)
                : Colors.white,
            foregroundColor: _isShowingReportFacilities
                ? Colors.white
                : const Color(0xFFE53935),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: _isLoadingReportFacilities
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.report_problem_outlined, size: 21),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: 16,
          bottom: widget.buttonBottom,
          child: FloatingActionButton(
            heroTag: 'current_location_button',
            mini: true,
            onPressed: _moveToCurrentLocation,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF6546FF),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.my_location, size: 20),
          ),
        ),
      ],
    );
  }
}
