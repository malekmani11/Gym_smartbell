import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
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
  int  _visitCount = 0;
  int  _daysLeft   = 0;
  int  _points     = 0;
  bool _loading    = true;

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
      _visitCount = 0;
      try {
        final userId = (m['userId'] ?? m['user']?['id'] ?? 0).toInt();
        if (userId > 0) {
          final subRes  = await dio.get(ApiConstants.subscriptionsByUser(userId), queryParameters: {'size': 1, 'sort': 'createdAt,desc'});
          final subData = subRes.data;
          final subList = subData is Map ? (subData['content'] ?? []) : [];
          if ((subList as List).isNotEmpty && subList.first['endDate'] != null) {
            final end = DateTime.tryParse(subList.first['endDate']);
            _daysLeft = end != null ? end.difference(DateTime.now()).inDays.clamp(0, 999) : 0;
          }
        }
      } catch (_) {}

      try {
        final tRes  = await dio.get(ApiConstants.trainingByMember(memberId));
        final tData = tRes.data;
        final tList = tData is List ? tData : (tData is Map ? (tData['content'] ?? []) : []);
        if ((tList as List).isNotEmpty) _program = TrainingProgram.fromJson(tList.first);
      } catch (_) {}

      try {
        final nRes  = await dio.get(ApiConstants.nutritionByMember(memberId));
        final nData = nRes.data;
        final nList = nData is List ? nData : (nData is Map ? (nData['content'] ?? []) : []);
        if ((nList as List).isNotEmpty) _nutrition = NutritionPlan.fromJson(nList.first);
      } catch (_) {}

      _points = 0;
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (m['membershipStatus'] ?? m['status'] ?? '').toString().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(
        children: [
          // ── Dark header ──
          Container(
            color: const Color(0xFF1A1A1A),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Back button row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Détail membre',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 36),
                    ]),
                  ),
                  // Avatar + info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Column(children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2A2A2A),
                          border: Border.all(color: const Color(0xFFE5A01A).withValues(alpha: 0.4), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(_initials, style: const TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.bold, fontSize: 22)),
                      ),
                      const SizedBox(height: 10),
                      Text(_fullName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(m['email'] ?? '', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable body ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
                : RefreshIndicator(
                    color: const Color(0xFFE5A01A),
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Status + plan
                        Row(children: [
                          _StatusPill(status: status),
                          const SizedBox(width: 8),
                          if (m['planName'] != null)
                            _PlanPill(label: m['planName'].toString()),
                        ]),
                        const SizedBox(height: 16),

                        // Stats row
                        Row(children: [
                          Expanded(child: _StatCard(value: '$_visitCount', label: 'Visites\nce mois',   icon: Icons.bar_chart)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(value: '$_points',     label: 'Points\nfidélité',   icon: Icons.stars)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(
                            value: '$_daysLeft j',
                            label: 'Jours\nrestants',
                            icon: Icons.timer_outlined,
                            accent: _daysLeft < 7 ? const Color(0xFFE53935) : const Color(0xFFE5A01A),
                          )),
                        ]),
                        const SizedBox(height: 20),

                        // Training program
                        _SectionHeader(title: "Programme d'entraînement"),
                        const SizedBox(height: 10),
                        _program == null
                            ? _EmptySection(label: 'Aucun programme assigné', icon: Icons.fitness_center_outlined)
                            : _ProgramCard(program: _program!),
                        const SizedBox(height: 20),

                        // Nutrition plan
                        const _SectionHeader(title: 'Plan nutritionnel'),
                        const SizedBox(height: 10),
                        _nutrition == null
                            ? _EmptySection(label: 'Aucun plan nutritionnel', icon: Icons.restaurant_menu_outlined)
                            : _NutritionCard(plan: _nutrition!),
                        const SizedBox(height: 20),

                        // Actions
                        const Text('Actions', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _ActionButton(icon: Icons.chat_outlined,  label: 'Message', onTap: () {})),
                          const SizedBox(width: 12),
                          Expanded(child: _ActionButton(icon: Icons.history,        label: 'Visites',  onTap: () {})),
                        ]),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'ACTIVE'    => (const Color(0xFFEAF3DE), const Color(0xFF3B6D11), 'Actif'),
      'INACTIVE'  => (const Color(0xFFF0F0F0), const Color(0xFF666666), 'Inactif'),
      'SUSPENDED' => (const Color(0xFFFAEEDA), const Color(0xFF854F0B), 'Suspendu'),
      _           => (const Color(0xFFF0F0F0), const Color(0xFF888888), status.isNotEmpty ? status : '—'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _PlanPill extends StatelessWidget {
  final String label;
  const _PlanPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE5A01A).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? accent;
  const _StatCard({required this.value, required this.label, required this.icon, this.accent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: accent ?? const Color(0xFFE5A01A), size: 16),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: accent ?? const Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 9), maxLines: 2),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.w600),
  );
}

class _EmptySection extends StatelessWidget {
  final String label;
  final IconData icon;
  const _EmptySection({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
    ),
    child: Row(children: [
      Icon(icon, color: const Color(0xFFBBBBBB), size: 22),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
    ]),
  );
}

class _ProgramCard extends StatelessWidget {
  final TrainingProgram program;
  const _ProgramCard({required this.program});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(program.name, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 6),
      Text('${program.exercises.length} exercices', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
      if (program.exercises.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...program.exercises.take(3).map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.circle, color: Color(0xFFE5A01A), size: 6),
            const SizedBox(width: 8),
            Text('${e.name}  ·  ${e.sets}×${e.reps}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          ]),
        )),
        if (program.exercises.length > 3)
          Text('+${program.exercises.length - 3} autres…', style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
      ],
    ]),
  );
}

class _NutritionCard extends StatelessWidget {
  final NutritionPlan plan;
  const _NutritionCard({required this.plan});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(plan.name, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 6),
      Text('Objectif : ${plan.targetCalories.toInt()} kcal/jour', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
      if (plan.meals.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...plan.meals.take(3).map((meal) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 6),
            const SizedBox(width: 8),
            Text('${meal.typeLabel}  ·  ${meal.calories.toInt()} kcal', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          ]),
        )),
        if (plan.meals.length > 3)
          Text('+${plan.meals.length - 3} autres…', style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
      ],
    ]),
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1A1A1A), size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}
