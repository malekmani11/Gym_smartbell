import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/validation_store.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../models/nutrition_plan.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  NutritionPlan? _plan;
  bool _loading = true;

  // Submit to coach
  bool    _submitting       = false;
  String? _submissionStatus; // PENDING | VALIDATED | REJECTED | null

  // Profile form
  double _height    = 170;
  double _weight    = 70;
  int    _age       = 25;
  String _goal      = 'FORME_GENERALE';
  String _activity  = 'MODERE';
  bool   _showForm  = false;

  static const _goals = {
    'PERTE_DE_POIDS':  ('🔥', 'Perte de poids'),
    'PRISE_DE_MUSCLE': ('💪', 'Prise de muscle'),
    'ENDURANCE':       ('🏃', 'Endurance'),
    'FORME_GENERALE':  ('⚡', 'Forme générale'),
  };

  static const _activities = {
    'SEDENTAIRE':  ('🛋️', 'Sédentaire'),
    'LEGER':       ('🚶', 'Léger'),
    'MODERE':      ('🏃', 'Modéré'),
    'INTENSE':     ('⚡', 'Intense'),
    'TRES_INTENSE':('🔥', 'Très intense'),
  };

  @override
  void initState() {
    super.initState();
    _loadFromBackendOrGenerate();
    _checkSubmissionStatus();
  }

  Future<void> _checkSubmissionStatus() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    try {
      final res = await DioClient.instance.dio.get('/members/user/${user.id}');
      final memberId = (res.data['id'] ?? 0).toInt();
      final entry = await ValidationStore.getLatestNutritionForMember(memberId);
      if (mounted && entry != null) {
        setState(() => _submissionStatus = entry['status'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _submitToCoach() async {
    if (_plan == null) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      int memberId = user.id;
      try {
        final res = await DioClient.instance.dio.get('/members/user/${user.id}');
        memberId = (res.data['id'] ?? 0).toInt();
      } catch (_) {}

      await ValidationStore.submitNutrition(
        memberId:   memberId,
        memberName: user.fullName,
        plan:       _plan!.toJson(),
      );

      if (mounted) {
        setState(() { _submissionStatus = 'PENDING'; _submitting = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Plan envoyé au coach pour validation !'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(DioClient.errorMessage(e)),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Future<void> _loadFromBackendOrGenerate() async {
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      _plan = _generateLocally();
      setState(() => _loading = false);
      return;
    }

    try {
      final memberRes = await DioClient.instance.dio.get('/members/user/${user.id}');
      final memberId  = (memberRes.data['id'] ?? 0).toInt();
      if (memberId > 0) {
        final nRes  = await DioClient.instance.dio.get('/nutrition-plans/member/$memberId');
        final nData = nRes.data;
        final nList = nData is List ? nData : (nData is Map ? (nData['content'] ?? []) : []);
        if ((nList as List).isNotEmpty) {
          _plan = NutritionPlan.fromJson(nList.first);
          setState(() => _loading = false);
          return;
        }
      }
    } catch (_) {}

    // Fallback: generate locally
    _plan = _generateLocally();
    setState(() => _loading = false);
  }

  NutritionPlan _generateLocally() {
    final activityFactor = {
      'SEDENTAIRE':   1.2,
      'LEGER':        1.375,
      'MODERE':       1.55,
      'INTENSE':      1.725,
      'TRES_INTENSE': 1.9,
    }[_activity] ?? 1.55;

    // Harris-Benedict formula
    final bmr = 10 * _weight + 6.25 * _height - 5 * _age + 5;
    double tdee = bmr * activityFactor;

    // Adjust for goal
    double targetCal;
    switch (_goal) {
      case 'PERTE_DE_POIDS':  targetCal = tdee - 500; break;
      case 'PRISE_DE_MUSCLE': targetCal = tdee + 300; break;
      case 'ENDURANCE':       targetCal = tdee + 100; break;
      default:                targetCal = tdee;
    }
    targetCal = targetCal.clamp(1200, 4000);

    // Macros split by goal
    double protPct, carbPct, fatPct;
    switch (_goal) {
      case 'PRISE_DE_MUSCLE': protPct = 0.30; carbPct = 0.45; fatPct = 0.25; break;
      case 'PERTE_DE_POIDS':  protPct = 0.35; carbPct = 0.35; fatPct = 0.30; break;
      case 'ENDURANCE':       protPct = 0.20; carbPct = 0.55; fatPct = 0.25; break;
      default:                protPct = 0.25; carbPct = 0.45; fatPct = 0.30;
    }

    final totalProt = (targetCal * protPct / 4).roundToDouble();
    final totalCarb = (targetCal * carbPct / 4).roundToDouble();
    final totalFat  = (targetCal * fatPct  / 9).roundToDouble();

    final meals = _buildMeals(targetCal, totalProt, totalCarb, totalFat);

    return NutritionPlan(
      id:             DateTime.now().millisecondsSinceEpoch,
      name:           '${_goals[_goal]?.$2 ?? 'Plan'} · ${targetCal.toInt()} kcal',
      targetCalories: targetCal,
      meals:          meals,
    );
  }

  List<Meal> _buildMeals(double cal, double prot, double carb, double fat) {
    // Split: 25% breakfast, 35% lunch, 30% dinner, 10% snack
    final splits = [0.25, 0.35, 0.30, 0.10];
    final types  = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'];

    final breakfastFoods = _goal == 'PRISE_DE_MUSCLE'
        ? 'Flocons d\'avoine, œufs brouillés, banane, lait'
        : _goal == 'PERTE_DE_POIDS'
            ? 'Yaourt grec, fruits rouges, amandes, café noir'
            : 'Pain complet, beurre de cacahuète, banane, lait';

    final lunchFoods = _goal == 'PRISE_DE_MUSCLE'
        ? 'Riz basmati, poulet grillé, légumes verts, huile d\'olive'
        : _goal == 'PERTE_DE_POIDS'
            ? 'Salade de quinoa, thon, légumes crus, citron'
            : 'Pâtes complètes, poulet, salade verte';

    final dinnerFoods = _goal == 'PRISE_DE_MUSCLE'
        ? 'Saumon, patate douce, brocoli, riz'
        : _goal == 'PERTE_DE_POIDS'
            ? 'Poisson blanc vapeur, légumes grillés, courgettes'
            : 'Filet de dinde, haricots verts, pomme de terre';

    final snackFoods = _goal == 'PRISE_DE_MUSCLE'
        ? 'Shake protéiné, noix mélangées, yaourt'
        : _goal == 'PERTE_DE_POIDS'
            ? 'Pomme, fromage blanc 0%, amandes'
            : 'Fruit frais, barre céréales, eau';

    final foods = [breakfastFoods, lunchFoods, dinnerFoods, snackFoods];

    return List.generate(4, (i) {
      final c = cal * splits[i];
      final p = prot * splits[i];
      final cb = carb * splits[i];
      final f  = fat  * splits[i];
      return Meal(
        id:       i + 1,
        name:     foods[i],
        type:     types[i],
        calories: c,
        macro:    Macro(proteins: p, carbs: cb, fats: f),
      );
    });
  }

  void _onGenerate() {
    setState(() {
      _plan = _generateLocally();
      _showForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.primary),
            tooltip: 'Personnaliser',
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _loadFromBackendOrGenerate,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Personalization form ──
                    if (_showForm) ...[
                      _ProfileForm(
                        height:    _height,
                        weight:    _weight,
                        age:       _age,
                        goal:      _goal,
                        activity:  _activity,
                        goals:     _goals,
                        activities: _activities,
                        onHeightChanged:   (v) => setState(() => _height   = v),
                        onWeightChanged:   (v) => setState(() => _weight   = v),
                        onAgeChanged:      (v) => setState(() => _age      = v),
                        onGoalChanged:     (v) => setState(() => _goal     = v),
                        onActivityChanged: (v) => setState(() => _activity = v),
                        onGenerate: _onGenerate,
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_plan != null) ...[
                      // ── Validation status banner ──
                      if (_submissionStatus != null) ...[
                        _NutritionValidationBanner(status: _submissionStatus!),
                        const SizedBox(height: 16),
                      ],

                      // ── Calories summary ──
                      _CaloriesSummaryCard(plan: _plan!),
                      const SizedBox(height: 16),

                      // ── Macros ring ──
                      _MacrosSummaryCard(plan: _plan!),
                      const SizedBox(height: 20),

                      // ── Meals ──
                      const Text('Repas du jour', style: AppTheme.headingMedium),
                      const SizedBox(height: 12),
                      ..._plan!.meals.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MealCard(meal: m),
                      )),
                      const SizedBox(height: 12),

                      // ── Submit to coach ──
                      if (_submissionStatus == null || _submissionStatus == 'REJECTED')
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _submitting ? null : _submitToCoach,
                            icon: _submitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                                : const Icon(Icons.send_outlined, size: 18),
                            label: Text(_submissionStatus == 'REJECTED'
                                ? 'Renvoyer au coach'
                                : 'Envoyer au coach pour validation'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ── Tips ──
                      _TipsCard(goal: _goal),
                      const SizedBox(height: 24),
                    ],
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

// ─── Profile Form ─────────────────────────────────────────────────────────────

class _ProfileForm extends StatelessWidget {
  final double height, weight;
  final int age;
  final String goal, activity;
  final Map<String, (String, String)> goals, activities;
  final ValueChanged<double> onHeightChanged, onWeightChanged;
  final ValueChanged<int>    onAgeChanged;
  final ValueChanged<String> onGoalChanged, onActivityChanged;
  final VoidCallback onGenerate;

  const _ProfileForm({
    required this.height, required this.weight, required this.age,
    required this.goal,   required this.activity,
    required this.goals,  required this.activities,
    required this.onHeightChanged, required this.onWeightChanged,
    required this.onAgeChanged,    required this.onGoalChanged,
    required this.onActivityChanged, required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.tune, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Text('Personnaliser mon plan', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 16),

          // Sliders
          _SliderRow(label: 'Taille', value: height, unit: 'cm', min: 140, max: 220, onChanged: onHeightChanged),
          _SliderRow(label: 'Poids',  value: weight, unit: 'kg', min: 40,  max: 200, onChanged: onWeightChanged),
          _SliderRow(label: 'Âge',    value: age.toDouble(), unit: 'ans', min: 10, max: 80, isInt: true, onChanged: (v) => onAgeChanged(v.toInt())),
          const SizedBox(height: 12),

          // Goal
          const Text('Objectif', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: goals.entries.map((e) {
            final sel = goal == e.key;
            return GestureDetector(
              onTap: () => onGoalChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.border, width: sel ? 1.5 : 0.5),
                ),
                child: Text('${e.value.$1} ${e.value.$2}', style: TextStyle(
                  color: sel ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                )),
              ),
            );
          }).toList()),
          const SizedBox(height: 12),

          // Activity
          const Text('Niveau d\'activité', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: activities.entries.map((e) {
            final sel = activity == e.key;
            return GestureDetector(
              onTap: () => onActivityChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppTheme.success : AppTheme.border, width: sel ? 1.5 : 0.5),
                ),
                child: Text('${e.value.$1} ${e.value.$2}', style: TextStyle(
                  color: sel ? AppTheme.success : AppTheme.textSecondary,
                  fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                )),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: const Text('Calculer mon plan'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final bool isInt;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label, required this.value,
    required this.unit,  required this.min, required this.max,
    required this.onChanged, this.isInt = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 45, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary, inactiveTrackColor: AppTheme.border,
            thumbColor: AppTheme.primary, overlayColor: AppTheme.primary.withValues(alpha: 0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7), trackHeight: 3,
          ),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).toInt(), onChanged: onChanged),
        ),
      ),
      SizedBox(
        width: 55,
        child: Text(
          isInt ? '${value.toInt()} $unit' : '${value.toStringAsFixed(0)} $unit',
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.right,
        ),
      ),
    ]),
  );
}

// ─── Calories Summary Card ────────────────────────────────────────────────────

class _CaloriesSummaryCard extends StatelessWidget {
  final NutritionPlan plan;
  const _CaloriesSummaryCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final pct = plan.targetCalories > 0
        ? (plan.totalCalories / plan.targetCalories).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.18), AppTheme.primary.withValues(alpha: 0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${plan.totalCalories.toInt()}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const Text(' / ', style: TextStyle(color: AppTheme.textMuted, fontSize: 20)),
              Text(
                '${plan.targetCalories.toInt()} kcal',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(children: [
            Container(height: 8, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(10))),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text('${(pct * 100).toInt()}% de l\'objectif journalier',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Macros Summary Card ──────────────────────────────────────────────────────

class _MacrosSummaryCard extends StatelessWidget {
  final NutritionPlan plan;
  const _MacrosSummaryCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final totalP = plan.meals.fold(0.0, (s, m) => s + m.macro.proteins);
    final totalC = plan.meals.fold(0.0, (s, m) => s + m.macro.carbs);
    final totalF = plan.meals.fold(0.0, (s, m) => s + m.macro.fats);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          const Row(children: [
            Icon(Icons.pie_chart_outline, color: AppTheme.primary, size: 16),
            SizedBox(width: 6),
            Text('Répartition des macros', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroCircle(label: 'Protéines', value: totalP, unit: 'g', color: AppTheme.error,   pct: totalP / (totalP + totalC + totalF)),
              _MacroCircle(label: 'Glucides',  value: totalC, unit: 'g', color: AppTheme.warning,  pct: totalC / (totalP + totalC + totalF)),
              _MacroCircle(label: 'Lipides',   value: totalF, unit: 'g', color: AppTheme.success,  pct: totalF / (totalP + totalC + totalF)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCircle extends StatelessWidget {
  final String label, unit;
  final double value, pct;
  final Color color;
  const _MacroCircle({required this.label, required this.value, required this.unit, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(
      width: 70, height: 70,
      child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: pct.clamp(0, 1), backgroundColor: AppTheme.border, color: color, strokeWidth: 6),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${value.toInt()}', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          Text(unit, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        ]),
      ]),
    ),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    Text('${(pct * 100).toInt()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  ]);
}

// ─── Meal Card ────────────────────────────────────────────────────────────────

class _MealCard extends StatefulWidget {
  final Meal meal;
  const _MealCard({required this.meal});

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  bool _expanded = false;

  IconData get _icon {
    switch (widget.meal.type.toUpperCase()) {
      case 'BREAKFAST': return Icons.free_breakfast_outlined;
      case 'LUNCH':     return Icons.lunch_dining_outlined;
      case 'DINNER':    return Icons.dinner_dining_outlined;
      default:          return Icons.apple_outlined;
    }
  }

  Color get _color {
    switch (widget.meal.type.toUpperCase()) {
      case 'BREAKFAST': return const Color(0xFFFFB74D);
      case 'LUNCH':     return AppTheme.success;
      case 'DINNER':    return AppTheme.info;
      default:          return AppTheme.primary;
    }
  }

  String get _time {
    switch (widget.meal.type.toUpperCase()) {
      case 'BREAKFAST': return '07:00 – 08:30';
      case 'LUNCH':     return '12:00 – 13:30';
      case 'DINNER':    return '19:00 – 20:30';
      default:          return '16:00 – 16:30';
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meal;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _expanded ? _color.withValues(alpha: 0.5) : AppTheme.border, width: 0.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_icon, color: _color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.typeLabel, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(m.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(_time, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    ],
                  )),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${m.calories.toInt()} kcal', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.textMuted, size: 18),
                  ]),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full meal text
                    Text(m.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                    const SizedBox(height: 12),
                    // Macros bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MacroChip(label: 'Protéines', value: '${m.macro.proteins.toInt()}g', color: AppTheme.error),
                        _MacroChip(label: 'Glucides',  value: '${m.macro.carbs.toInt()}g',    color: AppTheme.warning),
                        _MacroChip(label: 'Lipides',   value: '${m.macro.fats.toInt()}g',     color: AppTheme.success),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      Text(label,  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
    ]),
  );
}

// ─── Validation Banner ────────────────────────────────────────────────────────

class _NutritionValidationBanner extends StatelessWidget {
  final String status;
  const _NutritionValidationBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    switch (status) {
      case 'VALIDATED':
        color = AppTheme.success;
        icon  = Icons.check_circle;
        label = 'Plan nutritionnel validé par votre coach !';
        break;
      case 'REJECTED':
        color = AppTheme.error;
        icon  = Icons.cancel;
        label = 'Plan rejeté — modifiez-le et renvoyez-le.';
        break;
      default:
        color = AppTheme.warning;
        icon  = Icons.hourglass_empty;
        label = 'En attente de validation par votre coach...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ─── Tips Card ────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  final String goal;
  const _TipsCard({required this.goal});

  static const _tips = {
    'PERTE_DE_POIDS': [
      '💧 Bois 2.5L d\'eau par jour — l\'hydratation aide à contrôler la faim',
      '🕐 Mange lentement, attends 20min avant de reprendre',
      '🥗 Remplis la moitié de ton assiette de légumes',
      '🚫 Évite les sucres raffinés et les aliments ultra-transformés',
    ],
    'PRISE_DE_MUSCLE': [
      '🥩 Consomme 1.6-2.2g de protéines par kg de poids corporel',
      '⏰ Mange dans les 30-60min après l\'entraînement',
      '🍚 Les glucides sont tes alliés pour la récupération musculaire',
      '😴 Le muscle se construit pendant le sommeil — dors 8h minimum',
    ],
    'ENDURANCE': [
      '🍌 Mange des glucides complexes 2h avant l\'entraînement',
      '🧃 Hydrate-toi pendant l\'effort : 500ml/heure d\'activité',
      '🔋 Reconstitue tes réserves de glycogène après l\'effort',
      '🧂 Les électrolytes sont importants pour les efforts longs',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final tipsList = _tips[goal] ?? [
      '💧 Bois au moins 2L d\'eau par jour',
      '🥦 Mange 5 fruits et légumes quotidiennement',
      '⏰ Respecte des horaires de repas réguliers',
      '🍽️ Évite de manger devant un écran',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.tips_and_updates_outlined, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Text('Conseils nutritionnels', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          ...tipsList.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(tip, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
          )),
        ],
      ),
    );
  }
}
