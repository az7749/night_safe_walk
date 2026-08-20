import 'package:flutter/material.dart';

class MoreBottomSheet extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onEmergencyContactsTap;
  final VoidCallback onAlarmSettingsTap;
  final VoidCallback onAlarmLogsTap;
  final VoidCallback onReportHistoryTap;
  final VoidCallback onLogoutTap;

  const MoreBottomSheet({
    super.key,
    required this.onProfileTap,
    required this.onEmergencyContactsTap,
    required this.onAlarmSettingsTap,
    required this.onAlarmLogsTap,
    required this.onReportHistoryTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              physics: const ClampingScrollPhysics(),
              children: [
                _buildSectionLabel('계정'),
                const SizedBox(height: 8),
                _buildMenuGroup(
                  children: [
                    _buildMenuButton(
                      icon: Icons.person_outline,
                      title: '내 정보',
                      onTap: onProfileTap,
                      showDivider: true,
                    ),
                    _buildMenuButton(
                      icon: Icons.contact_phone_outlined,
                      title: '비상 연락처',
                      onTap: onEmergencyContactsTap,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildSectionLabel('이용 내역'),
                const SizedBox(height: 8),
                _buildMenuGroup(
                  children: [
                    _buildMenuButton(
                      icon: Icons.receipt_long_outlined,
                      title: '신고 내역',
                      onTap: onReportHistoryTap,
                      showDivider: true,
                    ),
                    _buildMenuButton(
                      icon: Icons.notifications_active_outlined,
                      title: '알림 내역',
                      onTap: onAlarmLogsTap,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildSectionLabel('앱'),
                const SizedBox(height: 8),
                _buildMenuGroup(
                  children: [
                    _buildMenuButton(
                      icon: Icons.settings_outlined,
                      title: '설정',
                      onTap: onAlarmSettingsTap,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildMenuButton(
                  icon: Icons.logout_rounded,
                  title: '로그아웃',
                  onTap: onLogoutTap,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildMenuGroup({required List<Widget> children}) {
    return Material(
      color: const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = false,
    bool isDestructive = false,
  }) {
    final foregroundColor = isDestructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF6546FF);

    return Material(
      color: const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDestructive
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isDestructive)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
