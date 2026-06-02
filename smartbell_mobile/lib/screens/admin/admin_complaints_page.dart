import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});
  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
  final _dio = ApiClient().dio;
  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL';

  static const _filters = [
    {'key': 'ALL',         'label': 'Toutes'},
    {'key': 'OPEN',        'label': 'Ouvertes'},
    {'key': 'IN_PROGRESS', 'label': 'En cours'},
    {'key': 'RESOLVED',    'label': 'Résolues'},
    {'key': 'CLOSED',      'label': 'Fermées'},
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res  = await _dio.get('/complaints', queryParameters: {'size': 200, 'sort': 'createdAt,desc'});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _complaints = List<Map<String, dynamic>>.from(list as List)
          ..sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() { _error = e.response?.data?['message'] ?? 'Erreur de chargement'; _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'ALL') return _complaints;
    return _complaints.where((c) => c['status'] == _filter).toList();
  }

  int _count(String status) => _complaints.where((c) => c['status'] == status).length;

  Color _statusColor(String? s) {
    switch (s) {
      case 'OPEN':        return const Color(0xFFE53935);
      case 'IN_PROGRESS': return const Color(0xFF534AB7);
      case 'RESOLVED':    return const Color(0xFF4CBA7D);
      case 'CLOSED':      return const Color(0xFF888888);
      default:            return const Color(0xFF888888);
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'OPEN':        return 'Ouverte';
      case 'IN_PROGRESS': return 'En cours';
      case 'RESOLVED':    return 'Résolue';
      case 'CLOSED':      return 'Fermée';
      default:            return s ?? '';
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(dateStr));
      if (diff.inSeconds < 60)  return 'à l\'instant';
      if (diff.inMinutes < 60)  return 'il y a ${diff.inMinutes}min';
      if (diff.inHours < 24)    return 'il y a ${diff.inHours}h';
      return 'il y a ${diff.inDays}j';
    } catch (_) { return ''; }
  }

  String _initials(Map<String, dynamic> c) {
    final f = (c['firstName'] as String? ?? '');
    final l = (c['lastName']  as String? ?? '');
    return ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase();
  }

  Future<void> _markInProgress(Map<String, dynamic> c) async {
    try {
      final res = await _dio.patch('/complaints/${c['id']}/read');
      setState(() {
        final idx = _complaints.indexWhere((x) => x['id'] == c['id']);
        if (idx != -1) _complaints[idx] = Map<String, dynamic>.from(res.data as Map);
      });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.response?.data?['message'] ?? 'Erreur'),
          backgroundColor: const Color(0xFFE53935),
        ));
      }
    }
  }

  void _openDetail(Map<String, dynamic> complaint) {
    final responseCtrl = TextEditingController(text: complaint['response'] as String? ?? '');
    String newStatus   = complaint['status'] as String? ?? 'IN_PROGRESS';
    bool   saving      = false;

    const statusOptions = [
      {'key': 'IN_PROGRESS', 'label': 'En cours'},
      {'key': 'RESOLVED',    'label': 'Résolue'},
      {'key': 'CLOSED',      'label': 'Fermée'},
    ];

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

                // Header: initials + name + status badge
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: _statusColor(complaint['status'] as String?).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(_initials(complaint),
                      style: TextStyle(color: _statusColor(complaint['status'] as String?), fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '${complaint['firstName'] ?? ''} ${complaint['lastName'] ?? ''}'.trim(),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(complaint['userName'] as String? ?? '',
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(complaint['status'] as String?).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusLabel(complaint['status'] as String?),
                      style: TextStyle(color: _statusColor(complaint['status'] as String?), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 16),

                // Sujet
                Text(complaint['subject'] as String? ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_timeAgo(complaint['createdAt'] as String?),
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                const SizedBox(height: 14),

                // Description
                _sheetLabel('Description'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    complaint['description'] as String? ?? '',
                    style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),

                // Réponse précédente si elle existe
                if ((complaint['response'] as String? ?? '').isNotEmpty) ...[
                  _sheetLabel('Réponse précédente'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CBA7D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4CBA7D).withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      complaint['response'] as String,
                      style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Nouvelle réponse
                _sheetLabel('Réponse admin'),
                TextField(
                  controller: responseCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Rédigez votre réponse...',
                    hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 12),
                    filled: true, fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5A01A), width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Nouveau statut
                _sheetLabel('Changer le statut'),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: statusOptions.map((opt) {
                    final selected = newStatus == opt['key'];
                    final c = _statusColor(opt['key']);
                    return GestureDetector(
                      onTap: () => setModal(() => newStatus = opt['key']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? c.withValues(alpha: 0.16) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? c : const Color(0xFF3A3A3A),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(opt['label']!,
                          style: TextStyle(color: selected ? c : const Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3A3A3A)),
                        ),
                        child: const Center(child: Text('Fermer', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: saving ? null : () async {
                        if (responseCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('La réponse ne peut pas être vide'),
                            backgroundColor: Color(0xFFE53935),
                          ));
                          return;
                        }
                        setModal(() => saving = true);
                        try {
                          final res = await _dio.patch('/complaints/${complaint['id']}/respond', data: {
                            'response': responseCtrl.text.trim(),
                            'status':   newStatus,
                          });
                          setState(() {
                            final idx = _complaints.indexWhere((x) => x['id'] == complaint['id']);
                            if (idx != -1) _complaints[idx] = Map<String, dynamic>.from(res.data as Map);
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Réponse envoyée avec succès'),
                              backgroundColor: Color(0xFF4CBA7D),
                            ));
                          }
                        } on DioException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.response?.data?['message'] ?? 'Erreur lors de l\'envoi'),
                              backgroundColor: const Color(0xFFE53935),
                            ));
                          }
                        } finally {
                          if (ctx.mounted) setModal(() => saving = false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: saving ? const Color(0xFF444444) : const Color(0xFFE5A01A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.send, color: Color(0xFF1A1A1A), size: 15),
                              SizedBox(width: 6),
                              Text('Envoyer', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 14)),
                            ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );

  @override
  Widget build(BuildContext context) {
    final open = _count('OPEN');

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
          const Text('Plaintes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (open > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(10)),
              child: Text('$open', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                      // ── Stats ──────────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(children: [
                            _StatChip(label: 'Ouvertes',  value: _count('OPEN'),        color: const Color(0xFFE53935)),
                            const SizedBox(width: 8),
                            _StatChip(label: 'En cours',  value: _count('IN_PROGRESS'), color: const Color(0xFF534AB7)),
                            const SizedBox(width: 8),
                            _StatChip(label: 'Résolues',  value: _count('RESOLVED'),    color: const Color(0xFF4CBA7D)),
                            const SizedBox(width: 8),
                            _StatChip(label: 'Fermées',   value: _count('CLOSED'),      color: const Color(0xFF888888)),
                          ]),
                        ),
                      ),

                      // ── Filter tabs ────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 46,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            itemCount: _filters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final f        = _filters[i];
                              final selected = _filter == f['key'];
                              return GestureDetector(
                                onTap: () => setState(() => _filter = f['key']!),
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

                      // ── List ───────────────────────────────────────────────
                      if (_filtered.isEmpty)
                        const SliverFillRemaining(
                          child: Center(child: Text('Aucune plainte', style: TextStyle(color: Color(0xFF888888), fontSize: 15))),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _ComplaintCard(
                                complaint: _filtered[i],
                                statusColor: _statusColor(_filtered[i]['status'] as String?),
                                statusLabel: _statusLabel(_filtered[i]['status'] as String?),
                                initials: _initials(_filtered[i]),
                                timeAgo: _timeAgo(_filtered[i]['createdAt'] as String?),
                                onTap: () => _openDetail(_filtered[i]),
                                onMarkInProgress: _filtered[i]['status'] == 'OPEN'
                                    ? () => _markInProgress(_filtered[i])
                                    : null,
                              ),
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Color(0xFF888888)), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A01A), foregroundColor: Colors.black),
        child: const Text('Réessayer'),
      ),
    ]),
  );
}

// ── Stat chip ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Column(children: [
        Text('$value', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Complaint card ─────────────────────────────────────────────────────────────

class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final Color statusColor;
  final String statusLabel;
  final String initials;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback? onMarkInProgress;

  const _ComplaintCard({
    required this.complaint,
    required this.statusColor,
    required this.statusLabel,
    required this.initials,
    required this.timeAgo,
    required this.onTap,
    this.onMarkInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final hasResponse = (complaint['response'] as String? ?? '').isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: complaint['status'] == 'OPEN'
                ? const Color(0xFFE53935).withValues(alpha: 0.3)
                : const Color(0xFF3A3A3A),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: avatar + name/username + status badge
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(initials, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${complaint['firstName'] ?? ''} ${complaint['lastName'] ?? ''}'.trim(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(timeAgo, style: const TextStyle(color: Color(0xFF666666), fontSize: 10)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),

            // Subject
            Text(complaint['subject'] as String? ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),

            // Description preview
            Text(complaint['description'] as String? ?? '',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),

            // Bottom row: has response badge + quick action
            if (hasResponse || onMarkInProgress != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                if (hasResponse)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CBA7D).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline, size: 11, color: Color(0xFF4CBA7D)),
                      SizedBox(width: 4),
                      Text('Répondu', style: TextStyle(color: Color(0xFF4CBA7D), fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                const Spacer(),
                if (onMarkInProgress != null)
                  GestureDetector(
                    onTap: onMarkInProgress,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF534AB7).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF534AB7).withValues(alpha: 0.35)),
                      ),
                      child: const Text('Prendre en charge',
                        style: TextStyle(color: Color(0xFF8B85E0), fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
