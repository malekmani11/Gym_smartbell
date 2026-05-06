import 'dart:math' show min, max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/measurement.dart';
import 'add_measurement_sheet.dart';
import 'progress_service.dart';

// ─── Period enum ──────────────────────────────────────────────────────────────

enum _Period {
  month1('1 mois'),
  month3('3 mois'),
  month6('6 mois'),
  all('Tout');

  final String label;
  const _Period(this.label);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _service = ProgressService();

  List<Measurement> _measurements = [];
  bool _loading = true;
  int? _memberId;
  _Period _period = _Period.month1;

  // ── Data ────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // Resolve member ID (may differ from user ID)
    try {
      final res =
          await DioClient.instance.dio.get('/members/user/${user.id}');
      _memberId = (res.data['id'] ?? user.id).toInt();
    } catch (_) {
      _memberId = user.id;
    }

    final data = await _service.getMeasurements(_memberId!);
    if (mounted) setState(() { _measurements = data; _loading = false; });
  }

  List<Measurement> get _filtered {
    if (_measurements.isEmpty) return [];
    final now = DateTime.now();
    final cutoff = switch (_period) {
      _Period.month1 => now.subtract(const Duration(days: 31)),
      _Period.month3 => now.subtract(const Duration(days: 91)),
      _Period.month6 => now.subtract(const Duration(days: 182)),
      _Period.all    => DateTime(2000),
    };
    return _measurements.where((m) => m.date.isAfter(cutoff)).toList();
  }

  Future<void> _delete(Measurement m) async {
    await _service.deleteMeasurement(_memberId!, m);
    await _load();
  }

  void _openAddSheet() {
    if (_memberId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddMeasurementSheet(
        memberId:   _memberId!,
        lastHeight: _measurements.isNotEmpty ? _measurements.last.height : null,
        onSaved:    _load,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ma Progression'),
        actions: [
          if (!_loading && _measurements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '${_measurements.length} mesure${_measurements.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        tooltip: 'Ajouter une mesure',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiRow(),
                    const SizedBox(height: 24),

                    // ── Period selector ──
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),

                    // ── Weight chart ──
                    const Text('ÉVOLUTION DU POIDS',
                        style: AppTheme.sectionTitle),
                    const SizedBox(height: 12),
                    _buildWeightChart(),
                    const SizedBox(height: 24),

                    // ── BMI chart ──
                    const Text('ÉVOLUTION IMC',
                        style: AppTheme.sectionTitle),
                    const SizedBox(height: 4),
                    _buildBmiLegend(),
                    const SizedBox(height: 10),
                    _buildBmiChart(),
                    const SizedBox(height: 24),

                    // ── History ──
                    if (_measurements.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('HISTORIQUE',
                              style: AppTheme.sectionTitle),
                          Text(
                            '↑ Glisser gauche pour supprimer',
                            style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildHistory(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ── KPI Row ──────────────────────────────────────────────────────────────────

  Widget _buildKpiRow() {
    if (_measurements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(children: [
          const Icon(Icons.monitor_weight_outlined,
              color: AppTheme.textMuted, size: 44),
          const SizedBox(height: 12),
          const Text('Aucune mesure enregistrée',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Appuyez sur + pour commencer',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ]),
      );
    }

    final last      = _measurements.last;
    final first     = _measurements.first;
    final variation = last.weight - first.weight;
    final isLoss    = variation < 0;

    return Row(children: [
      Expanded(
        child: _KpiCard(
          label: 'Poids actuel',
          value: last.weight.toStringAsFixed(1),
          unit:  'kg',
          icon:  Icons.monitor_weight_outlined,
          color: AppTheme.primary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _KpiCard(
          label: last.bmiLabel,
          value: last.bmi.toStringAsFixed(1),
          unit:  'IMC',
          icon:  Icons.person_outline,
          color: _bmiColor(last.bmi),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _KpiCard(
          label: _measurements.length < 2 ? 'Évolution' : 'Depuis le début',
          value: _measurements.length < 2
              ? '—'
              : '${isLoss ? '' : '+'}${variation.toStringAsFixed(1)}',
          unit:  'kg',
          icon:  isLoss ? Icons.trending_down : Icons.trending_up,
          color: _measurements.length < 2
              ? AppTheme.textSecondary
              : (isLoss ? AppTheme.success : AppTheme.error),
        ),
      ),
    ]);
  }

  // ── Period Selector ───────────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _Period.values.map((p) {
          final active = _period == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primary.withValues(alpha: 0.14)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? AppTheme.primary : AppTheme.border,
                    width: active ? 1.5 : 0.5,
                  ),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    color: active
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Weight Chart ─────────────────────────────────────────────────────────────

  Widget _buildWeightChart() {
    final data = _filtered;
    if (data.length < 2) {
      return _emptyChart(
        data.isEmpty
            ? 'Aucune mesure sur cette période'
            : 'Ajoutez au moins 2 mesures pour voir le graphique',
      );
    }

    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
        .toList();

    final weights  = data.map((m) => m.weight);
    final minW     = weights.reduce(min);
    final maxW     = weights.reduce(max);
    final rangeW   = maxW - minW;
    final padding  = rangeW < 2 ? 3.0 : rangeW * 0.15 + 1;
    final minY     = (minW - padding).clamp(0.0, double.infinity);
    final maxY     = maxW + padding;

    final interval = _yInterval(minY, maxY);
    final xInterval = data.length <= 7
        ? 1.0
        : (data.length / 5).ceilToDouble();

    return _chartContainer(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) =>
                    FlDotCirclePainter(
                  radius:      4,
                  color:       AppTheme.primary,
                  strokeColor: AppTheme.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.18),
                    AppTheme.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 44,
                interval:     interval,
                getTitlesWidget: (v, meta) => Text(
                  '${v.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 28,
                interval:     xInterval,
                getTitlesWidget: (v, meta) {
                  if (v != v.floorToDouble()) {
                    return const SizedBox.shrink();
                  }
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('dd/MM').format(data[idx].date),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppTheme.border, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.surface,
              tooltipBorder: const BorderSide(color: AppTheme.border),
              getTooltipItems: (spots) => spots.map((s) {
                final m = data[s.spotIndex];
                return LineTooltipItem(
                  '${DateFormat('dd/MM/yy').format(m.date)}\n'
                  '${m.weight.toStringAsFixed(1)} kg',
                  const TextStyle(
                    color:      AppTheme.primary,
                    fontSize:   12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── BMI Chart ─────────────────────────────────────────────────────────────────

  Widget _buildBmiLegend() {
    return Row(children: [
      _legendDot(AppTheme.success, 'Normal (18.5–24.9)'),
      const SizedBox(width: 14),
      _legendDot(AppTheme.warning, 'Surpoids (25–30)'),
      const SizedBox(width: 14),
      _legendDot(AppTheme.error,   'Obèse (>30)'),
    ]);
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.7), shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label,
          style:
              const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
    ],
  );

  Widget _buildBmiChart() {
    final data = _filtered;
    if (data.length < 2) {
      return _emptyChart(
        data.isEmpty
            ? 'Aucune mesure sur cette période'
            : 'Ajoutez au moins 2 mesures pour voir le graphique',
      );
    }

    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.bmi))
        .toList();

    final bmis    = data.map((m) => m.bmi);
    final minBmi  = bmis.reduce(min);
    final maxBmi  = bmis.reduce(max);
    final chartMin = max(minBmi - 2, 14.0);
    final chartMax = max(maxBmi + 2, 32.0);

    return _chartContainer(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: chartMin,
          maxY: chartMax,
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: 18.5, y2: 24.9,
                color: AppTheme.success.withValues(alpha: 0.12),
              ),
              HorizontalRangeAnnotation(
                y1: 25.0, y2: 29.9,
                color: AppTheme.warning.withValues(alpha: 0.10),
              ),
              HorizontalRangeAnnotation(
                y1: 30.0, y2: chartMax,
                color: AppTheme.error.withValues(alpha: 0.09),
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots:         spots,
              isCurved:      true,
              curveSmoothness: 0.30,
              color:         Colors.white,
              barWidth:      2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) =>
                    FlDotCirclePainter(
                  radius:      3.5,
                  color:       Colors.white,
                  strokeColor: AppTheme.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 38,
                interval:     5,
                getTitlesWidget: (v, meta) => Text(
                  v.toStringAsFixed(0),
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show:             true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (_) => FlLine(
              color:       AppTheme.border.withValues(alpha: 0.5),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.surface,
              tooltipBorder: const BorderSide(color: AppTheme.border),
              getTooltipItems: (spots) => spots.map((s) {
                final m = data[s.spotIndex];
                return LineTooltipItem(
                  '${DateFormat('dd/MM/yy').format(m.date)}\n'
                  'IMC ${m.bmi.toStringAsFixed(1)} · ${m.bmiLabel}',
                  const TextStyle(
                    color:      Colors.white,
                    fontSize:   12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── History ──────────────────────────────────────────────────────────────────

  Widget _buildHistory() {
    final reversed = _measurements.reversed.toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reversed.length,
      itemBuilder: (context, i) {
        final m = reversed[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: Key('${m.date.toIso8601String()}_${m.weight}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppTheme.error, size: 22),
            ),
            onDismissed: (_) => _delete(m),
            child: _MeasurementRow(m: m),
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _emptyChart(String message) => Container(
    height: 140,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.show_chart, color: AppTheme.textMuted, size: 36),
      const SizedBox(height: 8),
      Text(message,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12),
          textAlign: TextAlign.center),
    ]),
  );

  Widget _chartContainer({required double height, required Widget child}) =>
      Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(4, 16, 16, 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: child,
      );

  static double _yInterval(double min, double max) {
    final range = max - min;
    if (range <= 5)  return 1;
    if (range <= 15) return 2;
    if (range <= 30) return 5;
    return 10;
  }
}

Color _bmiColor(double bmi) {
  if (bmi < 18.5) return AppTheme.info;
  if (bmi < 25.0) return AppTheme.success;
  if (bmi < 30.0) return AppTheme.warning;
  return AppTheme.error;
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color:      color,
                    fontSize:   21,
                    fontWeight: FontWeight.bold,
                    height:     1,
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color:    color.withValues(alpha: 0.65),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 9),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Measurement Row ──────────────────────────────────────────────────────────

class _MeasurementRow extends StatelessWidget {
  final Measurement m;
  const _MeasurementRow({required this.m});

  @override
  Widget build(BuildContext context) {
    final color = _bmiColor(m.bmi);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(children: [
        // Date badge
        Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: [
            Text(
              DateFormat('dd').format(m.date),
              style: const TextStyle(
                color:      AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize:   16,
                height:     1,
              ),
            ),
            Text(
              DateFormat('MMM', 'fr_FR').format(m.date),
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 10),
            ),
          ]),
        ),
        const SizedBox(width: 14),

        // Data
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  '${m.weight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color:      AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize:   15,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'IMC ${m.bmi.toStringAsFixed(1)}',
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Text(
                  '${m.height.toStringAsFixed(0)} cm · ${m.bmiLabel}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ]),
              if (m.notes != null && m.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    m.notes!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),

        const Icon(Icons.swipe_left_outlined,
            color: AppTheme.textMuted, size: 14),
      ]),
    );
  }
}
