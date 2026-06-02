import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/providers/auth_provider.dart';

class CheckinHistoryScreen extends StatefulWidget {
  const CheckinHistoryScreen({super.key});

  @override
  State<CheckinHistoryScreen> createState() => _CheckinHistoryScreenState();
}

class _CheckinHistoryScreenState extends State<CheckinHistoryScreen> {
  List<Map<String, dynamic>> _checkins = [];
  int _totalThisMonth = 0;
  int _totalAll = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) { setState(() => _loading = false); return; }

      // Get member ID first
      int memberId = user.id;
      try {
        final mRes = await DioClient.instance.dio.get('/members/user/${user.id}');
        memberId = (mRes.data['id'] ?? user.id).toInt();
      } catch (_) {}

      final res = await DioClient.instance.dio.get('/checkins/member/$memberId');
      final raw = res.data;
      List<Map<String, dynamic>> list = [];

      int serverThisMonth = 0;
      int serverTotal = 0;

      if (raw is Map<String, dynamic>) {
        final content = raw['content'];
        if (content is List) {
          list = content.cast<Map<String, dynamic>>();
        }
        serverThisMonth = (raw['totalThisMonth'] as num? ?? 0).toInt();
        serverTotal = (raw['totalAll'] as num? ?? 0).toInt();
      } else if (raw is List) {
        list = raw.cast<Map<String, dynamic>>();
      }

      final now = DateTime.now();
      final calcThisMonth = serverThisMonth > 0
          ? serverThisMonth
          : list.where((item) {
              try {
                final dt = DateTime.parse(item['checkInTime'] as String? ?? '');
                return dt.year == now.year && dt.month == now.month;
              } catch (_) { return false; }
            }).length;

      setState(() {
        _checkins = list;
        _totalThisMonth = calcThisMonth;
        _totalAll = serverTotal > 0 ? serverTotal : list.length;
        _loading = false;
      });
    } catch (_) {
      // Backend endpoint not yet available — show empty state
      setState(() { _checkins = []; _totalThisMonth = 0; _totalAll = 0; _loading = false; });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return raw; }
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: const Text('Mes check-ins',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: const Color(0xFFE5A01A),
                  onRefresh: _load,
                  child: _checkins.isEmpty ? _buildEmpty() : _buildList(),
                ),
    );
  }

  Widget _buildList() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Résumé 2 colonnes ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ce mois', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('$_totalThisMonth',
                      style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 24, fontWeight: FontWeight.w600)),
                ]),
              )),
              const SizedBox(width: 10),
              Expanded(child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total visites', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('$_totalAll',
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 24, fontWeight: FontWeight.w600)),
                ]),
              )),
            ]),
          ),
        ),

        // ── Titre ─────────────────────────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Historique',
                style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ),

        // ── Liste ─────────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final item = _checkins[i];
                final time = item['checkInTime'] as String?;
                final status = (item['status'] as String? ?? '').toUpperCase();
                final isFailed = status == 'FAILED';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: isFailed ? const Color(0xFFFCEBEB) : const Color(0xFFEAF3DE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isFailed ? Icons.close : Icons.login,
                        color: isFailed ? const Color(0xFFA32D2D) : const Color(0xFF3B6D11),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_formatDate(time),
                          style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(_formatTime(time),
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFailed ? const Color(0xFFFCEBEB) : const Color(0xFFEAF3DE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isFailed ? 'Refusé' : 'Entrée',
                        style: TextStyle(
                          color: isFailed ? const Color(0xFFA32D2D) : const Color(0xFF3B6D11),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ]),
                );
              },
              childCount: _checkins.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() => ListView(
    children: const [
      SizedBox(height: 100),
      Center(child: Icon(Icons.calendar_today_outlined, color: Color(0xFFBBBBBB), size: 56)),
      SizedBox(height: 14),
      Center(child: Text('Aucun check-in enregistré',
          style: TextStyle(color: Color(0xFF888888), fontSize: 14))),
      SizedBox(height: 8),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Center(child: Text(
          "Scannez le QR code à l'entrée pour enregistrer vos visites",
          style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
          textAlign: TextAlign.center,
        )),
      ),
    ],
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_outlined, color: Color(0xFFA32D2D), size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Color(0xFF888888)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _load,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: const Text('Réessayer',
                style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );
}
