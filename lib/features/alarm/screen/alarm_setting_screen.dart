import 'package:flutter/material.dart';

import '../service/alarm_setting_service.dart';
import '../service/background_risk_monitor_service.dart';

class AlarmSettingScreen extends StatefulWidget {
  final int userId;

  const AlarmSettingScreen({super.key, required this.userId});

  @override
  State<AlarmSettingScreen> createState() => _AlarmSettingScreenState();
}

class _AlarmSettingScreenState extends State<AlarmSettingScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _riskZoneAlert = true;
  bool _pushAlert = true;
  bool _vibrationAlert = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await AlarmSettingService.loadSettings(widget.userId);
      if (!mounted) return;
      setState(() {
        _riskZoneAlert = settings.riskZoneAlert;
        _pushAlert = settings.pushAlert;
        _vibrationAlert = settings.vibrationAlert;
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

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final settings = AlarmSettings(
        riskZoneAlert: _riskZoneAlert,
        pushAlert: _pushAlert,
        vibrationAlert: _vibrationAlert,
      );
      await AlarmSettingService.saveSettings(
        userId: widget.userId,
        settings: settings,
      );
      await BackgroundRiskMonitorService.startOrUpdate(
        userId: widget.userId,
        settings: settings,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('설정을 저장했습니다.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _buildBody(),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6546FF),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(_isSaving ? '저장 중...' : '저장'),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadSettings,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _SectionTitle(title: '알림'),
        const SizedBox(height: 8),
        _SettingTile(
          icon: Icons.warning_amber_rounded,
          title: '위험구역 진입 알림',
          subtitle: '위험 등급 도로 진입 시 화면 경고를 표시합니다.',
          value: _riskZoneAlert,
          onChanged: (value) => setState(() => _riskZoneAlert = value),
        ),
        const SizedBox(height: 10),
        _SettingTile(
          icon: Icons.vibration_rounded,
          title: '진동 알림',
          subtitle: '위험구역 진입 알림과 함께 진동을 사용합니다.',
          value: _vibrationAlert,
          onChanged: _riskZoneAlert
              ? (value) => setState(() => _vibrationAlert = value)
              : null,
        ),
        const SizedBox(height: 10),
        _SettingTile(
          icon: Icons.notifications_outlined,
          title: '푸시 알림',
          subtitle: '위험 및 긴급 알림을 푸시로 수신합니다.',
          value: _pushAlert,
          onChanged: (value) => setState(() => _pushAlert = value),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EDFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF6546FF), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
