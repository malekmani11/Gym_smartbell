import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../models/coach_model.dart';

class AdminCoachesPage extends StatefulWidget {
  const AdminCoachesPage({super.key});

  @override
  State<AdminCoachesPage> createState() => _AdminCoachesPageState();
}

class _AdminCoachesPageState extends State<AdminCoachesPage> {
  List<CoachModel> _coaches = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  bool _addLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _specializationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().dio.get('/coaches', queryParameters: {'size': 100});
      final data = res.data;
      final content = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _coaches = (content as List)
            .map((e) => CoachModel.fromJson(e as Map<String, dynamic>))
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

  Future<void> _addCoach() async {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir les champs obligatoires'),
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
        'roleName':  'ROLE_COACH',
      });
      if (mounted) Navigator.of(context).pop();
      _firstNameCtrl.clear();
      _lastNameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _phoneCtrl.clear();
      _specializationCtrl.clear();
      await _loadCoaches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Coach ajouté avec succès'),
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

  void _showAddCoachSheet() {
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _phoneCtrl.clear();
    _specializationCtrl.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
              'Ajouter un coach',
              style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sheetField(
                      controller: _firstNameCtrl,
                      label: 'Prénom *',
                      icon: Icons.person_outline),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _sheetField(
                      controller: _lastNameCtrl,
                      label: 'Nom *',
                      icon: Icons.person_outline),
                ),
              ],
            ),
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
            const SizedBox(height: 12),
            _sheetField(
                controller: _specializationCtrl,
                label: 'Spécialisation',
                icon: Icons.fitness_center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _addLoading ? null : _addCoach,
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
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 18),
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

  Color _availabilityFg(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':   return const Color(0xFF3B6D11);
      case 'BUSY':        return const Color(0xFF854F0B);
      case 'UNAVAILABLE': return const Color(0xFFA32D2D);
      case 'ON_LEAVE':    return const Color(0xFF185FA5);
      default:            return const Color(0xFFBBBBBB);
    }
  }

  Color _availabilityBg(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':   return const Color(0xFFEAF3DE);
      case 'BUSY':        return const Color(0xFFFAEEDA);
      case 'UNAVAILABLE': return const Color(0xFFFCEBEB);
      case 'ON_LEAVE':    return const Color(0xFFDCEAF8);
      default:            return const Color(0xFFF5F5F0);
    }
  }

  String _availabilityLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':   return 'Disponible';
      case 'BUSY':        return 'Occupé';
      case 'UNAVAILABLE': return 'Indisponible';
      case 'ON_LEAVE':    return 'En congé';
      default:            return status ?? 'Inconnu';
    }
  }

  List<CoachModel> get _filteredCoaches {
    if (_search.trim().isEmpty) return _coaches;
    final q = _search.toLowerCase();
    return _coaches.where((c) {
      return c.fullName.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
    }).toList();
  }

  void _showCoachDetail(CoachModel coach) {
    final availBg = _availabilityBg(coach.availabilityStatus);
    final availFg = _availabilityFg(coach.availabilityStatus);
    final availLabel = _availabilityLabel(coach.availabilityStatus);
    final initiale = coach.firstName.isNotEmpty ? coach.firstName[0].toUpperCase() : '?';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Avatar + nom + badge
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE5A01A),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                initiale,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              coach.fullName,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: availBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                availLabel,
                style: TextStyle(
                  color: availFg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Note moyenne (étoiles)
            if (coach.ratingAvg != null) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ...List.generate(5, (i) {
                  final filled = i < coach.ratingAvg!.round();
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: const Color(0xFFE5A01A), size: 20,
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  coach.ratingAvg!.toStringAsFixed(1),
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ]),
            ],
            const SizedBox(height: 20),

            // Contact
            _DetailSection(
              title: 'Contact',
              items: [
                _DetailRow(icon: Icons.email_outlined,   label: 'Email',     value: coach.email),
                if (coach.phone != null && coach.phone!.isNotEmpty)
                  _DetailRow(icon: Icons.phone_outlined, label: 'Téléphone', value: coach.phone!),
              ],
            ),
            const SizedBox(height: 10),

            // Profil professionnel
            _DetailSection(
              title: 'Profil professionnel',
              items: [
                if (coach.specialization != null && coach.specialization!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.fitness_center,
                    label: 'Spécialisation',
                    value: CoachModel.specializationLabel(coach.specialization),
                  ),
                if (coach.certification != null && coach.certification!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.verified_outlined,
                    label: 'Certification',
                    value: coach.certification!,
                  ),
                if (coach.hireDate != null && coach.hireDate!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: "Date d'embauche",
                    value: coach.hireDate!.length >= 10
                        ? coach.hireDate!.substring(0, 10)
                        : coach.hireDate!,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Bio
            if (coach.bio != null && coach.bio!.isNotEmpty) ...[
              _DetailSection(
                title: 'Bio',
                items: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      coach.bio!,
                      style: const TextStyle(color: Color(0xFF555555), fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),

            // Bouton fermer
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                ),
                child: const Center(
                  child: Text(
                    'Fermer',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredCoaches;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Coachs',
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
                  '${_coaches.length}',
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
                        border: Border.all(
                            color: const Color(0xFFE8E8E8), width: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(
                            color: Color(0xFF1A1A1A), fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un coach...',
                          hintStyle: TextStyle(
                              color: Color(0xFFBBBBBB), fontSize: 13),
                          prefixIcon: Icon(Icons.search,
                              color: Color(0xFFBBBBBB), size: 18),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFFE5A01A),
                        onRefresh: _loadCoaches,
                        child: displayed.isEmpty
                            ? _buildEmpty()
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 8),
                                itemCount: displayed.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final coach = displayed[i];
                                  return _CoachCard(
                                    coach: coach,
                                    availabilityBg: _availabilityBg(
                                        coach.availabilityStatus),
                                    availabilityFg: _availabilityFg(
                                        coach.availabilityStatus),
                                    availabilityLabel: _availabilityLabel(
                                        coach.availabilityStatus),
                                    onTap: () => _showCoachDetail(coach),
                                  );
                                },
                              ),
                      ),
                    ),
                    // Bottom button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: GestureDetector(
                        onTap: _showAddCoachSheet,
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
                              Text('Ajouter un coach',
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
          const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Color(0xFF888888))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCoaches,
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
              Icon(Icons.school_outlined, color: Color(0xFFBBBBBB), size: 64),
              SizedBox(height: 16),
              Text('Aucun coach trouvé',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 16)),
              SizedBox(height: 8),
              Text('Ajoutez un coach via le bouton ci-dessous',
                  style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoachCard extends StatelessWidget {
  final CoachModel coach;
  final Color availabilityBg;
  final Color availabilityFg;
  final String availabilityLabel;
  final VoidCallback onTap;

  const _CoachCard({
    required this.coach,
    required this.availabilityBg,
    required this.availabilityFg,
    required this.availabilityLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initiale =
        coach.firstName.isNotEmpty ? coach.firstName[0].toUpperCase() : '?';

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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE5A01A),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(initiale,
                style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coach.fullName,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(coach.email,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 11)),
                if (coach.specialization != null && coach.specialization!.isNotEmpty)
                  Text(CoachModel.specializationLabel(coach.specialization),
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: availabilityBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(availabilityLabel,
                    style: TextStyle(
                        color: availabilityFg,
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
    ));
  }
}

// ── Detail modal widgets ───────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _DetailSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...items,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFE5A01A)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
              Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
