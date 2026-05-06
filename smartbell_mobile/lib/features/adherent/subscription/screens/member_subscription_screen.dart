import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../models/subscription_model.dart';
import '../../../../models/subscription_plan_model.dart';

class MemberSubscriptionScreen extends StatefulWidget {
  const MemberSubscriptionScreen({super.key});

  @override
  State<MemberSubscriptionScreen> createState() =>
      _MemberSubscriptionScreenState();
}

class _MemberSubscriptionScreenState extends State<MemberSubscriptionScreen> {
  SubscriptionModel? _currentSub;
  List<SubscriptionPlanModel> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final dio = DioClient.instance.dio;
    try {
      final results = await Future.wait([
        dio.get(
          ApiConstants.subscriptionsByUser(user.id),
          queryParameters: {'size': 1, 'sort': 'createdAt,desc'},
        ),
        dio.get(
          ApiConstants.plans,
          queryParameters: {'activeOnly': true},
        ),
      ]);

      // Current subscription
      final subData = results[0].data;
      final subList = subData is Map ? (subData['content'] ?? []) : [];
      SubscriptionModel? sub;
      if ((subList as List).isNotEmpty) {
        sub = SubscriptionModel.fromJson(subList.first as Map<String, dynamic>);
      }

      // Plans
      final planData = results[1].data;
      List<dynamic> planList = [];
      if (planData is Map && planData.containsKey('content')) {
        planList = planData['content'] as List<dynamic>;
      } else if (planData is List) {
        planList = planData;
      }

      if (!mounted) return;
      setState(() {
        _currentSub = sub;
        _plans = planList
            .map((p) =>
                SubscriptionPlanModel.fromJson(p as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mon abonnement'),
        backgroundColor: AppTheme.surfaceAlt,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCurrentSubSection(),
                      const SizedBox(height: 24),
                      _buildPlansSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentSubSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ABONNEMENT ACTUEL', style: AppTheme.sectionTitle),
        const SizedBox(height: 12),
        _currentSub == null
            ? _buildNoSubCard()
            : _CurrentSubCard(sub: _currentSub!),
      ],
    );
  }

  Widget _buildNoSubCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: const Column(
        children: [
          Icon(Icons.card_membership_outlined,
              color: AppTheme.textMuted, size: 40),
          SizedBox(height: 10),
          Text(
            'Aucun abonnement actif',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Choisissez un plan ci-dessous',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PLANS DISPONIBLES', style: AppTheme.sectionTitle),
        const SizedBox(height: 12),
        if (_plans.isEmpty)
          const Center(
            child: Text('Aucun plan disponible',
                style: TextStyle(color: AppTheme.textSecondary)),
          )
        else
          ..._plans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanCard(
                  plan: plan,
                  isCurrent: _currentSub?.planId == plan.id,
                ),
              )),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ── Current subscription card ─────────────────────────────────────────────────

class _CurrentSubCard extends StatelessWidget {
  final SubscriptionModel sub;
  const _CurrentSubCard({required this.sub});

  Color get _statusColor {
    switch (sub.status?.toUpperCase()) {
      case 'ACTIVE':
        return AppTheme.success;
      case 'EXPIRED':
        return AppTheme.error;
      case 'CANCELLED':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textMuted;
    }
  }

  String get _statusLabel {
    switch (sub.status?.toUpperCase()) {
      case 'ACTIVE':
        return 'Actif';
      case 'EXPIRED':
        return 'Expiré';
      case 'CANCELLED':
        return 'Annulé';
      default:
        return sub.status ?? '—';
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '—';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return d;
    }
  }

  double get _progress =>
      sub.totalDays > 0
          ? (sub.daysRemaining / sub.totalDays).clamp(0.0, 1.0)
          : 0.0;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.12),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3), width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_membership,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.planName ?? 'Plan inconnu',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Abonnement #${sub.id}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dates row
          Row(
            children: [
              _DateChip(
                  label: 'Début', date: _formatDate(sub.startDate)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward,
                  color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 8),
              _DateChip(label: 'Fin', date: _formatDate(sub.endDate)),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sub.daysRemaining} jours restants',
                style: TextStyle(
                    color: sub.daysRemaining < 7
                        ? AppTheme.error
                        : AppTheme.textSecondary,
                    fontSize: 12),
              ),
              Text(
                '${sub.totalDays} jours total',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppTheme.border,
              valueColor:
                  AlwaysStoppedAnimation<Color>(sub.daysRemaining < 7
                      ? AppTheme.error
                      : AppTheme.primary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String date;
  const _DateChip({required this.label, required this.date});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 10)),
          Text(date,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      );
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final bool isCurrent;
  const _PlanCard({required this.plan, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppTheme.primary.withValues(alpha: 0.5)
              : AppTheme.border,
          width: isCurrent ? 1.2 : 0.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Duration badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${plan.durationMonths}',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const Text(
                  'mois',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppTheme.primary.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'Actuel',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                if (plan.description != null &&
                    plan.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    plan.description!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  plan.durationLabel,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price
          Text(
            '${plan.price.toStringAsFixed(2)} DT',
            style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
