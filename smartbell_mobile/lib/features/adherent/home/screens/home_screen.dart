import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../shared/models/measurement.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/dark_card.dart';
import '../../../../shared/widgets/gym_badge.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../adherent/training/offline_training_repository.dart';

class AdherentHomeScreen extends StatefulWidget {
  const AdherentHomeScreen({super.key});

  @override
  State<AdherentHomeScreen> createState() => _AdherentHomeScreenState();
}

class _AdherentHomeScreenState extends State<AdherentHomeScreen>
    with TickerProviderStateMixin {
  int _checkinsThisMonth = 0;
  int _loyaltyPoints     = 0;
  int _daysRemaining     = 0;
  int _totalDays         = 30;
  String? _planName;
  String? _nextCourseName;
  String? _nextCourseTime;
  bool _loading = true;
  bool _syncing = false;

  // Progress snapshot
  double? _currentWeight;
  double? _weightVariation;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) { setState(() => _loading = false); return; }
    final dio = DioClient.instance.dio;

    try {
      // Load checkins
      try {
        final memberRes = await dio.get(ApiConstants.memberByUser(user.id));
        final memberData = memberRes.data is Map ? memberRes.data : {};
        final memberId = (memberData['id'] ?? 0).toInt();
        if (memberId > 0) {
          final ciRes = await dio.get(ApiConstants.checkinsByMember(memberId));
          final ciData = ciRes.data;
          final ciList = ciData is List ? ciData : (ciData is Map ? (ciData['content'] ?? []) : []);
          final now = DateTime.now();
          _checkinsThisMonth = (ciList as List).where((c) {
            try {
              final d = DateTime.parse(c['checkInTime'] ?? c['date'] ?? '');
              return d.month == now.month && d.year == now.year;
            } catch (_) { return false; }
          }).length;
        }
      } catch (_) {}

      _loyaltyPoints = 0;

      // Load subscription
      try {
        final subRes = await dio.get(ApiConstants.subscriptionsByUser(user.id),
            queryParameters: {'size': 1, 'sort': 'createdAt,desc'});
        final subData = subRes.data;
        final subList = subData is Map ? (subData['content'] ?? []) : [];
        if ((subList as List).isNotEmpty) {
          final sub = subList.first;
          _planName = sub['planName'];
          if (sub['endDate'] != null) {
            final end = DateTime.tryParse(sub['endDate']);
            if (end != null) {
              _daysRemaining = end.difference(DateTime.now()).inDays.clamp(0, 999);
            }
          }
          if (sub['startDate'] != null && sub['endDate'] != null) {
            final start = DateTime.tryParse(sub['startDate']);
            final end   = DateTime.tryParse(sub['endDate']);
            if (start != null && end != null) {
              _totalDays = end.difference(start).inDays.clamp(1, 999);
            }
          }
        }
      } catch (_) {}

      // Load progress snapshot from local cache (same key as ProgressService)
      try {
        final membRes = await dio.get(ApiConstants.memberByUser(user.id));
        final mid = (membRes.data['id'] ?? user.id).toInt();
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('smartbell_measurements_$mid');
        if (raw != null) {
          final list = (jsonDecode(raw) as List)
              .map((j) => Measurement.fromJson(j as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          if (list.isNotEmpty) {
            _currentWeight  = list.last.weight;
            _weightVariation = list.length > 1
                ? list.last.weight - list.first.weight
                : null;
          }
        }
      } catch (_) {}

      // Load next course today
      try {
        final courseRes = await dio.get(ApiConstants.courses,
            queryParameters: {'size': 50, 'active': true});
        final courseData = courseRes.data;
        final courseList = courseData is Map
            ? (courseData['content'] ?? [])
            : (courseData ?? []);
        final days = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'];
        final today = days[DateTime.now().weekday - 1];
        final todayCourses = (courseList as List)
            .where((c) => (c['dayOfWeek'] ?? '').toString().toUpperCase() == today)
            .toList();
        if (todayCourses.isNotEmpty) {
          _nextCourseName = todayCourses.first['name'];
          _nextCourseTime = todayCourses.first['startTime'];
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() => _loading = false);
    } on DioException {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _syncData() async {
    final user = context.read<AuthProvider>().user;
    final isOnline = await ConnectivityService.instance.checkConnectivity();
    if (!isOnline) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hors-ligne — synchronisation impossible'),
          backgroundColor: Color(0xFFE24B4A),
        ),
      );
      return;
    }
    setState(() => _syncing = true);
    try {
      if (user != null) {
        final memberRes = await DioClient.instance.dio
            .get(ApiConstants.memberByUser(user.id));
        final memberId = (memberRes.data['id'] ?? 0).toInt();
        if (memberId > 0) {
          await OfflineTrainingRepository().forceSync(memberId);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données synchronisées'),
          backgroundColor: Color(0xFF3C9E5F),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de la synchronisation'),
          backgroundColor: Color(0xFFE24B4A),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  double get _subscriptionProgress =>
      _totalDays > 0 ? (_daysRemaining / _totalDays).clamp(0.0, 1.0) : 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final now  = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) _pulseCtrl.stop();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/member/scan'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        tooltip: 'Scanner une machine',
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header banner ──
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF222222), Color(0xFF181818)],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0x40EF9F27),
                      width: 0.5,
                    ),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 14,
                  left: 20, right: 20, bottom: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, ${user?.firstName ?? 'Adhérent'} 👋',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            now,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/member/profile'),
                          child: Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                AppTheme.primary.withValues(alpha: 0.25),
                                AppTheme.primary.withValues(alpha: 0.08),
                              ]),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user?.initials ?? 'M',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        // Pulsing status dot
                        Positioned(
                          right: 0, top: 0,
                          child: disableAnimations
                              ? Container(
                                  width: 11, height: 11,
                                  decoration: BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.background, width: 2),
                                  ),
                                )
                              : AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (_, __) => Container(
                                    width: 11, height: 11,
                                    decoration: BoxDecoration(
                                      color: AppTheme.success
                                          .withValues(alpha: _pulse.value),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppTheme.background, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.success
                                              .withValues(alpha: _pulse.value * 0.6),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Stat Cards ──
                    Row(children: [
                      Expanded(child: StatCard(
                        value: '$_checkinsThisMonth',
                        label: 'Visites ce mois',
                        icon: Icons.bar_chart,
                        color: AppTheme.primary,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: StatCard(
                        value: '$_loyaltyPoints',
                        label: 'Points fidélité',
                        icon: Icons.stars,
                        color: AppTheme.success,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: StatCard(
                        value: '$_daysRemaining',
                        label: 'Jours restants',
                        icon: Icons.timer_outlined,
                        color: _daysRemaining < 7 ? AppTheme.error : AppTheme.info,
                      )),
                    ]),
                    const SizedBox(height: 20),

                    // ── Subscription progress ──
                    if (_planName != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _planName!,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GymBadge(
                            text: '$_daysRemaining jours',
                            type: _daysRemaining < 7
                                ? BadgeType.red
                                : BadgeType.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _subscriptionProgress,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppTheme.primary,
                                AppTheme.primary.withValues(alpha: 0.5),
                              ]),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // ── Ma Progression card ──
                    _ProgressCard(
                      currentWeight: _currentWeight,
                      variation: _weightVariation,
                      onTap: () => context.go('/member/progress'),
                    ),
                    const SizedBox(height: 20),

                    // ── Aujourd'hui ──
                    const Text("AUJOURD'HUI", style: AppTheme.sectionTitle),
                    const SizedBox(height: 10),
                    DarkCard(children: [
                      _TodayRow(
                        icon: Icons.fitness_center,
                        color: AppTheme.primary,
                        title: 'Séance d\'entraînement',
                        subtitle: 'Voir mon programme',
                        onTap: () => context.go('/member/training'),
                      ),
                      _TodayRow(
                        icon: Icons.restaurant_menu,
                        color: AppTheme.success,
                        title: 'Plan nutritionnel',
                        subtitle: 'Voir mes repas',
                        onTap: () => context.go('/member/nutrition'),
                      ),
                      _TodayRow(
                        icon: Icons.event,
                        color: AppTheme.info,
                        title: _nextCourseName ?? 'Prochain cours',
                        subtitle: _nextCourseTime != null
                            ? 'À $_nextCourseTime'
                            : 'Voir le planning',
                        onTap: () => context.go('/member/courses'),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Quick actions ──
                    const Text('ACCÈS RAPIDE', style: AppTheme.sectionTitle),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.05,
                      children: [
                        _QuickAction(
                          icon: Icons.fitness_center,
                          label: 'Entraînement',
                          color: AppTheme.primary,
                          path: '/member/training',
                        ),
                        _QuickAction(
                          icon: Icons.restaurant_menu,
                          label: 'Nutrition',
                          color: AppTheme.success,
                          path: '/member/nutrition',
                        ),
                        _QuickAction(
                          icon: Icons.calendar_today,
                          label: 'Cours',
                          color: AppTheme.info,
                          path: '/member/courses',
                        ),
                        _QuickAction(
                          icon: Icons.chat_outlined,
                          label: 'Messages',
                          color: AppTheme.warning,
                          path: '/member/chat',
                        ),
                        _QuickAction(
                          icon: Icons.stars,
                          label: 'Fidélité',
                          color: const Color(0xFFE5C200),
                          path: '/member/loyalty',
                        ),
                        _QuickAction(
                          icon: Icons.person_outline,
                          label: 'Profil',
                          color: AppTheme.textSecondary,
                          path: '/member/profile',
                        ),
                        _QuickAction(
                          icon: Icons.qr_code_scanner,
                          label: 'Scanner',
                          color: AppTheme.primary,
                          path: '/member/scan',
                          usePush: true,
                        ),
                        _QuickAction(
                          icon: Icons.monitor_weight_outlined,
                          label: 'Progression',
                          color: AppTheme.info,
                          path: '/member/progress',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Today row ─────────────────────────────────────────────────────────────────
class _TodayRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TodayRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
    ]),
  );
}

// ── Quick action tile ─────────────────────────────────────────────────────────
class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  final bool usePush;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.path,
    this.usePush = false,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: () => widget.usePush ? context.push(widget.path) : context.go(widget.path),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (_pressed && !disableAnimations) ? 0.95 : 1.0,
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOutExpo,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF272727), Color(0xFF1E1E1E)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.28),
              width: 0.5,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Progress card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final double? currentWeight;
  final double? variation;
  final VoidCallback onTap;

  const _ProgressCard({
    required this.currentWeight,
    required this.variation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = currentWeight != null;
    final isLoss  = (variation ?? 0) < 0;
    final varColor = variation == null
        ? AppTheme.textMuted
        : (isLoss ? AppTheme.success : AppTheme.error);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.10),
              AppTheme.primary.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.22), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.show_chart,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ma Progression',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasData
                        ? '${currentWeight!.toStringAsFixed(1)} kg'
                            '${variation != null ? '  ·  ${isLoss ? '▼' : '▲'} ${variation!.abs().toStringAsFixed(1)} kg' : ''}'
                        : 'Commencer le suivi de poids',
                    style: TextStyle(
                      color: hasData ? varColor : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          hasData ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
