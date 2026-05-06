import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/dark_card.dart';
import '../auth/providers/auth_provider.dart';

class AdherentProfileScreen extends StatelessWidget {
  const AdherentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initials = user?.initials ?? 'M';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.surfaceAlt,
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.background],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 2),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16)],
                    ),
                    child: Center(child: Text(initials, style: const TextStyle(color: AppTheme.primary, fontSize: 26, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 10),
                  Text(user?.fullName ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Adhérent', style: TextStyle(color: AppTheme.primary.withValues(alpha: 0.8), fontSize: 12)),
                ]),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              DarkCard(children: [
                _InfoRow(icon: Icons.person_outline,  label: 'Nom complet', value: user?.fullName ?? '—'),
                _InfoRow(icon: Icons.email_outlined,  label: 'Email',       value: user?.email   ?? '—'),
                _InfoRow(icon: Icons.badge_outlined,  label: 'Rôle',        value: 'Adhérent'),
              ]),
              const SizedBox(height: 16),
              DarkCard(children: [
                _NavRow(icon: Icons.card_membership,  label: 'Mon abonnement', color: AppTheme.success, path: '/member/subscription'),
                _NavRow(icon: Icons.receipt_long,     label: 'Mes paiements',  color: AppTheme.info,    path: '/member/payments'),
                _NavRow(icon: Icons.stars,            label: 'Programme fidélité', color: const Color(0xFFE5C200), path: '/member/loyalty'),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: const Text('Déconnexion', style: TextStyle(color: AppTheme.textPrimary)),
                        content: const Text('Voulez-vous vous déconnecter ?', style: TextStyle(color: AppTheme.textSecondary)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Déconnecter', style: TextStyle(color: AppTheme.error))),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      context.go('/login');
                      await context.read<AuthProvider>().logout();
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Se déconnecter'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
            ])),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppTheme.primary, size: 18),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      Text(value,  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
    ]),
  ]);
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  const _NavRow({required this.icon, required this.label, required this.color, required this.path});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.go(path),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
      const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 16),
    ]),
  );
}
