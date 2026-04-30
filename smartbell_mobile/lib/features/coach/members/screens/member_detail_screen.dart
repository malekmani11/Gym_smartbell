import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/gym_badge.dart';
import '../../../../features/adherent/training/models/training_program.dart';
import '../../../../features/adherent/nutrition/models/nutrition_plan.dart';

class MemberDetailScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  TrainingProgram? _program;
  NutritionPlan?  _nutrition;
  int  _visitCount   = 0;
  int  _daysLeft     = 0;
  int  _points       = 0;
  bool _loading      = true;

  Map<String, dynamic> get m => widget.member;

  String get _fullName => '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();

  String get _initials {
    final f = (m['firstName'] ?? '').toString();
    final l = (m['lastName']  ?? '').toString();
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final memberId = (m['id'] ?? 0).toInt();
    final dio      = DioClient.instance.dio;

    try {
      // Checkins this month
      try {
        final ciRes  = await dio.get(ApiConstants.checkinsByMember(memberId));
        final ciData = ciRes.data;
        final ciList = ciData is List ? ciData : (ciData is Map ? (ciData['content'] ?? []) : []);
        final now    = DateTime.now();
        _visitCount  = (ciList as List).where((c) {
          try { final d = DateTime.parse(c['checkInTime'] ?? c['date'] ?? ''); return d.month == now.month && d.year == now.year; } catch (_) { return false; }
        }).length;
      } catch (_) {}

      // Subscription days left
      try {
        final userId = (m['userId'] ?? m['user']?['id'] ?? 0).toInt();
        if (userId > 0) {
          final subRes  = await dio.get(ApiConstants.subscriptionsByUser(userId), queryParameters: {'size': 1, 'sort': 'createdAt,desc'});
          final subData = subRes.data;
          final subList = subData is Map ? (subData['content'] ?? []) : [];
          if ((subList as List).isNotEmpty && subList.first['endDate'] != null) {
            final end  = DateTime.tryParse(subList.first['endDate']);
            _daysLeft  = end != null ? end.difference(DateTime.now()).inDays.clamp(0, 999) : 0;
          }
        }
      } catch (_) {}

      // Training program
      try {
        final tRes  = await dio.get(ApiConstants.trainingByMember(memberId));
        final tData = tRes.data;
        final tList = tData is List ? tData : (tData is Map ? (tData['content'] ?? []) : []);
        if ((tList as List).isNotEmpty) _program = TrainingProgram.fromJson(tList.first);
      } catch (_) {}

      // Nutrition plan
      try {
        final nRes  = await dio.get(ApiConstants.nutritionByMember(memberId));
        final nData = nRes.data;
        final nList = nData is List ? nData : (nData is Map ? (nData['content'] ?? []) : []);
        if ((nList as List).isNotEmpty) _nutrition = NutritionPlan.fromJson(nList.first);
      } catch (_) {}

      _points = 0; // placeholder until loyalty API is available
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (m['membershipStatus'] ?? m['status'] ?? '').toString().toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar with avatar ──
          SliverAppBar(
            backgroundColor: AppTheme.surfaceAlt,
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: 0.25), AppTheme.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      child: Text(_initials, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 22)),
                    ),
                    const SizedBox(height: 8),
                    Text(_fullName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(m['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                // ── Status + plan ──
                Row(children: [
                  _statusBadge(status),
                  const SizedBox(width: 8),
                  if (m['planName'] != null)
                    GymBadge(text: m['planName'].toString(), type: BadgeType.blue),
                ]),
                const SizedBox(height: 16),

                // ── Stats ──
                Row(children: [
                  Expanded(child: StatCard(value: '$_visitCount', label: 'Visites ce mois', icon: Icons.bar_chart, color: AppTheme.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(value: '$_points', label: 'Points fidélité', icon: Icons.stars, color: const Color(0xFFE5C200))),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(value: '$_daysLeft j', label: 'Jours restants', icon: Icons.timer_outlined, color: _daysLeft < 7 ? AppTheme.error : AppTheme.success)),
                ]),
                const SizedBox(height: 20),

                // ── Training program ──
                _SectionHeader(title: 'Programme d\'entraînement', actionLabel: 'Modifier', onAction: () {}),
                const SizedBox(height: 10),
                _program == null
                    ? _EmptySection(label: 'Aucun programme assigné', icon: Icons.fitness_center_outlined)
                    : _ProgramCard(program: _program!),
                const SizedBox(height: 20),

                // ── Nutrition plan ──
                _SectionHeader(title: 'Plan nutritionnel', actionLabel: 'Modifier', onAction: () {}),
                const SizedBox(height: 10),
                _nutrition == null
                    ? _EmptySection(label: 'Aucun plan nutritionnel', icon: Icons.restaurant_menu_outlined)
                    : _NutritionCard(plan: _nutrition!),
                const SizedBox(height: 20),

                // ── Actions ──
                const Text('Actions', style: AppTheme.headingMedium),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_outlined, size: 16),
                      label: const Text('Message'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('Visites'),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
              ])),
            ),
        ],
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: AppTheme.headingMedium),
      if (actionLabel != null)
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel!, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
    ],
  );
}

class _EmptySection extends StatelessWidget {
  final String label;
  final IconData icon;
  const _EmptySection({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border, width: 0.5)),
    child: Row(children: [
      Icon(icon, color: AppTheme.textMuted, size: 22),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ]),
  );
}

class _ProgramCard extends StatelessWidget {
  final TrainingProgram program;
  const _ProgramCard({required this.program});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 0.5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(program.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Text('${program.exercises.length} exercices', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        if (program.exercises.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...program.exercises.take(3).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.circle, color: AppTheme.primary, size: 6),
              const SizedBox(width: 8),
              Text('${e.name}  ·  ${e.sets}×${e.reps}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          )),
          if (program.exercises.length > 3)
            Text('+${program.exercises.length - 3} autres…', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ],
    ),
  );
}

class _NutritionCard extends StatelessWidget {
  final NutritionPlan plan;
  const _NutritionCard({required this.plan});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.success.withValues(alpha: 0.3), width: 0.5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Text('Objectif : ${plan.targetCalories.toInt()} kcal/jour', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        if (plan.meals.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...plan.meals.take(3).map((meal) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.circle, color: AppTheme.success, size: 6),
              const SizedBox(width: 8),
              Text('${meal.typeLabel}  ·  ${meal.calories.toInt()} kcal', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          )),
          if (plan.meals.length > 3)
            Text('+${plan.meals.length - 3} autres…', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ],
    ),
  );
}
