import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/validation_store.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../../shared/widgets/workout_rest_timer.dart';
import '../../../../shared/widgets/dark_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../models/ai_training_request.dart';
import '../models/training_program.dart';
import '../providers/training_provider.dart';
import '../services/ai_training_service.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  bool _initiated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initiated) {
      _initiated = true;
      _loadIfNeeded();
    }
  }

  // On first open: try the offline-aware repository (cache if offline, API if online)
  Future<void> _loadIfNeeded() async {
    final tp = context.read<TrainingProvider>();
    if (tp.active != null || tp.loading) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    try {
      final res =
          await DioClient.instance.dio.get('/members/user/${user.id}');
      final memberId = (res.data['id'] ?? user.id).toInt();
      await tp.loadForMember(memberId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrainingProvider>();

    if (tp.loading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (tp.active != null) {
      return _ActiveWorkoutScreen(tp: tp);
    }

    // No program → show AI generator
    return const _AiGeneratorScreen();
  }
}

// ─── AI Generator Screen ─────────────────────────────────────────────────────

class _AiGeneratorScreen extends StatefulWidget {
  const _AiGeneratorScreen();

  @override
  State<_AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends State<_AiGeneratorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _service = AiTrainingService();

  // Form fields
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');
  final _ageCtrl    = TextEditingController(text: '25');
  final _injuryCtrl = TextEditingController();

  String _goal      = 'FORME_GENERALE';
  String _level     = 'DEBUTANT';
  String _equipment = 'SALLE';
  int _sessions     = 3;

  bool    _generating = false;
  String? _error;

  static const _goals = [
    _Option('PERTE_DE_POIDS',  '🔥 Perte de poids',          AppTheme.error),
    _Option('PRISE_DE_MUSCLE', '💪 Prise de muscle',          AppTheme.primary),
    _Option('ENDURANCE',       '🏃 Endurance',                AppTheme.info),
    _Option('FORME_GENERALE',  '⚡ Forme générale',           AppTheme.success),
  ];

  static const _levels = [
    _Option('DEBUTANT',      '🌱 Débutant',      AppTheme.success),
    _Option('INTERMEDIAIRE', '🔥 Intermédiaire', AppTheme.primary),
    _Option('AVANCE',        '⚡ Avancé',         AppTheme.error),
  ];

  static const _equipments = [
    _Option('SALLE',            '🏋️ Salle complète',  AppTheme.primary),
    _Option('MAISON',           '🏠 À domicile',       AppTheme.success),
    _Option('SANS_EQUIPEMENT',  '🤸 Poids du corps',  AppTheme.info),
  ];

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    _injuryCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _generating = true; _error = null; });

    final req = AiTrainingRequest(
      height:          double.parse(_heightCtrl.text),
      weight:          double.parse(_weightCtrl.text),
      age:             int.parse(_ageCtrl.text),
      goal:            _goal,
      level:           _level,
      equipment:       _equipment,
      sessionsPerWeek: _sessions,
      injuries:        _injuryCtrl.text.trim().isEmpty ? null : _injuryCtrl.text.trim(),
    );

    try {
      final program = await _service.generateProgram(req);
      if (!mounted) return;
      // Push to provider and navigate to workout
      context.read<TrainingProvider>().selectProgram(program);
    } catch (e) {
      setState(() {
        _error = 'Erreur IA : ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Programme IA'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.auto_awesome, color: AppTheme.primary, size: 14),
              SizedBox(width: 4),
              Text('IA', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.primary.withValues(alpha: 0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology, color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coach IA personnalisé', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Remplis ton profil et obtiens un programme 100% adapté à toi.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Error banner ──
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // ── Section 1 : Mensurations ──
              _SectionHeader(icon: Icons.straighten, title: 'Mensurations'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _NumField(ctrl: _heightCtrl, label: 'Taille (cm)', min: 100, max: 250)),
                const SizedBox(width: 12),
                Expanded(child: _NumField(ctrl: _weightCtrl, label: 'Poids (kg)',  min: 30,  max: 300)),
                const SizedBox(width: 12),
                Expanded(child: _NumField(ctrl: _ageCtrl,    label: 'Âge (ans)',   min: 10,  max: 99, isInt: true)),
              ]),

              // ── IMC preview ──
              if (_heightCtrl.text.isNotEmpty && _weightCtrl.text.isNotEmpty)
                _BmiPreview(
                  height: double.tryParse(_heightCtrl.text) ?? 170,
                  weight: double.tryParse(_weightCtrl.text) ?? 70,
                ),
              const SizedBox(height: 24),

              // ── Section 2 : Objectif ──
              _SectionHeader(icon: Icons.track_changes, title: 'Objectif'),
              const SizedBox(height: 12),
              _OptionGrid(
                options:  _goals,
                selected: _goal,
                onSelect: (v) => setState(() => _goal = v),
              ),
              const SizedBox(height: 24),

              // ── Section 3 : Niveau ──
              _SectionHeader(icon: Icons.bar_chart, title: 'Niveau'),
              const SizedBox(height: 12),
              Row(children: _levels.map((o) => Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _OptionPill(
                  option: o,
                  selected: _level == o.value,
                  onTap: () => setState(() => _level = o.value),
                ),
              ))).toList()),
              const SizedBox(height: 24),

              // ── Section 4 : Équipement ──
              _SectionHeader(icon: Icons.fitness_center, title: 'Équipement disponible'),
              const SizedBox(height: 12),
              _OptionGrid(
                options:  _equipments,
                selected: _equipment,
                onSelect: (v) => setState(() => _equipment = v),
                columns:  3,
              ),
              const SizedBox(height: 24),

              // ── Section 5 : Séances/semaine ──
              _SectionHeader(icon: Icons.calendar_today, title: 'Séances par semaine'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_sessions séance${_sessions > 1 ? 's' : ''}',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                  Row(children: [
                    _CircleBtn(icon: Icons.remove, onTap: () { if (_sessions > 1) setState(() => _sessions--); }),
                    const SizedBox(width: 12),
                    _CircleBtn(icon: Icons.add,    onTap: () { if (_sessions < 7) setState(() => _sessions++); }),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor:   AppTheme.primary,
                  inactiveTrackColor: AppTheme.border,
                  thumbColor:         AppTheme.primary,
                  overlayColor:       AppTheme.primary.withValues(alpha: 0.1),
                  thumbShape:         const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight:        4,
                ),
                child: Slider(
                  value: _sessions.toDouble(),
                  min: 1, max: 7, divisions: 6,
                  onChanged: (v) => setState(() => _sessions = v.toInt()),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section 6 : Blessures (optionnel) ──
              _SectionHeader(icon: Icons.healing_outlined, title: 'Blessures / restrictions (optionnel)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _injuryCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ex: douleur genou droit, hernie discale...',
                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),

              // ── Generate button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generating ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _generating
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)),
                          SizedBox(width: 12),
                          Text('L\'IA génère ton programme...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ])
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 10),
                          Text('Générer mon programme IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Active Workout Screen ────────────────────────────────────────────────────

class _ActiveWorkoutScreen extends StatefulWidget {
  final TrainingProvider tp;
  const _ActiveWorkoutScreen({required this.tp});

  @override
  State<_ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<_ActiveWorkoutScreen> {
  bool _submitting = false;
  String? _submissionStatus; // 'PENDING' | 'VALIDATED' | 'REJECTED' | null
  late final DateTime _sessionStartTime;

  TrainingProvider get tp => widget.tp;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _checkSubmissionStatus();
  }

  Future<void> _checkSubmissionStatus() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    try {
      final res = await DioClient.instance.dio.get('/members/user/${user.id}');
      final memberId = (res.data['id'] ?? 0).toInt();
      final entry = await ValidationStore.getLatestTrainingForMember(memberId);
      if (mounted && entry != null) {
        setState(() => _submissionStatus = entry['status'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _submitToCoach() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || tp.active == null) return;

    setState(() => _submitting = true);
    try {
      int memberId = 0;
      try {
        final res = await DioClient.instance.dio.get('/members/user/${user.id}');
        memberId = (res.data['id'] ?? 0).toInt();
      } catch (_) {
        memberId = user.id;
      }

      final prefs = await SharedPreferences.getInstance();
      final coachId = prefs.getInt('gym_selected_coach_id');

      await ValidationStore.submitTraining(
        memberId:   memberId,
        memberName: user.fullName,
        program:    tp.active!.toJson(),
        coachId:    coachId,
      );

      if (mounted) {
        setState(() => _submissionStatus = 'PENDING');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Programme envoyé au coach pour validation !'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(DioClient.errorMessage(e)),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = tp.active!;
    final current = tp.currentExercise;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(program.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology, color: AppTheme.primary),
            tooltip: 'Nouveau programme IA',
            onPressed: () => _confirmReset(context),
          ),
          if (tp.programs.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _showProgramPicker(context, tp),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OfflineBanner(),

            // ── Validation status banner ──
            if (_submissionStatus != null) ...[
              _ValidationBanner(status: _submissionStatus!),
              const SizedBox(height: 16),
            ],

            // ── Progress ──
            _ProgressHeader(program: program, currentIndex: tp.currentIndex),
            const SizedBox(height: 20),


            // ── Exercises ──
            const Text('Exercices', style: AppTheme.headingMedium),
            const SizedBox(height: 12),
            ...program.exercises.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExerciseCard(
                exercise: e.value,
                index: e.key,
                isCurrent: e.key == tp.currentIndex && !tp.restActive,
              ),
            )),
            const SizedBox(height: 20),

            // ── Coach note / AI advice ──
            if (program.coachNote != null && program.coachNote!.isNotEmpty) ...[
              DarkCard(
                header: const Row(children: [
                  Icon(Icons.psychology, color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Conseil de l\'IA', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
                children: [
                  Text(program.coachNote!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ── Submit to coach ──
            if (_submissionStatus == null || _submissionStatus == 'REJECTED') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : _submitToCoach,
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
              const SizedBox(height: 12),
            ],

            // ── Workout action button ──
            if (!tp.restActive && current != null && !current.done)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onExerciseDone,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(tp.isLastExercise ? 'Terminer la séance 🏆' : 'Série terminée → Repos'),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _onExerciseDone() {
    final isLast    = tp.isLastExercise;
    final restSecs  = tp.currentExercise?.restSeconds ?? 60;
    final nextIdx   = tp.currentIndex + 1;
    final nextName  = (!isLast && nextIdx < (tp.active?.exercises.length ?? 0))
        ? tp.active!.exercises[nextIdx].name
        : null;

    tp.markCurrentDone();

    if (isLast) {
      _showCompletionSheet();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => WorkoutRestTimer(
        restSeconds: restSecs,
        nextExerciseName: nextName,
        onComplete: () {
          tp.onRestFinished();
          Navigator.of(sheetCtx).pop();
        },
        onSkip: () {
          tp.onRestFinished();
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }

  void _showCompletionSheet() {
    final duration            = DateTime.now().difference(_sessionStartTime);
    final exercisesCompleted  = tp.active?.exercises.where((e) => e.done).length ?? 0;
    final totalExercises      = tp.active?.exercises.length ?? 0;
    final calories            = (duration.inMinutes.clamp(1, 999) * 8).round();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CompletionSheet(
        duration: duration,
        exercisesCompleted: exercisesCompleted,
        totalExercises: totalExercises,
        calories: calories,
        onNewProgram: () {
          Navigator.of(context).pop();
          tp.resetActive();
        },
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Nouveau programme', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Générer un nouveau programme IA ? La séance en cours sera perdue.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TrainingProvider>().resetActive();
            },
            child: const Text('Continuer', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showProgramPicker(BuildContext context, TrainingProvider tp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Choisir un programme', style: AppTheme.headingMedium)),
          const Divider(height: 1),
          ...tp.programs.map((p) => ListTile(
            title: Text(p.name, style: const TextStyle(color: AppTheme.textPrimary)),
            subtitle: Text('${p.exercises.length} exercices', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            trailing: tp.active?.id == p.id ? const Icon(Icons.check, color: AppTheme.primary) : null,
            onTap: () { tp.selectProgram(p); Navigator.pop(context); },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

}

// ─── Validation status banner ─────────────────────────────────────────────────

class _ValidationBanner extends StatelessWidget {
  final String status;
  const _ValidationBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    switch (status) {
      case 'VALIDATED':
        color = AppTheme.success; icon = Icons.check_circle; label = 'Programme validé par votre coach !';
        break;
      case 'REJECTED':
        color = AppTheme.error; icon = Icons.cancel; label = 'Programme rejeté — vous pouvez le renvoyer après modification.';
        break;
      default:
        color = AppTheme.warning; icon = Icons.hourglass_empty; label = 'En attente de validation par votre coach...';
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
        Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ─── Shared Sub-widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
      child: Icon(icon, color: AppTheme.primary, size: 16),
    ),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
  ]);
}

class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final double min, max;
  final bool isInt;
  const _NumField({required this.ctrl, required this.label, required this.min, required this.max, this.isInt = false});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
    textAlign: TextAlign.center,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    ),
    validator: (v) {
      final n = double.tryParse(v ?? '');
      if (n == null) return 'Invalide';
      if (n < min || n > max) return '${min.toInt()}-${max.toInt()}';
      return null;
    },
  );
}

class _BmiPreview extends StatelessWidget {
  final double height, weight;
  const _BmiPreview({required this.height, required this.weight});

  @override
  Widget build(BuildContext context) {
    if (height <= 0 || weight <= 0) return const SizedBox.shrink();
    final bmi = weight / ((height / 100) * (height / 100));
    final color = bmi < 18.5 ? AppTheme.info : (bmi < 25 ? AppTheme.success : (bmi < 30 ? AppTheme.warning : AppTheme.error));
    final label = bmi < 18.5 ? 'Insuffisance pondérale' : (bmi < 25 ? 'Poids normal ✓' : (bmi < 30 ? 'Surpoids' : 'Obésité'));

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Text('IMC : ${bmi.toStringAsFixed(1)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 8),
        Text('— $label', style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
      ]),
    );
  }
}

class _Option {
  final String value, label;
  final Color color;
  const _Option(this.value, this.label, this.color);
}

class _OptionGrid extends StatelessWidget {
  final List<_Option> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final int columns;
  const _OptionGrid({required this.options, required this.selected, required this.onSelect, this.columns = 2});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += columns) {
      rows.add(Row(children: [
        for (var j = i; j < i + columns && j < options.length; j++) ...[
          if (j > i) const SizedBox(width: 10),
          Expanded(child: _OptionPill(option: options[j], selected: selected == options[j].value, onTap: () => onSelect(options[j].value))),
        ],
      ]));
      if (i + columns < options.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }
}

class _OptionPill extends StatelessWidget {
  final _Option option;
  final bool selected;
  final VoidCallback onTap;
  const _OptionPill({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? option.color.withValues(alpha: 0.15) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? option.color : AppTheme.border, width: selected ? 1.5 : 0.5),
      ),
      child: Center(
        child: Text(option.label, style: TextStyle(
          color: selected ? option.color : AppTheme.textSecondary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ), textAlign: TextAlign.center),
      ),
    ),
  );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(icon, color: AppTheme.textPrimary, size: 18),
    ),
  );
}

class _ProgressHeader extends StatelessWidget {
  final TrainingProgram program;
  final int currentIndex;
  const _ProgressHeader({required this.program, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final done  = program.exercises.where((e) => e.done).length;
    final total = program.exercises.length;
    final pct   = total > 0 ? done / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$done / $total exercices', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text('${(pct * 100).toInt()}%', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, backgroundColor: AppTheme.border, color: AppTheme.primary, minHeight: 6),
        ),
      ]),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int index;
  final bool isCurrent;
  const _ExerciseCard({required this.exercise, required this.index, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrent
        ? AppTheme.primary
        : exercise.done ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.primary.withValues(alpha: 0.07) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 0.5),
      ),
      child: Row(children: [
        // Number / check
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: exercise.done
                ? AppTheme.success.withValues(alpha: 0.15)
                : isCurrent ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.border.withValues(alpha: 0.4),
          ),
          child: Center(
            child: exercise.done
                ? const Icon(Icons.check, color: AppTheme.success, size: 16)
                : Text('${index + 1}', style: TextStyle(
                    color: isCurrent ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            exercise.name,
            style: TextStyle(
              color: exercise.done ? AppTheme.textMuted : AppTheme.textPrimary,
              fontWeight: FontWeight.w600, fontSize: 14,
              decoration: exercise.done ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${exercise.sets} séries × ${exercise.reps} reps'
            '${exercise.weight != null && exercise.weight! > 0 ? " · ${exercise.weight} kg" : " · Poids du corps"}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          if (exercise.restSeconds != null)
            Text('Repos : ${exercise.restSeconds}s', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ])),
        if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('En cours', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}

// ─── Completion Sheet ─────────────────────────────────────────────────────────

class _CompletionSheet extends StatelessWidget {
  final Duration duration;
  final int exercisesCompleted;
  final int totalExercises;
  final int calories;
  final VoidCallback onNewProgram;

  const _CompletionSheet({
    required this.duration,
    required this.exercisesCompleted,
    required this.totalExercises,
    required this.calories,
    required this.onNewProgram,
  });

  String get _durationStr {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    if (m > 0) return '${m}min ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 28),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Séance terminée !',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Excellent travail, continue comme ça !',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBubble(label: 'Durée',     value: _durationStr,                         icon: Icons.timer_outlined),
                _StatBubble(label: 'Exercices', value: '$exercisesCompleted/$totalExercises', icon: Icons.fitness_center),
                _StatBubble(label: 'Calories',  value: '~$calories kcal',                    icon: Icons.local_fire_department_outlined),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNewProgram,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Nouveau programme',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBubble({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ],
  );
}
