import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class GuideBottomSheet extends StatelessWidget {
  final NLatLng? startPoint;
  final NLatLng? destinationPoint;
  final bool isRouteLoading;
  final VoidCallback onReset;
  final ValueChanged<String> onRouteSelected;
  final String? startPointName;
  final String? destinationPointName;

  const GuideBottomSheet({
    super.key,
    required this.startPoint,
    required this.destinationPoint,
    required this.isRouteLoading,
    required this.onReset,
    required this.onRouteSelected,
    this.startPointName,
    this.destinationPointName,
  });

  String _formatPoint(NLatLng? point, String? name) {
    if (point == null) return '지도에서 선택해 주세요';
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return '지도에서 선택한 위치';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SingleChildScrollView(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onReset,
                    tooltip: '출발지와 도착지 초기화',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _RoutePointRow(
                  label: '출발지',
                  value: _formatPoint(startPoint, startPointName),
                  color: const Color(0xFF2563EB),
                ),
                const Divider(height: 1, indent: 48, endIndent: 14),
                _RoutePointRow(
                  label: '도착지',
                  value: _formatPoint(destinationPoint, destinationPointName),
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            for (final mode in ['fast', 'safe']) ...[
              if (mode == 'safe') const SizedBox(width: 10),
              Expanded(child: SizedBox(height: 48, child: FilledButton.icon(
                onPressed: startPoint == null || destinationPoint == null || isRouteLoading
                    ? null : () => onRouteSelected(mode),
                style: FilledButton.styleFrom(
                  backgroundColor: mode == 'fast' ? const Color(0xFF2563EB) : const Color(0xFF6546FF),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(mode == 'fast' ? Icons.directions_walk_rounded : Icons.shield_outlined, size: 20),
                label: FittedBox(child: Text(mode == 'fast' ? '빠른길' : '안전한길')),
              ))),
            ],
          ]),
          if (isRouteLoading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xFF6546FF),
                backgroundColor: Color(0xFFE5E7EB),
              ),
            ),
        ],
      )),
    );
  }
}

class _RoutePointRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RoutePointRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
