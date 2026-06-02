import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/payment_model.dart';

class MemberPaymentsScreen extends StatefulWidget {
  const MemberPaymentsScreen({super.key});

  @override
  State<MemberPaymentsScreen> createState() => _MemberPaymentsScreenState();
}

class _MemberPaymentsScreenState extends State<MemberPaymentsScreen> {
  final _dio = DioClient.instance.dio;
  List<PaymentModel> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) { setState(() { _loading = false; }); return; }

      final res = await _dio.get(
        '/payments/user/${user.id}',
        queryParameters: {'size': 50, 'sort': 'paymentDate,desc'},
      );
      final content = res.data['content'] as List? ?? res.data as List? ?? [];
      setState(() {
        _payments = content.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE8E8E8)),
        ),
        title: const Text(
          'Mes Paiements',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: const Color(0xFFE5A01A),
                  backgroundColor: Colors.white,
                  onRefresh: _load,
                  child: _payments.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Color(0xFF888888)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _load,
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

  Widget _buildEmpty() => ListView(
    children: const [
      SizedBox(height: 120),
      Center(child: Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFFBBBBBB))),
      SizedBox(height: 16),
      Center(child: Text('Aucun paiement trouvé',
          style: TextStyle(color: Color(0xFF888888), fontSize: 16))),
    ],
  );

  Widget _buildList() {
    final total = _payments.fold(0.0, (sum, p) => sum + p.amount);
    final completed = _payments.where((p) => p.status == 'COMPLETED').length;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _SummaryCard(total: total, completed: completed, totalCount: _payments.length),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _PaymentTile(payment: _payments[i]),
              childCount: _payments.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double total;
  final int completed;
  final int totalCount;
  const _SummaryCard({required this.total, required this.completed, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total payé', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            '${total.toStringAsFixed(2)} DT',
            style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ]),
      )),
      const SizedBox(width: 10),
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Complétés', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            '$completed / $totalCount',
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ]),
      )),
    ]);
  }
}

// ── Payment Tile ──────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(payment.status);
    final methodIcon  = _methodIcon(payment.paymentMethod);
    final dateStr     = _formatDate(payment.paymentDate);

    Color statusBg, statusFg;
    switch (payment.status?.toUpperCase()) {
      case 'COMPLETED':
        statusBg = const Color(0xFFEAF3DE);
        statusFg = const Color(0xFF3B6D11);
        break;
      case 'PENDING':
        statusBg = const Color(0xFFFAEEDA);
        statusFg = const Color(0xFF854F0B);
        break;
      case 'FAILED':
        statusBg = const Color(0xFFFCEBEB);
        statusFg = const Color(0xFFA32D2D);
        break;
      default:
        statusBg = const Color(0xFFF5F5F0);
        statusFg = const Color(0xFF888888);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFAEEDA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(methodIcon, color: const Color(0xFFBA7517), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              '${payment.amount.toStringAsFixed(2)} DT',
              style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFFBBBBBB)),
            const SizedBox(width: 4),
            Text(dateStr, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
            const SizedBox(width: 10),
            const Icon(Icons.payment_outlined, size: 12, color: Color(0xFFBBBBBB)),
            const SizedBox(width: 4),
            Text(_methodLabel(payment.paymentMethod), style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          ]),
          if (payment.transactionRef != null) ...[
            const SizedBox(height: 3),
            Text(
              'Réf: ${payment.transactionRef}',
              style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ])),
      ]),
    );
  }

  String _statusLabel(String? status) => switch (status?.toUpperCase()) {
    'COMPLETED' => 'Complété',
    'PENDING'   => 'En attente',
    'FAILED'    => 'Échoué',
    'REFUNDED'  => 'Remboursé',
    _           => status ?? '—',
  };

  IconData _methodIcon(String? method) => switch (method?.toUpperCase()) {
    'CARD'          => Icons.credit_card,
    'BANK_TRANSFER' => Icons.account_balance,
    'ONLINE'        => Icons.language,
    _               => Icons.payments_outlined,
  };

  String _methodLabel(String? method) => switch (method?.toUpperCase()) {
    'CASH'          => 'Espèces',
    'CARD'          => 'Carte',
    'BANK_TRANSFER' => 'Virement',
    'ONLINE'        => 'En ligne',
    _               => method ?? '—',
  };

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
