import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    // Pick a coach first
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CoachPickerSheet(),
    );
    if (picked == null || !mounted) return;

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
        coachId:    picked['id'] as int?,
      );

      if (mounted) {
        setState(() { _submissionStatus = 'PENDING'; _submitting = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Plan envoyé à ${picked['name']} pour validation !'),
          backgroundColor: const Color(0xFF3B6D11),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(DioClient.errorMessage(e)),
          backgroundColor: const Color(0xFFA32D2D),
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
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mon Plan Nutrition',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFFE5A01A)),
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
                : RefreshIndicator(
              color: const Color(0xFFE5A01A),
              onRefresh: _loadFromBackendOrGenerate,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                      const SizedBox(height: 10),
                    ],

                    if (_plan != null) ...[
                      // ── Validation status banner ──
                      if (_submissionStatus != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _NutritionValidationBanner(status: _submissionStatus!),
                        ),
                      ],

                      // ── Calories summary ──
                      _CaloriesSummaryCard(plan: _plan!),
                      const SizedBox(height: 10),

                      // ── Macros ring ──
                      _MacrosSummaryCard(plan: _plan!),
                      const SizedBox(height: 16),

                      // ── Meals ──
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Text(
                          'Repas du jour',
                          style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: _plan!.meals.map((m) => _MealCard(meal: m)).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Submit to coach ──
                      if (_submissionStatus == null || _submissionStatus == 'REJECTED')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _submitting ? null : _submitToCoach,
                              icon: _submitting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))
                                  : const Icon(Icons.send_outlined, size: 18),
                              label: Text(_submissionStatus == 'REJECTED'
                                  ? 'Renvoyer au coach'
                                  : 'Envoyer au coach pour validation'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                foregroundColor: const Color(0xFFE5A01A),
                                side: const BorderSide(color: Color(0xFFE5A01A)),
                              ),
                            ),
                          ),
                        ),

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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personnaliser mon plan',
            style: TextStyle(color: Color(0xFFE5A01A), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),

          // Sliders
          _SliderRow(label: 'Taille', value: height, unit: 'cm', min: 140, max: 220, onChanged: onHeightChanged),
          _SliderRow(label: 'Poids',  value: weight, unit: 'kg', min: 40,  max: 200, onChanged: onWeightChanged),
          _SliderRow(label: 'Âge',    value: age.toDouble(), unit: 'ans', min: 10, max: 80, isInt: true, onChanged: (v) => onAgeChanged(v.toInt())),
          const SizedBox(height: 14),

          // Goal chips
          const Text('Objectif', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: goals.entries.map((e) {
            final active = goal == e.key;
            return GestureDetector(
              onTap: () => onGoalChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE5A01A) : const Color(0xFFF5F5F0),
                  border: Border.all(color: active ? const Color(0xFFE5A01A) : const Color(0xFFE8E8E8)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${e.value.$1} ${e.value.$2}',
                  style: TextStyle(
                    color: active ? const Color(0xFF1A1A1A) : const Color(0xFF888888),
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList()),

          const SizedBox(height: 14),

          // Activity chips
          const Text('Activité', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: activities.entries.map((e) {
            final active = activity == e.key;
            return GestureDetector(
              onTap: () => onActivityChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF3B6D11) : const Color(0xFFF5F5F0),
                  border: Border.all(color: active ? const Color(0xFF3B6D11) : const Color(0xFFE8E8E8)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${e.value.$1} ${e.value.$2}',
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF888888),
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList()),

          const SizedBox(height: 16),

          // Calculate button
          GestureDetector(
            onTap: onGenerate,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Calculer mon plan',
                style: TextStyle(color: Color(0xFFE5A01A), fontSize: 14, fontWeight: FontWeight.w600),
              ),
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
      SizedBox(width: 45, child: Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11))),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFE5A01A),
            inactiveTrackColor: const Color(0xFFE8E8E8),
            thumbColor: const Color(0xFFE5A01A),
            overlayColor: const Color(0xFFE5A01A).withValues(alpha: 0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            trackHeight: 3,
          ),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).toInt(), onChanged: onChanged),
        ),
      ),
      SizedBox(
        width: 55,
        child: Text(
          isInt ? '${value.toInt()} $unit' : '${value.toStringAsFixed(0)} $unit',
          style: const TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600, fontSize: 12),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.totalCalories}',
            style: const TextStyle(
              color: Color(0xFFE5A01A),
              fontSize: 36,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          const Text('kcal / jour', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE5A01A)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).toInt()}% de l\'objectif',
            style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
          ),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MacroCircle(
            label: 'Protéines',
            grams: totalP.toInt(),
            color: const Color(0xFFE24B4A),
            total: plan.totalCalories ~/ 4,
          ),
          _MacroCircle(
            label: 'Glucides',
            grams: totalC.toInt(),
            color: const Color(0xFFFFB74D),
            total: plan.totalCalories ~/ 4,
          ),
          _MacroCircle(
            label: 'Lipides',
            grams: totalF.toInt(),
            color: const Color(0xFF4CBA7D),
            total: plan.totalCalories ~/ 9,
          ),
        ],
      ),
    );
  }
}

class _MacroCircle extends StatelessWidget {
  final String label;
  final int grams, total;
  final Color color;

  const _MacroCircle({
    required this.label,
    required this.grams,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (grams / total).clamp(0.0, 1.0) : 0.0;
    return Column(children: [
      SizedBox(
        width: 60,
        height: 60,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: pct,
            strokeWidth: 5,
            backgroundColor: const Color(0xFFE8E8E8),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '${grams}g',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
    ]);
  }
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
      case 'LUNCH':     return const Color(0xFF4CBA7D);
      case 'DINNER':    return const Color(0xFF5B8CDB);
      default:          return const Color(0xFFE5A01A);
    }
  }

  String? get _time {
    switch (widget.meal.type.toUpperCase()) {
      case 'BREAKFAST': return '07:00 – 08:30';
      case 'LUNCH':     return '12:00 – 13:30';
      case 'DINNER':    return '19:00 – 20:30';
      case 'SNACK':     return '16:00 – 16:30';
      default:          return null;
    }
  }

  String get _type => widget.meal.type.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final m = widget.meal;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _type,
                        style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_time != null) ...[
                      const SizedBox(width: 6),
                      Text(_time!, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 10)),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    m.name,
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
              Text(
                '${m.calories.toInt()} kcal',
                style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFFBBBBBB),
                size: 18,
              ),
            ]),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                _MacroChip(label: '${m.macro.proteins.toInt()}g', sub: 'Prot.', color: const Color(0xFFE24B4A)),
                const SizedBox(width: 6),
                _MacroChip(label: '${m.macro.carbs.toInt()}g', sub: 'Gluc.', color: const Color(0xFFFFB74D)),
                const SizedBox(width: 6),
                _MacroChip(label: '${m.macro.fats.toInt()}g', sub: 'Lip.', color: const Color(0xFF4CBA7D)),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label, sub;
  final Color color;

  const _MacroChip({required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(children: [
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      Text(sub, style: const TextStyle(color: Color(0xFF888888), fontSize: 9)),
    ]),
  );
}

// ─── Validation Banner ────────────────────────────────────────────────────────

class _NutritionValidationBanner extends StatelessWidget {
  final String status;
  const _NutritionValidationBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color fgColor;
    final Color borderColor;
    final IconData icon;
    final String label;

    switch (status) {
      case 'VALIDATED':
        bgColor     = const Color(0xFFEAF3DE);
        fgColor     = const Color(0xFF3B6D11);
        borderColor = const Color(0xFF3B6D11);
        icon        = Icons.check_circle;
        label       = 'Plan nutritionnel validé par votre coach !';
        break;
      case 'REJECTED':
        bgColor     = const Color(0xFFFCEBEB);
        fgColor     = const Color(0xFFA32D2D);
        borderColor = const Color(0xFFA32D2D);
        icon        = Icons.cancel;
        label       = 'Plan rejeté — modifiez-le et renvoyez-le.';
        break;
      default:
        bgColor     = const Color(0xFFFAEEDA);
        fgColor     = const Color(0xFF854F0B);
        borderColor = const Color(0xFF854F0B);
        icon        = Icons.hourglass_empty;
        label       = 'En attente de validation par votre coach...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: fgColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: fgColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conseils',
            style: TextStyle(color: Color(0xFFE5A01A), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...tipsList.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(tip, style: const TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.4)),
          )),
        ],
      ),
    );
  }
}

// ─── Coach Picker Sheet ───────────────────────────────────────────────────────

class _CoachPickerSheet extends StatefulWidget {
  const _CoachPickerSheet();
  @override
  State<_CoachPickerSheet> createState() => _CoachPickerSheetState();
}

class _CoachPickerSheetState extends State<_CoachPickerSheet> {
  List<Map<String, dynamic>> _coaches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await DioClient.instance.dio.get('/coaches', queryParameters: {'size': 50});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _coaches = (list as List).map((c) => {
          'id':   (c['id'] ?? 0) as int,
          'name': '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim(),
          'spec': c['specialization']?.toString() ?? '',
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Icon(Icons.person_search, color: Color(0xFFE5A01A), size: 20),
              SizedBox(width: 10),
              Text('Choisir un coach', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Sélectionne le coach qui validera ton plan nutritionnel',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFFE5A01A)),
            )
          else if (_coaches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucun coach disponible', style: TextStyle(color: Color(0xFF888888))),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _coaches.length,
                itemBuilder: (_, i) {
                  final c = _coaches[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE5A01A).withValues(alpha: 0.15),
                      child: Text(
                        (c['name'] as String).isNotEmpty ? (c['name'] as String)[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(c['name'] as String,
                        style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
                    subtitle: (c['spec'] as String).isNotEmpty
                        ? Text(c['spec'] as String, style: const TextStyle(color: Color(0xFF888888), fontSize: 11))
                        : null,
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
