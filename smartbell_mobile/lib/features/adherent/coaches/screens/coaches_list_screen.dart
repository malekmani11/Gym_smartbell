import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../models/coach_model.dart';

// ── Palette ────────────────────────────────────────────────────────────────────
const _bg     = Color(0xFFF5F5F0);
const _dark   = Color(0xFF1A1A1A);
const _white  = Colors.white;
const _gold   = Color(0xFFE5A01A);
const _border = Color(0xFFE8E8E8);
const _muted  = Color(0xFF888888);
const _green  = Color(0xFF1D9E75);

// ── Screen ─────────────────────────────────────────────────────────────────────

class AdherentCoachesScreen extends StatefulWidget {
  const AdherentCoachesScreen({super.key});

  @override
  State<AdherentCoachesScreen> createState() => _AdherentCoachesScreenState();
}

class _AdherentCoachesScreenState extends State<AdherentCoachesScreen> {
  List<CoachModel> _coaches = [];
  bool   _loading = true;
  String? _error;

  // keeps track of which coachIds the user already rated (local, session only)
  final Set<int> _ratedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await DioClient.instance.dio
          .get('/coaches', queryParameters: {'size': 50});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _coaches = (list as List)
            .map((e) => CoachModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  void _openRatingSheet(CoachModel coach) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RatingSheet(
        coach: coach,
        onRated: () {
          setState(() => _ratedIds.add(coach.id!));
          _load(); // refresh ratingAvg
        },
      ),
    );
  }

  Color _statusColor(String? s) => switch ((s ?? '').toUpperCase()) {
    'AVAILABLE'   => _green,
    'BUSY'        => const Color(0xFFFFB74D),
    'UNAVAILABLE' => const Color(0xFFE24B4A),
    _             => _muted,
  };

  String _statusLabel(String? s) => switch ((s ?? '').toUpperCase()) {
    'AVAILABLE'   => 'Disponible',
    'BUSY'        => 'Occupé',
    'UNAVAILABLE' => 'Indisponible',
    _             => s ?? '',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _dark,
        elevation: 0,
        iconTheme: const IconThemeData(color: _white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nos Coachs',
                style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Évaluez vos coachs', style: TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                ),
                child: Text('${_coaches.length}',
                    style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: _gold,
                  onRefresh: _load,
                  child: _coaches.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _coaches.length,
                          itemBuilder: (_, i) {
                            final coach = _coaches[i];
                            final alreadyRated = coach.id != null && _ratedIds.contains(coach.id);
                            return _CoachCard(
                              coach: coach,
                              statusColor: _statusColor(coach.availabilityStatus),
                              statusLabel: _statusLabel(coach.availabilityStatus),
                              alreadyRated: alreadyRated,
                              onRate: coach.id != null && !alreadyRated
                                  ? () => _openRatingSheet(coach)
                                  : null,
                            );
                          },
                        ),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_outlined, color: Color(0xFFE24B4A), size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: _muted), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _load,
          style: ElevatedButton.styleFrom(backgroundColor: _dark, foregroundColor: _gold),
          child: const Text('Réessayer'),
        ),
      ]),
    ),
  );

  Widget _buildEmpty() => ListView(children: const [
    SizedBox(height: 120),
    Center(child: Icon(Icons.school_outlined, color: _muted, size: 64)),
    SizedBox(height: 16),
    Center(child: Text('Aucun coach disponible',
        style: TextStyle(color: _muted, fontSize: 15))),
  ]);
}

// ── Coach card ─────────────────────────────────────────────────────────────────

class _CoachCard extends StatelessWidget {
  final CoachModel coach;
  final Color  statusColor;
  final String statusLabel;
  final bool   alreadyRated;
  final VoidCallback? onRate;

  const _CoachCard({
    required this.coach,
    required this.statusColor,
    required this.statusLabel,
    required this.alreadyRated,
    required this.onRate,
  });

  String get _initials {
    final f = coach.firstName.isNotEmpty ? coach.firstName[0] : '';
    final l = coach.lastName.isNotEmpty  ? coach.lastName[0]  : '';
    return (f + l).toUpperCase().isNotEmpty ? (f + l).toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final avg = coach.ratingAvg ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // ── Top row ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_gold.withValues(alpha: 0.8), _gold],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(_initials,
                      style: const TextStyle(color: _dark, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),

              // Name + email + spec
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(coach.fullName,
                    style: const TextStyle(color: _dark, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(coach.email,
                    style: const TextStyle(color: _muted, fontSize: 12)),
                if (coach.specialization != null && coach.specialization!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.fitness_center, color: _muted, size: 12),
                    const SizedBox(width: 4),
                    Text(coach.specialization!,
                        style: const TextStyle(color: _muted, fontSize: 11)),
                  ]),
                ],
              ])),

              // Availability badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          // ── Separator ─────────────────────────────────────────────────────
          const Divider(height: 1, color: _border),

          // ── Rating + button row ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(children: [
              // Stars display
              _StarDisplay(avg: avg),
              const SizedBox(width: 8),
              Text(
                avg > 0 ? avg.toStringAsFixed(1) : 'Pas encore noté',
                style: TextStyle(
                  color: avg > 0 ? _dark : _muted,
                  fontSize: 13,
                  fontWeight: avg > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              // Rate button
              if (alreadyRated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _green.withValues(alpha: 0.3)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline, color: _green, size: 14),
                    SizedBox(width: 4),
                    Text('Noté', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                )
              else
                GestureDetector(
                  onTap: onRate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_outline, color: _dark, size: 15),
                      SizedBox(width: 5),
                      Text('Évaluer', style: TextStyle(
                          color: _dark, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Star display (read-only) ───────────────────────────────────────────────────

class _StarDisplay extends StatelessWidget {
  final double avg;
  const _StarDisplay({required this.avg});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < avg.floor();
        final half   = !filled && i < avg && (avg - avg.floor()) >= 0.3;
        return Icon(
          filled ? Icons.star_rounded
              : half ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          color: filled || half ? _gold : const Color(0xFFDDDDDD),
          size: 18,
        );
      }),
    );
  }
}

// ── Rating bottom sheet ────────────────────────────────────────────────────────

class _RatingSheet extends StatefulWidget {
  final CoachModel  coach;
  final VoidCallback onRated;
  const _RatingSheet({required this.coach, required this.onRated});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int     _selected  = 0;   // 0 = none chosen yet
  bool    _submitting = false;
  String? _error;
  final   _commentCtrl = TextEditingController();

  static const _labels = ['', 'Mauvais', 'Insuffisant', 'Correct', 'Bien', 'Excellent !'];
  static const _colors = [
    Colors.transparent,
    Color(0xFFE24B4A),
    Color(0xFFFF7043),
    Color(0xFFFFB74D),
    Color(0xFF66BB6A),
    Color(0xFF1D9E75),
  ];

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_selected == 0) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await DioClient.instance.dio.post(
        '/coaches/${widget.coach.id}/ratings',
        data: {
          'rating':  _selected,
          if (_commentCtrl.text.trim().isNotEmpty)
            'comment': _commentCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onRated();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Merci pour votre évaluation de ${widget.coach.firstName} !'),
          backgroundColor: _green,
        ));
      }
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = _selected > 0 ? _colors[_selected] : _muted;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
              )),

              // Coach avatar + name
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAEEDA), shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    ((widget.coach.firstName.isNotEmpty ? widget.coach.firstName[0] : '') +
                     (widget.coach.lastName.isNotEmpty  ? widget.coach.lastName[0]  : '')).toUpperCase(),
                    style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Évaluer ${widget.coach.fullName}',
                  style: const TextStyle(color: _dark, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              const Text('Votre avis aide les autres membres',
                  style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 28),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE24B4A).withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFE24B4A), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFE24B4A), fontSize: 12))),
                  ]),
                ),
              ],

              // ── 5 Interactive stars ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  final filled = star <= _selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = star),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: filled ? _gold : const Color(0xFFDDDDDD),
                        size: 46,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),

              // Label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _selected > 0 ? _labels[_selected] : 'Appuyez sur une étoile',
                  key: ValueKey(_selected),
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Comment (optional)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Commentaire (optionnel)',
                    style: const TextStyle(color: _dark, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentCtrl,
                maxLines: 3,
                style: const TextStyle(color: _dark, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Partagez votre expérience avec ce coach...',
                  hintStyle: const TextStyle(color: _muted, fontSize: 12),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _gold, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_selected > 0 && !_submitting) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected > 0 ? _gold : _gold.withValues(alpha: 0.4),
                    foregroundColor: _dark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: _dark))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.star_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(_selected > 0
                              ? 'Soumettre $_selected/5 étoile${_selected > 1 ? 's' : ''}'
                              : 'Sélectionnez une note'),
                        ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
