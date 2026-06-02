import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/providers/auth_provider.dart';
import '../services/loyalty_service.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final _service = LoyaltyService();
  final _dio     = DioClient.instance.dio;
  int?  _memberId;

  bool _loading = true;
  String? _error;

  int _points = 0;
  String _tier = 'BRONZE';
  int? _nextTierPoints;
  List<dynamic> _history = [];

  static const _rewards = [
    _Reward(icon: Icons.fitness_center,  label: 'Séance gratuite', points: 200,  color: Color(0xFFE5A01A)),
    _Reward(icon: Icons.blender,         label: 'Supplément',      points: 350,  color: Color(0xFF3B6D11)),
    _Reward(icon: Icons.checkroom,       label: 'T-shirt gym',     points: 500,  color: Color(0xFF185FA5)),
    _Reward(icon: Icons.spa,             label: 'Massage 30min',   points: 800,  color: Color(0xFFBA68C8)),
    _Reward(icon: Icons.card_membership, label: 'Mois gratuit',    points: 2000, color: Color(0xFFA32D2D)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Résoudre memberId depuis AuthProvider si pas encore chargé
      if (_memberId == null) {
        final user = context.read<AuthProvider>().user;
        if (user == null) {
          setState(() { _error = 'Utilisateur non connecté.'; _loading = false; });
          return;
        }
        try {
          final res = await _dio.get('/members/user/${user.id}');
          _memberId = ((res.data['id'] ?? res.data['userId'] ?? user.id) as num).toInt();
        } catch (_) {
          _memberId = user.id;
        }
      }
      final results = await Future.wait([
        _service.getBalance(_memberId!),
        _service.getHistory(_memberId!),
      ]);
      final balance = results[0] as Map<String, dynamic>;
      final history = results[1] as List<dynamic>;
      setState(() {
        _points         = (balance['loyaltyPoints'] ?? 0) as int;
        _tier           = (balance['tier'] ?? 'BRONZE') as String;
        _nextTierPoints = balance['nextTierPoints'] as int?;
        _history        = history;
        _loading        = false;
      });
    } catch (e) {
      setState(() { _error = 'Impossible de charger les données de fidélité.'; _loading = false; });
    }
  }

  String _formatTxDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw as String);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildError() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off, color: Color(0xFFA32D2D), size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFF888888))),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ]),
      );

  Widget _buildEmpty() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        ),
        child: const Column(children: [
          Icon(Icons.history, color: Color(0xFFBBBBBB), size: 32),
          SizedBox(height: 8),
          Text('Aucune transaction', style: TextStyle(color: Color(0xFF888888))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: const Text(
          'Fidélité',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFFE5A01A),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Points Card ──
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.stars, color: Color(0xFFE5A01A), size: 22),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _tier,
                                    style: const TextStyle(
                                      color: Color(0xFFE5A01A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 14),
                              Text(
                                '$_points',
                                style: const TextStyle(
                                  color: Color(0xFFE5A01A),
                                  fontSize: 52,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                'points fidélité',
                                style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                              ),
                              if (_nextTierPoints != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${_nextTierPoints! - _points} pts pour le niveau suivant',
                                  style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // ── Récompenses ──
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(
                            'Récompenses',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          itemCount: _rewards.length,
                          itemBuilder: (_, i) {
                            final reward = _rewards[i];
                            final canRedeem = _points >= reward.points;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: canRedeem ? const Color(0xFFE5A01A) : const Color(0xFFE8E8E8),
                                  width: canRedeem ? 1 : 0.5,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: reward.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(reward.icon, color: reward.color, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reward.label,
                                        style: const TextStyle(
                                          color: Color(0xFF1A1A1A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${reward.points} pts',
                                        style: const TextStyle(
                                          color: Color(0xFFE5A01A),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (canRedeem)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF3DE),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Dispo',
                                      style: TextStyle(
                                        color: Color(0xFF3B6D11),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ]),
                            );
                          },
                        ),

                        // ── Historique ──
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Text(
                            'Historique',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: _history.isEmpty
                              ? _buildEmpty()
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                                  ),
                                  child: Column(
                                    children: _history.asMap().entries.map((e) {
                                      final tx = e.value as Map<String, dynamic>;
                                      final pts = (tx['points'] as int? ?? 0);
                                      final isPos = pts > 0;
                                      return Column(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          child: Row(children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: isPos ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                isPos ? Icons.add : Icons.remove,
                                                color: isPos ? const Color(0xFF3B6D11) : const Color(0xFFA32D2D),
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tx['description'] ?? 'Transaction',
                                                    style: const TextStyle(
                                                      color: Color(0xFF1A1A1A),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatTxDate(tx['createdAt']),
                                                    style: const TextStyle(
                                                      color: Color(0xFFBBBBBB),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${isPos ? '+' : ''}$pts pts',
                                              style: TextStyle(
                                                color: isPos ? const Color(0xFF3B6D11) : const Color(0xFFA32D2D),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ]),
                                        ),
                                        if (e.key < _history.length - 1)
                                          const Divider(height: 0.5, color: Color(0xFFF5F5F0)),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ── Data Classes ─────────────────────────────────────────────────────────────

class _Reward {
  final IconData icon;
  final String label;
  final int points;
  final Color color;
  const _Reward({required this.icon, required this.label, required this.points, required this.color});
}
