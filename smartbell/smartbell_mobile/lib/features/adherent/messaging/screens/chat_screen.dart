import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
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
  List<Map<String, dynamic>> _coaches = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadCoaches(); }

  Future<void> _loadCoaches() async {
    setState(() => _loading = true);
    try {
      final res = await DioClient.instance.dio.get('/coaches', queryParameters: {'size': 50});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() { _coaches = List<Map<String, dynamic>>.from(list); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _coaches.isEmpty
              ? const Center(child: Text('Aucun coach disponible', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _coaches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final coach = _coaches[i];
                    final coachUserId = (coach['userId'] ?? coach['user']?['id'] ?? 0).toInt();
                    final name = '${coach['firstName'] ?? ''} ${coach['lastName'] ?? ''}'.trim();
                    final initials = name.isNotEmpty ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase() : 'C';
                    return _CoachTile(
                      name: name.isNotEmpty ? name : 'Coach',
                      initials: initials,
                      specialization: coach['specialization'],
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          myUserId: user?.id ?? 0,
                          otherUserId: coachUserId,
                          otherName: name.isNotEmpty ? name : 'Coach',
                          otherInitials: initials,
                        ),
                      )),
                    );
                  },
                ),
    );
  }
}

class _CoachTile extends StatelessWidget {
  final String name;
  final String initials;
  final String? specialization;
  final VoidCallback onTap;

  const _CoachTile({required this.name, required this.initials, this.specialization, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            child: Text(initials, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            if (specialization != null)
              Text(specialization!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
        ],
      ),
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
  void dispose() { _pollTimer?.cancel(); _textCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

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
          backgroundColor: AppTheme.error,
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            child: Text(widget.otherInitials, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Text(widget.otherName),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Commencez la conversation', style: TextStyle(color: AppTheme.textMuted)))
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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceAlt,
              border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.border, width: 0.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.border, width: 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.primary, width: 1)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
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
    try { if (message.sentAt != null) time = DateTime.parse(message.sentAt!); } catch (_) {}
    final timeFmt = time != null ? DateFormat('HH:mm').format(time) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            const CircleAvatar(radius: 14, backgroundColor: AppTheme.surface, child: Icon(Icons.person, color: AppTheme.textSecondary, size: 14)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: isMine ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                border: isMine ? null : Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(message.content, style: TextStyle(color: isMine ? Colors.black : AppTheme.textPrimary, fontSize: 14, height: 1.4)),
                  if (timeFmt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(timeFmt, style: TextStyle(color: isMine ? Colors.black54 : AppTheme.textMuted, fontSize: 10)),
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
