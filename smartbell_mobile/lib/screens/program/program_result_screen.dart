import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/adherent/training/models/training_program.dart';
import '../../features/adherent/training/providers/training_provider.dart';
import '../../models/program_generation_response.dart';

const _bg   = Color(0xFF111111);
const _card = Color(0xFF1E1E1E);
const _gold = Color(0xFFEF9F27);
const _green= Color(0xFF1D9E75);

class ProgramResultScreen extends StatelessWidget {
  final ProgramGenerationResponse result;
  const ProgramResultScreen({super.key, required this.result});

  // Labels lisibles
  static const _typeLabels = {
    'musculation'    : 'Musculation',
    'cardio_dominant': 'Cardio dominant',
    'mixte'          : 'Programme mixte',
    'HIIT'           : 'HIIT',
  };
  static const _splitLabels = {
    'full_body' : 'Full Body',
    'push_pull' : 'Push / Pull',
    'ppl'       : 'PPL',
    'haut_bas'  : 'Haut / Bas',
  };

  String _typeLabel(String v) => _typeLabels[v] ?? v;
  String _splitLabel(String v) => _splitLabels[v] ?? v;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        // Header
        Container(
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.canPop(context) ? Navigator.pop(context) : null,
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ton programme personnalisé',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('Généré par Intelligence Artificielle',
                        style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _gold.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: _gold, size: 20),
                ),
              ]),
            ),
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Badge succès ──────────────────────────────────────────────
              Center(
                child: Column(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: _green.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Icon(Icons.check, color: _green, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text('Programme généré avec succès !',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 28),

              // ── Card principale ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _gold.withValues(alpha: 0.25), width: 1),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('TYPE DE PROGRAMME',
                      style: TextStyle(color: Color(0xFF666666), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Text(
                    _typeLabel(result.typeProgramme),
                    style: const TextStyle(color: _gold, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF2A2A2A)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _Badge(label: 'Intensité', value: '${result.intensite} / 5', color: _green, icon: Icons.bolt),
                    const SizedBox(width: 10),
                    _Badge(label: 'Split', value: _splitLabel(result.split), color: const Color(0xFF9F97EC), icon: Icons.grid_view),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF2A2A2A)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _Badge(label: 'IMC', value: result.imc.toStringAsFixed(1), color: const Color(0xFF5BC4BF), icon: Icons.monitor_weight_outlined),
                    const SizedBox(width: 10),
                    _Badge(label: 'Catégorie', value: result.imcCategorie, color: const Color(0xFFEC9797), icon: Icons.category_outlined),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Conseils coach ────────────────────────────────────────────
              if (result.noteCoach.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold.withValues(alpha: 0.2)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.auto_awesome, color: _gold, size: 16),
                      SizedBox(width: 8),
                      Text('Conseils du coach IA',
                          style: TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 12),
                    Text(result.noteCoach,
                        style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.6)),
                  ]),
                ),
              const SizedBox(height: 16),

              // ── Séances ───────────────────────────────────────────────────
              if (result.seances.isNotEmpty) ...[
                const Text('SÉANCES GÉNÉRÉES',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                ...result.seances.asMap().entries.map((entry) {
                  final i      = entry.key;
                  final seance = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(seance.nom,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${seance.exercices.length} exercices',
                              style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF444444), size: 18),
                    ]),
                  );
                }),
              ],
              const SizedBox(height: 24),

              // ── Bouton principal ──────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  if (result.seances.isEmpty) return;
                  final firstSeance = result.seances.first;
                  final program = TrainingProgram(
                    id         : DateTime.now().millisecondsSinceEpoch,
                    name       : firstSeance.nom,
                    description: 'Programme généré par IA SmartBell',
                    coachNote  : result.noteCoach.isNotEmpty ? result.noteCoach : null,
                    exercises  : firstSeance.exercices,
                  );
                  context.read<TrainingProvider>().selectProgram(program);
                  context.go('/member/training');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: result.seances.isEmpty ? _gold.withValues(alpha: 0.4) : _gold,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.fitness_center, color: Colors.black, size: 18),
                    SizedBox(width: 8),
                    Text('Commencer la séance 1',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              // ── Bouton régénérer ──────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.refresh, color: _gold, size: 18),
                    SizedBox(width: 8),
                    Text('Régénérer', style: TextStyle(color: _gold, fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Widgets helpers ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _Badge({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 9, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ])),
      ]),
    ),
  );
}
