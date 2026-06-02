import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class CoachRatingsScreen extends StatefulWidget {
  final int userId;
  const CoachRatingsScreen({super.key, required this.userId});

  @override
  State<CoachRatingsScreen> createState() => _CoachRatingsScreenState();
}

class _CoachRatingsScreenState extends State<CoachRatingsScreen> {
  List<Map<String, dynamic>> _ratings = [];
  bool _loading = true;
  String? _error;
  double? _average;
  int? _coachId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Obtenir l'ID coach à partir du userId
      final coachRes = await DioClient.instance.dio.get(
        ApiConstants.coachByUser(widget.userId),
      );
      _coachId = (coachRes.data['id'] ?? 0).toInt();

      // Charger les évaluations
      final res = await DioClient.instance.dio.get(
        '/coaches/$_coachId/ratings',
      );
      final list = res.data as List;

      // Moyenne
      final avgRes = await DioClient.instance.dio.get(
        '/coaches/$_coachId/ratings/average',
      );
      _average = (avgRes.data as num?)?.toDouble();

      setState(() {
        _ratings = list.cast<Map<String, dynamic>>()
          ..sort((a, b) {
            final da = a['createdAt']?.toString() ?? '';
            final db = b['createdAt']?.toString() ?? '';
            return db.compareTo(da);
          });
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(children: [
        // Header
        Container(
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Mes évaluations',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (_average != null)
                      Text('Moyenne : ${_average!.toStringAsFixed(1)} / 5',
                          style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 12)),
                  ]),
                ),
                if (_average != null) _StarBadge(rating: _average!),
              ]),
            ),
          ),
        ),

        // Body
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
              : _error != null
                  ? _buildError()
                  : _ratings.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: const Color(0xFFE5A01A),
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _ratings.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _RatingCard(
                              rating: _ratings[i],
                              formatDate: _formatDate,
                            ),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _buildError() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Color(0xFF888888)), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _load,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
          child: const Text('Réessayer', style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
        ),
      ),
    ],
  ));

  Widget _buildEmpty() => const Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.star_border, color: Color(0xFFBBBBBB), size: 56),
      SizedBox(height: 12),
      Text('Aucune évaluation pour l\'instant',
          style: TextStyle(color: Color(0xFF888888), fontSize: 15)),
      SizedBox(height: 4),
      Text('Les membres pourront vous évaluer après les séances',
          style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
          textAlign: TextAlign.center),
    ],
  ));
}

// ── Star badge ────────────────────────────────────────────────────────────────

class _StarBadge extends StatelessWidget {
  final double rating;
  const _StarBadge({required this.rating});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE5A01A).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5A01A).withValues(alpha: 0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star, color: Color(0xFFE5A01A), size: 14),
      const SizedBox(width: 4),
      Text(rating.toStringAsFixed(1),
          style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 13, fontWeight: FontWeight.bold)),
    ]),
  );
}

// ── Rating card ───────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  final Map<String, dynamic> rating;
  final String Function(String?) formatDate;
  const _RatingCard({required this.rating, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final memberName = rating['memberName'] as String? ?? 'Membre';
    final score      = (rating['rating'] as num?)?.toInt() ?? 0;
    final comment    = rating['comment'] as String?;
    final date       = formatDate(rating['createdAt']?.toString());
    final initials   = memberName.isNotEmpty ? memberName[0].toUpperCase() : 'M';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(initials,
              style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(memberName,
                  style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text(date, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          // Étoiles
          Row(children: List.generate(5, (i) => Icon(
            i < score ? Icons.star : Icons.star_border,
            color: i < score ? const Color(0xFFE5A01A) : const Color(0xFFDDDDDD),
            size: 16,
          ))),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment,
                style: const TextStyle(color: Color(0xFF555555), fontSize: 12, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ])),
      ]),
    );
  }
}
