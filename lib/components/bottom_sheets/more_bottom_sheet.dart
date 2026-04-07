import 'package:flutter/material.dart';

class MoreBottomSheet extends StatelessWidget {
  const MoreBottomSheet({super.key});

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
          _buildMenuButton(
            icon: Icons.person_outline,
            title: '내 정보',
            onTap: () {
              debugPrint('내 정보 클릭');
            },
          ),
          // const SizedBox(height: 12),

          // _buildMenuButton(
          //   icon: Icons.contact_phone_outlined,
          //   title: '보호자 연락처',
          //   onTap: () {
          //     debugPrint('보호자 연락처 클릭');
          //   },
          // ),
          // const SizedBox(height: 12),

          // _buildMenuButton(
          //   icon: Icons.notifications_none,
          //   title: '알림 설정',
          //   onTap: () {
          //     debugPrint('알림 설정 클릭');
          //   },
          // ),
          // const SizedBox(height: 12),

          // _buildMenuButton(
          //   icon: Icons.receipt_long_outlined,
          //   title: '신고 내역',
          //   onTap: () {
          //     debugPrint('신고 내역 클릭');
          //   },
          // ),
          const SizedBox(height: 12),

          _buildMenuButton(
            icon: Icons.logout,
            title: '로그아웃',
            // isLogout: true,
            onTap: () {
              debugPrint('로그아웃 클릭');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6546FF), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
