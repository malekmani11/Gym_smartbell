import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/adherent/messaging/screens/chat_screen.dart';

/// Coach side — shows list of admins to contact.
class CoachMessagesScreen extends StatefulWidget {
  const CoachMessagesScreen({super.key});

  @override
  State<CoachMessagesScreen> createState() => _CoachMessagesScreenState();
}

class _CoachMessagesScreenState extends State<CoachMessagesScreen> {
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load all users and filter admins client-side
      final res = await DioClient.instance.dio
          .get('/users', queryParameters: {'size': 100});
      final data = res.data;
      final list = data is Map
          ? List<Map<String, dynamic>>.from(data['content'] ?? [])
          : List<Map<String, dynamic>>.from(data ?? []);

      final admins = list.where((u) {
        final roles = List<String>.from(u['roles'] ?? []);
        return roles.contains('ROLE_ADMIN') || roles.contains('ROLE_MANAGER');
      }).toList();

      setState(() { _admins = admins; _loading = false; });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachUserId = context.watch<AuthProvider>().user?.id ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Messagerie Admin',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _admins.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: _loadAdmins,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _admins.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final admin = _admins[i];
                          final adminId = (admin['id'] ?? 0).toInt();
                          final name =
                              '${admin['firstName'] ?? ''} ${admin['lastName'] ?? ''}'
                                  .trim();
                          final initials = name.isNotEmpty
                              ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                              : 'A';

                          return _AdminCard(
                            name: name.isNotEmpty ? name : 'Administrateur',
                            initials: initials,
                            email: admin['email'] as String? ?? '',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  myUserId: coachUserId,
                                  otherUserId: adminId,
                                  otherName: name.isNotEmpty ? name : 'Admin',
                                  otherInitials: initials,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadAdmins,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black),
          child: const Text('Réessayer'),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.admin_panel_settings, color: AppColors.textMuted, size: 56),
        SizedBox(height: 12),
        Text('Aucun administrateur trouvé',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      ],
    ),
  );
}

// ─── Admin Card ──────────────────────────────────────────────────────────────

class _AdminCard extends StatelessWidget {
  final String name;
  final String initials;
  final String email;
  final VoidCallback onTap;

  const _AdminCard({
    required this.name,
    required this.initials,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Admin avatar with shield icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Admin',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(email,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
