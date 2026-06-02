import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/program_generation_response.dart';
import '../../services/program_service.dart';
import 'program_result_screen.dart';

// ── Constantes de design ─────────────────────────────────────────────────────
const _bg    = Color(0xFF111111);
const _card  = Color(0xFF1E1E1E);
const _gold  = Color(0xFFEF9F27);
const _green = Color(0xFF1D9E75);
const _border= Color(0xFF2A2A2A);

class ProgramFormScreen extends StatefulWidget {
  const ProgramFormScreen({super.key});
  @override
  State<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends State<ProgramFormScreen> {
  int _step = 0;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl    = TextEditingController();
  String? _goal;
  String? _level;
  String? _sexe;
  int     _seances = 4;
  bool    _loading = false;
  String? _error;

  final _service = ProgramService();

  // Futures annulables
  Future<ProgramGenerationResponse>? _generateFuture;
  bool _cancelled = false;

  @override
  void dispose() {
    _cancelled = true;
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  // ── Validation étape 1 ──────────────────────────────────────────────────────
  String? _validateHeight(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null) return 'Nombre invalide';
    if (n < 100 || n > 250) return 'Taille entre 100 et 250 cm';
    return null;
  }

  String? _validateWeight(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null) return 'Nombre invalide';
    if (n < 30 || n > 200) return 'Poids entre 30 et 200 kg';
    return null;
  }

  String? _validateAge(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Nombre invalide';
    if (n < 10 || n > 100) return 'Âge entre 10 et 100 ans';
    return null;
  }

  bool get _step1Valid =>
      _validateHeight(_heightCtrl.text) == null &&
      _validateWeight(_weightCtrl.text) == null &&
      _validateAge(_ageCtrl.text) == null;

  bool get _step2Valid => _goal != null && _level != null && _sexe != null;

  // ── Génération ──────────────────────────────────────────────────────────────
  Future<void> _generate() async {
    if (!_step1Valid || !_step2Valid) return;
    setState(() { _loading = true; _error = null; });

    final memberId = context.read<AuthProvider>().user?.id ?? 0;
    final taille   = double.parse(_heightCtrl.text.trim().replaceAll(',', '.'));
    final poids    = double.parse(_weightCtrl.text.trim().replaceAll(',', '.'));
    final age      = int.parse(_ageCtrl.text.trim());

    _generateFuture = _service.generateProgram(
      memberId: memberId,
      poids   : poids,
      taille  : taille,
      age     : age,
      sexe    : _sexe!,
      objectif: _goal!,
      niveau  : _level!,
      seances : _seances,
    );

    try {
      final result = await _generateFuture!;
      if (_cancelled || !mounted) return;
      setState(() => _loading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProgramResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (_cancelled || !mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

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
                    Text('Programme IA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Génération personnalisée', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: _gold, size: 18),
                ),
              ]),
            ),
          ),
        ),

        // Stepper
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(primary: _gold),
            ),
            child: Stepper(
              currentStep: _step,
              type: StepperType.vertical,
              physics: const ClampingScrollPhysics(),
              onStepTapped: (i) {
                if (i < _step || (i == 1 && _step1Valid)) {
                  setState(() => _step = i);
                }
              },
              onStepContinue: () {
                if (_step == 0 && _step1Valid) setState(() => _step = 1);
              },
              onStepCancel: () {
                if (_step > 0) setState(() => _step--);
              },
              controlsBuilder: (context, details) => _buildControls(details),
              steps: [
                _buildStep1(),
                _buildStep2(),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Étape 1 — Profil physique ──────────────────────────────────────────────

  Step _buildStep1() => Step(
    title: const Text('Profil physique', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    subtitle: const Text('Taille, poids et âge', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
    isActive: _step >= 0,
    state: _step > 0 ? StepState.complete : StepState.indexed,
    content: Column(children: [
      _NumberField(
        controller: _heightCtrl,
        label: 'Taille (cm)',
        hint: 'Ex : 175',
        icon: Icons.height,
        validate: _validateHeight,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      _NumberField(
        controller: _weightCtrl,
        label: 'Poids (kg)',
        hint: 'Ex : 75',
        icon: Icons.monitor_weight_outlined,
        validate: _validateWeight,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      _NumberField(
        controller: _ageCtrl,
        label: 'Âge (ans)',
        hint: 'Ex : 25',
        icon: Icons.cake_outlined,
        validate: _validateAge,
        onChanged: (_) => setState(() {}),
        isInteger: true,
      ),
      const SizedBox(height: 8),
    ]),
  );

  // ── Étape 2 — Objectif & niveau ───────────────────────────────────────────

  Step _buildStep2() => Step(
    title: const Text('Objectif & niveau', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    subtitle: const Text('Personnalisez votre programme', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
    isActive: _step >= 1,
    state: _step > 1 ? StepState.complete : StepState.indexed,
    content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('SEXE', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _SelectCard(label: 'Homme', icon: Icons.male, value: 'homme', selected: _sexe, onTap: (v) => setState(() => _sexe = v))),
        const SizedBox(width: 8),
        Expanded(child: _SelectCard(label: 'Femme', icon: Icons.female, value: 'femme', selected: _sexe, onTap: (v) => setState(() => _sexe = v))),
      ]),
      const SizedBox(height: 20),
      const Text('OBJECTIF', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _SelectCard(label: 'Perte de poids', icon: Icons.local_fire_department, value: 'perte_poids', selected: _goal, onTap: (v) => setState(() => _goal = v))),
        const SizedBox(width: 8),
        Expanded(child: _SelectCard(label: 'Prise de masse', icon: Icons.fitness_center, value: 'prise_masse', selected: _goal, onTap: (v) => setState(() => _goal = v))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _SelectCard(label: 'Endurance', icon: Icons.directions_run, value: 'endurance', selected: _goal, onTap: (v) => setState(() => _goal = v))),
        const SizedBox(width: 8),
        Expanded(child: _SelectCard(label: 'Tonification', icon: Icons.self_improvement, value: 'tonification', selected: _goal, onTap: (v) => setState(() => _goal = v))),
      ]),
      const SizedBox(height: 20),
      const Text('NIVEAU', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _SelectCard(label: 'Débutant', icon: Icons.emoji_people, value: 'debutant', selected: _level, onTap: (v) => setState(() => _level = v))),
        const SizedBox(width: 8),
        Expanded(child: _SelectCard(label: 'Intermédiaire', icon: Icons.trending_up, value: 'intermediaire', selected: _level, onTap: (v) => setState(() => _level = v))),
        const SizedBox(width: 8),
        Expanded(child: _SelectCard(label: 'Avancé', icon: Icons.military_tech, value: 'avance', selected: _level, onTap: (v) => setState(() => _level = v))),
      ]),
      const SizedBox(height: 20),
      const Text('SÉANCES / SEMAINE', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final val = i + 1;
          final selected = _seances == val;
          return GestureDetector(
            onTap: () => setState(() => _seances = val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: selected ? _gold : _card,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? _gold : _border),
              ),
              child: Center(
                child: Text('$val', style: TextStyle(
                  color: selected ? Colors.black : const Color(0xFF888888),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                )),
              ),
            ),
          );
        }),
      ),

      const SizedBox(height: 24),

      // Erreur
      if (_error != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
          ]),
        ),
        const SizedBox(height: 16),
      ],

      // Bouton générer
      GestureDetector(
        onTap: (_loading || !_step2Valid) ? null : _generate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: (_loading || !_step2Valid) ? _gold.withValues(alpha: 0.4) : _gold,
            borderRadius: BorderRadius.circular(14),
          ),
          child: _loading
              ? const Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                  SizedBox(width: 8),
                  Text('Générer mon programme', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
        ),
      ),
      const SizedBox(height: 8),
    ]),
  );

  // ── Contrôles du stepper ──────────────────────────────────────────────────

  Widget _buildControls(ControlsDetails details) {
    if (_step == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _step1Valid ? details.onStepContinue : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _step1Valid ? _gold : _gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Suivant', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ),
          ),
        ]),
      );
    }
    // Étape 2 : contrôles gérés inline (bouton Générer)
    return const SizedBox.shrink();
  }
}

// ── Widgets helper ─────────────────────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final String? Function(String?) validate;
  final ValueChanged<String> onChanged;
  final bool isInteger;

  const _NumberField({
    required this.controller, required this.label, required this.hint,
    required this.icon, required this.validate, required this.onChanged,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    final err = validate(controller.text);
    final hasValue = controller.text.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: isInteger
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(isInteger ? RegExp(r'\d') : RegExp(r'[\d.,]')),
        ],
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF555555)),
          prefixIcon: Icon(icon, color: hasValue && err == null ? _gold : const Color(0xFF666666), size: 20),
          suffixIcon: hasValue && err == null
              ? const Icon(Icons.check_circle, color: _green, size: 18)
              : null,
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.6))),
          errorText: hasValue ? err : null,
          errorStyle: const TextStyle(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }
}


class _SelectCard extends StatelessWidget {
  final String label, value;
  final String? selected;
  final IconData icon;
  final ValueChanged<String> onTap;

  const _SelectCard({
    required this.label, required this.value, required this.icon,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? _gold.withValues(alpha: 0.12) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _gold : _border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? _gold : const Color(0xFF666666), size: 22),
          const SizedBox(height: 6),
          Text(
            label, textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? _gold : const Color(0xFF888888),
              fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ]),
      ),
    );
  }
}
