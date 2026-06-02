import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key});
  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(children: [
        // ── Header ──
        Container(
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.canPop(context) ? Navigator.pop(context) : null,
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    ),
                  ),
                  const Expanded(
                    child: Text('Absences', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 36),
                ]),
              ),
              TabBar(
                controller: _tabCtrl,
                indicatorColor: const Color(0xFFE5A01A),
                labelColor: const Color(0xFFE5A01A),
                unselectedLabelColor: const Color(0xFF888888),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Nouvelle demande'),
                  Tab(text: 'Mes demandes'),
                ],
              ),
            ]),
          ),
        ),

        // ── Tabs ──
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              _NewRequestTab(),
              _HistoryTab(),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── New Request Tab ────────────────────────────────────────────────────────────

class _NewRequestTab extends StatefulWidget {
  const _NewRequestTab();
  @override
  State<_NewRequestTab> createState() => _NewRequestTabState();
}

class _NewRequestTabState extends State<_NewRequestTab> {
  final _formKey   = GlobalKey<FormState>();
  final _motifCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool      _submitting = false;
  String?   _success;
  String?   _error;

  final _fmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() { _motifCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFE5A01A), onPrimary: Colors.white,
            surface: Colors.white, onSurface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Veuillez sélectionner les deux dates');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'La date de fin doit être après la date de début');
      return;
    }

    setState(() { _submitting = true; _error = null; _success = null; });
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      final coachRes = await DioClient.instance.dio.get(ApiConstants.coachByUser(user.id));
      final coachId  = (coachRes.data['id'] as num).toInt();

      await DioClient.instance.dio.post(
        '/absence-requests/coach/$coachId',
        data: {
          'startDate': _startDate!.toIso8601String().split('T').first,
          'endDate':   _endDate!.toIso8601String().split('T').first,
          'reason':    _motifCtrl.text.trim(),
        },
      );

      setState(() {
        _success    = 'Demande envoyée du ${_fmt.format(_startDate!)} au ${_fmt.format(_endDate!)}. En attente de validation.';
        _submitting = false;
        _motifCtrl.clear();
        _startDate  = null;
        _endDate    = null;
      });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 18),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Votre demande sera soumise à l\'administrateur pour validation avant d\'être prise en compte.',
                style: TextStyle(color: Color(0xFF555555), fontSize: 12, height: 1.4),
              )),
            ]),
          ),
          const SizedBox(height: 20),

          if (_success != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3DE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_success!, style: const TextStyle(color: Color(0xFF3B6D11), fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
              ),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFE53935), fontSize: 13)),
            ),
            const SizedBox(height: 16),
          ],

          const Text("Période d'absence",
            style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _DateField(
              label: 'Date de début',
              value: _startDate != null ? _fmt.format(_startDate!) : null,
              onTap: () => _pickDate(true),
            )),
            const SizedBox(width: 12),
            Expanded(child: _DateField(
              label: 'Date de fin',
              value: _endDate != null ? _fmt.format(_endDate!) : null,
              onTap: () => _pickDate(false),
            )),
          ]),
          const SizedBox(height: 20),

          const Text('Motif',
            style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motifCtrl,
            maxLines: 4,
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Vacances, maladie, formation...',
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5A01A), width: 1)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Motif requis' : null,
          ),
          const SizedBox(height: 28),

          GestureDetector(
            onTap: _submitting ? null : _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _submitting ? const Color(0xFF444444) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_submitting)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFFE5A01A), strokeWidth: 2))
                else
                  const Icon(Icons.send_outlined, color: Color(0xFFE5A01A), size: 18),
                const SizedBox(width: 10),
                const Text("Soumettre la demande",
                  style: TextStyle(color: Color(0xFFE5A01A), fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── History Tab ────────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>> _requests = [];
  bool   _loading = true;
  String? _error;

  final _fmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      final coachRes = await DioClient.instance.dio.get(ApiConstants.coachByUser(user.id));
      final coachId  = (coachRes.data['id'] as num).toInt();

      final res  = await DioClient.instance.dio.get('/absence-requests/coach/$coachId', queryParameters: {'size': 50, 'sort': 'createdAt,desc'});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _requests = List<Map<String, dynamic>>.from(list as List);
        _loading  = false;
      });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'APPROVED': return const Color(0xFF4CBA7D);
      case 'REJECTED': return const Color(0xFFE53935);
      default:         return const Color(0xFFE5A01A);
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'APPROVED': return 'Approuvée';
      case 'REJECTED': return 'Refusée';
      default:         return 'En attente';
    }
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'APPROVED': return Icons.check_circle_outline;
      case 'REJECTED': return Icons.cancel_outlined;
      default:         return Icons.hourglass_empty;
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    try { return _fmt.format(DateTime.parse(d)); } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)));
    if (_error != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Color(0xFF888888))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A01A), foregroundColor: Colors.black), child: const Text('Réessayer')),
    ]));

    if (_requests.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFE5A01A).withValues(alpha: 0.10), shape: BoxShape.circle),
        child: const Icon(Icons.event_available, color: Color(0xFFE5A01A), size: 30)),
      const SizedBox(height: 12),
      const Text('Aucune demande', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('Vos demandes apparaîtront ici', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
    ]));

    return RefreshIndicator(
      color: const Color(0xFFE5A01A),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r      = _requests[i];
          final status = r['status'] as String?;
          final color  = _statusColor(status);
          final start  = _formatDate(r['startDate'] as String?);
          final end    = _formatDate(r['endDate']   as String?);
          final note   = r['adminNote'] as String?;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_statusIcon(status), color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('$start → $end',
                  style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text(_statusLabel(status), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
              if ((r['reason'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(r['reason'] as String, style: const TextStyle(color: Color(0xFF888888), fontSize: 12, height: 1.4)),
              ],
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 13, color: color),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Note admin : $note',
                      style: TextStyle(color: color, fontSize: 11, height: 1.4))),
                  ]),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

// ── Date field widget ──────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _DateField({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null ? const Color(0xFFE5A01A).withValues(alpha: 0.5) : const Color(0xFFE8E8E8),
          width: value != null ? 1.0 : 0.5,
        ),
      ),
      child: Row(children: [
        Icon(Icons.calendar_today, size: 16, color: value != null ? const Color(0xFFE5A01A) : const Color(0xFFBBBBBB)),
        const SizedBox(width: 8),
        Expanded(child: Text(value ?? label,
          style: TextStyle(color: value != null ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB), fontSize: 13))),
      ]),
    ),
  );
}
