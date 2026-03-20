import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final ValueChanged<int> onTap;

  const BottomNavbar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 72, // 하단바 높이 확보
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(
              icon: Icons.room_outlined,
              label: '길안내',
              onPressed: () => onTap(0),
            ),
            _NavButton(
              icon: Icons.star_outline,
              label: '즐겨찾기',
              onPressed: () => onTap(1),
            ),
            _NavButton(
              icon: Icons.menu,
              label: '더보기',
              onPressed: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
          children: [
            Icon(icon),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 14), // 글자 살짝 줄임
            ),
          ],
        ),
      ),
    );
  }
}
