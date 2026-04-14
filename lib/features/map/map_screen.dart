import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  final double buttonBottom;

  const MapScreen({super.key, required this.buttonBottom});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;
  // 주석: 현재 화면 범위 기준 CCTV 마커 재조회/교체 상태값
  NOverlayImage? _cctvMarkerIcon;
  bool _isFetchingCctvMarkers = false;
  String? _lastBoundsRequestKey;

  static const NLatLng _defaultPosition = NLatLng(36.6424, 127.4890);
  // 주석: 줌 레벨이 너무 낮을 때는 CCTV 마커 조회를 생략
  static const double _cctvVisibleZoomThreshold = 13;
  static const int _defaultFacilityLimit = 200;

  Future<NOverlayImage> _buildMarkerIcon() {
    return NOverlayImage.fromWidget(
      context: context,
      size: const Size(26, 26),
      widget: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Icon(
          Icons.videocam_outlined,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }

  Future<NOverlayImage> _getCctvMarkerIcon() async {
    return _cctvMarkerIcon ??= await _buildMarkerIcon();
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

  Future<void> _clearCctvMarkers() async {
    if (_mapController == null) return;
    // 주석: CCTV 마커는 매 재조회마다 교체되므로 기존 마커를 먼저 정리
    await _mapController!.clearOverlays(type: NOverlayType.marker);
  }

  Future<void> _reloadCctvMarkersForVisibleBounds() async {
    if (_mapController == null || _isFetchingCctvMarkers) return;

    _isFetchingCctvMarkers = true;

    try {
      final controller = _mapController!;
      final cameraPosition = await controller.getCameraPosition();
      final currentZoom = cameraPosition.zoom;

      if (currentZoom < _cctvVisibleZoomThreshold) {
        _lastBoundsRequestKey = null;
        await _clearCctvMarkers();
        debugPrint('CCTV marker load skipped at zoom $currentZoom');
        return;
      }

      final bounds = await controller.getContentBounds();
      final requestKey = _buildBoundsRequestKey(bounds, currentZoom);

      if (_lastBoundsRequestKey == requestKey) {
        debugPrint('CCTV marker request skipped for same bounds');
        return;
      }

      _lastBoundsRequestKey = requestKey;

      // 주석: 현재 화면 bounds를 서버로 보내 CCTV만 다시 조회
      final markerIcon = await _getCctvMarkerIcon();
      final uri = Uri.parse('http://10.0.2.2:5000/facilities').replace(
        queryParameters: {
          'min_lat': bounds.southLatitude.toString(),
          'max_lat': bounds.northLatitude.toString(),
          'min_lng': bounds.westLongitude.toString(),
          'max_lng': bounds.eastLongitude.toString(),
          'limit': _defaultFacilityLimit.toString(),
        },
      );

      final response = await http.get(uri);
      debugPrint('CCTV statusCode: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('CCTV body: ${response.body}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        debugPrint('CCTV load failed: ${data['message']}');
        return;
      }

      final facilities = List<Map<String, dynamic>>.from(data['facilities']);
      debugPrint('CCTV facilities count: ${facilities.length}');

      await _clearCctvMarkers();

      if (facilities.isEmpty) return;

      final markers = facilities.map((item) {
        return NMarker(
          id: item['facility_id'].toString(),
          position: NLatLng(
            (item['lat'] as num).toDouble(),
            (item['lng'] as num).toDouble(),
          ),
          icon: markerIcon,
          size: const Size(26, 26),
          anchor: const NPoint(0.5, 0.5),
        );
      }).toSet();

      await controller.addOverlayAll(markers);
    } catch (e) {
      debugPrint('CCTV marker reload error: $e');
    } finally {
      _isFetchingCctvMarkers = false;
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
      ).showSnackBar(const SnackBar(content: Text('위치 권한이 거부되었습니다.')));
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
            await _reloadCctvMarkersForVisibleBounds();
          },
          // 주석: 카메라 이동이 끝날 때마다 현재 화면 범위 기준으로 CCTV 재조회
          onCameraIdle: () {
            _reloadCctvMarkersForVisibleBounds();
          },
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: 16,
          bottom: widget.buttonBottom,
          child: FloatingActionButton(
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
