import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../features/favorite/service/favorite_service.dart';
import '../../features/map/service/place_search_service.dart';

class PlaceActionBottomSheet extends StatefulWidget {
  final NLatLng point;
  final String? placeName;
  final int? userId;
  final VoidCallback onFavoriteChanged;
  final void Function(String displayName) onSelectStart;
  final void Function(String displayName) onSelectDestination;

  const PlaceActionBottomSheet({
    super.key,
    required this.point,
    required this.placeName,
    required this.userId,
    required this.onFavoriteChanged,
    required this.onSelectStart,
    required this.onSelectDestination,
  });

  @override
  State<PlaceActionBottomSheet> createState() => _PlaceActionBottomSheetState();
}

class _PlaceActionBottomSheetState extends State<PlaceActionBottomSheet> {
  String? address;
  FavoritePlace? favorite;
  bool isLoadingAddress = true;
  bool isLoadingFavorite = true;
  bool isSavingFavorite = false;

  String get title {
    final name = widget.placeName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (address != null && address!.isNotEmpty) return address!;
    return '선택한 위치';
  }

  String get displayName {
    final name = widget.placeName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (address != null && address!.isNotEmpty) return address!;
    return '지도에서 선택한 위치';
  }

  @override
  void initState() {
    super.initState();
    loadAddress();
    loadFavoriteStatus();
  }

  Future<void> loadFavoriteStatus() async {
    final userId = widget.userId;
    if (userId == null) {
      if (mounted) setState(() => isLoadingFavorite = false);
      return;
    }

    try {
      final favorites = await FavoriteService.loadFavorites(userId);
      FavoritePlace? matched;
      for (final item in favorites) {
        final sameLatitude =
            (item.latitude - widget.point.latitude).abs() < 0.000001;
        final sameLongitude =
            (item.longitude - widget.point.longitude).abs() < 0.000001;
        if (sameLatitude && sameLongitude) {
          matched = item;
          break;
        }
      }
      if (!mounted) return;
      setState(() => favorite = matched);
    } catch (_) {
      // Favorite status does not block selecting the place as a route point.
    } finally {
      if (mounted) setState(() => isLoadingFavorite = false);
    }
  }

  Future<void> toggleFavorite() async {
    final userId = widget.userId;
    if (userId == null) {
      showMessage('로그인 후 즐겨찾기를 사용할 수 있습니다.');
      return;
    }
    if (isSavingFavorite || isLoadingFavorite) return;

    if (widget.placeName?.trim().isEmpty != false && isLoadingAddress) {
      showMessage('주소를 불러온 후 다시 시도해 주세요.');
      return;
    }

    setState(() => isSavingFavorite = true);
    try {
      final savedFavorite = favorite;
      if (savedFavorite == null) {
        await FavoriteService.createFavorite(
          userId: userId,
          alias: displayName,
          latitude: widget.point.latitude,
          longitude: widget.point.longitude,
        );
        await loadFavoriteStatus();
        widget.onFavoriteChanged();
        if (mounted) showMessage('즐겨찾기에 추가했습니다.');
      } else {
        await FavoriteService.deleteFavorite(
          userId: userId,
          favoriteId: savedFavorite.favoriteId,
        );
        if (!mounted) return;
        setState(() => favorite = null);
        widget.onFavoriteChanged();
        showMessage('즐겨찾기에서 삭제했습니다.');
      }
    } catch (error) {
      if (mounted) {
        showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => isSavingFavorite = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> loadAddress() async {
    try {
      final result = await PlaceSearchService.reverseGeocode(
        latitude: widget.point.latitude,
        longitude: widget.point.longitude,
      );
      if (!mounted) return;
      setState(() => address = result);
    } catch (_) {
      // The selected coordinate can still be used when address lookup fails.
    } finally {
      if (mounted) setState(() => isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPlaceName = widget.placeName?.trim().isNotEmpty == true;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1EFFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.place_outlined,
                    color: Color(0xFF6546FF),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (hasPlaceName || isLoadingAddress) ...[
                        const SizedBox(height: 5),
                        Text(
                          isLoadingAddress
                              ? '주소를 불러오는 중입니다.'
                              : (address?.isNotEmpty == true
                                    ? address!
                                    : '주소를 확인할 수 없습니다.'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isLoadingFavorite || isSavingFavorite
                      ? null
                      : toggleFavorite,
                  tooltip: favorite == null ? '즐겨찾기 추가' : '즐겨찾기 삭제',
                  icon: isSavingFavorite
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          favorite == null
                              ? Icons.star_border_rounded
                              : Icons.star_rounded,
                          color: favorite == null
                              ? const Color(0xFF64748B)
                              : const Color(0xFFF59E0B),
                        ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: '닫기',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onSelectStart(displayName),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.trip_origin_rounded, size: 18),
                    label: const Text(
                      '출발',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onSelectDestination(displayName),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFF6546FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.flag_outlined, size: 19),
                    label: const Text(
                      '도착',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
