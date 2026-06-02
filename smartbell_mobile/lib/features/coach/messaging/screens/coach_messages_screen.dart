import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/adherent/messaging/screens/chat_screen.dart';
import '../../../../features/shared/group_chat/group_chat_screen.dart';

class CoachMessagesScreen extends StatefulWidget {
  const CoachMessagesScreen({super.key});
  @override
  State<CoachMessagesScreen> createState() => _CoachMessagesScreenState();
}

class _CoachMessagesScreenState extends State<CoachMessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _admins  = [];
  List<Map<String, dynamic>> _coaches = [];
  List<Map<String, dynamic>> _members = [];

  bool _loadingAdmins  = true;
  bool _loadingCoaches = true;
  bool _loadingMembers = true;

  String? _errorAdmins;
  String? _errorCoaches;
  String? _errorMembers;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() { _tab.dispose(); _searchCtrl.dispose(); super.dispose(); }

  void _loadAll() { _loadAdmins(); _loadCoaches(); _loadMembers(); }

  Future<void> _loadAdmins() async {
    setState(() { _loadingAdmins = true; _errorAdmins = null; });
    try {
      final res  = await DioClient.instance.dio.get('/users/by-role',
          queryParameters: {'role': 'ROLE_ADMIN', 'size': 100});
      final data = res.data;
      setState(() {
        _admins = data is Map
            ? List<Map<String, dynamic>>.from(data['content'] ?? [])
            : List<Map<String, dynamic>>.from(data ?? []);
        _loadingAdmins = false;
      });
    } catch (e) {
      setState(() { _errorAdmins = DioClient.errorMessage(e); _loadingAdmins = false; });
    }
  }

  Future<void> _loadCoaches() async {
    setState(() { _loadingCoaches = true; _errorCoaches = null; });
    final myId = context.read<AuthProvider>().user?.id ?? 0;
    try {
      final res  = await DioClient.instance.dio.get('/coaches',
          queryParameters: {'size': 100});
      final data = res.data;
      final list = data is Map
          ? List<Map<String, dynamic>>.from(data['content'] ?? [])
          : List<Map<String, dynamic>>.from(data ?? []);
      // Exclure le coach connecté lui-même
      setState(() {
        _coaches = list.where((c) {
          final uid = (c['userId'] ?? c['user']?['id'] ?? 0).toInt();
          return uid != myId;
        }).toList();
        _loadingCoaches = false;
      });
    } catch (e) {
      setState(() { _errorCoaches = DioClient.errorMessage(e); _loadingCoaches = false; });
    }
  }

  Future<void> _loadMembers() async {
    setState(() { _loadingMembers = true; _errorMembers = null; });
    try {
      final res  = await DioClient.instance.dio.get('/users/by-role',
          queryParameters: {'role': 'ROLE_MEMBER', 'size': 100});
      final data = res.data;
      setState(() {
        _members = data is Map
            ? List<Map<String, dynamic>>.from(data['content'] ?? [])
            : List<Map<String, dynamic>>.from(data ?? []);
        _loadingMembers = false;
      });
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

  String _name(Map<String, dynamic> u) =>
      '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();

  String _initials(String name) => name.isNotEmpty
      ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
      : '?';

  int _userId(Map<String, dynamic> u) =>
      (u['userId'] ?? u['user']?['id'] ?? u['id'] ?? 0).toInt();

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?.id ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(children: [
        // ── Header sombre ──
        Container(
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              // Titre
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFFE5A01A), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Messagerie', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  GestureDetector(
                    onTap: () {
                      final coach = context.read<AuthProvider>().user;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => GroupChatScreen(
                          myUserId: coach?.id ?? 0,
                          myName:   coach?.fullName ?? 'Coach',
                          myRole:   'COACH',
                        ),
                      ));
                    },
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_admins.length + _coaches.length + _members.length} contacts',
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
              // Barre de recherche
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
                      hintText: _tab.index == 0
                          ? 'Rechercher un admin...'
                          : _tab.index == 1
                              ? 'Rechercher un coach...'
                              : 'Rechercher un membre...',
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
              // Tabs
              TabBar(
                controller: _tab,
                indicatorColor: const Color(0xFFE5A01A),
                indicatorWeight: 2,
                labelColor: const Color(0xFFE5A01A),
                unselectedLabelColor: const Color(0xFF888888),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Admins (${_admins.length})'),
                  Tab(text: 'Coachs (${_coaches.length})'),
                  Tab(text: 'Membres (${_members.length})'),
                ],
              ),
            ]),
          ),
        ),

        // ── Contenu ──
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              // Admins
              _buildList(
                loading: _loadingAdmins,
                error: _errorAdmins,
                items: _filter(_admins),
                role: 'Admin',
                accentColor: const Color(0xFFE5A01A),
                myId: myId,
                onRetry: _loadAdmins,
              ),
              // Coachs
              _buildList(
                loading: _loadingCoaches,
                error: _errorCoaches,
                items: _filter(_coaches),
                role: 'Coach',
                accentColor: const Color(0xFF9F97EC),
                myId: myId,
                onRetry: _loadCoaches,
              ),
              // Membres
              _buildList(
                loading: _loadingMembers,
                error: _errorMembers,
                items: _filter(_members),
                role: 'Membre',
                accentColor: const Color(0xFF4CBA7D),
                myId: myId,
                onRetry: _loadMembers,
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildList({
    required bool loading,
    required String? error,
    required List<Map<String, dynamic>> items,
    required String role,
    required Color accentColor,
    required int myId,
    required VoidCallback onRetry,
  }) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)));
    if (error != null) return _buildError(error, onRetry);
    if (items.isEmpty) return _buildEmpty(role);

    return RefreshIndicator(
      color: const Color(0xFFE5A01A),
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final user     = items[i];
          final uid      = _userId(user);
          final name     = _name(user).isNotEmpty ? _name(user) : '$role #${user['id']}';
          final initials = _initials(name);
          final email    = user['email'] as String? ?? '';

          return _ContactCard(
            name:        name,
            initials:    initials,
            email:       email,
            role:        role,
            accentColor: accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(
                myUserId:      myId,
                otherUserId:   uid,
                otherName:     name,
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
      const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 48),
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
      const Icon(Icons.chat_bubble_outline, color: Color(0xFFBBBBBB), size: 56),
      const SizedBox(height: 12),
      Text('Aucun $role trouvé', style: const TextStyle(color: Color(0xFF888888), fontSize: 15)),
    ],
  ));
}

// ── Contact Card ──────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final String name, initials, email, role;
  final Color accentColor;
  final VoidCallback onTap;
  const _ContactCard({required this.name, required this.initials, required this.email,
      required this.role, required this.accentColor, required this.onTap});

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
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(initials, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        const SizedBox(width: 12),
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
          if (email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(email, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
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
