import 'package:flutter/material.dart';

import '../service/alarm_log_service.dart';

class AlarmLogScreen extends StatefulWidget {
  final int userId;

  const AlarmLogScreen({super.key, required this.userId});

  @override
  State<AlarmLogScreen> createState() => _AlarmLogScreenState();
}

class _AlarmLogScreenState extends State<AlarmLogScreen> {
  List<AlarmLog> _logs = const [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AlarmLogService.loadLogs(widget.userId);
      if (!mounted) return;
      setState(() {
        _logs = result.logs;
        _unreadCount = result.unreadCount;
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

  Future<void> _markAsRead(AlarmLog log) async {
    if (log.isRead || _isUpdating) return;
    setState(() {
      _isUpdating = true;
    });

    try {
      await AlarmLogService.markAsRead(userId: widget.userId, logId: log.logId);
      if (!mounted) return;
      setState(() {
        _logs = _logs
            .map(
              (item) =>
                  item.logId == log.logId ? item.copyWith(isRead: true) : item,
            )
            .toList();
        _unreadCount = (_unreadCount - 1).clamp(0, _logs.length);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0 || _isUpdating) return;
    setState(() {
      _isUpdating = true;
    });

    try {
      await AlarmLogService.markAllAsRead(widget.userId);
      if (!mounted) return;
      setState(() {
        _logs = _logs.map((log) => log.copyWith(isRead: true)).toList();
        _unreadCount = 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteLog(AlarmLog log) async {
    if (_isUpdating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 삭제'),
        content: const Text('이 알림 내역을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await AlarmLogService.deleteLog(
        userId: widget.userId,
        logId: log.logId,
      );
      if (!mounted) return;
      setState(() {
        _logs = _logs.where((item) => item.logId != log.logId).toList();
        if (!log.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, _logs.length);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteAll() async {
    if (_logs.isEmpty || _isUpdating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 알림 삭제'),
        content: const Text('모든 알림 내역을 삭제할까요?\n삭제한 내역은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            child: const Text('전체 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await AlarmLogService.deleteAll(widget.userId);
      if (!mounted) return;
      setState(() {
        _logs = const [];
        _unreadCount = 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('알림 내역'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _isUpdating ? null : _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 19),
              label: const Text('모두 읽음'),
            ),
          if (_logs.isNotEmpty)
            IconButton(
              onPressed: _isUpdating ? null : _deleteAll,
              tooltip: '전체 삭제',
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: _buildBody(),
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
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (_logs.isNotEmpty) ...[
            Text(
              _unreadCount == 0 ? '새 알림이 없습니다.' : '읽지 않은 알림 $_unreadCount개',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 160),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 14),
                  Text(
                    '수신한 알림이 없습니다.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._logs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlarmLogTile(
                  log: log,
                  onTap: () => _markAsRead(log),
                  onDelete: () => _deleteLog(log),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlarmLogTile extends StatelessWidget {
  final AlarmLog log;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AlarmLogTile({
    required this.log,
    required this.onTap,
    required this.onDelete,
  });

  bool get _isSos => log.alarmType.trim() == 'sos';

  String get _title => _isSos ? '긴급 SOS 요청' : '위험구역 진입';

  String get _content => _isSos
      ? log.content
      : '위험구역에 진입했습니다. 주변을 살피고 안전에 유의해주세요.';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: log.isRead ? Colors.white : const Color(0xFFFFF7F7),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: log.isRead
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSos ? Icons.sos_rounded : Icons.warning_amber_rounded,
                  color: Color(0xFFE11D48),
                  size: 21,
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
                            _title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!log.isRead) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE11D48),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        IconButton(
                          onPressed: onDelete,
                          tooltip: '삭제',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _content,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formatDate(log.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
