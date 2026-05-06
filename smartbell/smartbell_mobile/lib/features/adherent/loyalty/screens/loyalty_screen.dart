import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  static const _rewards = [
    _Reward(icon: Icons.fitness_center,  label: 'Séance gratuite',  points: 200, color: AppTheme.primary),
    _Reward(icon: Icons.blender,         label: 'Supplément',       points: 350, color: AppTheme.success),
    _Reward(icon: Icons.checkroom,       label: 'T-shirt gym',      points: 500, color: AppTheme.info),
    _Reward(icon: Icons.spa,             label: 'Massage 30min',    points: 800, color: Color(0xFFBA68C8)),
    _Reward(icon: Icons.card_membership, label: 'Mois gratuit',     points: 2000, color: AppTheme.error),
  ];

  static const _history = [
    _Transaction(label: 'Visite du 08/04', points: 10, isPositive: true),
    _Transaction(label: 'Visite du 07/04', points: 10, isPositive: true),
    _Transaction(label: 'Réservation cours', points: 5, isPositive: true),
    _Transaction(label: 'Supplément échangé', points: -350, isPositive: false),
    _Transaction(label: 'Visite du 05/04', points: 10, isPositive: true),
    _Transaction(label: 'Séance gratuite échangée', points: -200, isPositive: false),
  ];

  static const int _totalPoints = 175;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Programme Fidélité')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Points card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF9F27), Color(0xFFE5841A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars, color: Colors.black54, size: 36),
                  const SizedBox(height: 8),
                  const Text('Mes points', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const Text('$_totalPoints', style: TextStyle(color: Colors.black, fontSize: 52, fontWeight: FontWeight.bold, letterSpacing: -2)),
                  const Text('points fidélité', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.black26),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _PointsInfo(label: 'Ce mois', value: '35'),
                      _PointsInfo(label: 'Total gagné', value: '725'),
                      _PointsInfo(label: 'Échangés', value: '550'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Rewards grid ──
            const Text('Récompenses', style: AppTheme.headingMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: _rewards.map((r) => _RewardCard(reward: r, userPoints: _totalPoints)).toList(),
            ),
            const SizedBox(height: 24),

            // ── History ──
            const Text('Historique', style: AppTheme.headingMedium),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Column(
                children: _history.asMap().entries.map((e) => Column(
                  children: [
                    _TransactionTile(tx: e.value),
                    if (e.key < _history.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PointsInfo extends StatelessWidget {
  final String label;
  final String value;
  const _PointsInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
    ],
  );
}

class _RewardCard extends StatelessWidget {
  final _Reward reward;
  final int userPoints;
  const _RewardCard({required this.reward, required this.userPoints});

  @override
  Widget build(BuildContext context) {
    final canRedeem = userPoints >= reward.points;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: canRedeem ? reward.color.withValues(alpha: 0.4) : AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: reward.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(reward.icon, color: reward.color, size: 18),
            ),
            if (canRedeem)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Text('Dispo', style: TextStyle(color: AppTheme.success, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reward.label, style: TextStyle(color: canRedeem ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
              Text('${reward.points} pts', style: TextStyle(color: canRedeem ? reward.color : AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final _Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: tx.isPositive ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(tx.isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: tx.isPositive ? AppTheme.success : AppTheme.error, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(tx.label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
      Text(
        '${tx.isPositive ? '+' : ''}${tx.points} pts',
        style: TextStyle(color: tx.isPositive ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ]),
  );
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _Reward {
  final IconData icon;
  final String label;
  final int points;
  final Color color;
  const _Reward({required this.icon, required this.label, required this.points, required this.color});
}

class _Transaction {
  final String label;
  final int points;
  final bool isPositive;
  const _Transaction({required this.label, required this.points, required this.isPositive});
}
