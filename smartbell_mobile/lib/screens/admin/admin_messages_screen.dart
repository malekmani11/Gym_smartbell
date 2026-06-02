import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/adherent/messaging/screens/chat_screen.dart';
import '../../../features/shared/group_chat/group_chat_screen.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});
  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _coaches = [];
  List<Map<String, dynamic>> _members = [];
  bool _loadingCoaches = true;
  bool _loadingMembers = true;
  String? _errorCoaches;
  String? _errorMembers;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _loadCoaches();
    _loadMembers();
  }

  @override
  void dispose() { _tab.dispose(); _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadCoaches() async {
    setState(() { _loadingCoaches = true; _errorCoaches = null; });
    try {
      final res  = await DioClient.instance.dio.get('/coaches', queryParameters: {'size': 100});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() { _coaches = List<Map<String, dynamic>>.from(list); _loadingCoaches = false; });
    } catch (e) {
      setState(() { _errorCoaches = DioClient.errorMessage(e); _loadingCoaches = false; });
    }
  }

  Future<void> _loadMembers() async {
    setState(() { _loadingMembers = true; _errorMembers = null; });
    try {
      final res  = await DioClient.instance.dio.get('/members', queryParameters: {'size': 100});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() { _members = List<Map<String, dynamic>>.from(list); _loadingMembers = false; });
    } catch (e) {
      setState(() { _errorMembers = DioClient.errorMessage(e); _loadingMembers = false; });
    }
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> list) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((u) {
      final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.toLowerCase();
      return name.contains(q) || (u['email'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final adminId = context.watch<AuthProvider>().user?.id ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(children: [
        // ── Dark header ──
        Container(
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFFE5A01A), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Messagerie', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  // Bouton groupe
                  GestureDetector(
                    onTap: () => _openParticipantPicker(context, adminId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A01A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5A01A).withValues(alpha: 0.4)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.groups, color: Color(0xFFE5A01A), size: 14),
                        SizedBox(width: 5),
                        Text('Groupe', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _tab.index == 0 ? 'Rechercher un coach...' : 'Rechercher un membre...',
                      hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF666666), size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Color(0xFF666666)),
                              onPressed: () { _searchCtrl.clear(); setState(() {}); },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              // TabBar
              TabBar(
                controller: _tab,
                indicatorColor: const Color(0xFFE5A01A),
                indicatorWeight: 2,
                labelColor: const Color(0xFFE5A01A),
                unselectedLabelColor: const Color(0xFF888888),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Coachs (${_coaches.length})'),
                  Tab(text: 'Membres (${_members.length})'),
                ],
              ),
            ]),
          ),
        ),

        // ── Tab content ──
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildList(
                loading: _loadingCoaches,
                error: _errorCoaches,
                items: _filter(_coaches),
                role: 'Coach',
                accentColor: const Color(0xFFE5A01A),
                adminId: adminId,
                onRetry: _loadCoaches,
                getUserId: (c) => (c['userId'] ?? c['user']?['id'] ?? 0).toInt(),
                getSub: (c) => c['specialization'] as String?,
              ),
              _buildList(
                loading: _loadingMembers,
                error: _errorMembers,
                items: _filter(_members),
                role: 'Membre',
                accentColor: const Color(0xFF3B82F6),
                adminId: adminId,
                onRetry: _loadMembers,
                getUserId: (m) => (m['userId'] ?? m['id'] ?? 0).toInt(),
                getSub: (m) => m['planName'] as String?,
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _openParticipantPicker(BuildContext context, int adminId) {
    final authUser = context.read<AuthProvider>().user;
    final selected = <Map<String, dynamic>>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final allPeople = [
            ..._coaches.map((c) => {...c, '_role': 'Coach'}),
            ..._members.map((m) => {...m, '_role': 'Membre'}),
          ];

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.92,
            builder: (_, scrollCtrl) => Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF444444),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(children: [
                    const Icon(Icons.groups, color: Color(0xFFE5A01A), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Créer une discussion de groupe',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Sélectionnez les participants',
                            style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                      ]),
                    ),
                    if (selected.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5A01A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5A01A).withValues(alpha: 0.4)),
                        ),
                        child: Text('${selected.length} sélectionné${selected.length > 1 ? 's' : ''}',
                            style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFF2A2A2A)),
                // Liste
                Expanded(
                  child: allPeople.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          itemCount: allPeople.length,
                          itemBuilder: (_, i) {
                            final person = allPeople[i];
                            final isCoach = person['_role'] == 'Coach';
                            final name = '${person['firstName'] ?? ''} ${person['lastName'] ?? ''}'.trim();
                            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                            final accent = isCoach ? const Color(0xFFE5A01A) : const Color(0xFF3B82F6);
                            final isSelected = selected.any((s) =>
                                s['id'].toString() == person['id'].toString() &&
                                s['_role'] == person['_role']);

                            return InkWell(
                              onTap: () => setSheet(() {
                                if (isSelected) {
                                  selected.removeWhere((s) =>
                                      s['id'].toString() == person['id'].toString() &&
                                      s['_role'] == person['_role']);
                                } else {
                                  selected.add(person);
                                }
                              }),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accent.withValues(alpha: 0.12)
                                      : const Color(0xFF242424),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? accent.withValues(alpha: 0.5)
                                        : const Color(0xFF333333),
                                  ),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 38, height: 38,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(initial,
                                        style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(name.isNotEmpty ? name : '${person['_role']} #${person['id']}',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                    Text(person['_role'] as String,
                                        style: TextStyle(color: accent, fontSize: 11)),
                                  ])),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: accent, size: 20)
                                  else
                                    Icon(Icons.radio_button_unchecked, color: const Color(0xFF555555), size: 20),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
                // Bouton confirmer
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(ctx).padding.bottom + 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selected.isEmpty ? null : () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => GroupChatScreen(
                            myUserId:     adminId,
                            myName:       authUser?.fullName ?? 'Admin',
                            myRole:       'ADMIN',
                            participants: selected.toList(),
                          ),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A01A),
                        disabledBackgroundColor: const Color(0xFF333333),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        selected.isEmpty
                            ? 'Sélectionnez des participants'
                            : 'Ouvrir le groupe (${selected.length})',
                        style: TextStyle(
                          color: selected.isEmpty ? const Color(0xFF666666) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList({
    required bool loading,
    required String? error,
    required List<Map<String, dynamic>> items,
    required String role,
    required Color accentColor,
    required int adminId,
    required VoidCallback onRetry,
    required int Function(Map<String, dynamic>) getUserId,
    required String? Function(Map<String, dynamic>) getSub,
  }) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)));
    if (error != null) return _buildError(error, onRetry);
    if (items.isEmpty) return _buildEmpty(role);

    return RefreshIndicator(
      color: const Color(0xFFE5A01A),
      onRefresh: () async { role == 'Coach' ? await _loadCoaches() : await _loadMembers(); },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final user    = items[i];
          final userId  = getUserId(user);
          final name    = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
          final initials = name.isNotEmpty
              ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
              : role[0];
          final sub = getSub(user);

          return _UserCard(
            name:     name.isNotEmpty ? name : '$role #${user['id']}',
            initials: initials,
            role:     role,
            sub:      sub,
            accentColor: accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(
                myUserId:      adminId,
                otherUserId:   userId,
                otherName:     name.isNotEmpty ? name : role,
                otherInitials: initials,
              )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback onRetry) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 48),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: Color(0xFF888888)), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
          child: const Text('Réessayer', style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
        ),
      ),
    ],
  ));

  Widget _buildEmpty(String role) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(role == 'Coach' ? Icons.sports : Icons.people_outline, color: const Color(0xFFBBBBBB), size: 56),
      const SizedBox(height: 12),
      Text('Aucun $role trouvé', style: const TextStyle(color: Color(0xFF888888), fontSize: 15)),
    ],
  ));
}

// ── User card ──────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final String name, initials, role;
  final String? sub;
  final Color accentColor;
  final VoidCallback onTap;
  const _UserCard({required this.name, required this.initials, required this.role,
      this.sub, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(initials, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(role, style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ]),
          if (sub != null && sub!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub!, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
          ],
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chat_bubble_outline, color: accentColor, size: 12),
            const SizedBox(width: 4),
            Text('Message', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    ),
  );
}
