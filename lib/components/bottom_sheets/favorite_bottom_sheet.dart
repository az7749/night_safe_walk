import 'package:flutter/material.dart';

import '../../features/favorite/service/favorite_service.dart';

class FavoriteBottomSheet extends StatefulWidget {
  final int? userId;
  final double? selectedLatitude;
  final double? selectedLongitude;
  final String suggestedAlias;
  final int refreshToken;
  final ValueChanged<FavoritePlace> onSelected;

  const FavoriteBottomSheet({
    super.key,
    required this.userId,
    required this.selectedLatitude,
    required this.selectedLongitude,
    required this.suggestedAlias,
    required this.refreshToken,
    required this.onSelected,
  });

  @override
  State<FavoriteBottomSheet> createState() => _FavoriteBottomSheetState();
}

class _FavoriteBottomSheetState extends State<FavoriteBottomSheet> {
  List<FavoritePlace> favorites = const [];
  bool isLoading = true;
  bool isSaving = false;

  bool get canAdd =>
      widget.userId != null &&
      widget.selectedLatitude != null &&
      widget.selectedLongitude != null;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  @override
  void didUpdateWidget(covariant FavoriteBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      loadFavorites();
    }
  }

  Future<void> loadFavorites() async {
    final userId = widget.userId;
    if (userId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final loaded = await FavoriteService.loadFavorites(userId);
      if (!mounted) return;
      setState(() {
        favorites = loaded;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage(error);
    }
  }

  Future<void> addFavorite() async {
    final userId = widget.userId;
    final latitude = widget.selectedLatitude;
    final longitude = widget.selectedLongitude;
    if (userId == null || latitude == null || longitude == null || isSaving) {
      return;
    }

    var pendingAlias = widget.suggestedAlias.trim().isEmpty
        ? '저장한 장소'
        : widget.suggestedAlias.trim();
    final alias = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('즐겨찾기 추가'),
        content: TextFormField(
          initialValue: pendingAlias,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: '장소 이름',
            hintText: '예: 집, 학교',
          ),
          onChanged: (value) => pendingAlias = value,
          onFieldSubmitted: (value) =>
              Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, pendingAlias.trim()),
            child: const Text('추가'),
          ),
        ],
      ),
    );
    if (alias == null || alias.isEmpty || !mounted) return;

    setState(() => isSaving = true);
    try {
      await FavoriteService.createFavorite(
        userId: userId,
        alias: alias,
        latitude: latitude,
        longitude: longitude,
      );
      await loadFavorites();
    } catch (error) {
      if (mounted) showMessage(error);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> deleteFavorite(FavoritePlace favorite) async {
    final userId = widget.userId;
    if (userId == null || isSaving) return;

    setState(() => isSaving = true);
    try {
      await FavoriteService.deleteFavorite(
        userId: userId,
        favoriteId: favorite.favoriteId,
      );
      if (!mounted) return;
      setState(() {
        favorites = favorites
            .where((item) => item.favoriteId != favorite.favoriteId)
            .toList();
      });
    } catch (error) {
      if (mounted) showMessage(error);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void showMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    onPressed: canAdd && !isSaving ? addFavorite : null,
                    tooltip: canAdd ? '선택한 장소 추가' : '지도에서 장소를 먼저 선택하세요',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_location_alt_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : favorites.isEmpty
                ? Center(
                    child: Text(
                      canAdd
                          ? '오른쪽 위 추가 버튼으로 장소를 저장하세요.'
                          : '지도에서 장소를 선택한 후 저장할 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: favorites.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final favorite = favorites[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.place_outlined,
                          color: Color(0xFF6546FF),
                        ),
                        title: Text(
                          favorite.alias,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: IconButton(
                          onPressed: isSaving
                              ? null
                              : () => deleteFavorite(favorite),
                          tooltip: '삭제',
                          icon: const Icon(Icons.delete_outline),
                        ),
                        onTap: () => widget.onSelected(favorite),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
