import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';

class AdminAbsencesPage extends StatefulWidget {
  const AdminAbsencesPage({super.key});
  @override
  State<AdminAbsencesPage> createState() => _AdminAbsencesPageState();
}

class _AdminAbsencesPageState extends State<AdminAbsencesPage> {
  final _dio = ApiClient().dio;
  final _fmt = DateFormat('dd/MM/yyyy');

  List<Map<String, dynamic>> _requests = [];
  bool   _loading = true;
  String? _error;
  String  _filter = 'PENDING';

  static const _filters = [
    {'key': 'ALL',      'label': 'Toutes'},
    {'key': 'PENDING',  'label': 'En attente'},
    {'key': 'APPROVED', 'label': 'Approuvées'},
    {'key': 'REJECTED', 'label': 'Refusées'},
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{'size': 100, 'sort': 'createdAt,desc'};
      if (_filter != 'ALL') params['status'] = _filter;
      final res  = await _dio.get('/absence-requests', queryParameters: params);
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _requests = List<Map<String, dynamic>>.from(list as List);
        _loading  = false;
      });
    } on DioException catch (e) {
      setState(() { _error = e.response?.data?['message'] ?? 'Erreur de chargement'; _loading = false; });
    }
  }

  int _pendingCount() => _requests.where((r) => r['status'] == 'PENDING').length;

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

  String _formatDate(String? d) {
    if (d == null) return '';
    try { return _fmt.format(DateTime.parse(d)); } catch (_) { return d; }
  }

  String _initials(Map<String, dynamic> r) {
    final f = (r['coachFirstName'] as String? ?? '');
    final l = (r['coachLastName']  as String? ?? '');
    return ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase();
  }

  void _openDetail(Map<String, dynamic> request) {
    final noteCtrl = TextEditingController();
    bool acting = false;

    final isPending = request['status'] == 'PENDING';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFF444444), borderRadius: BorderRadius.circular(2)),
                )),

                // Coach info
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFE5A01A).withValues(alpha: 0.18), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(_initials(request),
                      style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '${request['coachFirstName'] ?? ''} ${request['coachLastName'] ?? ''}'.trim(),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(request['coachEmail'] as String? ?? '',
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(request['status'] as String?).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusLabel(request['status'] as String?),
                      style: TextStyle(color: _statusColor(request['status'] as String?), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 18),

                // Dates
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFE5A01A), size: 16),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Période demandée', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
                      Text(
                        '${_formatDate(request['startDate'] as String?)}  →  ${_formatDate(request['endDate'] as String?)}',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),

                // Motif
                if ((request['reason'] as String? ?? '').isNotEmpty) ...[
                  _sheetLabel('Motif'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
                    child: Text(request['reason'] as String,
                      style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.5)),
                  ),
                  const SizedBox(height: 14),
                ],

                // Note admin existante (si déjà traitée)
                if (!isPending && (request['adminNote'] as String? ?? '').isNotEmpty) ...[
                  _sheetLabel('Note admin'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _statusColor(request['status'] as String?).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _statusColor(request['status'] as String?).withValues(alpha: 0.25)),
                    ),
                    child: Text(request['adminNote'] as String,
                      style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.5)),
                  ),
                  const SizedBox(height: 14),
                ],

                // Actions si PENDING
                if (isPending) ...[
                  _sheetLabel('Note admin (optionnelle)'),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Commentaire pour le coach...',
                      hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 12),
                      filled: true, fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5A01A), width: 1)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(children: [
                    // Refuser
                    Expanded(
                      child: GestureDetector(
                        onTap: acting ? null : () async {
                          setModal(() => acting = true);
                          try {
                            final res = await _dio.patch('/absence-requests/${request['id']}/reject',
                              data: {'adminNote': noteCtrl.text.trim()});
                            _updateRequest(res.data as Map<String, dynamic>);
                            if (ctx.mounted) { Navigator.pop(ctx); }
                            if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Demande refusée'), backgroundColor: Color(0xFFE53935))); }
                          } on DioException catch (e) {
                            if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.response?.data?['message'] ?? 'Erreur'),
                              backgroundColor: const Color(0xFFE53935))); }
                          } finally { if (ctx.mounted) { setModal(() => acting = false); } }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
                          ),
                          child: Center(child: acting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFFE53935), strokeWidth: 2))
                            : const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.close, color: Color(0xFFE53935), size: 16),
                                SizedBox(width: 6),
                                Text('Refuser', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 14)),
                              ])),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Approuver
                    Expanded(
                      child: GestureDetector(
                        onTap: acting ? null : () async {
                          setModal(() => acting = true);
                          try {
                            final res = await _dio.patch('/absence-requests/${request['id']}/approve',
                              data: {'adminNote': noteCtrl.text.trim()});
                            _updateRequest(res.data as Map<String, dynamic>);
                            if (ctx.mounted) { Navigator.pop(ctx); }
                            if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Demande approuvée'), backgroundColor: Color(0xFF4CBA7D))); }
                          } on DioException catch (e) {
                            if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.response?.data?['message'] ?? 'Erreur'),
                              backgroundColor: const Color(0xFFE53935))); }
                          } finally { if (ctx.mounted) { setModal(() => acting = false); } }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CBA7D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: acting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.check, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('Approuver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ])),
                        ),
                      ),
                    ),
                  ]),
                ] else ...[
                  // Déjà traitée — bouton fermer seulement
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Fermer', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600))),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateRequest(Map<String, dynamic> updated) {
    setState(() {
      final idx = _requests.indexWhere((r) => r['id'] == updated['id']);
      if (idx != -1) _requests[idx] = updated;
    });
  }

  Widget _sheetLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );

  @override
  Widget build(BuildContext context) {
    final pending = _pendingCount();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFF2A2A2A)),
        ),
        title: Row(children: [
          const Text('Demandes d\'absence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (pending > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE5A01A), borderRadius: BorderRadius.circular(10)),
              child: Text('$pending', style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: const Color(0xFFE5A01A),
                  backgroundColor: const Color(0xFF2A2A2A),
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Filter tabs
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            itemCount: _filters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final f        = _filters[i];
                              final selected = _filter == f['key'];
                              return GestureDetector(
                                onTap: () { setState(() => _filter = f['key']!); _load(); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected ? const Color(0xFFE5A01A) : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(f['label']!,
                                    style: TextStyle(
                                      color: selected ? const Color(0xFF1A1A1A) : const Color(0xFF888888),
                                      fontSize: 12,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                                    )),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      if (_requests.isEmpty)
                        const SliverFillRemaining(
                          child: Center(child: Text('Aucune demande', style: TextStyle(color: Color(0xFF888888), fontSize: 15))),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _buildCard(_requests[i]),
                              childCount: _requests.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final status = r['status'] as String?;
    final color  = _statusColor(status);
    final start  = _formatDate(r['startDate'] as String?);
    final end    = _formatDate(r['endDate']   as String?);

    return GestureDetector(
      onTap: () => _openDetail(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: status == 'PENDING' ? const Color(0xFFE5A01A).withValues(alpha: 0.4) : const Color(0xFF3A3A3A),
            width: 0.5,
          ),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(_initials(r), style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${r['coachFirstName'] ?? ''} ${r['coachLastName'] ?? ''}'.trim(),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.calendar_today, size: 11, color: Color(0xFF888888)),
              const SizedBox(width: 4),
              Text('$start → $end', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            ]),
            if ((r['reason'] as String? ?? '').isNotEmpty)
              Text(r['reason'] as String,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_statusLabel(status),
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Color(0xFF888888))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A01A), foregroundColor: Colors.black),
        child: const Text('Réessayer')),
    ]),
  );
}
