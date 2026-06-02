import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/storage/validation_store.dart';

class CoachValidationsScreen extends StatefulWidget {
  const CoachValidationsScreen({super.key});

  @override
  State<CoachValidationsScreen> createState() => _CoachValidationsScreenState();
}

class _CoachValidationsScreenState extends State<CoachValidationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _trainings  = [];
  List<Map<String, dynamic>> _nutritions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final t = await ValidationStore.getAllTrainings();
    final n = await ValidationStore.getAllNutritions();
    t.sort((a, b) => (b['submittedAt'] as String).compareTo(a['submittedAt'] as String));
    n.sort((a, b) => (b['submittedAt'] as String).compareTo(a['submittedAt'] as String));
    if (mounted) setState(() { _trainings = t; _nutritions = n; _loading = false; });
  }

  Future<void> _validate(String id, bool approved, bool isTraining, {String? note}) async {
    final status = approved ? 'VALIDATED' : 'REJECTED';
    if (isTraining) {
      await ValidationStore.updateTrainingStatus(id, status, coachNote: note);
    } else {
      await ValidationStore.updateNutritionStatus(id, status, coachNote: note);
    }
    await _load();
  }

  void _showValidateDialog(Map<String, dynamic> item, bool isTraining) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(children: [
          const Icon(Icons.rate_review_outlined, color: Color(0xFFE5A01A), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(
            isTraining ? 'Valider le programme' : 'Valider le plan nutritionnel',
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15),
          )),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adhérent : ${item['memberName']}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
            const SizedBox(height: 14),
            const Text("Note pour l'adhérent (optionnel)",
                style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ex: Très bon programme, augmente les charges progressivement...',
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF5F5F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _validate(item['id'], false, isTraining,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
            },
            child: const Text('Rejeter', style: TextStyle(color: Color(0xFFE53935))),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _validate(item['id'], true, isTraining,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Valider', style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingT = _trainings.where((e) => e['status'] == 'PENDING').length;
    final pendingN = _nutritions.where((e) => e['status'] == 'PENDING').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(
        children: [
          // ── Dark header with tabs ──
          Container(
            color: const Color(0xFF1A1A1A),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Text(
                      'Validations',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TabBar(
                    controller: _tab,
                    labelColor: const Color(0xFFE5A01A),
                    unselectedLabelColor: const Color(0xFF888888),
                    indicatorColor: const Color(0xFFE5A01A),
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: 'Entraînement${pendingT > 0 ? ' ($pendingT)' : ''}'),
                      Tab(text: 'Nutrition${pendingN > 0 ? ' ($pendingN)' : ''}'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
                : TabBarView(
                    controller: _tab,
                    children: [
                      _SubmissionList(
                        items: _trainings,
                        isTraining: true,
                        onReview: (item) => _showValidateDialog(item, true),
                        onRefresh: _load,
                      ),
                      _SubmissionList(
                        items: _nutritions,
                        isTraining: false,
                        onReview: (item) => _showValidateDialog(item, false),
                        onRefresh: _load,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Submission list ────────────────────────────────────────────────────────────

class _SubmissionList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isTraining;
  final void Function(Map<String, dynamic>) onReview;
  final Future<void> Function() onRefresh;

  const _SubmissionList({
    required this.items,
    required this.isTraining,
    required this.onReview,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          isTraining ? Icons.fitness_center_outlined : Icons.restaurant_menu_outlined,
          color: const Color(0xFFBBBBBB), size: 48,
        ),
        const SizedBox(height: 12),
        const Text('Aucune soumission', style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
      ]));
    }

    return RefreshIndicator(
      color: const Color(0xFFE5A01A),
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SubmissionCard(
            item: items[i],
            isTraining: isTraining,
            onReview: () => onReview(items[i]),
          ),
        ),
      ),
    );
  }
}

// ── Submission card ────────────────────────────────────────────────────────────

class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isTraining;
  final VoidCallback onReview;

  const _SubmissionCard({required this.item, required this.isTraining, required this.onReview});

  Color get _statusColor => switch (item['status']) {
    'VALIDATED' => const Color(0xFF4CAF50),
    'REJECTED'  => const Color(0xFFE53935),
    _           => const Color(0xFFFF9800),
  };

  String get _statusLabel => switch (item['status']) {
    'VALIDATED' => 'Validé',
    'REJECTED'  => 'Rejeté',
    _           => 'En attente',
  };

  IconData get _statusIcon => switch (item['status']) {
    'VALIDATED' => Icons.check_circle,
    'REJECTED'  => Icons.cancel,
    _           => Icons.hourglass_empty,
  };

  @override
  Widget build(BuildContext context) {
    final isPending     = item['status'] == 'PENDING';
    final submittedAt   = _formatDate(item['submittedAt']);
    final data          = isTraining ? (item['program'] as Map?) : (item['plan'] as Map?);
    final title         = data?['name'] ?? (isTraining ? 'Programme IA' : 'Plan nutritionnel');
    final subtitle      = isTraining
        ? '${(data?['exercises'] as List? ?? []).length} exercices'
        : '${(data?['targetCalories'] ?? 0).toInt()} kcal / jour';
    final borderColor   = isPending
        ? const Color(0xFFFF9800).withValues(alpha: 0.4)
        : _statusColor.withValues(alpha: 0.25);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isTraining ? const Color(0xFFE5A01A) : const Color(0xFF4CAF50)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isTraining ? Icons.fitness_center : Icons.restaurant_menu,
                color: isTraining ? const Color(0xFFE5A01A) : const Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['memberName'] ?? 'Adhérent',
                  style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 14)),
              Text(title,    style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
              Text(subtitle, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_statusIcon, color: _statusColor, size: 12),
                const SizedBox(width: 4),
                Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),

        const Divider(height: 1, color: Color(0xFFE8E8E8)),

        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(children: [
            const Icon(Icons.schedule, color: Color(0xFFBBBBBB), size: 13),
            const SizedBox(width: 4),
            Text(submittedAt, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
            if (item['coachNote'] != null && (item['coachNote'] as String).isNotEmpty) ...[
              const SizedBox(width: 10),
              const Icon(Icons.comment_outlined, color: Color(0xFFBBBBBB), size: 13),
              const SizedBox(width: 4),
              Expanded(child: Text(
                item['coachNote'],
                style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              )),
            ] else
              const Spacer(),
            if (isPending) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onReview,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Examiner', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
