import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/loyalty_service.dart';

class LoyaltyScreen extends StatefulWidget {
  final int memberId;
  const LoyaltyScreen({super.key, required this.memberId});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final _service = LoyaltyService();

  bool _loading = true;
  String? _error;

  int _points = 0;
  String _tier = 'BRONZE';
  int? _nextTierPoints;
  String _firstName = '';
  List<dynamic> _history = [];

  static const _rewards = [
    _Reward(icon: Icons.fitness_center,  label: 'Séance gratuite',  points: 200, color: AppTheme.primary),
    _Reward(icon: Icons.blender,         label: 'Supplément',       points: 350, color: AppTheme.success),
    _Reward(icon: Icons.checkroom,       label: 'T-shirt gym',      points: 500, color: AppTheme.info),
    _Reward(icon: Icons.spa,             label: 'Massage 30min',    points: 800, color: Color(0xFFBA68C8)),
    _Reward(icon: Icons.card_membership, label: 'Mois gratuit',     points: 2000, color: AppTheme.error),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getBalance(widget.memberId),
        _service.getHistory(widget.memberId),
      ]);
      final balance = results[0] as Map<String, dynamic>;
      final history = results[1] as List<dynamic>;
      setState(() {
        _points        = (balance['loyaltyPoints'] ?? 0) as int;
        _tier          = (balance['tier'] ?? 'BRONZE') as String;
        _nextTierPoints= balance['nextTierPoints'] as int?;
        _firstName     = (balance['firstName'] ?? '') as String;
        _history       = history;
        _loading       = false;
      });
    } catch (e) {
      setState(() { _error = 'Impossible de charger les données de fidélité.'; _loading = false; });
    }
  }

  Color get _tierColor => switch (_tier) {
    'SILVER'   => const Color(0xFF9E9E9E),
    'GOLD'     => AppTheme.primary,
    'PLATINUM' => const Color(0xFF7C4DFF),
    _          => const Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Programme Fidélité'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off, color: AppTheme.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PointsCard(
                          points:         _points,
                          tier:           _tier,
                          tierColor:      _tierColor,
                          nextTierPoints: _nextTierPoints,
                          firstName:      _firstName,
                        ),
                        const SizedBox(height: 24),

                        const Text('Récompenses', style: AppTheme.headingMedium),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: _rewards
                              .map((r) => _RewardCard(reward: r, userPoints: _points))
                              .toList(),
                        ),
                        const SizedBox(height: 24),

                        const Text('Historique', style: AppTheme.headingMedium),
                        const SizedBox(height: 12),
                        if (_history.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border, width: 0.5),
                            ),
                            child: const Column(children: [
                              Icon(Icons.history, color: AppTheme.textMuted, size: 32),
                              SizedBox(height: 8),
                              Text('Aucune transaction', style: TextStyle(color: AppTheme.textSecondary)),
                            ]),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border, width: 0.5),
                            ),
                            child: Column(
                              children: _history.asMap().entries.map((e) {
                                final tx = e.value as Map<String, dynamic>;
                                final pts   = (tx['points'] ?? 0) as int;
                                final isPos = tx['type'] == 'EARN' || tx['type'] == 'ADMIN_ADJUST';
                                final desc  = (tx['description'] ?? tx['type'] ?? 'Transaction') as String;
                                final date  = (tx['createdAt'] as String? ?? '').split('T').first;
                                return Column(children: [
                                  _TransactionTile(label: desc, points: pts, isPositive: isPos, date: date),
                                  if (e.key < _history.length - 1)
                                    const Divider(height: 1, indent: 16, endIndent: 16),
                                ]);
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ── Points Card ──────────────────────────────────────────────────────────────

class _PointsCard extends StatelessWidget {
  final int points;
  final String tier;
  final Color tierColor;
  final int? nextTierPoints;
  final String firstName;

  const _PointsCard({
    required this.points,
    required this.tier,
    required this.tierColor,
    required this.nextTierPoints,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Icon(Icons.stars, color: Colors.black54, size: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tier,
                style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            '$points',
            style: const TextStyle(color: Colors.black, fontSize: 52, fontWeight: FontWeight.bold, letterSpacing: -2),
          ),
          const Text('points fidélité', style: TextStyle(color: Colors.black54, fontSize: 13)),
          if (nextTierPoints != null && nextTierPoints! > 0) ...[
            const SizedBox(height: 8),
            Text(
              'encore $nextTierPoints pts pour le palier suivant',
              style: const TextStyle(color: Colors.black45, fontSize: 11),
            ),
          ],
          if (firstName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(firstName, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// ── Reward Card ──────────────────────────────────────────────────────────────

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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              reward.label,
              style: TextStyle(color: canRedeem ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Text(
              '${reward.points} pts',
              style: TextStyle(color: canRedeem ? reward.color : AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Transaction Tile ─────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final String label;
  final int points;
  final bool isPositive;
  final String date;
  const _TransactionTile({required this.label, required this.points, required this.isPositive, required this.date});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isPositive ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
          color: isPositive ? AppTheme.success : AppTheme.error,
          size: 16,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        if (date.isNotEmpty)
          Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ])),
      Text(
        '${isPositive ? '+' : ''}$points pts',
        style: TextStyle(color: isPositive ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ]),
  );
}

// ── Data Classes ─────────────────────────────────────────────────────────────

class _Reward {
  final IconData icon;
  final String label;
  final int points;
  final Color color;
  const _Reward({required this.icon, required this.label, required this.points, required this.color});
}
