import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../models/coach_model.dart';

class AdherentCoachesScreen extends StatefulWidget {
  const AdherentCoachesScreen({super.key});

  @override
  State<AdherentCoachesScreen> createState() => _AdherentCoachesScreenState();
}

class _AdherentCoachesScreenState extends State<AdherentCoachesScreen> {
  List<CoachModel> _coaches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }

  Future<void> _loadCoaches() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().dio.get('/users/by-role', queryParameters: {'role': 'ROLE_COACH', 'size': 50});
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

  Color _availabilityColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':   return AppColors.success;
      case 'BUSY':        return AppColors.warning;
      case 'UNAVAILABLE': return AppColors.error;
      default:            return AppColors.textMuted;
    }
  }

  String _availabilityLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':   return 'Disponible';
      case 'BUSY':        return 'Occupé';
      case 'UNAVAILABLE': return 'Indisponible';
      default:            return status ?? 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Nos Coachs',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final coach = _coaches[i];
                            return _CoachCard(
                              coach: coach,
                              availabilityColor: _availabilityColor(coach.availabilityStatus),
                              availabilityLabel: _availabilityLabel(coach.availabilityStatus),
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
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCoaches,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.black),
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
              Text('Aucun coach disponible',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              coach.firstName.isNotEmpty ? coach.firstName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.primary,
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
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (coach.specialization != null && coach.specialization!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.fitness_center,
                          color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        coach.specialization!,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: availabilityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: availabilityColor.withValues(alpha: 0.4)),
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
