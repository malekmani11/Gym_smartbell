import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  String _role     = 'ROLE_MEMBER';
  bool _obscure1   = true;
  bool _obscure2   = true;

  late final AnimationController _blobCtrl;
  late final Animation<double> _blob1;
  late final Animation<double> _blob2;

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _blob1 = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut),
    );
    _blob2 = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _pass2Ctrl]) {
      c.dispose();
    }
    _blobCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      firstName: _firstCtrl.text.trim(),
      lastName:  _lastCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      password:  _passCtrl.text,
      phone:     _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      roleName:  _role,
    );
    if (!mounted) return;
    if (ok) {
      final user = auth.user!;
      if (user.isCoach) { context.go('/coach'); return; }
      context.go('/member');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) _blobCtrl.stop();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppTheme.textSecondary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Stack(
        children: [
          // ── Ambient blobs ──
          if (!disableAnimations) ...[
            Positioned(
              top: -80, right: -60,
              child: AnimatedBuilder(
                animation: _blob1,
                builder: (_, __) => Transform.scale(
                  scale: _blob1.value,
                  child: Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.success.withValues(alpha: 0.10),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80, left: -80,
              child: AnimatedBuilder(
                animation: _blob2,
                builder: (_, __) => Transform.scale(
                  scale: _blob2.value,
                  child: Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.primary.withValues(alpha: 0.10),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Form content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Créer un compte', style: AppTheme.headingLarge),
                  const SizedBox(height: 4),
                  const Text(
                    'Rejoignez SmartBell Gym',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // ── Error banner ──
                  if (auth.error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppTheme.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(auth.error!,
                              style: const TextStyle(
                                  color: AppTheme.error, fontSize: 13)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Card wrapper ──
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Inner top highlight
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 20, 20, 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('IDENTITÉ', style: AppTheme.sectionTitle),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                      child: _field(
                                        _firstCtrl, 'Prénom',
                                        Icons.person_outline,
                                        (v) => v!.isEmpty ? 'Requis' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _field(
                                        _lastCtrl, 'Nom',
                                        Icons.person_outline,
                                        (v) => v!.isEmpty ? 'Requis' : null,
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 20),

                                  const Text('CONTACT', style: AppTheme.sectionTitle),
                                  const SizedBox(height: 10),
                                  _field(
                                    _emailCtrl, 'Email', Icons.email_outlined,
                                    (v) {
                                      if (v!.isEmpty) return 'Requis';
                                      if (!v.contains('@')) return 'Email invalide';
                                      return null;
                                    },
                                    type: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 14),
                                  _field(
                                    _phoneCtrl,
                                    'Téléphone (optionnel)',
                                    Icons.phone_outlined,
                                    (_) => null,
                                    type: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 20),

                                  const Text('RÔLE', style: AppTheme.sectionTitle),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: _role,
                                    dropdownColor: AppTheme.surface,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14),
                                    decoration: const InputDecoration(
                                      labelText: 'Rôle',
                                      prefixIcon: Icon(Icons.badge_outlined,
                                          color: AppTheme.textSecondary,
                                          size: 20),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'ROLE_MEMBER',
                                          child: Text('Adhérent')),
                                      DropdownMenuItem(
                                          value: 'ROLE_COACH',
                                          child: Text('Coach')),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _role = v!),
                                  ),
                                  const SizedBox(height: 20),

                                  const Text('SÉCURITÉ', style: AppTheme.sectionTitle),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscure1,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14),
                                    decoration: InputDecoration(
                                      labelText: 'Mot de passe',
                                      prefixIcon: const Icon(Icons.lock_outline,
                                          color: AppTheme.textSecondary,
                                          size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure1
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppTheme.textSecondary,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                            () => _obscure1 = !_obscure1),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 6)
                                            ? 'Minimum 6 caractères'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _pass2Ctrl,
                                    obscureText: _obscure2,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14),
                                    decoration: InputDecoration(
                                      labelText: 'Confirmer le mot de passe',
                                      prefixIcon: const Icon(Icons.lock_outline,
                                          color: AppTheme.textSecondary,
                                          size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure2
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppTheme.textSecondary,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                            () => _obscure2 = !_obscure2),
                                      ),
                                    ),
                                    validator: (v) =>
                                        v != _passCtrl.text
                                            ? 'Les mots de passe ne correspondent pas'
                                            : null,
                                  ),
                                  const SizedBox(height: 28),

                                  // ── Submit ──
                                  _PressableButton(
                                    onTap: auth.loading ? null : _submit,
                                    child: Container(
                                      height: 52,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: auth.loading
                                            ? null
                                            : AppTheme.primaryGradient,
                                        color: auth.loading
                                            ? AppTheme.border
                                            : null,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        boxShadow: auth.loading
                                            ? null
                                            : AppTheme.primaryGlow,
                                      ),
                                      child: auth.loading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'S\'inscrire',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Déjà inscrit ?',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String? Function(String?) validator, {
    TextInputType? type,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
      validator: validator,
      onChanged: (_) => context.read<AuthProvider>().clearError(),
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
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _pressed = false)
          : null,
      child: AnimatedScale(
        scale: (_pressed && !disableAnimations) ? 0.97 : 1.0,
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOutExpo,
        child: widget.child,
      ),
    );
  }
}
