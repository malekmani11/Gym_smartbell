import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/gym_badge.dart';
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
      _all      = await _service.getAllMembers();
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mes membres'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher un membre...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: AppTheme.textMuted),
                        onPressed: () { _searchCtrl.clear(); _filter(''); },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _ErrView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? const Center(child: Text('Aucun membre trouvé', style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final m = _filtered[i];
                            final status  = (m['membershipStatus'] ?? m['status'] ?? '').toString().toUpperCase();
                            final plan    = m['planName'] ?? m['subscriptionPlan'] ?? '—';
                            final initials = _initials(m);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => MemberDetailScreen(member: m),
                                )),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.border, width: 0.5),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: _avatarColor(i).withValues(alpha: 0.15),
                                        child: Text(initials, style: TextStyle(color: _avatarColor(i), fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim(),
                                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                          Text(m['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                          if (plan != '—') Text(plan.toString(), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                        ],
                                      )),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        _statusBadge(status),
                                        const SizedBox(height: 6),
                                        const Text('Voir →', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                                      ]),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _statusBadge(String status) {
    switch (status) {
      case 'ACTIVE':    return GymBadge(text: 'Actif',    type: BadgeType.green);
      case 'INACTIVE':  return GymBadge(text: 'Inactif',  type: BadgeType.grey);
      case 'SUSPENDED': return GymBadge(text: 'Suspendu', type: BadgeType.amber);
      default:          return GymBadge(text: status.isNotEmpty ? status : '—', type: BadgeType.grey);
    }
  }
}

class _ErrView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off_outlined, color: AppTheme.error, size: 48),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 16), label: const Text('Réessayer')),
      ],
    )),
  );
}
