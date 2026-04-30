import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../features/auth/providers/auth_provider.dart';
import '../../messaging/screens/chat_screen.dart';

class AdherentCoachesScreen extends StatefulWidget {
  const AdherentCoachesScreen({super.key});

  @override
  State<AdherentCoachesScreen> createState() => _AdherentCoachesScreenState();
}

class _AdherentCoachesScreenState extends State<AdherentCoachesScreen> {
  List<Map<String, dynamic>> _coaches = [];
  Map<int, double> _ratings = {};
  int? _selectedCoachId; // coachId (entity id) of chosen coach
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadCoaches(), _loadPrefs()]);
    setState(() => _loading = false);
  }

  Future<void> _loadCoaches() async {
    try {
      final res = await DioClient.instance.dio.get('/coaches', queryParameters: {'size': 100});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      _coaches = List<Map<String, dynamic>>.from(list);
    } catch (_) {}
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCoachId = prefs.getInt('gym_selected_coach_id');
    final ratingsRaw = prefs.getString('gym_coach_ratings') ?? '{}';
    try {
      final map = jsonDecode(ratingsRaw) as Map<String, dynamic>;
      _ratings = map.map((k, v) => MapEntry(int.parse(k), (v as num).toDouble()));
    } catch (_) {}
  }

  Future<void> _saveRating(int coachId, double rating) async {
    setState(() => _ratings[coachId] = rating);
    final prefs = await SharedPreferences.getInstance();
    final map = _ratings.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString('gym_coach_ratings', jsonEncode(map));
  }

  Future<void> _selectCoach(Map<String, dynamic> coach) async {
    final coachId = (coach['id'] ?? 0).toInt();
    final coachUserId = (coach['userId'] ?? coach['user']?['id'] ?? 0).toInt();
    final name = '${coach['firstName'] ?? ''} ${coach['lastName'] ?? ''}'.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gym_selected_coach_id', coachId);
    await prefs.setInt('gym_selected_coach_user_id', coachUserId);
    await prefs.setString('gym_selected_coach_name', name);

    setState(() => _selectedCoachId = coachId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name est maintenant votre coach référent'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _coaches;
    final q = _search.toLowerCase();
    return _coaches.where((c) {
      final name = '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.toLowerCase();
      final spec = (c['specialization'] ?? '').toString().toLowerCase();
      return name.contains(q) || spec.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nos Coachs'),
        backgroundColor: AppTheme.surfaceAlt,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un coach...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          if (_selectedCoachId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.verified, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Vos programmes seront envoyés à votre coach référent',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                  )),
                ]),
              ),
            ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filtered.isEmpty
                    ? const Center(child: Text('Aucun coach trouvé', style: TextStyle(color: AppTheme.textSecondary)))
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _loadAll,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final coach = _filtered[i];
                            final coachId = (coach['id'] ?? 0).toInt();
                            final coachUserId = (coach['userId'] ?? coach['user']?['id'] ?? 0).toInt();
                            final name = '${coach['firstName'] ?? ''} ${coach['lastName'] ?? ''}'.trim();
                            final initials = name.isNotEmpty
                                ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                                : 'C';
                            final isSelected = _selectedCoachId == coachId;
                            final rating = _ratings[coachId] ?? 0.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary.withValues(alpha: 0.5)
                                        : AppTheme.border,
                                    width: isSelected ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Coach info
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 28,
                                                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                                                child: Text(initials, style: const TextStyle(
                                                  color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                                              ),
                                              if (isSelected)
                                                Positioned(
                                                  right: 0, bottom: 0,
                                                  child: Container(
                                                    width: 16, height: 16,
                                                    decoration: const BoxDecoration(
                                                      color: AppTheme.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.check, color: Colors.black, size: 10),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(children: [
                                                  Text(name.isNotEmpty ? name : 'Coach',
                                                      style: const TextStyle(color: AppTheme.textPrimary,
                                                          fontWeight: FontWeight.bold, fontSize: 15)),
                                                  if (isSelected) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.primary.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text('Mon coach',
                                                          style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ]
                                                ]),
                                                if (coach['specialization'] != null)
                                                  Text(coach['specialization'],
                                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                                const SizedBox(height: 6),
                                                // Star rating
                                                _StarRating(
                                                  rating: rating,
                                                  onRate: (r) => _saveRating(coachId, r),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const Divider(height: 1, indent: 14, endIndent: 14),

                                    // Action buttons
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                      child: Row(
                                        children: [
                                          // Message button
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: coachUserId > 0 ? () => Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => ChatScreen(
                                                  myUserId: user?.id ?? 0,
                                                  otherUserId: coachUserId,
                                                  otherName: name.isNotEmpty ? name : 'Coach',
                                                  otherInitials: initials,
                                                )),
                                              ) : null,
                                              icon: const Icon(Icons.chat_outlined, size: 15),
                                              label: const Text('Message', style: TextStyle(fontSize: 12)),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.info,
                                                side: BorderSide(color: AppTheme.info.withValues(alpha: 0.4)),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Choose coach button
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: isSelected ? null : () => _selectCoach(coach),
                                              icon: Icon(isSelected ? Icons.check : Icons.person_add_outlined, size: 15),
                                              label: Text(isSelected ? 'Sélectionné' : 'Choisir', style: const TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isSelected ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.primary,
                                                foregroundColor: isSelected ? AppTheme.primary : Colors.black,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Star Rating Widget ────────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final double rating;
  final void Function(double) onRate;

  const _StarRating({required this.rating, required this.onRate});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      final filled = i < rating;
      return GestureDetector(
        onTap: () => onRate((i + 1).toDouble()),
        child: Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            color: filled ? const Color(0xFFE5C200) : AppTheme.textMuted,
            size: 18,
          ),
        ),
      );
    }),
  );
}
