import 'package:flutter/material.dart';

import '../../../utils/phone_number_formatter.dart';
import '../service/emergency_contact_service.dart';

class EmergencyContactScreen extends StatefulWidget {
  final int userId;

  const EmergencyContactScreen({super.key, required this.userId});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  List<EmergencyContact> _contacts = const [];
  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final contacts = await EmergencyContactService.loadContacts(
        widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
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

  Future<void> _openContactForm([EmergencyContact? contact]) async {
    if (_isMutating || (contact == null && _contacts.length >= 3)) return;

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _EmergencyContactFormSheet(contact: contact),
    );

    if (result == null || !mounted) return;
    setState(() {
      _isMutating = true;
    });

    try {
      if (contact == null) {
        await EmergencyContactService.createContact(
          userId: widget.userId,
          name: result['name']!,
          phone: result['phone']!,
        );
      } else {
        await EmergencyContactService.updateContact(
          userId: widget.userId,
          contactId: contact.contactId,
          name: result['name']!,
          phone: result['phone']!,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(contact == null ? '연락처를 등록했습니다.' : '연락처를 수정했습니다.'),
        ),
      );
      await _loadContacts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    if (_isMutating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비상 연락처 삭제'),
        content: Text('${contact.name} 연락처를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      _isMutating = true;
    });

    try {
      await EmergencyContactService.deleteContact(
        userId: widget.userId,
        contactId: contact.contactId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연락처를 삭제했습니다.')));
      await _loadContacts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('비상 연락처'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      floatingActionButton: !_isLoading && _contacts.length < 3
          ? FloatingActionButton(
              onPressed: _isMutating ? null : _openContactForm,
              tooltip: '비상 연락처 추가',
              backgroundColor: const Color(0xFF6546FF),
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add_alt_1_rounded),
            )
          : null,
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
                onPressed: _loadContacts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            '등록된 연락처 ${_contacts.length}/3',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 130),
              child: Column(
                children: [
                  Icon(
                    Icons.contact_phone_outlined,
                    size: 48,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 14),
                  Text(
                    '등록된 비상 연락처가 없습니다.',
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
            ..._contacts.map(
              (contact) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EmergencyContactListItem(
                  contact: contact,
                  enabled: !_isMutating,
                  onEdit: () => _openContactForm(contact),
                  onDelete: () => _deleteContact(contact),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmergencyContactListItem extends StatelessWidget {
  final EmergencyContact contact;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmergencyContactListItem({
    required this.contact,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF6546FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phone,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: enabled ? onEdit : null,
            tooltip: '수정',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: enabled ? onDelete : null,
            tooltip: '삭제',
            color: const Color(0xFFDC2626),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactFormSheet extends StatefulWidget {
  final EmergencyContact? contact;

  const _EmergencyContactFormSheet({this.contact});

  @override
  State<_EmergencyContactFormSheet> createState() =>
      _EmergencyContactFormSheetState();
}

class _EmergencyContactFormSheetState
    extends State<_EmergencyContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(
      text: formatPhoneNumber(widget.contact?.phone ?? ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.contact == null ? '비상 연락처 추가' : '비상 연락처 수정',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 20,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '이름을 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: const [PhoneNumberInputFormatter()],
              decoration: const InputDecoration(
                labelText: '전화번호',
                hintText: '010-1234-5678',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                if (!RegExp(r'^01[016789]\d{7,8}$').hasMatch(digits)) {
                  return '올바른 휴대전화 번호를 입력해주세요.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6546FF),
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(widget.contact == null ? '추가' : '저장'),
            ),
          ],
        ),
      ),
    );
  }
}
