import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';

class NotificationsScreen extends StatefulWidget {
  final int? userId;
  const NotificationsScreen({super.key, this.userId});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  String? _error;

  bool get _isUserMode => widget.userId != null;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final path = _isUserMode
          ? '/notifications/user/${widget.userId}'
          : '/notifications';
      final res  = await DioClient.instance.dio.get(path);
      final data = res.data;
      final list = data is List ? data : (data is Map ? (data['content'] ?? []) : []);
      setState(() {
        _notifs  = List<Map<String, dynamic>>.from(list)
          ..sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  Future<void> _markRead(int broadcastId) async {
    try {
      if (_isUserMode) {
        await DioClient.instance.dio.patch(
          '/notifications/$broadcastId/read/user/${widget.userId}',
          data: {},
        );
      } else {
        await DioClient.instance.dio.patch('/notifications/$broadcastId/read', data: {});
      }
      setState(() {
        _notifs = _notifs.map((n) =>
          (n['id'] ?? 0) == broadcastId ? {...n, 'isRead': true} : n
        ).toList();
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      if (_isUserMode) {
        // Marquer chaque notification non lue individuellement
        final unread = _notifs.where((n) => !(n['isRead'] ?? false)).toList();
        await Future.wait(unread.map((n) {
          final id = (n['id'] ?? 0) as int;
          return DioClient.instance.dio.patch(
            '/notifications/$id/read/user/${widget.userId}',
            data: {},
          );
        }));
      } else {
        await DioClient.instance.dio.patch('/notifications/mark-all-read', data: {});
      }
      setState(() {
        _notifs = _notifs.map((n) => {...n, 'isRead': true}).toList();
      });
    } catch (_) {}
  }

  int get _unreadCount => _notifs.where((n) => !(n['isRead'] ?? false)).length;

  Color _typeColor(String? type) {
    switch (type) {
      case 'WARNING':  return const Color(0xFFE5A01A);
      case 'ALERT':    return const Color(0xFFE53935);
      case 'REMINDER': return const Color(0xFF9333EA);
      default:         return const Color(0xFF3B82F6);
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'WARNING':  return Icons.warning_amber_outlined;
      case 'ALERT':    return Icons.error_outline;
      case 'REMINDER': return Icons.notifications_active_outlined;
      default:         return Icons.info_outline;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final diff = DateTime.now().difference(DateTime.parse(dateStr));
    if (diff.inSeconds < 60)  return 'à l\'instant';
    if (diff.inMinutes < 60)  return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24)    return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  // ── Broadcast modal (admin only) ────────────────────────────────────────────
  void _showBroadcastSheet() {
    final titleCtrl   = TextEditingController();
    final messageCtrl = TextEditingController();
    String type       = 'INFO';
    String target     = 'ALL';   // ALL | MEMBRES | COACHS
    bool   sending    = false;

    const types = [
      {'key': 'INFO',     'label': 'Info',    'color': Color(0xFF3B82F6)},
      {'key': 'WARNING',  'label': 'Avertissement', 'color': Color(0xFFE5A01A)},
      {'key': 'ALERT',    'label': 'Alerte',  'color': Color(0xFFE53935)},
      {'key': 'REMINDER', 'label': 'Rappel',  'color': Color(0xFF9333EA)},
    ];
    const targets = [
      {'key': 'ALL',     'label': 'Tous les utilisateurs'},
      {'key': 'MEMBRES', 'label': 'Membres uniquement'},
      {'key': 'COACHS',  'label': 'Coachs uniquement'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFF444444), borderRadius: BorderRadius.circular(2)),
                )),

                const Text('Diffuser une notification',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Titre
                _sheetLabel('Titre'),
                _sheetField(controller: titleCtrl, hint: 'Ex: Fermeture exceptionnelle'),
                const SizedBox(height: 14),

                // Message
                _sheetLabel('Message'),
                _sheetArea(controller: messageCtrl, hint: 'Contenu de la notification...'),
                const SizedBox(height: 14),

                // Type
                _sheetLabel('Type'),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: types.map((t) {
                    final selected = type == t['key'];
                    final c = t['color'] as Color;
                    return GestureDetector(
                      onTap: () => setModal(() => type = t['key'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? c.withValues(alpha: 0.18) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? c : const Color(0xFF3A3A3A),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(t['label'] as String,
                          style: TextStyle(color: selected ? c : const Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Destinataires
                _sheetLabel('Destinataires'),
                Column(
                  children: targets.map((t) {
                    final selected = target == t['key'];
                    return GestureDetector(
                      onTap: () => setModal(() => target = t['key'] as String),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFE5A01A).withValues(alpha: 0.10) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? const Color(0xFFE5A01A) : const Color(0xFF3A3A3A),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: selected ? const Color(0xFFE5A01A) : const Color(0xFF555555),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(t['label'] as String,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF888888),
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            )),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Boutons
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3A3A3A)),
                        ),
                        child: const Center(child: Text('Annuler', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: sending ? null : () async {
                        if (titleCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Titre et message requis'),
                            backgroundColor: Color(0xFFE53935),
                          ));
                          return;
                        }
                        setModal(() => sending = true);
                        try {
                          final body = <String, dynamic>{
                            'title':   titleCtrl.text.trim(),
                            'message': messageCtrl.text.trim(),
                            'type':    type,
                          };
                          if (target == 'ALL') {
                            body['targetAll'] = true;
                          } else if (target == 'MEMBRES') {
                            body['roleName'] = 'MEMBER';
                          } else {
                            body['roleName'] = 'COACH';
                          }
                          await DioClient.instance.dio.post('/notifications', data: body);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Notification diffusée avec succès'),
                              backgroundColor: Color(0xFF4CBA7D),
                            ));
                            _load();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Erreur : ${DioClient.errorMessage(e)}'),
                              backgroundColor: const Color(0xFFE53935),
                            ));
                          }
                        } finally {
                          if (ctx.mounted) setModal(() => sending = false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: sending ? const Color(0xFF444444) : const Color(0xFFE5A01A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.send, color: Color(0xFF1A1A1A), size: 16),
                              SizedBox(width: 6),
                              Text('Diffuser', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 14)),
                            ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );

  Widget _sheetField({required TextEditingController controller, String hint = ''}) =>
    TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 13),
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5A01A), width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  Widget _sheetArea({required TextEditingController controller, String hint = ''}) =>
    TextField(
      controller: controller,
      maxLines: 4,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 13),
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5A01A), width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      floatingActionButton: !_isUserMode
          ? FloatingActionButton(
              onPressed: _showBroadcastSheet,
              backgroundColor: const Color(0xFFE5A01A),
              foregroundColor: const Color(0xFF1A1A1A),
              child: const Icon(Icons.add_alert),
            )
          : null,
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
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (_unreadCount > 0)
                      Text('$_unreadCount non lue(s)', style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 11)),
                  ]),
                ),
                if (_unreadCount > 0)
                  GestureDetector(
                    onTap: _markAllRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A01A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Tout lire', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 11, fontWeight: FontWeight.w600)),
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
                  : _notifs.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: const Color(0xFFE5A01A),
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _notifs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _buildNotifCard(_notifs[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> n) {
    final id      = (n['id'] ?? 0) as int;
    final type    = n['type'] as String?;
    final title   = n['title'] as String? ?? '';
    final message = n['message'] as String? ?? '';
    final isRead  = n['isRead'] ?? false;
    final date    = n['createdAt'] as String?;
    final color   = _typeColor(type);

    return GestureDetector(
      onTap: isRead ? null : () => _markRead(id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFFFF9EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? const Color(0xFFE8E8E8) : const Color(0xFFE5A01A).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icône
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(type), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          // Contenu
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: TextStyle(
                color: const Color(0xFF1A1A1A),
                fontSize: 13, fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
              ))),
              if (!isRead)
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE5A01A), shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 3),
            Text(message, style: const TextStyle(color: Color(0xFF888888), fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              Text(_timeAgo(date), style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 10)),
              if (!isRead) ...[
                const SizedBox(width: 8),
                Text('· Appuyer pour marquer comme lu', style: TextStyle(color: const Color(0xFFE5A01A).withValues(alpha: 0.7), fontSize: 10)),
              ],
            ]),
          ])),
        ]),
      ),
    );
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

  Widget _buildEmpty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: const Color(0xFFE5A01A).withValues(alpha: 0.10), shape: BoxShape.circle),
        child: const Icon(Icons.notifications_none, color: Color(0xFFE5A01A), size: 36),
      ),
      const SizedBox(height: 12),
      const Text('Aucune notification', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('Vous êtes à jour !', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
    ],
  ));
}
