import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
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
  final _memberNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedMethod = 'CASH';
  bool _addLoading = false;

  // Member search state
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  Map<String, dynamic>? _selectedMemberData;
  int? _resolvedSubscriptionId;
  bool _loadingSubscription = false;
  bool _showSuggestions = false;

  static const _methods = ['CASH', 'CARD', 'BANK_TRANSFER', 'ONLINE'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadMembers();
  }

  @override
  void dispose() {
    _memberNameCtrl.dispose();
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
        ApiClient().dio.get('/payments/stats').catchError((_) =>
            Response(
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
      final items = data is Map ? (data['content'] ?? []) as List : (data ?? []) as List;
      final active = items.where(
          (s) => s['status']?.toString().toUpperCase() == 'ACTIVE').toList();
      final sub = active.isNotEmpty ? active.first : (items.isNotEmpty ? items.first : null);
      setModalState(() {
        _resolvedSubscriptionId = sub != null ? (sub['id'] as num).toInt() : null;
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
            content: Text('Veuillez sélectionner un membre avec un abonnement actif'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (_amountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir le montant'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Montant invalide'),
            backgroundColor: AppColors.error),
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
      _memberNameCtrl.clear();
      _amountCtrl.clear();
      setState(() {
        _selectedMemberData = null;
        _resolvedSubscriptionId = null;
        _filteredMembers = [];
        _showSuggestions = false;
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Paiement ajouté avec succès'),
              backgroundColor: AppColors.success),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.response?.data?['message'] ?? 'Erreur lors de l\'ajout'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _addLoading = false);
    }
  }

  void _showAddPaymentSheet() {
    _memberNameCtrl.clear();
    _amountCtrl.clear();
    _selectedMethod = 'CASH';
    _selectedMemberData = null;
    _resolvedSubscriptionId = null;
    _filteredMembers = [];
    _showSuggestions = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enregistrer un paiement',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // ── Member name search ──
              TextField(
                controller: _memberNameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nom du membre',
                  labelStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.person_search,
                      color: AppColors.textSecondary, size: 18),
                  suffixIcon: _memberNameCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary, size: 16),
                          onPressed: () {
                            _memberNameCtrl.clear();
                            setModalState(() {
                              _selectedMemberData = null;
                              _resolvedSubscriptionId = null;
                              _filteredMembers = [];
                              _showSuggestions = false;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface2,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (val) {
                  setModalState(() {
                    _selectedMemberData = null;
                    _resolvedSubscriptionId = null;
                    if (val.trim().isEmpty) {
                      _filteredMembers = [];
                      _showSuggestions = false;
                    } else {
                      final q = val.toLowerCase();
                      _filteredMembers = _members.where((m) {
                        final full =
                            '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'
                                .toLowerCase();
                        final email =
                            (m['email'] ?? '').toString().toLowerCase();
                        return full.contains(q) || email.contains(q);
                      }).take(5).toList();
                      _showSuggestions = _filteredMembers.isNotEmpty;
                    }
                  });
                },
              ),
              // Suggestions dropdown
              if (_showSuggestions) ...[
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: _filteredMembers.map((m) {
                      final fullName =
                          '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'
                              .trim();
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          _memberNameCtrl.text = fullName;
                          setModalState(() {
                            _selectedMemberData = m;
                            _showSuggestions = false;
                            _filteredMembers = [];
                          });
                          final userId = (m['id'] as num).toInt();
                          await _fetchSubscription(userId, setModalState);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  color: AppColors.textSecondary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fullName,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    Text(m['email'] ?? '',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
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
                              strokeWidth: 2, color: AppColors.primary)),
                      SizedBox(width: 8),
                      Text('Recherche de l\'abonnement…',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  )
                else if (_resolvedSubscriptionId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Text(
                            'Abonnement #$_resolvedSubscriptionId trouvé',
                            style: const TextStyle(
                                color: AppColors.success, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.error, size: 14),
                        SizedBox(width: 6),
                        Text('Aucun abonnement trouvé',
                            style: TextStyle(
                                color: AppColors.error, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              _sheetField(
                  controller: _amountCtrl,
                  label: 'Montant (DT)',
                  icon: Icons.attach_money,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              // Method dropdown
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                dropdownColor: AppColors.surface2,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Méthode de paiement',
                  labelStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.payment,
                      color: AppColors.textSecondary, size: 18),
                  filled: true,
                  fillColor: AppColors.surface2,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _addLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Enregistrer',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        filled: true,
        fillColor: AppColors.surface2,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      case 'REFUNDED':
        return AppColors.textSecondary;
      default:
        return AppColors.textMuted;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Paiements',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaymentSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Stats header
                      SliverToBoxAdapter(
                        child: _buildStatsHeader(),
                      ),
                      // Payments list
                      _payments.isEmpty
                          ? SliverFillRemaining(child: _buildEmpty())
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _PaymentCard(
                                      payment: _payments[i],
                                      statusColor: _statusColor(
                                          _payments[i].status),
                                      statusLabel: _statusLabel(
                                          _payments[i].status),
                                      methodIcon:
                                          _methodIcon(_payments[i].paymentMethod),
                                      formattedDate:
                                          _formatDate(_payments[i].paymentDate),
                                    ),
                                  ),
                                  childCount: _payments.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsHeader() {
    final revenueMonth = _stats?['revenueThisMonth'] ?? 0.0;
    final revenueTotal = _stats?['totalRevenue'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatsCard(
                  title: 'Revenus du mois',
                  value: '${(revenueMonth as num).toStringAsFixed(2)} DT',
                  icon: Icons.calendar_month,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatsCard(
                  title: 'Revenus totaux',
                  value: '${(revenueTotal as num).toStringAsFixed(2)} DT',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Historique des paiements (${_payments.length})',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black),
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
          Icon(Icons.payment_outlined, color: AppColors.textMuted, size: 64),
          SizedBox(height: 16),
          Text('Aucun paiement trouvé',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          SizedBox(height: 8),
          Text('Ajoutez un paiement via le bouton +',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final Color statusColor;
  final String statusLabel;
  final IconData methodIcon;
  final String formattedDate;

  const _PaymentCard({
    required this.payment,
    required this.statusColor,
    required this.statusLabel,
    required this.methodIcon,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Method icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(methodIcon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.memberName ?? 'Membre #${payment.subscriptionId}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(2)} DT',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
