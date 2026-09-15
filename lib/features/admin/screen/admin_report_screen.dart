import 'package:flutter/material.dart';

import '../../auth/screen/login_screen.dart';
import '../../report/service/facility_report_service.dart';
import '../service/admin_report_service.dart';
import 'admin_management_screen.dart';

class AdminReportScreen extends StatefulWidget {
  final int adminUserId;

  const AdminReportScreen({super.key, required this.adminUserId});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _statusGroups = ['received', 'approved', 'history'];

  late final TabController _tabController;
  List<FacilityReportHistoryItem> _reports = const [];
  int _selectedTab = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reports = await AdminReportService.loadReports(
        adminUserId: widget.adminUserId,
        statusGroup: _statusGroups[_selectedTab],
      );
      if (!mounted) return;
      setState(() {
        _reports = reports;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() {
      _selectedTab = index;
      _reports = const [];
    });
    _loadReports();
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openReport(FacilityReportHistoryItem report) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminReportDetailScreen(
          adminUserId: widget.adminUserId,
          report: report,
        ),
      ),
    );

    if (changed == true && mounted) {
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(title: Text('관리자')),
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('신고 관리'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('회원 관리'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminManagementScreen(
                        adminUserId: widget.adminUserId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('시설물 관리'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminManagementScreen(
                        adminUserId: widget.adminUserId,
                        facilities: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('신고 관리'),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: _selectTab,
          labelColor: const Color(0xFF6546FF),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF6546FF),
          tabs: const [
            Tab(text: '검수 대기'),
            Tab(text: '승인됨'),
            Tab(text: '처리 이력'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _AdminMessageView(
        icon: Icons.error_outline_rounded,
        message: _errorMessage!,
        buttonLabel: '다시 불러오기',
        onPressed: _loadReports,
      );
    }

    if (_reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 14),
            Center(
              child: Text(
                '해당하는 신고가 없습니다.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: _reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _AdminReportListItem(
            report: report,
            onTap: () => _openReport(report),
          );
        },
      ),
    );
  }
}

class AdminReportDetailScreen extends StatefulWidget {
  final int adminUserId;
  final FacilityReportHistoryItem report;

  const AdminReportDetailScreen({
    super.key,
    required this.adminUserId,
    required this.report,
  });

  @override
  State<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  bool _isSubmitting = false;

  Future<void> _confirmAction(String action) async {
    final actionLabel = switch (action) {
      'approved' => '승인',
      'rejected' => '반려',
      _ => '처리 완료',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('신고 $actionLabel'),
        content: Text('이 신고를 $actionLabel 처리하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      await AdminReportService.updateStatus(
        adminUserId: widget.adminUserId,
        reportId: widget.report.reportId,
        action: action,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('신고가 $actionLabel 처리되었습니다.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('신고 상세'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: report.imageUrl == null
                  ? const _AdminImagePlaceholder()
                  : Image.network(
                      report.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _AdminImagePlaceholder(),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _AdminDetailRow(label: '처리 상태', value: _statusLabel(report.status)),
          _AdminDetailRow(
            label: '시설물',
            value: _facilityLabel(report.facilityType),
          ),
          _AdminDetailRow(
            label: '시설물 ID',
            value: report.facilityId?.toString() ?? '-',
          ),
          _AdminDetailRow(
            label: '고장 유형',
            value: _reportTypeLabel(report.reportType),
          ),
          _AdminDetailRow(label: '접수 일시', value: _formatDate(report.createdAt)),
          const SizedBox(height: 20),
          const Text(
            '상세 내용',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            report.description.isEmpty
                ? '작성된 상세 내용이 없습니다.'
                : report.description,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActions(),
    );
  }

  Widget? _buildActions() {
    final status = widget.report.status;

    if (status == 'received' || status == 'checking') {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _confirmAction('rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                  ),
                  child: const Text('반려'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _confirmAction('approved'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6546FF),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('승인'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'approved') {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : () => _confirmAction('completed'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('처리 완료'),
          ),
        ),
      );
    }

    return null;
  }
}

class _AdminReportListItem extends StatelessWidget {
  final FacilityReportHistoryItem report;
  final VoidCallback onTap;

  const _AdminReportListItem({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: report.imageUrl == null
                      ? const _AdminImagePlaceholder()
                      : Image.network(
                          report.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _AdminImagePlaceholder(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _facilityLabel(report.facilityType),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          _statusLabel(report.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _reportTypeLabel(report.reportType),
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatDate(report.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _AdminDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminImagePlaceholder extends StatelessWidget {
  const _AdminImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF1F5F9),
      child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
    );
  }
}

class _AdminMessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _AdminMessageView({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF64748B)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

String _facilityLabel(String type) {
  return type == 'street_light' ? '가로등' : '보안등';
}

String _reportTypeLabel(String type) {
  return switch (type) {
    'not_working' => '불이 켜지지 않음',
    'flickering' => '불빛이 깜빡임',
    'damaged' => '시설물 파손',
    _ => '기타',
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'approved' => '승인',
    'rejected' => '반려',
    'completed' => '처리 완료',
    'checking' => '확인 중',
    _ => '검수 대기',
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'approved' => const Color(0xFF2563EB),
    'rejected' => const Color(0xFFDC2626),
    'completed' => const Color(0xFF15803D),
    _ => const Color(0xFFB45309),
  };
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
