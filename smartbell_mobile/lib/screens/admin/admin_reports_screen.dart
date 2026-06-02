import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../models/statistics_model.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _dio = ApiClient().dio;

  StatisticsModel? _stats;
  Map<String, dynamic>? _payStats;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final statsRes = await _dio.get('/statistics');
      _stats = StatisticsModel.fromJson(statsRes.data as Map<String, dynamic>);

      try {
        final payRes = await _dio.get('/payments/stats');
        _payStats = payRes.data as Map<String, dynamic>;
      } catch (_) {}


      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
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
                    Text('Rapports', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Statistiques détaillées', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  ]),
                ),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
                    child: const Icon(Icons.refresh, color: Color(0xFFE5A01A), size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // Body
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
          : _error != null
            ? _buildError()
            : RefreshIndicator(
                color: const Color(0xFFE5A01A),
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_stats != null) ...[
                      _buildRevenueCard(),
                      const SizedBox(height: 14),
                      _buildMembersCard(),
                      const SizedBox(height: 14),
                      _buildCoursesCard(),
                      const SizedBox(height: 14),
                      if (_payStats != null) _buildPaymentsCard(),
                      if (_payStats != null) const SizedBox(height: 14),
                      _buildRetentionCard(),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
        ),
      ]),
    );
  }

  // ── Revenue card ─────────────────────────────────────────────────────────────
  Widget _buildRevenueCard() {
    final s = _stats!;
    final prev = (_payStats?['revenuePrevMonth'] as num?)?.toDouble() ?? 0;
    final curr = s.revenueThisMonth;
    final change = prev > 0 ? ((curr - prev) / prev * 100) : 0.0;
    final isUp = change >= 0;

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle(icon: Icons.bar_chart, label: 'REVENUS'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _BigStat(
            label: 'Ce mois',
            value: '${s.revenueThisMonth.toStringAsFixed(0)} DT',
            color: const Color(0xFFE5A01A),
          )),
          Container(width: 1, height: 50, color: const Color(0xFFEEEEEE)),
          Expanded(child: _BigStat(
            label: 'Cette année',
            value: '${s.revenueThisYear.toStringAsFixed(0)} DT',
            color: const Color(0xFF1A1A1A),
          )),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isUp ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isUp ? Icons.trending_up : Icons.trending_down,
              size: 14, color: isUp ? const Color(0xFF3B6D11) : const Color(0xFFE53935)),
            const SizedBox(width: 4),
            Text(
              '${isUp ? '+' : ''}${change.toStringAsFixed(1)}% vs mois précédent',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: isUp ? const Color(0xFF3B6D11) : const Color(0xFFE53935),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Members card ─────────────────────────────────────────────────────────────
  Widget _buildMembersCard() {
    final s = _stats!;
    final inactive = s.totalMembers - s.activeMembers;
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle(icon: Icons.people, label: 'MEMBRES'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _SmallStat(label: 'Total',    value: '${s.totalMembers}',  color: const Color(0xFF1A1A1A))),
          Expanded(child: _SmallStat(label: 'Actifs',   value: '${s.activeMembers}', color: const Color(0xFF4CAF50))),
          Expanded(child: _SmallStat(label: 'Inactifs', value: '$inactive',           color: const Color(0xFF888888))),
          Expanded(child: _SmallStat(label: 'Coachs',   value: '${s.totalCoaches}',  color: const Color(0xFFE5A01A))),
        ]),
      ]),
    );
  }

  // ── Courses card ──────────────────────────────────────────────────────────────
  Widget _buildCoursesCard() {
    final s = _stats!;
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle(icon: Icons.fitness_center, label: 'COURS & ABONNEMENTS'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _SmallStat(label: 'Cours actifs',    value: '${s.totalCourses}',        color: const Color(0xFF3B82F6))),
          Expanded(child: _SmallStat(label: 'Abonnements',     value: '${s.activeSubscriptions}', color: const Color(0xFFE5A01A))),
          Expanded(child: _SmallStat(label: 'Check-ins/jour',  value: '${s.totalCheckInsToday}',  color: const Color(0xFF9333EA))),
        ]),
      ]),
    );
  }

  // ── Payments card ─────────────────────────────────────────────────────────────
  Widget _buildPaymentsCard() {
    final p = _payStats!;
    final completed = (p['completedCount'] ?? 0).toInt();
    final pending   = (p['pendingCount']   ?? 0).toInt();
    final failed    = (p['failedCount']    ?? 0).toInt();
    final refunded  = (p['refundedCount']  ?? 0).toInt();

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle(icon: Icons.payment, label: 'PAIEMENTS'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _SmallStat(label: 'Complétés', value: '$completed', color: const Color(0xFF4CAF50))),
          Expanded(child: _SmallStat(label: 'En attente', value: '$pending',  color: const Color(0xFFE5A01A))),
          Expanded(child: _SmallStat(label: 'Échoués',   value: '$failed',    color: const Color(0xFFE53935))),
          Expanded(child: _SmallStat(label: 'Remboursés',value: '$refunded',  color: const Color(0xFF888888))),
        ]),
        const SizedBox(height: 14),
        // Barre de répartition
        if (completed + pending + failed > 0) ...[
          const Text('Répartition', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
          const SizedBox(height: 6),
          _PaymentBar(completed: completed, pending: pending, failed: failed),
        ],
      ]),
    );
  }

  // ── Retention card ────────────────────────────────────────────────────────────
  Widget _buildRetentionCard() {
    final s = _stats!;
    final rate = s.totalMembers > 0 ? (s.activeMembers / s.totalMembers) : 0.0;
    final pct = (rate * 100).toInt();

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle(icon: Icons.show_chart, label: 'TAUX DE RÉTENTION'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$pct%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text('${s.activeMembers} actifs sur ${s.totalMembers} membres',
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          ])),
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 70, height: 70,
              child: CircularProgressIndicator(
                value: rate,
                strokeWidth: 7,
                backgroundColor: const Color(0xFFE8E8E8),
                valueColor: AlwaysStoppedAnimation(
                  rate >= 0.8 ? const Color(0xFF4CAF50)
                  : rate >= 0.5 ? const Color(0xFFE5A01A)
                  : const Color(0xFFE53935),
                ),
              ),
            ),
            Text('$pct%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildError() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Erreur', style: const TextStyle(color: Color(0xFF888888)), textAlign: TextAlign.center),
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
}

// ── Widgets helpers ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
    ),
    child: child,
  );
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CardTitle({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: const Color(0xFFE5A01A)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF888888), letterSpacing: 0.8)),
  ]);
}

class _BigStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _BigStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
  ]);
}

class _SmallStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SmallStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF888888)), textAlign: TextAlign.center),
  ]);
}

class _PaymentBar extends StatelessWidget {
  final int completed, pending, failed;
  const _PaymentBar({required this.completed, required this.pending, required this.failed});
  @override
  Widget build(BuildContext context) {
    final total = completed + pending + failed;
    if (total == 0) return const SizedBox();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(children: [
        if (completed > 0) Flexible(flex: completed, child: Container(height: 8, color: const Color(0xFF4CAF50))),
        if (pending   > 0) Flexible(flex: pending,   child: Container(height: 8, color: const Color(0xFFE5A01A))),
        if (failed    > 0) Flexible(flex: failed,    child: Container(height: 8, color: const Color(0xFFE53935))),
      ]),
    );
  }
}

