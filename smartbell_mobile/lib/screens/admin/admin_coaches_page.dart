import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
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
      final res = await ApiClient().dio.get('/users/by-role', queryParameters: {
        'role': 'ROLE_COACH',
        'size': 50,
      });
      final data = res.data;
      List<dynamic> content = [];
      if (data is Map && data.containsKey('content')) {
        content = data['content'] as List<dynamic>;
      } else if (data is List) {
        content = data;
      }
      setState(() {
        _coaches = content
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
            backgroundColor: AppColors.error),
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

  void _showAddCoachSheet() {
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _phoneCtrl.clear();
    _specializationCtrl.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ajouter un coach',
              style: TextStyle(
                  color: AppColors.textPrimary,
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
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

  Color _availabilityColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':
        return AppColors.success;
      case 'BUSY':
        return AppColors.warning;
      case 'UNAVAILABLE':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _availabilityLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':
        return 'Disponible';
      case 'BUSY':
        return 'Occupé';
      case 'UNAVAILABLE':
        return 'Indisponible';
      default:
        return status ?? 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Coachs',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_coaches.length}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCoachSheet,
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
                  onRefresh: _loadCoaches,
                  child: _coaches.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _coaches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final coach = _coaches[i];
                            return _CoachCard(
                              coach: coach,
                              availabilityColor:
                                  _availabilityColor(coach.availabilityStatus),
                              availabilityLabel:
                                  _availabilityLabel(coach.availabilityStatus),
                            );
                          },
                        ),
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
            onPressed: _loadCoaches,
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
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.school_outlined, color: AppColors.textMuted, size: 64),
              SizedBox(height: 16),
              Text('Aucun coach trouvé',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 16)),
              SizedBox(height: 8),
              Text('Ajoutez un coach via le bouton +',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoachCard extends StatelessWidget {
  final CoachModel coach;
  final Color availabilityColor;
  final String availabilityLabel;

  const _CoachCard({
    required this.coach,
    required this.availabilityColor,
    required this.availabilityLabel,
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
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.info.withValues(alpha: 0.15),
              border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              coach.firstName.isNotEmpty ? coach.firstName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.fullName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  coach.email,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                if (coach.specialization != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.fitness_center,
                          color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        coach.specialization!,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Availability badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: availabilityColor.withValues(alpha: 0.5), width: 1),
              boxShadow: [
                BoxShadow(color: availabilityColor.withValues(alpha: 0.15), blurRadius: 8, spreadRadius: -2),
              ],
            ),
            child: Text(
              availabilityLabel,
              style: TextStyle(
                  color: availabilityColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
