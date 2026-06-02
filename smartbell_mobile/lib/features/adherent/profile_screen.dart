import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';

class AdherentProfileScreen extends StatefulWidget {
  const AdherentProfileScreen({super.key});

  @override
  State<AdherentProfileScreen> createState() => _AdherentProfileScreenState();
}

class _AdherentProfileScreenState extends State<AdherentProfileScreen> {
  // ── Edit profile dialog ────────────────────────────────────────────────────
  void _showEditProfileDialog() {
    final user = context.read<AuthProvider>().user;
    final firstCtrl = TextEditingController(text: user?.firstName ?? '');
    final lastCtrl  = TextEditingController(text: user?.lastName  ?? '');
    final formKey   = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier le profil',
            style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.w600)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _DialogField(controller: firstCtrl, label: 'Prénom', icon: Icons.person_outline),
            const SizedBox(height: 12),
            _DialogField(controller: lastCtrl, label: 'Nom', icon: Icons.person_outline),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
          ),
          Consumer<AuthProvider>(
            builder: (ctx2, auth, _) => TextButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final ok = await auth.updateProfile(
                        firstName: firstCtrl.text.trim(),
                        lastName:  lastCtrl.text.trim(),
                      );
                      if (ctx2.mounted) Navigator.pop(ctx2);
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(auth.error ?? 'Erreur lors de la mise à jour')),
                        );
                      }
                    },
              child: auth.loading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))
                  : const Text('Enregistrer', style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Change password dialog ─────────────────────────────────────────────────
  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    var   obscureCurrent = true;
    var   obscureNew     = true;
    var   obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDlgState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Changer le mot de passe',
              style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.w600)),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _PasswordField(
                controller: currentCtrl,
                label: 'Mot de passe actuel',
                obscure: obscureCurrent,
                onToggle: () => setDlgState(() => obscureCurrent = !obscureCurrent),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: newCtrl,
                label: 'Nouveau mot de passe',
                obscure: obscureNew,
                onToggle: () => setDlgState(() => obscureNew = !obscureNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (v.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: confirmCtrl,
                label: 'Confirmer le mot de passe',
                obscure: obscureConfirm,
                onToggle: () => setDlgState(() => obscureConfirm = !obscureConfirm),
                validator: (v) => v != newCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx2),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
            ),
            Consumer<AuthProvider>(
              builder: (ctx3, auth, _) => TextButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await auth.changePassword(
                          currentCtrl.text,
                          newCtrl.text,
                        );
                        if (ctx3.mounted) Navigator.pop(ctx3);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Mot de passe modifié avec succès'
                                  : (auth.error ?? 'Erreur lors du changement')),
                              backgroundColor: ok ? const Color(0xFF3B6D11) : null,
                            ),
                          );
                        }
                      },
                child: auth.loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))
                    : const Text('Confirmer', style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initials = user?.initials ?? 'M';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: CustomScrollView(
        slivers: [
          // ── Header sombre ──
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF1A1A1A),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                left: 20, right: 20, bottom: 24,
              ),
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE5A01A),
                    border: Border.all(color: const Color(0xFFF0EDE5), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    user?.fullName ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: const Icon(Icons.edit_outlined, color: Color(0xFFE5A01A), size: 16),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Adhérent', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 11)),
                ),
              ]),
            ),
          ),

          // ── Card 1 — Infos personnelles ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _ProfileCard(children: [
                _EditableInfoRow(
                  icon: Icons.person_outline,
                  label: 'Nom complet',
                  value: user?.fullName ?? '-',
                  onEdit: _showEditProfileDialog,
                ),
                _InfoRow(icon: Icons.email_outlined,  label: 'Email', value: user?.email ?? '-'),
                _InfoRow(icon: Icons.badge_outlined,  label: 'Rôle',  value: 'Membre'),
              ]),
            ),
          ),

          // ── Card 2 — Navigation ──
          SliverToBoxAdapter(
            child: _ProfileCard(children: [
              _NavRow(
                icon: Icons.lock_outline,
                iconBg: const Color(0xFFEEE8FA), iconColor: const Color(0xFF5C35B0),
                label: 'Changer le mot de passe',
                onTap: _showChangePasswordDialog,
              ),
              _NavRow(
                icon: Icons.card_membership,
                iconBg: const Color(0xFFEAF3DE), iconColor: const Color(0xFF3B6D11),
                label: 'Mon abonnement',
                onTap: () => context.go('/member/subscription'),
              ),
              _NavRow(
                icon: Icons.receipt_long,
                iconBg: const Color(0xFFE6F1FB), iconColor: const Color(0xFF185FA5),
                label: 'Mes paiements',
                onTap: () => context.go('/member/payments'),
              ),
              _NavRow(
                icon: Icons.stars,
                iconBg: const Color(0xFFFAEEDA), iconColor: const Color(0xFFBA7517),
                label: 'Programme fidélité',
                onTap: () => context.go('/member/loyalty'),
              ),
              _NavRow(
                icon: Icons.event_outlined,
                iconBg: const Color(0xFFF3E5F5), iconColor: const Color(0xFF7B1FA2),
                label: 'Événements de la salle',
                onTap: () => context.go('/member/events'),
              ),
              _NavRow(
                icon: Icons.notifications_outlined,
                iconBg: const Color(0xFFFAEEDA), iconColor: const Color(0xFFE5A01A),
                label: 'Mes notifications',
                onTap: () => context.go('/member/notifications'),
              ),
            ]),
          ),

          // ── Bouton déconnexion ──
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Déconnexion', style: TextStyle(color: Color(0xFF1A1A1A))),
                    content: const Text('Voulez-vous vous déconnecter ?', style: TextStyle(color: Color(0xFF888888))),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Déconnecter', style: TextStyle(color: Color(0xFFA32D2D))),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                }
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  border: Border.all(color: const Color(0xFFF7C1C1), width: 0.5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout, color: Color(0xFFA32D2D), size: 16),
                  SizedBox(width: 8),
                  Text('Se déconnecter', style: TextStyle(color: Color(0xFFA32D2D), fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog field ──────────────────────────────────────────────────────────────
class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _DialogField({required this.controller, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFE5A01A), size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5A01A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

// ── Password field ────────────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFE5A01A), size: 18),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF888888), size: 18),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5A01A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

// ── Profile card ──────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      borderRadius: BorderRadius.circular(14),
    ),
    clipBehavior: Clip.hardEdge,
    child: Column(
      children: List.generate(children.length, (i) => Column(children: [
        children[i],
        if (i < children.length - 1)
          const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF5F5F0)),
      ])),
    ),
  );
}

// ── Info row (read-only) ───────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, color: const Color(0xFFE5A01A), size: 18),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 10)),
        Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
      ]),
    ]),
  );
}

// ── Editable info row ──────────────────────────────────────────────────────────
class _EditableInfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onEdit;
  const _EditableInfoRow({required this.icon, required this.label, required this.value, required this.onEdit});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onEdit,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: const Color(0xFFE5A01A), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 10)),
            Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
          ]),
        ),
        const Icon(Icons.edit_outlined, color: Color(0xFFCCCCCC), size: 15),
      ]),
    ),
  );
}

// ── Nav row ───────────────────────────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label;
  final VoidCallback onTap;
  const _NavRow({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14))),
        const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 15),
      ]),
    ),
  );
}
