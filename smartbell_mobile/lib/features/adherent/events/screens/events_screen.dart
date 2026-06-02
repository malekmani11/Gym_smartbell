import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';

class MemberEventsScreen extends StatefulWidget {
  const MemberEventsScreen({super.key});
  @override
  State<MemberEventsScreen> createState() => _MemberEventsScreenState();
}

class _MemberEventsScreenState extends State<MemberEventsScreen> {
  List<Map<String, dynamic>> _events = [];
  Set<int> _myEventIds = {};
  bool _loading = true;
  String? _error;
  final Set<int> _processing = {};

  final _dateFmt = DateFormat("dd MMM yyyy 'à' HH:mm", 'fr_FR');

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = DioClient.instance.dio;
      final evRes = await dio.get('/events', queryParameters: {'size': 50, 'sort': 'eventDate,asc'});
      final evData = evRes.data;
      final list = evData is Map ? (evData['content'] ?? []) : (evData ?? []);
      _events = List<Map<String, dynamic>>.from(list);

      // Mes inscriptions
      try {
        final myRes = await dio.get('/events/my-registrations');
        final myList = List<Map<String, dynamic>>.from(myRes.data ?? []);
        _myEventIds = myList
            .where((r) => r['status'] == 'REGISTERED')
            .map((r) => (r['eventId'] ?? 0) as int)
            .toSet();
      } catch (_) {}

      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  Future<void> _register(int eventId) async {
    setState(() => _processing.add(eventId));
    try {
      await DioClient.instance.dio.post('/events/$eventId/register');
      setState(() { _myEventIds.add(eventId); _processing.remove(eventId); });
      _showSnack('Inscription confirmée !', success: true);
    } catch (e) {
      setState(() => _processing.remove(eventId));
      _showSnack(DioClient.errorMessage(e), success: false);
    }
  }

  Future<void> _unregister(int eventId) async {
    setState(() => _processing.add(eventId));
    try {
      await DioClient.instance.dio.delete('/events/$eventId/register');
      setState(() { _myEventIds.remove(eventId); _processing.remove(eventId); });
      _showSnack('Inscription annulée', success: true);
    } catch (e) {
      setState(() => _processing.remove(eventId));
      _showSnack(DioClient.errorMessage(e), success: false);
    }
  }

  void _showSnack(String msg, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
      duration: const Duration(seconds: 2),
    ));
  }

  String _status(Map<String, dynamic> e) {
    final now      = DateTime.now();
    final date     = DateTime.tryParse(e['eventDate'] ?? '') ?? now;
    final count    = (e['registrationCount'] ?? 0) as int;
    final max      = (e['maxParticipants'] ?? 0) as int;
    if (count >= max && max > 0) return 'complet';
    if (date.isBefore(now)) return 'terminé';
    return 'disponible';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(children: [
        // Header
        Container(
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.canPop(context) ? Navigator.pop(context) : null,
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Événements', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Activités de la salle', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  ]),
                ),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
                    child: const Icon(Icons.refresh, color: Color(0xFFE5A01A), size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // Body
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
              : _error != null
                  ? _buildError()
                  : _events.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: const Color(0xFFE5A01A),
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _events.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _buildEventCard(_events[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final id       = (event['id'] ?? 0) as int;
    final title    = event['title'] as String? ?? 'Événement';
    final desc     = event['description'] as String? ?? '';
    final location = event['location'] as String? ?? '';
    final dateStr  = event['eventDate'] as String? ?? '';
    final count    = (event['registrationCount'] ?? 0) as int;
    final max      = (event['maxParticipants'] ?? 0) as int;
    final date     = DateTime.tryParse(dateStr);
    final status   = _status(event);
    final isRegistered = _myEventIds.contains(id);
    final isProcessing = _processing.contains(id);
    final fillPct  = max > 0 ? (count / max).clamp(0.0, 1.0) : 0.0;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'complet':  statusColor = const Color(0xFFE53935); statusLabel = 'COMPLET';    break;
      case 'terminé':  statusColor = const Color(0xFF888888); statusLabel = 'TERMINÉ';   break;
      default:         statusColor = const Color(0xFF4CAF50); statusLabel = 'À VENIR';   break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image + badge
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Stack(children: [
            Image.network(
              _getEventImage(title, desc),
              height: 140, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFE5A01A).withValues(alpha: 0.3), const Color(0xFF1A1A1A)],
                  ),
                ),
                child: const Center(child: Icon(Icons.event, color: Color(0xFFE5A01A), size: 48)),
              ),
            ),
            // Status badge
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            // Mes inscriptions badge
            if (isRegistered)
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Inscrit', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
          ]),
        ),

        // Contenu
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.bold)),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Color(0xFF888888), fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),

            // Date
            if (date != null)
              Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFFE5A01A)),
                const SizedBox(width: 6),
                Text(_dateFmt.format(date), style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
              ]),

            // Lieu
            if (location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFE5A01A)),
                const SizedBox(width: 6),
                Text(location, style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
              ]),
            ],
            const SizedBox(height: 10),

            // Barre remplissage
            if (max > 0) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Remplissage', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                Text('$count / $max', style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fillPct,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: AlwaysStoppedAnimation(
                    fillPct >= 1.0 ? const Color(0xFFE53935)
                    : fillPct >= 0.8 ? const Color(0xFFE5A01A)
                    : const Color(0xFF4CAF50),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Bouton inscription
            if (status != 'terminé')
              GestureDetector(
                onTap: isProcessing
                    ? null
                    : () => isRegistered ? _unregister(id) : _register(id),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isRegistered
                        ? const Color(0xFFFCEBEB)
                        : status == 'complet'
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRegistered
                          ? const Color(0xFFE53935).withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: isProcessing
                      ? const Center(child: SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A))))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(
                            isRegistered ? Icons.close : Icons.add,
                            size: 16,
                            color: isRegistered ? const Color(0xFFE53935)
                                : status == 'complet' ? const Color(0xFF888888) : const Color(0xFFE5A01A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRegistered ? "Annuler l'inscription"
                                : status == 'complet' ? "Complet"
                                : "S'inscrire",
                            style: TextStyle(
                              color: isRegistered ? const Color(0xFFE53935)
                                  : status == 'complet' ? const Color(0xFF888888) : const Color(0xFFE5A01A),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  String _getEventImage(String title, String desc) {
    final t = '${title.toLowerCase()} ${desc.toLowerCase()}';
    if (t.contains('padel') || t.contains('tennis')) { return 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=600&q=80&fit=crop'; }
    if (t.contains('yoga') || t.contains('méditation')) { return 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600&q=80&fit=crop'; }
    if (t.contains('nutrition') || t.contains('séminaire') || t.contains('conférence')) { return 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&q=80&fit=crop'; }
    if (t.contains('crossfit') || t.contains('wod')) { return 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=600&q=80&fit=crop'; }
    if (t.contains('boxe') || t.contains('combat') || t.contains('mma')) { return 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=600&q=80&fit=crop'; }
    if (t.contains('course') || t.contains('running') || t.contains('marathon')) { return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&q=80&fit=crop'; }
    if (t.contains('tournoi') || t.contains('compétition')) { return 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80&fit=crop'; }
    return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600&q=80&fit=crop';
  }

  Widget _buildError() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Color(0xFF888888)), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _load,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
          child: const Text('Réessayer', style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
        ),
      ),
    ],
  ));

  Widget _buildEmpty() => const Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.event_outlined, color: Color(0xFFBBBBBB), size: 56),
      SizedBox(height: 12),
      Text('Aucun événement disponible', style: TextStyle(color: Color(0xFF888888), fontSize: 15)),
    ],
  ));
}
