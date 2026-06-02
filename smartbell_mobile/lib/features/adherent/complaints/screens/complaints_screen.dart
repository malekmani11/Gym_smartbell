import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/providers/auth_provider.dart';

// ── Palette ────────────────────────────────────────────────────────────────────
const _bg     = Color(0xFFF5F5F0);
const _white  = Colors.white;
const _dark   = Color(0xFF1A1A1A);
const _gold   = Color(0xFFE5A01A);
const _border = Color(0xFFE8E8E8);
const _muted  = Color(0xFF888888);

// ── Status helpers ─────────────────────────────────────────────────────────────
Color _statusColor(String? s) => switch ((s ?? '').toUpperCase()) {
  'OPEN'        => const Color(0xFFE24B4A),
  'IN_PROGRESS' => const Color(0xFF534AB7),
  'RESOLVED'    => const Color(0xFF1D9E75),
  _             => const Color(0xFF888888),
};

String _statusLabel(String? s) => switch ((s ?? '').toUpperCase()) {
  'OPEN'        => 'Ouvert',
  'IN_PROGRESS' => 'En cours',
  'RESOLVED'    => 'Résolu',
  _             => 'Fermé',
};

// ── Screen ─────────────────────────────────────────────────────────────────────

class ComplaintsScreen extends StatefulWidget {
  final int? userId;
  const ComplaintsScreen({super.key, this.userId});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final path = widget.userId != null
          ? '/complaints/user/${widget.userId}'
          : '/complaints';
      final res = await DioClient.instance.dio.get(
        path,
        queryParameters: {'size': 100, 'sort': 'createdAt,desc'},
      );
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _complaints = (list as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  void _openPostSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PostComplaintSheet(onPosted: _load),
    );
  }

  // Stats rapides
  int get _open     => _complaints.where((c) => c['status'] == 'OPEN').length;
  int get _progress => _complaints.where((c) => c['status'] == 'IN_PROGRESS').length;
  int get _resolved => _complaints.where((c) => c['status'] == 'RESOLVED').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _dark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plaintes & Suggestions',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Fil communautaire', style: TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${_complaints.length}',
                  style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPostSheet,
        backgroundColor: _gold,
        foregroundColor: _dark,
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: const Text('Déposer', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: _gold,
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── Stats banner ──────────────────────────────────────
                      if (_complaints.isNotEmpty)
                        SliverToBoxAdapter(child: _StatsBanner(open: _open, progress: _progress, resolved: _resolved)),

                      // ── Feed ──────────────────────────────────────────────
                      if (_complaints.isEmpty)
                        const SliverFillRemaining(child: _EmptyState())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _ComplaintCard(complaint: _complaints[i]),
                              childCount: _complaints.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_outlined, color: Color(0xFFA32D2D), size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: _muted), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _load,
          style: ElevatedButton.styleFrom(backgroundColor: _dark, foregroundColor: _gold),
          child: const Text('Réessayer'),
        ),
      ]),
    ),
  );
}

// ── Stats banner ───────────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  final int open, progress, resolved;
  const _StatsBanner({required this.open, required this.progress, required this.resolved});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 2),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(value: open,     label: 'Ouvertes',  color: const Color(0xFFE24B4A)),
          _divider(),
          _Stat(value: progress, label: 'En cours',  color: const Color(0xFF534AB7)),
          _divider(),
          _Stat(value: resolved, label: 'Résolues',  color: const Color(0xFF1D9E75)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: const Color(0xFF2A2A2A));
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
  ]);
}

// ── Complaint card (post) ──────────────────────────────────────────────────────

class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  const _ComplaintCard({required this.complaint});

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1)  return 'À l\'instant';
      if (diff.inHours   < 1)  return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours   < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays    < 7)  return 'Il y a ${diff.inDays}j';
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) { return raw; }
  }

  String _initials() {
    final f = (complaint['firstName'] as String? ?? '');
    final l = (complaint['lastName']  as String? ?? '');
    return ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase().isNotEmpty
        ? ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase()
        : '?';
  }

  String _authorName() {
    final f = complaint['firstName'] as String? ?? '';
    final l = complaint['lastName']  as String? ?? '';
    final full = '$f $l'.trim();
    return full.isNotEmpty ? full : 'Membre anonyme';
  }

  @override
  Widget build(BuildContext context) {
    final status   = complaint['status'] as String? ?? 'OPEN';
    final color    = _statusColor(status);
    final response = complaint['response'] as String?;
    final hasResp  = response != null && response.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              // Avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(_initials(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_authorName(),
                    style: const TextStyle(color: _dark, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(_formatDate(complaint['createdAt'] as String?),
                    style: const TextStyle(color: _muted, fontSize: 11)),
              ])),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(_statusLabel(status),
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          // ── Séparateur fin ────────────────────────────────────────────────
          const Divider(height: 1, color: _border),

          // ── Contenu ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Sujet
              Row(children: [
                const Icon(Icons.label_outline, color: _muted, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    complaint['subject'] as String? ?? '',
                    style: const TextStyle(color: _dark, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              // Description
              Text(
                complaint['description'] as String? ?? '',
                style: const TextStyle(color: Color(0xFF444444), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
            ]),
          ),

          // ── Réponse admin ─────────────────────────────────────────────────
          if (hasResp) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1D9E75).withValues(alpha: 0.25)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: Color(0xFF1D9E75), size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Réponse de l\'administration',
                      style: TextStyle(color: Color(0xFF1D9E75), fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(response,
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, height: 1.4)),
                ])),
              ]),
            ),
          ] else ...[
            const SizedBox(height: 2),
          ],

          // ── Footer ────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border, width: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              const Icon(Icons.forum_outlined, color: _muted, size: 14),
              const SizedBox(width: 6),
              Text(
                hasResp ? 'Réponse disponible' : 'En attente de réponse',
                style: TextStyle(
                    color: hasResp ? const Color(0xFF1D9E75) : _muted,
                    fontSize: 11),
              ),
              const Spacer(),
              Text(
                '#${complaint['id'] ?? ''}',
                style: const TextStyle(color: _border, fontSize: 10),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.forum_outlined, color: _gold, size: 38),
        ),
        const SizedBox(height: 16),
        const Text('Aucune plainte pour l\'instant',
            style: TextStyle(color: _dark, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
          'Sois le premier à partager ton expérience\nou signaler un problème.',
          style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ]),
    ),
  );
}

// ── Post complaint sheet ──────────────────────────────────────────────────────

class _PostComplaintSheet extends StatefulWidget {
  final VoidCallback onPosted;
  const _PostComplaintSheet({required this.onPosted});

  @override
  State<_PostComplaintSheet> createState() => _PostComplaintSheetState();
}

class _PostComplaintSheetState extends State<_PostComplaintSheet> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl    = TextEditingController();
  bool _posting = false;
  String? _error;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _subjectCtrl.text.trim().isNotEmpty && _descCtrl.text.trim().length >= 10;

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || !_valid) return;

    setState(() { _posting = true; _error = null; });
    try {
      await DioClient.instance.dio.post(
        '/complaints/user/${user.id}',
        data: {
          'subject':     _subjectCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPosted();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Plainte déposée avec succès !'),
          backgroundColor: Color(0xFF1D9E75),
        ));
      }
    } catch (e) {
      setState(() {
        _error   = DioClient.errorMessage(e);
        _posting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: _border, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Title
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined, color: _gold, size: 18),
                ),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Nouvelle plainte',
                      style: TextStyle(color: _dark, fontWeight: FontWeight.bold, fontSize: 17)),
                  Text('Visible par tous les membres',
                      style: TextStyle(color: _muted, fontSize: 11)),
                ]),
              ]),
              const SizedBox(height: 20),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA32D2D).withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 12))),
                  ]),
                ),
              ],

              // Subject
              const Text('Sujet *',
                  style: TextStyle(color: _dark, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subjectCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: _dark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ex: Problème vestiaires, climatisation...',
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _gold, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              const Text('Description * (min. 10 caractères)',
                  style: TextStyle(color: _dark, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                onChanged: (_) => setState(() {}),
                maxLines: 4,
                style: const TextStyle(color: _dark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Décris le problème en détail...',
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _gold, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              // Char count
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_descCtrl.text.trim().length} caractères',
                  style: TextStyle(
                    color: _descCtrl.text.trim().length >= 10 ? _gold : _muted,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: (_valid && !_posting) ? _submit : null,
                  icon: _posting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: _dark))
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(_posting ? 'Envoi...' : 'Publier la plainte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _valid ? _gold : _gold.withValues(alpha: 0.4),
                    foregroundColor: _dark,
                    disabledBackgroundColor: _gold.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
