import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mon Abonnement',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: const Color(0xFFE5A01A),
                  backgroundColor: Colors.white,
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
        const Text(
          'ABONNEMENT ACTUEL',
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      child: const Column(
        children: [
          Icon(Icons.card_membership_outlined, color: Color(0xFFBBBBBB), size: 40),
          SizedBox(height: 10),
          Text(
            'Aucun abonnement actif',
            style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Choisissez un plan ci-dessous',
            style: TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLANS DISPONIBLES',
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        if (_plans.isEmpty)
          const Center(
            child: Text('Aucun plan disponible',
                style: TextStyle(color: Color(0xFF888888))),
          )
        else
          ..._plans.map((plan) => _PlanCard(
                plan: plan,
                isCurrentPlan: _currentSub?.planId == plan.id,
              )),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFF888888))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: const Color(0xFFE5A01A),
              elevation: 0,
            ),
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

  Color get _statusBg {
    switch (sub.status?.toUpperCase()) {
      case 'ACTIVE': return const Color(0xFFEAF3DE);
      case 'EXPIRED': return const Color(0xFFFCEBEB);
      case 'CANCELLED': return const Color(0xFFF5F5F0);
      default: return const Color(0xFFF5F5F0);
    }
  }

  Color get _statusFg {
    switch (sub.status?.toUpperCase()) {
      case 'ACTIVE': return const Color(0xFF3B6D11);
      case 'EXPIRED': return const Color(0xFFA32D2D);
      case 'CANCELLED': return const Color(0xFF888888);
      default: return const Color(0xFF888888);
    }
  }

  String get _statusLabel {
    switch (sub.status?.toUpperCase()) {
      case 'ACTIVE': return 'Actif';
      case 'EXPIRED': return 'Expiré';
      case 'CANCELLED': return 'Annulé';
      default: return sub.status ?? '—';
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
    final statusBg = _statusBg;
    final statusFg = _statusFg;
    final statusLabel = _statusLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFAEEDA),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.card_membership, color: Color(0xFFBA7517), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              sub.planName ?? 'Abonnement',
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text('#${sub.id}', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
          ])),
          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        // Dates
        Row(children: [
          _DateChip(label: sub.startDate != null ? _formatDate(sub.startDate!) : '-', icon: Icons.play_arrow_outlined),
          const SizedBox(width: 8),
          _DateChip(label: sub.endDate != null ? _formatDate(sub.endDate!) : '-', icon: Icons.stop_circle_outlined),
        ]),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 5,
            backgroundColor: const Color(0xFFE8E8E8),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFE5A01A)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${sub.daysRemaining} jours restants',
          style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
        ),
      ]),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _DateChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F0),
      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: const Color(0xFF888888)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
    ]),
  );
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final bool isCurrentPlan;
  const _PlanCard({required this.plan, required this.isCurrentPlan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isCurrentPlan ? const Color(0xFFE5A01A) : const Color(0xFFE8E8E8),
          width: isCurrentPlan ? 2 : 0.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFAEEDA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              '${plan.durationMonths}',
              style: const TextStyle(
                color: Color(0xFFE5A01A),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const Text('mois', style: TextStyle(color: Color(0xFF888888), fontSize: 9)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(
              plan.name,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500),
            ),
            if (isCurrentPlan) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Actuel',
                  style: TextStyle(color: Color(0xFFBA7517), fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ]),
          if (plan.description != null)
            Text(
              plan.description!,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text('${plan.durationMonths} mois', style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
        ])),
        Text(
          '${plan.price.toStringAsFixed(0)} DT',
          style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}
