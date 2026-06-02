import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/network/dio_client.dart';

class CoachProfileScreen extends StatefulWidget {
  const CoachProfileScreen({super.key});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  final _dio = DioClient.instance.dio;

  // ── Modifier le profil ──────────────────────────────────────────────────────
  void _showEditProfileSheet() {
    final user      = context.read<AuthProvider>().user;
    final firstCtrl = TextEditingController(text: user?.firstName ?? '');
    final lastCtrl  = TextEditingController(text: user?.lastName  ?? '');
    bool saving     = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const Text('Modifier le profil',
                    style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _profileField(controller: firstCtrl, label: 'Prénom', icon: Icons.person_outline),
                const SizedBox(height: 12),
                _profileField(controller: lastCtrl,  label: 'Nom',    icon: Icons.person_outline),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setModal(() => saving = true);
                      try {
                        await _dio.put('/users/${user?.id}', data: {
                          'firstName': firstCtrl.text.trim(),
                          'lastName':  lastCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil mis à jour'),
                              backgroundColor: Color(0xFF4CBA7D),
                            ),
                          );
                          setState(() {});
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur : ${e.toString()}'),
                              backgroundColor: const Color(0xFFA32D2D),
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setModal(() => saving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFFE5A01A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))
                        : const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Changer le mot de passe ─────────────────────────────────────────────────
  void _showChangePasswordSheet() {
    final user        = context.read<AuthProvider>().user;
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving      = false;
    bool showCurrent = false;
    bool showNew     = false;
    bool showConfirm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const Text('Changer le mot de passe',
                    style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _passwordField(
                  ctrl: currentCtrl, label: 'Mot de passe actuel',
                  show: showCurrent, onToggle: () => setModal(() => showCurrent = !showCurrent),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  ctrl: newCtrl, label: 'Nouveau mot de passe',
                  show: showNew, onToggle: () => setModal(() => showNew = !showNew),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  ctrl: confirmCtrl, label: 'Confirmer le mot de passe',
                  show: showConfirm, onToggle: () => setModal(() => showConfirm = !showConfirm),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez remplir tous les champs'),
                            backgroundColor: Color(0xFFA32D2D),
                          ),
                        );
                        return;
                      }
                      if (newCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Le mot de passe doit contenir au moins 6 caractères'),
                            backgroundColor: Color(0xFFA32D2D),
                          ),
                        );
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Les mots de passe ne correspondent pas'),
                            backgroundColor: Color(0xFFA32D2D),
                          ),
                        );
                        return;
                      }
                      setModal(() => saving = true);
                      try {
                        await _dio.patch('/users/${user?.id}/password', data: {
                          'currentPassword': currentCtrl.text,
                          'newPassword':     newCtrl.text,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mot de passe modifié avec succès'),
                              backgroundColor: Color(0xFF4CBA7D),
                            ),
                          );
                        }
                      } on DioException catch (e) {
                        if (mounted) {
                          final msg = e.response?.data?['message'] ?? 'Mot de passe actuel incorrect';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: const Color(0xFFA32D2D)),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setModal(() => saving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFFE5A01A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))
                        : const Text('Modifier', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Field helpers ───────────────────────────────────────────────────────────
  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) =>
    TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 18),
        filled: true, fillColor: const Color(0xFFF5F5F0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5A01A)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  Widget _passwordField({
    required TextEditingController ctrl,
    required String label,
    required bool show,
    required VoidCallback onToggle,
  }) =>
    TextField(
      controller: ctrl,
      obscureText: !show,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF888888), size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF888888), size: 18,
          ),
          onPressed: onToggle,
        ),
        filled: true, fillColor: const Color(0xFFF5F5F0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5A01A)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mon profil',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Avatar + identité ──
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE5A01A),
                border: Border.all(color: const Color(0xFFF0EDE5), width: 3),
              ),
              alignment: Alignment.center,
              child: Text(
                user?.initials ?? 'C',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A), fontSize: 26, fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user?.fullName ?? '',
              style: const TextStyle(
                color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Coach',
                  style: TextStyle(color: Color(0xFFE5A01A), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 28),

            // ── Menu compte ──
            _MenuCard(items: [
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Modifier le profil',
                onTap: _showEditProfileSheet,
              ),
              _MenuItem(
                icon: Icons.lock_outline,
                label: 'Changer le mot de passe',
                onTap: _showChangePasswordSheet,
              ),
            ]),
            const SizedBox(height: 12),

            // ── Menu navigation ──
            _MenuCard(items: [
              _MenuItem(
                icon: Icons.calendar_month_outlined,
                label: 'Mon planning',
                onTap: () => context.go('/coach/planning'),
              ),
              _MenuItem(
                icon: Icons.people_outline,
                label: 'Mes membres',
                onTap: () => context.go('/coach/members'),
              ),
              _MenuItem(
                icon: Icons.event_busy_outlined,
                label: 'Déclarer une absence',
                onTap: () => context.go('/coach/absences'),
              ),
              _MenuItem(
                icon: Icons.star_outline,
                label: 'Mes évaluations',
                onTap: () => context.go('/coach/ratings'),
              ),
              _MenuItem(
                icon: Icons.report_outlined,
                label: 'Plaintes',
                onTap: () => context.go('/coach/complaints'),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => context.go('/coach/notifications'),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Déconnexion ──
            _PressableButton(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Déconnexion',
                        style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
                    content: const Text('Voulez-vous vous déconnecter ?',
                        style: TextStyle(color: Color(0xFF888888))),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Déconnecter',
                            style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  border: Border.all(color: const Color(0xFFF7C1C1), width: 0.5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Color(0xFFA32D2D), size: 16),
                    SizedBox(width: 8),
                    Text('Se déconnecter',
                        style: TextStyle(color: Color(0xFFA32D2D), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Menu item data ─────────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.label, this.onTap});
}

// ── Menu card ──────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 20, color: const Color(0xFFE5A01A)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(item.label,
                            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14)),
                      ),
                      const Icon(Icons.chevron_right, size: 15, color: Color(0xFFCCCCCC)),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF5F5F0)),
            ],
          );
        }),
      ),
    );
  }
}

// ── Pressable button with scale feedback ──────────────────────────────────────

class _PressableButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _PressableButton({required this.onTap, required this.child});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
