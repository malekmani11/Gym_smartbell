import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../models/message.dart';
import '../services/message_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _coaches = [];
  bool _loadingCoaches = true;

  // Contrôle d'accès messagerie
  bool? _messagingEnabled;
  bool _checkingAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _checkAccess() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() { _messagingEnabled = false; _checkingAccess = false; });
      return;
    }
    try {
      final res  = await DioClient.instance.dio.get('/members/user/$userId');
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _messagingEnabled = data['messagingEnabled'] ?? false;
        _checkingAccess   = false;
      });
      if (_messagingEnabled == true) _loadCoaches();
    } catch (_) {
      setState(() { _messagingEnabled = false; _checkingAccess = false; });
    }
  }

  Future<void> _loadCoaches() async {
    setState(() => _loadingCoaches = true);
    try {
      final res  = await DioClient.instance.dio.get('/coaches', queryParameters: {'size': 100});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() { _coaches = List<Map<String, dynamic>>.from(list); _loadingCoaches = false; });
    } catch (_) { setState(() => _loadingCoaches = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _coaches;
    return _coaches.where((u) {
      final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?.id ?? 0;

    if (_checkingAccess) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A))),
      );
    }

    if (_messagingEnabled != true) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFA32D2D).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, color: Color(0xFFA32D2D), size: 38),
            ),
            const SizedBox(height: 20),
            const Text('Accès restreint',
                style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'La messagerie n\'est pas encore activée pour votre compte.\nContactez votre administrateur pour obtenir l\'accès.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.5),
            ),
          ]),
        ))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(children: [
        // Header
        Container(
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFFE5A01A), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Messagerie', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A01A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${_coaches.length} coachs',
                        style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un coach...',
                      hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF666666), size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Color(0xFF666666)),
                              onPressed: () { _searchCtrl.clear(); setState(() {}); })
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),

        // Liste coachs
        Expanded(
          child: _loadingCoaches
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
              : _filtered.isEmpty
                  ? const Center(child: Text('Aucun coach disponible', style: TextStyle(color: Color(0xFF888888))))
                  : RefreshIndicator(
                      color: const Color(0xFFE5A01A),
                      onRefresh: _loadCoaches,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final u    = _filtered[i];
                          final uid  = (u['userId'] ?? u['user']?['id'] ?? u['id'] ?? 0).toInt();
                          final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
                          final ini  = name.isNotEmpty
                              ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                              : 'C';
                          final spec = u['specialization'] as String? ?? u['email'] as String? ?? '';
                          return _MsgTile(
                            name: name.isNotEmpty ? name : 'Coach #${u['id']}',
                            initials: ini, sub: spec, role: 'Coach',
                            accentColor: const Color(0xFFE5A01A),
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ChatScreen(myUserId: myId, otherUserId: uid, otherName: name, otherInitials: ini),
                            )),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _MsgTile extends StatelessWidget {
  final String name, initials, sub, role;
  final Color accentColor;
  final VoidCallback onTap;
  const _MsgTile({required this.name, required this.initials, required this.sub,
      required this.role, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(initials, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w500))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(4)),
              child: Text(role, style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ]),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
          ],
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(border: Border.all(color: accentColor.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(20)),
          child: Text('Écrire', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
      ]),
    ),
  );
}

// ─── Chat Screen ─────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final int myUserId;
  final int otherUserId;
  final String otherName;
  final String otherInitials;

  const ChatScreen({
    super.key,
    required this.myUserId,
    required this.otherUserId,
    required this.otherName,
    required this.otherInitials,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service    = MessageService();
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Message> _messages = [];
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _service.getConversation(widget.myUserId, widget.otherUserId);
      if (mounted) {
        setState(() => _messages = msgs);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textCtrl.clear();
    try {
      final msg = await _service.sendMessage(
        senderId: widget.myUserId,
        receiverId: widget.otherUserId,
        content: text,
      );
      setState(() => _messages.add(msg));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(DioClient.errorMessage(e)),
          backgroundColor: const Color(0xFFA32D2D),
        ));
        _textCtrl.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE5A01A),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.otherInitials,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.otherName,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Commencez la conversation',
                      style: TextStyle(color: Color(0xFFBBBBBB)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _Bubble(
                      message: _messages[i],
                      isMine: _messages[i].senderId == widget.myUserId,
                    ),
                  ),
          ),
          // ── Input bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F0),
                      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textCtrl,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Color(0xFFE5A01A),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Color(0xFFE5A01A), size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    DateTime? time;
    try {
      if (message.sentAt != null) time = DateTime.parse(message.sentAt!);
    } catch (_) {}
    final timeFmt = time != null ? DateFormat('HH:mm').format(time) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFFE5A01A) : Colors.white,
                borderRadius: isMine
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                border: isMine ? null : Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMine ? Colors.white : const Color(0xFF1A1A1A),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (timeFmt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeFmt,
                      style: TextStyle(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.65)
                            : const Color(0xFFBBBBBB),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
