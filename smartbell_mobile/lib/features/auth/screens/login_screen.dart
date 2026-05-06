import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  late final AnimationController _blobCtrl;
  late final Animation<double> _blob1;
  late final Animation<double> _blob2;

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _blob1 = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut),
    );
    _blob2 = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _blobCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      final user = auth.user!;
      if (user.isCoach)  { context.go('/coach');  return; }
      if (user.isAdmin)  { context.go('/admin');  return; }
      context.go('/member');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) _blobCtrl.stop() ;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Ambient glow blobs ──
          if (!disableAnimations) ...[
            Positioned(
              top: -100, left: -70,
              child: AnimatedBuilder(
                animation: _blob1,
                builder: (_, __) => Transform.scale(
                  scale: _blob1.value,
                  child: Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.primary.withValues(alpha: 0.13),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 60, right: -90,
              child: AnimatedBuilder(
                animation: _blob2,
                builder: (_, __) => Transform.scale(
                  scale: _blob2.value,
                  child: Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.info.withValues(alpha: 0.10),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo ──
                    Center(
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            AppTheme.primary.withValues(alpha: 0.22),
                            AppTheme.primary.withValues(alpha: 0.05),
                          ]),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: AppTheme.primaryGlow,
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppTheme.primary,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'SmartBell Gym',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Connectez-vous pour continuer',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 36),

                    // ── Card ──
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
                                  Colors.white.withValues(alpha: 0.09),
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
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
                                          child: Text(
                                            auth.error!,
                                            style: const TextStyle(
                                                color: AppTheme.error, fontSize: 13),
                                          ),
                                        ),
                                      ]),
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // ── Form ──
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Text('EMAIL',
                                            style: AppTheme.sectionTitle),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _emailCtrl,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          style: const TextStyle(
                                              color: AppTheme.textPrimary),
                                          decoration: const InputDecoration(
                                            hintText: 'votre@email.com',
                                            prefixIcon: Icon(
                                              Icons.email_outlined,
                                              color: AppTheme.textSecondary,
                                              size: 20,
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return 'Email requis';
                                            }
                                            if (!v.contains('@')) {
                                              return 'Email invalide';
                                            }
                                            return null;
                                          },
                                          onChanged: (_) => context
                                              .read<AuthProvider>()
                                              .clearError(),
                                        ),
                                        const SizedBox(height: 20),

                                        const Text('MOT DE PASSE',
                                            style: AppTheme.sectionTitle),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _passCtrl,
                                          obscureText: _obscure,
                                          style: const TextStyle(
                                              color: AppTheme.textPrimary),
                                          decoration: InputDecoration(
                                            hintText: '••••••••',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              color: AppTheme.textSecondary,
                                              size: 20,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscure
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined,
                                                color: AppTheme.textSecondary,
                                                size: 20,
                                              ),
                                              onPressed: () => setState(
                                                  () => _obscure = !_obscure),
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                                  ? 'Mot de passe requis'
                                                  : null,
                                          onChanged: (_) => context
                                              .read<AuthProvider>()
                                              .clearError(),
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
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Se connecter',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Register link ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Pas encore de compte ?',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text(
                            'S\'inscrire',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        duration:
            disableAnimations ? Duration.zero : const Duration(milliseconds: 120),
        curve: Curves.easeOutExpo,
        child: widget.child,
      ),
    );
  }
}
