import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key});

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _motifCtrl  = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  String? _success;
  String? _error;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() { _motifCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary, surface: AppTheme.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) { _startDate = picked; }
        else { _endDate = picked; }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Veuillez sélectionner les dates');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'La date de fin doit être après la date de début');
      return;
    }

    setState(() { _submitting = true; _error = null; _success = null; });
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      // Get coach ID from user ID
      final coachRes = await DioClient.instance.dio.get(ApiConstants.coachByUser(user.id));
      final coachId  = (coachRes.data['id'] ?? 0).toInt();

      // Update coach availability status
      await DioClient.instance.dio.patch('${ApiConstants.coaches}/$coachId', data: {
        'availabilityStatus': 'UNAVAILABLE',
        'absenceStart': _startDate!.toIso8601String().split('T').first,
        'absenceEnd':   _endDate!.toIso8601String().split('T').first,
        'absenceReason': _motifCtrl.text.trim(),
      });

      setState(() {
        _success = 'Absence déclarée du ${_dateFmt.format(_startDate!)} au ${_dateFmt.format(_endDate!)}';
        _submitting = false;
        _motifCtrl.clear();
        _startDate = null;
        _endDate   = null;
      });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Déclarer une absence')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: AppTheme.info, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'Votre statut sera mis à "Indisponible" pendant la période sélectionnée.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  )),
                ]),
              ),
              const SizedBox(height: 24),

              // Success / Error banners
              if (_success != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_success!, style: const TextStyle(color: AppTheme.success, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              // Date fields
              const Text('Période d\'absence', style: AppTheme.headingSmall),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _DateField(
                  label: 'Date de début',
                  value: _startDate != null ? _dateFmt.format(_startDate!) : null,
                  onTap: () => _pickDate(true),
                )),
                const SizedBox(width: 12),
                Expanded(child: _DateField(
                  label: 'Date de fin',
                  value: _endDate != null ? _dateFmt.format(_endDate!) : null,
                  onTap: () => _pickDate(false),
                )),
              ]),
              const SizedBox(height: 20),

              // Reason
              const Text('Motif', style: AppTheme.headingSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motifCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Vacances, maladie, formation...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Motif requis' : null,
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.event_busy, size: 18),
                  label: const Text('Déclarer l\'absence'),
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

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateField({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value != null ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.border),
      ),
      child: Row(children: [
        Icon(Icons.calendar_today, size: 16, color: value != null ? AppTheme.primary : AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(
          value ?? label,
          style: TextStyle(color: value != null ? AppTheme.textPrimary : AppTheme.textMuted, fontSize: 13),
        )),
      ]),
    ),
  );
}
