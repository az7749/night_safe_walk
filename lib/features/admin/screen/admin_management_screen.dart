import 'package:flutter/material.dart';
import '../../../utils/phone_number_formatter.dart';
import '../service/admin_management_service.dart';

const facilityLabels = <String, String>{
  'street_light': '가로등',
  'security_light': '보안등',
  'cctv': 'CCTV',
  'police_station': '경찰서',
  'fire_station': '소방서',
  'convenience_store': '편의점',
  'emergency_bell': '비상벨',
};

class AdminManagementScreen extends StatefulWidget {
  final int adminUserId;
  final bool facilities;
  const AdminManagementScreen({
    super.key,
    required this.adminUserId,
    this.facilities = false,
  });
  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true, _more = false;
  String? _error;
  String _query = '';
  int _page = 0;
  String get _resource => widget.facilities ? 'facilities' : 'users';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AdminManagementService.load(
        _resource,
        widget.adminUserId,
        query: _query,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(result['items']);
        _more = result['has_more'] == true;
      });
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _submit() {
    if (_loading) return;
    final text = _search.text.trim();
    _query = widget.facilities
        ? facilityLabels.entries
                  .where((e) => e.value == text)
                  .map((e) => e.key)
                  .firstOrNull ??
              text
        : text;
    _page = 0;
    _load();
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _ManagementDetail(
          adminId: widget.adminUserId,
          facilities: widget.facilities,
          item: item,
        ),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.facilities ? '시설물 관리' : '회원 관리')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.facilities ? '시설물 번호 또는 종류' : '아이디, 이름, 전화번호',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: '검색',
                  onPressed: _loading ? null : _submit,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _load,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _items.isEmpty ? 1 : _items.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        if (_items.isEmpty)
                          return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: Text('검색 결과가 없습니다.')),
                          );
                        final item = _items[index];
                        return ListTile(
                          leading: Icon(
                            widget.facilities
                                ? Icons.location_on_outlined
                                : Icons.person_outline,
                          ),
                          title: Text(
                            widget.facilities
                                ? '${facilityLabels[item['type']] ?? item['type']} #${item['id']}'
                                : '${item['name']} (${item['login_id']})',
                          ),
                          subtitle: Text(
                            widget.facilities
                                ? '${item['lat']}, ${item['lng']}'
                                : '${item['phone'] ?? ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(item),
                        );
                      },
                    ),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: '이전 페이지',
                onPressed: _loading || _page == 0
                    ? null
                    : () {
                        _page--;
                        _load();
                      },
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${_page + 1}'),
              IconButton(
                tooltip: '다음 페이지',
                onPressed: _loading || !_more
                    ? null
                    : () {
                        _page++;
                        _load();
                      },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ManagementDetail extends StatefulWidget {
  final int adminId;
  final bool facilities;
  final Map<String, dynamic> item;
  const _ManagementDetail({
    required this.adminId,
    required this.facilities,
    required this.item,
  });
  @override
  State<_ManagementDetail> createState() => _ManagementDetailState();
}

class _ManagementDetailState extends State<_ManagementDetail> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _first, _second;
  String? _type, _error;
  List<String> _types = [];
  bool _saving = false, _loading = false;
  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _first = TextEditingController(
      text: '${item[widget.facilities ? 'lat' : 'name'] ?? ''}',
    );
    _second = TextEditingController(
      text: '${item[widget.facilities ? 'lng' : 'phone'] ?? ''}',
    );
    if (widget.facilities) {
      _type = item['type'];
      _loadTypes();
    }
  }

  Future<void> _loadTypes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminManagementService.load(
        'facility-types',
        widget.adminId,
      );
      if (mounted) setState(() => _types = List<String>.from(data['types']));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  String? _coordinate(String? value, int limit) {
    final number = double.tryParse(value ?? '');
    return number == null || !number.isFinite || number.abs() > limit
        ? '좌표 범위를 확인해주세요.'
        : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AdminManagementService.save(
        widget.facilities ? 'facilities' : 'users',
        widget.adminId,
        widget.item['id'],
        widget.facilities
            ? {
                'type': _type,
                'lat': double.parse(_first.text),
                'lng': double.parse(_second.text),
              }
            : {'name': _first.text.trim(), 'phone': _second.text.trim()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정보가 수정되었습니다.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.facilities ? '시설물 정보 수정' : '회원 정보 수정')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!widget.facilities) ...[
                Text('아이디: ${widget.item['login_id']}'),
                const SizedBox(height: 8),
                Text('생년월일: ${widget.item['birth_date'] ?? '-'}'),
                const SizedBox(height: 8),
                Text('성별: ${widget.item['gender'] ?? '-'}'),
                const SizedBox(height: 8),
                Text('역할: ${widget.item['role'] == 'admin' ? '관리자' : '회원'}'),
                const SizedBox(height: 8),
                Text('가입일: ${widget.item['created_at'] ?? '-'}'),
              ],
              if (widget.facilities) ...[
                Text('시설물 번호: ${widget.item['id']}'),
                const SizedBox(height: 16),
                if (_loading) const LinearProgressIndicator(),
                if (!_loading && _types.isEmpty)
                  TextButton(
                    onPressed: _loadTypes,
                    child: const Text('종류 다시 불러오기'),
                  ),
                if (_types.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _types.contains(_type) ? _type : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '종류'),
                    items: _types
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(facilityLabels[t] ?? t),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _type = value),
                    validator: (value) => value == null ? '종류를 선택해주세요.' : null,
                  ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _first,
                enabled: !_saving,
                maxLength: widget.facilities ? null : 50,
                keyboardType: widget.facilities
                    ? const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      )
                    : TextInputType.name,
                decoration: InputDecoration(
                  labelText: widget.facilities ? '위도' : '이름',
                ),
                validator: (v) => widget.facilities
                    ? _coordinate(v, 90)
                    : (v == null || v.trim().isEmpty ? '이름을 입력해주세요.' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _second,
                enabled: !_saving,
                keyboardType: widget.facilities
                    ? const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      )
                    : TextInputType.phone,
                inputFormatters: widget.facilities
                    ? null
                    : [const PhoneNumberInputFormatter()],
                decoration: InputDecoration(
                  labelText: widget.facilities ? '경도' : '전화번호',
                ),
                validator: (v) => widget.facilities
                    ? _coordinate(v, 180)
                    : (RegExp(
                            r'^01[016789]\d{7,8}$',
                          ).hasMatch((v ?? '').replaceAll(RegExp(r'\D'), ''))
                          ? null
                          : '휴대전화 번호를 확인해주세요.'),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed:
                    _saving || _loading || (widget.facilities && _types.isEmpty)
                    ? null
                    : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
