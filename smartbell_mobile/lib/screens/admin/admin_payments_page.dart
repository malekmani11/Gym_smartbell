import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/network/api_client.dart';
import '../../models/payment_model.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  List<PaymentModel> _payments = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  // Add form
  final _amountCtrl = TextEditingController();
  String _selectedMethod = 'CASH';
  bool _addLoading = false;

  // Member selection state
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _selectedMemberData;
  int? _selectedMemberId;
  int? _resolvedSubscriptionId;
  bool _loadingSubscription = false;

  static const _methods = ['CASH', 'CARD', 'BANK_TRANSFER', 'ONLINE'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadMembers();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient().dio.get('/payments', queryParameters: {
          'size': 50,
          'sort': 'paymentDate,desc',
        }),
        ApiClient().dio.get('/payments/stats').catchError((_) => Response(
              requestOptions: RequestOptions(path: '/payments/stats'),
              data: <String, dynamic>{},
              statusCode: 200,
            )),
      ]);

      final paymentsData = results[0].data;
      List<dynamic> content = [];
      if (paymentsData is Map && paymentsData.containsKey('content')) {
        content = paymentsData['content'] as List<dynamic>;
      } else if (paymentsData is List) {
        content = paymentsData;
      }

      setState(() {
        _payments = content
            .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final statsData = results[1].data;
        if (statsData is Map<String, dynamic>) {
          _stats = statsData;
        }
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Erreur de chargement';
        _loading = false;
      });
    }
  }

  Future<void> _loadMembers() async {
    try {
      final res = await ApiClient().dio.get(
        '/users/by-role',
        queryParameters: {'role': 'ROLE_MEMBER', 'size': 100},
      );
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      if (mounted) {
        setState(() => _members = List<Map<String, dynamic>>.from(list));
      }
    } catch (_) {}
  }

  Future<void> _fetchSubscription(
      int userId, void Function(void Function()) setModalState) async {
    setModalState(() => _loadingSubscription = true);
    try {
      final res = await ApiClient().dio.get('/subscriptions/user/$userId');
      final data = res.data;
      final items = data is Map
          ? (data['content'] ?? []) as List
          : (data ?? []) as List;
      final active = items
          .where((s) => s['status']?.toString().toUpperCase() == 'ACTIVE')
          .toList();
      final sub = active.isNotEmpty
          ? active.first
          : (items.isNotEmpty ? items.first : null);
      setModalState(() {
        _resolvedSubscriptionId =
            sub != null ? (sub['id'] as num).toInt() : null;
        _loadingSubscription = false;
      });
    } catch (_) {
      setModalState(() {
        _resolvedSubscriptionId = null;
        _loadingSubscription = false;
      });
    }
  }

  Future<void> _addPayment() async {
    if (_selectedMemberData == null || _resolvedSubscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Veuillez sélectionner un membre avec un abonnement actif'),
            backgroundColor: Color(0xFFA32D2D)),
      );
      return;
    }
    if (_amountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir le montant'),
            backgroundColor: Color(0xFFA32D2D)),
      );
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Montant invalide'),
            backgroundColor: Color(0xFFA32D2D)),
      );
      return;
    }

    setState(() => _addLoading = true);
    try {
      await ApiClient().dio.post('/payments', data: {
        'subscriptionId': _resolvedSubscriptionId,
        'amount': amount,
        'paymentMethod': _selectedMethod,
      });
      if (mounted) Navigator.of(context).pop();
      _amountCtrl.clear();
      setState(() {
        _selectedMemberData = null;
        _selectedMemberId = null;
        _resolvedSubscriptionId = null;
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Paiement ajouté avec succès'),
              backgroundColor: Color(0xFF3B6D11)),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.response?.data?['message'] ??
                  'Erreur lors de l\'ajout'),
              backgroundColor: const Color(0xFFA32D2D)),
        );
      }
    } finally {
      if (mounted) setState(() => _addLoading = false);
    }
  }

  Future<void> _exportPayments() async {
    if (_payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun paiement à exporter'), backgroundColor: Color(0xFF888888)),
      );
      return;
    }
    final lines = <String>['Référence,Membre,Date,Montant (DT),Méthode,Statut'];
    for (final p in _payments) {
      lines.add([
        p.transactionRef ?? (p.id?.toString() ?? ''),
        '"${p.memberName ?? 'Membre #${p.subscriptionId}'}"',
        _formatDate(p.paymentDate),
        p.amount.toStringAsFixed(2),
        _methodLabel(p.paymentMethod ?? ''),
        _statusLabel(p.status),
      ].join(','));
    }
    final csv = lines.join('\n');
    try {
      final file = File('${Directory.systemTemp.path}/paiements_smartbell.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Paiements SmartBell',
      );
    } catch (_) {
      await Share.share(csv, subject: 'Paiements SmartBell');
    }
  }

  void _onPaymentCardTap(PaymentModel payment) {
    Map<String, dynamic>? found;
    if (payment.memberName != null) {
      for (final m in _members) {
        final full = '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();
        if (full == payment.memberName) { found = m; break; }
      }
    }
    _showAddPaymentSheet(prefilledMember: found);
  }

  void _showAddPaymentSheet({Map<String, dynamic>? prefilledMember}) {
    _amountCtrl.clear();
    _selectedMethod = 'CASH';
    _selectedMemberData = prefilledMember;
    _selectedMemberId = prefilledMember != null
        ? (prefilledMember['id'] as num).toInt()
        : null;
    _resolvedSubscriptionId = null;
    _loadingSubscription = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Auto-fetch subscription if member was pre-filled
          if (_selectedMemberData != null && _resolvedSubscriptionId == null && !_loadingSubscription) {
            Future.microtask(() {
              final userId = (_selectedMemberData!['id'] as num).toInt();
              _fetchSubscription(userId, setModalState);
            });
          }
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 16),
              const Text('Enregistrer un paiement',
                  style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // ── Member dropdown ──────────────────────────────────
              DropdownButtonFormField<int>(
                value: _selectedMemberId,
                isExpanded: true,
                hint: const Text('Sélectionner un membre',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Membre',
                  labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF888888), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5A01A)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _members.map((m) {
                  final id   = (m['id'] as num).toInt();
                  final name = '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();
                  final email = m['email'] as String? ?? '';
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(email, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (id) async {
                  if (id == null) return;
                  final member = _members.firstWhere((m) => (m['id'] as num).toInt() == id);
                  setModalState(() {
                    _selectedMemberId   = id;
                    _selectedMemberData = member;
                    _resolvedSubscriptionId = null;
                  });
                  await _fetchSubscription(id, setModalState);
                },
              ),
              // Subscription status feedback
              if (_selectedMemberData != null) ...[
                const SizedBox(height: 8),
                if (_loadingSubscription)
                  const Row(
                    children: [
                      SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE5A01A))),
                      SizedBox(width: 8),
                      Text('Recherche de l\'abonnement…',
                          style: TextStyle(
                              color: Color(0xFF888888), fontSize: 12)),
                    ],
                  )
                else if (_resolvedSubscriptionId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3DE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B6D11)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF3B6D11), size: 14),
                        const SizedBox(width: 6),
                        Text(
                            'Abonnement #$_resolvedSubscriptionId trouvé',
                            style: const TextStyle(
                                color: Color(0xFF3B6D11), fontSize: 12)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA32D2D)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning,
                            color: Color(0xFFA32D2D), size: 14),
                        SizedBox(width: 6),
                        Text('Aucun abonnement trouvé',
                            style: TextStyle(
                                color: Color(0xFFA32D2D), fontSize: 12)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              _sheetField(
                  controller: _amountCtrl,
                  label: 'Montant (DT)',
                  icon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true)),
              const SizedBox(height: 12),
              // Method dropdown
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                dropdownColor: const Color(0xFFF5F5F0),
                style: const TextStyle(
                    color: Color(0xFF1A1A1A), fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Méthode de paiement',
                  labelStyle: const TextStyle(
                      color: Color(0xFF888888), fontSize: 13),
                  prefixIcon: const Icon(Icons.payment,
                      color: Color(0xFF888888), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5A01A)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                items: _methods
                    .map((m) => DropdownMenuItem<String>(
                          value: m,
                          child: Text(_methodLabel(m)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setModalState(() => _selectedMethod = v ?? 'CASH'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _addLoading ? null : _addPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: const Color(0xFFE5A01A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _addLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE5A01A)),
                        )
                      : const Text('Enregistrer',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: Color(0xFF888888), fontSize: 13),
        prefixIcon:
            Icon(icon, color: const Color(0xFF888888), size: 18),
        filled: true,
        fillColor: const Color(0xFFF5F5F0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5A01A)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Color _statusFg(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF3B6D11);
      case 'PENDING':
        return const Color(0xFF854F0B);
      case 'FAILED':
        return const Color(0xFFA32D2D);
      case 'REFUNDED':
        return const Color(0xFF888888);
      default:
        return const Color(0xFFBBBBBB);
    }
  }

  Color _statusBg(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFFEAF3DE);
      case 'PENDING':
        return const Color(0xFFFAEEDA);
      case 'FAILED':
        return const Color(0xFFFCEBEB);
      case 'REFUNDED':
        return const Color(0xFFF5F5F0);
      default:
        return const Color(0xFFF5F5F0);
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return 'Complété';
      case 'PENDING':
        return 'En attente';
      case 'FAILED':
        return 'Échoué';
      case 'REFUNDED':
        return 'Remboursé';
      default:
        return status ?? 'Inconnu';
    }
  }

  IconData _methodIcon(String? method) {
    switch (method?.toUpperCase()) {
      case 'CASH':
        return Icons.money;
      case 'CARD':
        return Icons.credit_card;
      case 'BANK_TRANSFER':
        return Icons.account_balance;
      case 'ONLINE':
        return Icons.language;
      default:
        return Icons.payment;
    }
  }

  String _methodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'Espèces';
      case 'CARD':
        return 'Carte';
      case 'BANK_TRANSFER':
        return 'Virement';
      case 'ONLINE':
        return 'En ligne';
      default:
        return method;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Regroupe les paiements par membre (clé = nom du membre)
  Map<String, List<PaymentModel>> get _groupedPayments {
    final map = <String, List<PaymentModel>>{};
    for (final p in _payments) {
      final key = p.memberName ?? 'Membre #${p.subscriptionId}';
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  Widget _buildStatsHeader() {
    final revenueMonth = _stats?['revenueThisMonth'] ?? 0.0;
    final revenueTotal = _stats?['totalRevenue'] ?? 0.0;
    final grouped = _groupedPayments;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ce mois',
                          style: TextStyle(
                              color: Color(0xFF666666), fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                          '${(revenueMonth as num).toStringAsFixed(2)} DT',
                          style: const TextStyle(
                              color: Color(0xFFE5A01A),
                              fontSize: 20,
                              fontWeight: FontWeight.w600)),
                      const Text('↑ +12%',
                          style: TextStyle(
                              color: Color(0xFF4CBA7D), fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: const Color(0xFFE8E8E8), width: 0.5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total général',
                          style: TextStyle(
                              color: Color(0xFF888888), fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                          '${(revenueTotal as num).toStringAsFixed(2)} DT',
                          style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 20,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '${grouped.length} membre${grouped.length > 1 ? 's' : ''} · ${_payments.length} paiement${_payments.length > 1 ? 's' : ''}',
              style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Paiements',
            style: TextStyle(
                color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () {},
              child: const Text('Exporter',
                  style: TextStyle(
                      color: Color(0xFFE5A01A), fontSize: 12)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFFE5A01A),
                        onRefresh: _loadData,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(child: _buildStatsHeader()),
                            _payments.isEmpty
                                ? SliverFillRemaining(child: _buildEmpty())
                                : SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 8),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (_, i) {
                                          final entries = _groupedPayments.entries.toList();
                                          final entry = entries[i];
                                          return _MemberPaymentGroup(
                                            memberName: entry.key,
                                            payments: entry.value,
                                            statusBg: _statusBg,
                                            statusFg: _statusFg,
                                            statusLabel: _statusLabel,
                                            methodIcon: _methodIcon,
                                            formatDate: _formatDate,
                                            onAddPayment: () {
                                              Map<String, dynamic>? found;
                                              for (final m in _members) {
                                                final full = '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();
                                                if (full == entry.key) { found = m; break; }
                                              }
                                              _showAddPaymentSheet(prefilledMember: found);
                                            },
                                          );
                                        },
                                        childCount: _groupedPayments.length,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: GestureDetector(
                        onTap: _showAddPaymentSheet,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,
                                  color: Color(0xFFE5A01A), size: 18),
                              SizedBox(width: 8),
                              Text('Ajouter un paiement',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFA32D2D), size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Color(0xFF888888))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: const Color(0xFFE5A01A)),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined,
              color: Color(0xFFBBBBBB), size: 64),
          SizedBox(height: 16),
          Text('Aucun paiement trouvé',
              style:
                  TextStyle(color: Color(0xFF888888), fontSize: 16)),
          SizedBox(height: 8),
          Text('Ajoutez un paiement via le bouton ci-dessous',
              style:
                  TextStyle(color: Color(0xFFBBBBBB), fontSize: 13)),
        ],
      ),
    );
  }
}

class _MemberPaymentGroup extends StatefulWidget {
  final String memberName;
  final List<PaymentModel> payments;
  final Color Function(String?) statusBg;
  final Color Function(String?) statusFg;
  final String Function(String?) statusLabel;
  final IconData Function(String?) methodIcon;
  final String Function(String?) formatDate;
  final VoidCallback onAddPayment;

  const _MemberPaymentGroup({
    required this.memberName,
    required this.payments,
    required this.statusBg,
    required this.statusFg,
    required this.statusLabel,
    required this.methodIcon,
    required this.formatDate,
    required this.onAddPayment,
  });

  @override
  State<_MemberPaymentGroup> createState() => _MemberPaymentGroupState();
}

class _MemberPaymentGroupState extends State<_MemberPaymentGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.payments.fold(0.0, (s, p) => s + p.amount);
    final count = widget.payments.length;
    final initial = widget.memberName.isNotEmpty
        ? widget.memberName[0].toUpperCase()
        : '?';
    final lastDate = widget.formatDate(widget.payments.first.paymentDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // ── En-tête membre ──────────────────────────────────────────
          InkWell(
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar initial
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAEEDA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(initial,
                          style: const TextStyle(
                              color: Color(0xFFBA7517),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Nom + nb paiements
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.memberName,
                            style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text(
                          '$count paiement${count > 1 ? 's' : ''} · dernier: $lastDate',
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Total + flèche
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${total.toStringAsFixed(2)} DT',
                          style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF888888),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Historique expandable ────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ...widget.payments.map((p) => _buildPaymentRow(p)),
            // Bouton ajouter un paiement pour ce membre
            InkWell(
              onTap: widget.onAddPayment,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAF8),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Color(0xFFE5A01A), size: 14),
                    SizedBox(width: 4),
                    Text('Ajouter un paiement',
                        style: TextStyle(
                            color: Color(0xFFE5A01A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentRow(PaymentModel p) {
    final bg = widget.statusBg(p.status);
    final fg = widget.statusFg(p.status);
    final label = widget.statusLabel(p.status);
    final icon = widget.methodIcon(p.paymentMethod);
    final date = widget.formatDate(p.paymentDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFBA7517), size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(date,
                style: const TextStyle(
                    color: Color(0xFF555555), fontSize: 12)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text(label,
                style: TextStyle(
                    color: fg, fontSize: 10, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Text('${p.amount.toStringAsFixed(2)} DT',
              style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
