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

  static const NLatLng _defaultPosition = NLatLng(36.6424, 127.4890);

  Future<NOverlayImage> _buildMarkerIcon() {
    return NOverlayImage.fromWidget(
      context: context,
      size: const Size(26, 26),
      widget: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFEAB308),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Icon(
          Icons.lightbulb_outlined,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }

  Future<void> _loadFacilityMarkers() async {
    if (_mapController == null) return;

    print('_loadFacilityMarkers called');

    final markerIcon = await _buildMarkerIcon();

    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/facilities'),
    );

    print('statusCode: ${response.statusCode}');
    print('body: ${response.body}');

    final data = jsonDecode(response.body);

    if (data['success'] != true) return;
    print('facilities count: ${(data['facilities'] as List).length}');

    final List facilities = data['facilities'];

    for (final item in facilities) {
      print('marker: ${item['facility_id']} / ${item['lat']} / ${item['lng']}');
      final marker = NMarker(
        id: item['facility_id'].toString(),
        position: NLatLng(
          (item['lat'] as num).toDouble(),
          (item['lng'] as num).toDouble(),
        ),
        icon: markerIcon,
        size: const Size(26, 26),
        anchor: const NPoint(0.5, 0.5),
      );

      await _mapController!.addOverlay(marker);
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
            await _loadFacilityMarkers();
            //   final marker = NMarker(
            //     id: 'test',
            //     position: ,
            //     icon: markerIcon,
            //     size: const Size(26, 26),
            //     anchor: const NPoint(0.5, 0.5),
            //   );
            //   await controller.addOverlay(marker);
            //   // await controller.updateCamera(
            //   //   NCameraUpdate.scrollAndZoomTo(
            //   //     target: _cityHallPosition,
            //   //     zoom: 15,
            //   //   ),
            //   // );
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
