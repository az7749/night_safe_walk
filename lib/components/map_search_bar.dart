import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onTap;
  final VoidCallback? onSearch;
  final ValueChanged<String>? onSubmitted;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onTap,
    this.onSearch,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: Container(
            height: 52,
            padding: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onTap: onTap,
                    onSubmitted: onSubmitted,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: '검색',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Container(width: 1, height: 22, color: Colors.grey.shade300),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
