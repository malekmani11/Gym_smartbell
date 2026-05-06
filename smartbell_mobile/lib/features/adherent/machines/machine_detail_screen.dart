import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import 'machine_model.dart';

class MachineDetailScreen extends StatelessWidget {
  final Machine machine;
  const MachineDetailScreen({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Détail machine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MachineHeader(machine: machine),
            const SizedBox(height: 20),

            _InfoSection(machine: machine),
            const SizedBox(height: 20),

            if (machine.exercises.isNotEmpty) ...[
              _ExercisesSection(exercises: machine.exercises),
              const SizedBox(height: 20),
            ],

            // Tutorial
            if (machine.tutorialUrl != null && machine.tutorialUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openTutorial(context),
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: const Text('Voir le tutoriel'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // Report problem
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReportDialog(context),
                icon: const Icon(Icons.report_problem_outlined, size: 18),
                label: const Text('Signaler un problème'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Scan another
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scanner une autre machine'),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _openTutorial(BuildContext context) async {
    final uri = Uri.tryParse(machine.tutorialUrl ?? '');
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible d\'ouvrir le tutoriel'),
          backgroundColor: AppTheme.error,
        ));
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ReportDialog(machine: machine),
    );
  }
}

// ─── Machine Header ───────────────────────────────────────────────────────────

class _MachineHeader extends StatelessWidget {
  final Machine machine;
  const _MachineHeader({required this.machine});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.14),
            AppTheme.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fitness_center,
                color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusBadge(status: machine.status),
                if (machine.location != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.place_outlined,
                        color: AppTheme.textMuted, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      machine.location!,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'AVAILABLE'       => ('Disponible', AppTheme.success),
      'MAINTENANCE'     => ('En maintenance', AppTheme.warning),
      'OUT_OF_SERVICE'  => ('Hors service', AppTheme.error),
      _                 => ('Inconnu', AppTheme.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

// ─── Info Section ─────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final Machine machine;
  const _InfoSection({required this.machine});

  @override
  Widget build(BuildContext context) {
    if (machine.description == null && machine.location == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('INFORMATIONS', style: AppTheme.sectionTitle),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (machine.location != null)
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Localisation',
                  value: machine.location!,
                ),
              if (machine.location != null && machine.description != null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: AppTheme.border, height: 1),
                ),
              if (machine.description != null)
                _InfoRow(
                  icon: Icons.info_outline,
                  label: 'Description',
                  value: machine.description!,
                  multiline: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 10)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Exercises Section ────────────────────────────────────────────────────────

class _ExercisesSection extends StatelessWidget {
  final List<MachineExercise> exercises;
  const _ExercisesSection({required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('EXERCICES ASSOCIÉS', style: AppTheme.sectionTitle),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${exercises.length}',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...exercises.map((ex) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ExerciseRow(exercise: ex),
            )),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final MachineExercise exercise;
  const _ExerciseRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center,
                color: AppTheme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (exercise.muscleGroup != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    exercise.muscleGroup!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (exercise.difficultyLevel != null)
            _DiffBadge(level: exercise.difficultyLevel!),
        ],
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  final String level;
  const _DiffBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level.toUpperCase()) {
      'DEBUTANT'       => ('Débutant', AppTheme.success),
      'INTERMEDIAIRE'  => ('Interméd.', AppTheme.warning),
      'AVANCE'         => ('Avancé', AppTheme.error),
      _                => (level, AppTheme.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Report Dialog ────────────────────────────────────────────────────────────

class _ReportDialog extends StatefulWidget {
  final Machine machine;
  const _ReportDialog({required this.machine});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _ctrl    = TextEditingController();
  bool _sending  = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _ctrl.text.trim();
    if (desc.isEmpty) return;

    setState(() => _sending = true);
    try {
      await DioClient.instance.dio.post('/complaints', data: {
        'subject':     'Problème machine: ${widget.machine.name}',
        'description': desc,
        'machineId':   widget.machine.id,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Signalement envoyé, merci !'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(DioClient.errorMessage(e)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.report_problem_outlined, color: AppTheme.error, size: 20),
        SizedBox(width: 8),
        Text('Signaler un problème',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.machine.name,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            autofocus: true,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Décrivez le problème rencontré...',
              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _sending ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }
}
