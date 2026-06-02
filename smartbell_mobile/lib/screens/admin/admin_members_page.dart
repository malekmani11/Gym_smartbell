import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../models/member_model.dart';

class AdminMembersPage extends StatefulWidget {
  const AdminMembersPage({super.key});

  @override
  State<AdminMembersPage> createState() => _AdminMembersPageState();
}

class _AdminMembersPageState extends State<AdminMembersPage> {
  List<MemberModel> _members = [];
  List<Map<String, dynamic>> _coaches = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int _selectedFilter = 0;

  // Add form controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _addLoading = false;

  static const _avatarColors = [
    [Color(0xFF534AB7), Colors.white],
    [Color(0xFF0F6E56), Colors.white],
    [Color(0xFF993C1D), Colors.white],
    [Color(0xFF185FA5), Colors.white],
    [Color(0xFF639922), Colors.white],
    [Color(0xFF993556), Colors.white],
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadCoaches();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    try {
      final res = await ApiClient().dio.get('/coaches', queryParameters: {'size': 100});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      if (mounted) setState(() => _coaches = List<Map<String, dynamic>>.from(list as List));
    } catch (_) {}
  }

  Future<void> _showCoachAssignSheet(MemberModel member) async {
    int? selectedCoachId   = member.assignedCoachId;
    bool messagingEnabled  = member.messagingEnabled;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)),
              )),

              // En-tête membre
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A01A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(member.fullName, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(member.email, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                ])),
              ]),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE8E8E8)),
              const SizedBox(height: 16),

              const Text('Affecter un coach', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Sélectionnez le coach responsable de ce membre', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 14),

              // Coach actuel
              if (member.assignedCoachId != null || member.assignedCoachName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A01A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5A01A).withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.sports, color: Color(0xFFE5A01A), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Coach actuel : ${member.assignedCoachName ?? 'ID ${member.assignedCoachId}'}',
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              // Dropdown coaches
              if (_coaches.isEmpty)
                const Center(child: Text('Aucun coach disponible', style: TextStyle(color: Color(0xFF888888), fontSize: 13)))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: selectedCoachId,
                      isExpanded: true,
                      hint: const Text('Choisir un coach', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                      dropdownColor: Colors.white,
                      iconEnabledColor: const Color(0xFF888888),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('— Aucun coach —', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                        ),
                        ..._coaches.map((c) {
                          final id   = (c['id'] as num).toInt();
                          final name = '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim();
                          final spec = c['specialization'] as String?;
                          return DropdownMenuItem<int?>(
                            value: id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(name, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w500)),
                                if (spec != null && spec.isNotEmpty)
                                  Text(spec, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (v) => setModal(() => selectedCoachId = v),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Toggle messagerie
              GestureDetector(
                onTap: () => setModal(() => messagingEnabled = !messagingEnabled),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: messagingEnabled
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
                        : const Color(0xFFF5F5F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: messagingEnabled
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                          : const Color(0xFFE8E8E8),
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      messagingEnabled ? Icons.chat_bubble_outline : Icons.chat_bubble_outline,
                      color: messagingEnabled ? const Color(0xFF3B82F6) : const Color(0xFF888888),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        'Accès à la messagerie',
                        style: TextStyle(
                          color: messagingEnabled ? const Color(0xFF3B82F6) : const Color(0xFF1A1A1A),
                          fontSize: 13, fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        messagingEnabled ? 'Activé — le membre peut contacter ses coachs' : 'Désactivé — accès restreint',
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                      ),
                    ])),
                    Switch(
                      value: messagingEnabled,
                      onChanged: (v) => setModal(() => messagingEnabled = v),
                      activeColor: const Color(0xFF3B82F6),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Boutons
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE8E8E8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setModal(() => saving = true);
                      try {
                        // Affectation coach (coachId omis = désaffectation)
                        await ApiClient().dio.patch(
                          '/members/${member.id}/assign-coach',
                          queryParameters: selectedCoachId != null
                              ? {'coachId': selectedCoachId}
                              : {},
                        );
                        // Accès messagerie
                        await ApiClient().dio.patch(
                          '/members/${member.id}/messaging-access',
                          queryParameters: {'enabled': messagingEnabled},
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadMembers();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(selectedCoachId == null
                                ? 'Coach retiré'
                                : 'Coach affecté avec succès'),
                            backgroundColor: const Color(0xFF4CBA7D),
                          ));
                        }
                      } on DioException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.response?.data?['message'] ?? 'Erreur'),
                            backgroundColor: const Color(0xFFA32D2D),
                          ));
                        }
                      } finally {
                        if (ctx.mounted) setModal(() => saving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFFE5A01A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))
                        : const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMembers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().dio.get('/members', queryParameters: {'size': 100});
      final data = res.data;
      final content = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _members = (content as List)
            .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Erreur de chargement';
        _loading = false;
      });
    }
  }

  Future<void> _addMember() async {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires'),
            backgroundColor: Color(0xFFA32D2D)),
      );
      return;
    }

    setState(() => _addLoading = true);
    try {
      await ApiClient().dio.post('/auth/register', data: {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName':  _lastNameCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'password':  _passwordCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty)
          'phone':   _phoneCtrl.text.trim(),
        'roleName':  'ROLE_MEMBER',
      });
      if (mounted) Navigator.of(context).pop();
      _firstNameCtrl.clear();
      _lastNameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _phoneCtrl.clear();
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Membre ajouté avec succès'),
              backgroundColor: Color(0xFF3B6D11)),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.response?.data?['message'] ?? 'Erreur lors de l\'ajout'),
              backgroundColor: const Color(0xFFA32D2D)),
        );
      }
    } finally {
      if (mounted) setState(() => _addLoading = false);
    }
  }

  void _showAddMemberSheet() {
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _phoneCtrl.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ajouter un membre',
                style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _sheetField(
                  controller: _firstNameCtrl, label: 'Prénom *', icon: Icons.person_outline),
              const SizedBox(height: 12),
              _sheetField(
                  controller: _lastNameCtrl, label: 'Nom *', icon: Icons.person_outline),
              const SizedBox(height: 12),
              _sheetField(
                  controller: _emailCtrl,
                  label: 'Email *',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _sheetField(
                  controller: _passwordCtrl,
                  label: 'Mot de passe *',
                  icon: Icons.lock_outline,
                  obscureText: true),
              const SizedBox(height: 12),
              _sheetField(
                  controller: _phoneCtrl,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _addLoading ? null : _addMember,
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
                              strokeWidth: 2, color: Color(0xFFE5A01A)),
                        )
                      : const Text('Ajouter',
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
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888)),
        prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 20),
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
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF3B6D11);
      case 'INACTIVE':
        return const Color(0xFFA32D2D);
      case 'SUSPENDED':
        return const Color(0xFF854F0B);
      default:
        return const Color(0xFFBBBBBB);
    }
  }

  Color _statusBg(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFFEAF3DE);
      case 'INACTIVE':
        return const Color(0xFFFCEBEB);
      case 'SUSPENDED':
        return const Color(0xFFFAEEDA);
      default:
        return const Color(0xFFF5F5F0);
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return 'Actif';
      case 'INACTIVE':
        return 'Inactif';
      case 'SUSPENDED':
        return 'Suspendu';
      default:
        return status ?? 'Inconnu';
    }
  }

  List<MemberModel> get _filteredMembers {
    var list = _members;

    // Filter by chip
    switch (_selectedFilter) {
      case 1:
        list = list.where((m) => m.membershipStatus?.toUpperCase() == 'ACTIVE').toList();
        break;
      case 2:
        list = list.where((m) {
          final s = m.membershipStatus?.toUpperCase();
          return s == 'INACTIVE' || s == 'EXPIRED';
        }).toList();
        break;
      case 3:
        list = list.where((m) {
          final s = m.membershipStatus?.toUpperCase();
          return s == 'SUSPENDED' || s == 'PENDING';
        }).toList();
        break;
    }

    // Filter by search text
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((m) {
      return m.fullName.toLowerCase().contains(q) ||
          m.email.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredMembers;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Membres',
            style: TextStyle(
                color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A01A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_members.length}',
                  style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
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
                    // Search bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un membre...',
                          hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: Color(0xFFBBBBBB), size: 18),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    // Filter chips
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _filterChip('Tous', 0),
                            const SizedBox(width: 8),
                            _filterChip('Actifs', 1),
                            const SizedBox(width: 8),
                            _filterChip('Expirés', 2),
                            const SizedBox(width: 8),
                            _filterChip('En attente', 3),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFFE5A01A),
                        onRefresh: _loadMembers,
                        child: displayed.isEmpty
                            ? _buildEmpty()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                                itemCount: displayed.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) => _MemberCard(
                                  member: displayed[i],
                                  index: i,
                                  statusBg: _statusBg(displayed[i].membershipStatus),
                                  statusFg: _statusColor(displayed[i].membershipStatus),
                                  statusLabel: _statusLabel(displayed[i].membershipStatus),
                                  avatarColors: _avatarColors,
                                  onTap: () => _showCoachAssignSheet(displayed[i]),
                                ),
                              ),
                      ),
                    ),
                    // Bottom button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: GestureDetector(
                        onTap: _showAddMemberSheet,
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
                              Icon(Icons.add, color: Color(0xFFE5A01A), size: 18),
                              SizedBox(width: 8),
                              Text('Ajouter un membre',
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

  Widget _filterChip(String label, int index) {
    final active = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border.all(
              color: active ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
              width: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFE5A01A) : const Color(0xFF888888),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Color(0xFF888888))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMembers,
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
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, color: Color(0xFFBBBBBB), size: 64),
              SizedBox(height: 16),
              Text('Aucun membre trouvé',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 16)),
              SizedBox(height: 8),
              Text('Ajoutez un membre via le bouton ci-dessous',
                  style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberModel member;
  final int index;
  final Color statusBg;
  final Color statusFg;
  final String statusLabel;
  final List<List<Color>> avatarColors;
  final VoidCallback onTap;

  const _MemberCard({
    required this.member,
    required this.index,
    required this.statusBg,
    required this.statusFg,
    required this.statusLabel,
    required this.avatarColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = avatarColors[index % avatarColors.length];
    final avatarBg = colors[0];
    final avatarFg = colors[1];
    final initiale =
        member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : '?';
    final hasCoach = member.assignedCoachId != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, color: avatarBg),
              alignment: Alignment.center,
              child: Text(initiale,
                  style: TextStyle(
                      color: avatarFg,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName,
                      style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  Text(member.email,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 11)),
                  if (hasCoach)
                    Row(children: [
                      const Icon(Icons.sports, size: 10, color: Color(0xFFE5A01A)),
                      const SizedBox(width: 3),
                      Text(
                        member.assignedCoachName ?? 'Coach #${member.assignedCoachId}',
                        style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ])
                  else
                    const Text('Aucun coach assigné',
                        style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusFg,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right,
                    size: 14, color: Color(0xFFCCCCCC)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
