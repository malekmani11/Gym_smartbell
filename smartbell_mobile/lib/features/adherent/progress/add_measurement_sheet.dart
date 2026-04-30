import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/measurement.dart';
import 'progress_service.dart';

class AddMeasurementSheet extends StatefulWidget {
  final int memberId;
  final double? lastHeight;
  final VoidCallback onSaved;

  const AddMeasurementSheet({
    super.key,
    required this.memberId,
    this.lastHeight,
    required this.onSaved,
  });

  @override
  State<AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<AddMeasurementSheet> {
  final _service    = ProgressService();
  final _weightCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  late final TextEditingController _heightCtrl;

  DateTime _date    = DateTime.now();
  bool _saving      = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _heightCtrl = TextEditingController(
      text: widget.lastHeight != null
          ? widget.lastHeight!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
    final height = double.tryParse(_heightCtrl.text.trim().replaceAll(',', '.'));

    if (weight == null || weight < 20 || weight > 400) {
      setState(() => _error = 'Poids invalide (20–400 kg)');
      return;
    }
    if (height == null || height < 100 || height > 250) {
      setState(() => _error = 'Taille invalide (100–250 cm)');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      final m = Measurement(
        memberId: widget.memberId,
        date:     _date,
        weight:   weight,
        height:   height,
        notes:    _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await _service.addMeasurement(widget.memberId, m);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(children: [
                const Icon(Icons.monitor_weight_outlined,
                    color: AppTheme.primary, size: 22),
                const SizedBox(width: 10),
                const Text('Nouvelle mesure', style: AppTheme.headingMedium),
              ]),
              const SizedBox(height: 4),
              const Text(
                'Enregistrez votre poids pour suivre votre évolution',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 22),

              // Date row
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.event_outlined,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMMM yyyy', 'fr_FR').format(_date),
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.expand_more,
                        color: AppTheme.textMuted, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 14),

              // Weight + Height in a row
              Row(children: [
                Expanded(
                  child: _NumField(
                    ctrl: _weightCtrl,
                    label: 'Poids (kg)',
                    icon: Icons.monitor_weight_outlined,
                    hint: '75.5',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumField(
                    ctrl: _heightCtrl,
                    label: 'Taille (cm)',
                    icon: Icons.height,
                    hint: '175',
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Ressenti, contexte particulier...',
                  prefixIcon:
                      Icon(Icons.notes_outlined, size: 18),
                ),
              ),

              // Error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 15),
                    const SizedBox(width: 6),
                    Text(_error!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 12)),
                  ]),
                ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2.5),
                        )
                      : const Text('Enregistrer'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final String hint;

  const _NumField({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        prefixIcon: Icon(icon, size: 16, color: AppTheme.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      ),
    );
  }
}
