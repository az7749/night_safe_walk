import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class GuideBottomSheet extends StatelessWidget {
  final NLatLng? startPoint;
  final NLatLng? destinationPoint;
  final bool isRouteLoading;
  final VoidCallback onStartRoute;
  final VoidCallback onReset;

  const GuideBottomSheet({
    super.key,
    required this.startPoint,
    required this.destinationPoint,
    required this.isRouteLoading,
    required this.onStartRoute,
    required this.onReset,
  });

  String _formatPoint(NLatLng? point) {
    if (point == null) return '지도에서 선택해 주세요';
    return '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '길안내',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(onPressed: onReset, child: const Text('초기화')),
            ],
          ),
          const SizedBox(height: 12),
          _RoutePointTile(
            label: '출발지',
            value: _formatPoint(startPoint),
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 10),
          _RoutePointTile(
            label: '도착지',
            value: _formatPoint(destinationPoint),
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          // Text(
          //   destinationPoint == null
          //       ? '지도를 눌러 출발지와 도착지를 차례대로 선택하세요.'
          //       : '좌표 선택 완료. 길안내 시작을 누르면 경로가 표시됩니다.',
          //   style: const TextStyle(
          //     fontSize: 14,
          //     color: Color(0xFF6B7280),
          //     height: 1.35,
          //   ),
          // ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed:
                  startPoint != null &&
                      destinationPoint != null &&
                      !isRouteLoading
                  ? onStartRoute
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6546FF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: const Color(0xFF9CA3AF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(isRouteLoading ? '경로 계산 중' : '길안내 시작'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePointTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RoutePointTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }
}
