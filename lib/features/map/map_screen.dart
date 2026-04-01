import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const initialPosition = NLatLng(36.6424, 127.4890); // 청주 예시

    return NaverMap(
      options: const NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: initialPosition,
          zoom: 14,
        ),
      ),
      onMapReady: (controller) async {
        final marker = NMarker(
          id: 'marker_1',
          position: initialPosition,
          caption: const NOverlayCaption(text: '현재 테스트 위치'),
        );

        controller.addOverlay(marker);
      },
    );
  }
}
