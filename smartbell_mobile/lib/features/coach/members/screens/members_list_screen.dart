import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../services/member_service.dart';
import 'member_detail_screen.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final _service    = CoachMemberService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _all      = [];
  List<Map<String, dynamic>> _filtered = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) { setState(() => _loading = false); return; }
      _all      = await _service.getMembersByCoach(user.id);
      _filtered = List.from(_all);
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  void _filter(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = _all.where((m) {
        final name = '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.toLowerCase();
        return name.contains(query) || (m['email'] ?? '').toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  static const _avatarColors = [
    Color(0xFFEF9F27), Color(0xFF1D9E75), Color(0xFF534AB7),
    Color(0xFFE24B4A), Color(0xFF64B5F6), Color(0xFFBA68C8),
  ];

  Color _avatarColor(int index) => _avatarColors[index % _avatarColors.length];

  String _initials(Map<String, dynamic> m) {
    final f = (m['firstName'] ?? '').toString();
    final l = (m['lastName']  ?? '').toString();
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(
        children: [
          // ── Dark header ──
          Container(
            color: const Color(0xFF1A1A1A),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mes membres',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${_filtered.length}',
                          style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _filter,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un membre...',
                          hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF666666), size: 18),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16, color: Color(0xFF666666)),
                                  onPressed: () { _searchCtrl.clear(); _filter(''); },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
                : _error != null
                    ? _ErrView(message: _error!, onRetry: _load)
                    : RefreshIndicator(
                        color: const Color(0xFFE5A01A),
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? const Center(
                                child: Text('Aucun membre trouvé',
                                    style: TextStyle(color: Color(0xFF888888))),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) {
                                  final m        = _filtered[i];
                                  final status   = (m['membershipStatus'] ?? m['status'] ?? '').toString().toUpperCase();
                                  final plan     = m['planName'] ?? m['subscriptionPlan'] ?? '—';
                                  final initials = _initials(m);
                                  final color    = _avatarColor(i);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => MemberDetailScreen(member: m),
                                      )),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                                        ),
                                        child: Row(children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: color.withValues(alpha: 0.15),
                                            child: Text(initials, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim(),
                                                style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 14),
                                              ),
                                              Text(m['email'] ?? '', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                                              if (plan != '—')
                                                Text(plan.toString(), style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
                                            ],
                                          )),
                                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                            _StatusPill(status: status),
                                            const SizedBox(height: 6),
                                            const Text('Voir →', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 11, fontWeight: FontWeight.w500)),
                                          ]),
                                        ]),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Status pill ────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'ACTIVE'    => (const Color(0xFFEAF3DE), const Color(0xFF3B6D11), 'Actif'),
      'INACTIVE'  => (const Color(0xFFF0F0F0), const Color(0xFF666666), 'Inactif'),
      'SUSPENDED' => (const Color(0xFFFAEEDA), const Color(0xFF854F0B), 'Suspendu'),
      _           => (const Color(0xFFF0F0F0), const Color(0xFF888888), status.isNotEmpty ? status : '—'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off_outlined, color: Color(0xFFE53935), size: 48),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: Color(0xFF888888), fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Réessayer', style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    )),
  );
}
