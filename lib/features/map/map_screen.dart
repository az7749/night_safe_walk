import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

import 'service/road_overlay_service.dart';

class MapScreen extends StatefulWidget {
  final double buttonBottom;
  final NLatLng? startPoint;
  final NLatLng? destinationPoint;
  final List<NLatLng> routePath;
  final ValueChanged<NLatLng> onRoutePointSelected;

  const MapScreen({
    super.key,
    required this.buttonBottom,
    required this.startPoint,
    required this.destinationPoint,
    required this.routePath,
    required this.onRoutePointSelected,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;
  NOverlayImage? _startPointMarkerIcon;
  NOverlayImage? _destinationPointMarkerIcon;
  bool _isFetchingRoadOverlays = false;
  String? _lastRoadBoundsRequestKey;

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
        NOverlayInfo(type: NOverlayType.polylineOverlay, id: _routePathOverlayId),
      );
    } catch (_) {
      // 아직 추가되지 않은 경로선을 지울 때는 무시합니다.
    }
  }

  Future<void> _deleteRoutePointMarker(String markerId) async {
    if (_mapController == null) return;

    try {
      await _mapController!.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: markerId),
      );
    } catch (_) {
      // 아직 추가되지 않은 마커를 지울 때는 무시합니다.
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
      ).showSnackBar(const SnackBar(content: Text('위치 권한이 거부되었습니다.')));
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해 주세요.'),
        ),
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
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.startPoint != widget.startPoint ||
        oldWidget.destinationPoint != widget.destinationPoint) {
      _renderRoutePointMarkers();
    }

    if (oldWidget.routePath != widget.routePath) {
      _renderRoutePathOverlay();
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
          },
          onCameraIdle: () async {
            await _reloadRoadOverlaysForVisibleBounds();
          },
          onMapTapped: (_, latLng) {
            widget.onRoutePointSelected(latLng);
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
